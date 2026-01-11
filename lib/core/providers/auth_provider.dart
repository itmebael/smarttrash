import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/notification_data_service.dart';
import '../services/notification_service.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.data(null)) {
    _initializeAuth();
  }

  // Supabase Configuration
  // static const String _supabaseUrl = 'https://ssztyskjcoilweqmheef.supabase.co';
  // static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzenR5c2tqY29pbHdlcW1oZWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxODkxMjYsImV4cCI6MjA3Mzc2NTEyNn0.yP0Qihye9C7AiAhVN5_PBziCzfvgRlBu_dcdX9L9SSQ';

  SupabaseClient? _supabase;

  void _initializeAuth() {
    try {
      _supabase = Supabase.instance.client;
      print('✅ Supabase auth client initialized');

      _supabase!.auth.onAuthStateChange.listen((data) async {
        try {
          final AuthChangeEvent event = data.event;
          final Session? session = data.session;

          if (event == AuthChangeEvent.signedIn && session?.user != null) {
            await _loadUserData(session!.user.id);
          } else if (event == AuthChangeEvent.signedOut) {
            NotificationDataService.stopListening();
            state = const AsyncValue.data(null);
          }
        } catch (e) {
          print('Error in auth state change listener: $e');
          // Don't change state on error, just log it
        }
      });
    } catch (e) {
      print('❌ Supabase not available: $e');
      _supabase = null;
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      if (_supabase == null) {
        state = AsyncValue.error('Database connection not available', StackTrace.current);
        return;
      }

      try {
        final response =
            await _supabase!.from('users').select().eq('id', uid).single();

        final user = UserModel.fromMap(response);
        state = AsyncValue.data(user);

      try {
        // Pull the latest notifications and start listening for new ones
        await NotificationDataService.getAllNotifications(userId: user.id);
        NotificationDataService.startListening(userId: user.id);
      } catch (e) {
        print('⚠️  Notification listener setup failed: $e');
      }

        // Update FCM token
        await _updateFCMToken(user);
      } catch (e) {
        // If user not found in database (PGRST116)
        if (e.toString().contains('PGRST116') || e.toString().contains('0 rows')) {
          
          // Retry logic: Sometimes RLS or propagation causes a delay.
          // Wait a bit and try to load again BEFORE attempting to create.
          print('⏳ User not found. Waiting for consistency check...');
          await Future.delayed(const Duration(milliseconds: 500));
          
          try {
             final retryResponse = await _supabase!.from('users').select().eq('id', uid).single();
             final user = UserModel.fromMap(retryResponse);
             state = AsyncValue.data(user);
             print('✅ Loaded user record on retry.');
             // Also need to set up notifications and FCM here if we return early, 
             // but easier to just let it fall through or duplicate logic? 
             // Let's duplicate the setup logic for safety or extract it.
             // For minimal change, let's just proceed to setup.
             
             try {
                await NotificationDataService.getAllNotifications(userId: user.id);
                NotificationDataService.startListening(userId: user.id);
             } catch (_) {}
             await _updateFCMToken(user);
             return;
          } catch (retryError) {
             // If still failing, THEN try to create
             print('⚠️ User truly not found (PGRST116). Attempting to create record...');
             await _createMissingUserRecord(uid);
          }
        } else {
          print('⚠️ Error loading user data: $e');
          // Don't set error state - let the existing state stand or set to null
        }
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> _createMissingUserRecord(String uid) async {
    try {
      final user = _supabase?.auth.currentUser;
      if (user == null || user.id != uid) return;

      final email = user.email ?? '';
      final name = user.userMetadata?['name'] ?? email.split('@')[0];

      // Default values for new user
      final newUser = {
        'id': uid,
        'email': email,
        'name': name,
        'role': 'staff', // Default role
        'phone_number': '',
        'created_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };

      print('🛠️ Creating missing user record for $email ($uid)...');
      await _supabase!.from('users').insert(newUser);
      print('✅ Created missing user record successfully');

      // Retry loading
      // We call _loadUserData again, but we need to be careful about infinite recursion
      // The recursion is broken because if insert succeeds, select should succeed.
      // If insert fails, we go to catch block of _createMissingUserRecord
      final response =
          await _supabase!.from('users').select().eq('id', uid).single();
      final userModel = UserModel.fromMap(response);
      state = AsyncValue.data(userModel);
      
    } catch (e) {
      // Regardless of the error (duplicate key or otherwise), 
      // let's try to load the user one last time.
      // If the user exists in the DB, we should be able to load them.
      
      // If it's a duplicate key error, just log info, don't scream error
      if (e.toString().contains('23505') || (e is PostgrestException && e.code == '23505')) {
         print('ℹ️ User record already exists (Duplicate Key). Loading existing...');
      } else {
         print('⚠️ Failed to create user record (${e.toString().split('\n').first}). Attempting to load existing user...');
      }
      
      try {
        final response =
            await _supabase!.from('users').select().eq('id', uid).single();
        
        final userModel = UserModel.fromMap(response);
        state = AsyncValue.data(userModel);
        print('✅ Successfully loaded existing user record!');
        return; // Success!
      } catch (loadError) {
        print('❌ Failed to create AND failed to load user: $loadError');
        // This is a true failure
      }
    }
  }

  /// Reload current user data from database
  Future<void> reloadUser() async {
    final currentUser = state.value;
    if (currentUser != null) {
      await _loadUserData(currentUser.id);
    } else {
      final session = _supabase?.auth.currentSession;
      if (session?.user != null) {
        await _loadUserData(session!.user.id);
      }
    }
  }

  Future<void> _updateFCMToken(UserModel user) async {
    try {
      if (_supabase == null) return;

      final fcmToken = await NotificationService.getFCMToken();
      if (fcmToken != null) {
        await _supabase!
            .from('users')
            .update({'fcmToken': fcmToken}).eq('id', user.id);
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    print('=== LOGIN START ===');
    print('Email: $email');
    print('Password: $password');

    try {
      // Set loading state
      state = const AsyncValue.loading();

      // Check hardcoded ADMIN
      if (email == 'admin@ssu.edu.ph' && password == 'admin123') {
        print('✅ HARDCODED ADMIN LOGIN!');
        
        const adminId = '00000000-0000-0000-0000-000000000001';
        
        final user = UserModel(
          id: adminId,
          email: 'admin@ssu.edu.ph',
          name: 'System Administrator',
          phoneNumber: '+639123456789',
          role: UserRole.admin,
          department: 'Administration',
          position: 'System Administrator',
          createdAt: DateTime.now(),
          isActive: true,
        );

        state = AsyncValue.data(user);
        
        try {
          await NotificationDataService.getAllNotifications(userId: adminId);
          NotificationDataService.startListening(userId: adminId);
        } catch (e) {
          print('⚠️  Notification listener setup failed for admin: $e');
        }

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', adminId);
          await prefs.setString('userRole', 'admin');
        } catch (e) {
          print('⚠️ SharedPreferences error: $e');
        }
        
        print('✅ Admin logged in successfully!');
        return true;
      }

      // Try Supabase authentication (database users)
      print('🔍 Checking database for user...');
      
      if (_supabase == null) {
        print('❌ Supabase not initialized');
        state = AsyncValue.error('Database connection not available', StackTrace.current);
        return false;
      }

      final response = await _supabase!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user != null) {
        print('✅ Database authentication success!');
        await _loadUserData(response.user!.id);
        
        // If user not in database, create basic user object so they can still login
        if (state.value == null) {
          print('⚠️ User not in database, creating basic user object...');
          // Get email from the login attempt (since auth response might not have it)
          final basicUser = UserModel(
            id: response.user!.id,
            email: email, // Use the email from login attempt
            name: response.user!.userMetadata?['name']?.toString() ?? email.split('@')[0], // Use part of email as name
            phoneNumber: response.user!.userMetadata?['phone_number']?.toString() ?? '+63-0000000000', // Default phone
            role: UserRole.staff, // Default to staff
            createdAt: DateTime.now(),
            isActive: true,
          );
          state = AsyncValue.data(basicUser);
          print('✅ Basic user object created: ${basicUser.email}');

          try {
            await NotificationDataService.getAllNotifications(
              userId: basicUser.id,
            );
            NotificationDataService.startListening(userId: basicUser.id);
          } catch (e) {
            print('⚠️  Notification listener setup failed for basic user: $e');
          }
        }
        
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', response.user!.id);
          
          if (state.value != null) {
            final userRole = state.value!.role == UserRole.admin ? 'admin' : 'staff';
            await prefs.setString('userRole', userRole);
            print('✅ User role from database: $userRole');
          }
        } catch (prefsError) {
          print('⚠️ SharedPreferences error: $prefsError');
        }
        
        return true;
      }

      print('❌ Login failed - Invalid credentials');
      state = AsyncValue.error('Invalid email or password', StackTrace.current);
      return false;
      
    } catch (e) {
      print('❌ Login exception: $e');
      state = AsyncValue.error('Invalid email or password', StackTrace.current);
      return false;
    } finally {
      print('=== LOGIN END ===');
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      state = const AsyncValue.loading();

      final response = await _supabase!.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone_number': phoneNumber,
          'role': role.name,
        },
      );

      if (response.user != null) {
        final user = UserModel(
          id: response.user!.id,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          role: role,
          createdAt: DateTime.now(),
        );

        // Save user data to Supabase
        try {
          await _supabase!.from('users').insert(user.toMap());
        } catch (e) {
          // If insert fails (e.g. user already exists), we should still proceed
          // The user is authenticated in Auth, so we just need to ensure the user record exists
          print('⚠️ Registration insert warning: $e');
          
          // Try to load existing if insert failed
          try {
            final existing = await _supabase!.from('users').select().eq('id', user.id).single();
            print('✅ Found existing user record during registration, proceeding...');
          } catch (loadError) {
             print('❌ Could not verify user record: $loadError');
             // We continue anyway since auth succeeded
          }
        }

        state = AsyncValue.data(user);

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userId', response.user!.id);

        return true;
      }
      return false;
    } on AuthException catch (e) {
      String message = 'An error occurred during registration';
      switch (e.message) {
        case 'Password should be at least 6 characters':
          message = 'Password is too weak';
          break;
        case 'User already registered':
          message = 'An account already exists with this email';
          break;
        case 'Invalid email':
          message = 'Invalid email address';
          break;
      }
      state = AsyncValue.error(message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  // Constants from main.dart
  static const _supabaseUrl = 'https://ssztyskjcoilweqmheef.supabase.co';
  static const _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzenR5c2tqY29pbHdlcW1oZWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxODkxMjYsImV4cCI6MjA3Mzc2NTEyNn0.yP0Qihye9C7AiAhVN5_PBziCzfvgRlBu_dcdX9L9SSQ';
  /// Returns the User ID if successful, null otherwise
  Future<String?> registerStaff({
    required String email,
    required String password,
    required String name,
    String phoneNumber = '+63-0000000000',
    String? department,
    String? position,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    int? age,
    DateTime? dateOfBirth,
    String? emergencyContact,
    String? emergencyPhone,
  }) async {
    try {
      print('🛠️ Registering staff account...');

      // 1. Try using the secure Edge Function first (Best Practice)
      try {
        print('⚡ Attempting to create user via Edge Function (create-user)...');
        final functionResponse = await _supabase!.functions.invoke(
          'create-user',
          body: {
            'email': email,
            'password': password,
            'name': name,
            'phone_number': phoneNumber,
            'role': 'staff',
            if (department != null) 'department': department,
            if (position != null) 'position': position,
            if (address != null) 'address': address,
            if (city != null) 'city': city,
            if (state != null) 'state': state,
            if (zipCode != null) 'zip_code': zipCode,
            if (age != null) 'age': age,
            if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String(),
            if (emergencyContact != null) 'emergency_contact': emergencyContact,
            if (emergencyPhone != null) 'emergency_phone': emergencyPhone,
          },
        );

        if (functionResponse.status == 200) {
          final data = functionResponse.data;
          print('✅ User created successfully via Edge Function: ${data['user']['id']}');
          return data['user']['id'];
        } else {
          print('⚠️ Edge Function returned error status: ${functionResponse.status}');
          if (functionResponse.status != 404) {
             // If it's not a 404 (Function not found), it might be a real error like duplicate email
             // so we should probably stop here or log it clearly
             print('   Error details: ${functionResponse.data}');
          }
        }
      } catch (e) {
        print('⚠️ Edge Function call failed: $e');
        print('   (This is normal if the function is not deployed yet)');
      }

      print('🔄 Falling back to client-side creation (Legacy method)...');
      
      // 2. Fallback: Use a separate client to avoid affecting the main session (Admin session)
      // Using pure Dart SupabaseClient to avoid Flutter persistence conflicts
      // We use AuthFlowType.implicit to avoid needing asyncStorage (PKCE requires storage)
      final tempClient = SupabaseClient(
        _supabaseUrl, 
        _supabaseAnonKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

      final response = await tempClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone_number': phoneNumber,
          'role': 'staff',
        },
      );

      if (response.user != null) {
        final userId = response.user!.id;
        final user = UserModel(
          id: userId,
          email: email,
          name: name,
          phoneNumber: phoneNumber,
          role: UserRole.staff,
          createdAt: DateTime.now(),
          department: department,
          position: position,
          address: address,
          city: city,
          state: state,
          zipCode: zipCode,
          age: age,
          dateOfBirth: dateOfBirth,
          emergencyContact: emergencyContact,
          emergencyPhone: emergencyPhone,
        );

        // Save user data to Supabase
              try {
                // Try upsert to handle cases where the user might already exist (e.g. via trigger)
                await tempClient.from('users').upsert(user.toMap());
                print('✅ Staff user inserted/updated into database via temp client');
              } catch (e) {
                print('⚠️ Registration insert warning (temp client): $e');
                try {
                  print('🔄 Retrying insert with main (Admin) client...');
                  // Admin client should have permission to insert/update users
                  await _supabase!.from('users').upsert(user.toMap());
                  print('✅ Staff user inserted/updated into database via Admin client');
                } catch (e2) {
                  print('❌ Insert failed with both clients: $e2');
                  // CRITICAL: Throw error so the UI knows the operation failed
                  throw Exception('Account created but failed to save profile data. Please contact support.'); 
                }
              }
        
        return userId;
      }
      return null;

    } on AuthException catch (e) {
      print('❌ Staff registration failed: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Staff registration error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      print('=== LOGOUT START ===');
      print('🔐 Starting logout process...');
      
      // Step 1: Sign out from Supabase FIRST (before clearing state)
      // Use global scope to ensure session is fully cleared across devices
      // Add timeout to prevent hanging
      print('🔓 Signing out from Supabase (global scope)...');
      if (_supabase != null) {
        try {
          await _supabase!.auth.signOut(scope: SignOutScope.global)
              .timeout(
                const Duration(seconds: 3),
                onTimeout: () {
                  print('⚠️  Supabase signOut timeout - continuing anyway');
                },
              );
          print('✅ Supabase signOut successful');
        } catch (e) {
          print('⚠️  Supabase signOut error (continuing): $e');
        }
      }

      // Stop notification listener
      NotificationDataService.stopListening();

      // Step 2: Clear ALL local storage
      print('🗑️  Clearing local storage...');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isLoggedIn');
        await prefs.remove('userId');
        await prefs.remove('userEmail');
        await prefs.remove('userRole');
        print('✅ Local storage cleared');
      } catch (e) {
        print('⚠️  Error clearing local storage: $e');
      }
      
      // Step 3: Clear auth state LAST (after Supabase signOut)
      // This prevents the auth state listener from reloading the user
      print('📝 Clearing auth state...');
      state = const AsyncValue.data(null);
      print('✅ Auth state cleared');
      
      print('✅ Logout complete - user state is null');
      print('=== LOGOUT END ===');
    } catch (e) {
      print('❌ Logout error: $e');
      // Even if there's an error, still clear the state
      try {
        NotificationDataService.stopListening();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('isLoggedIn');
        await prefs.remove('userId');
        await prefs.remove('userEmail');
        await prefs.remove('userRole');
      } catch (_) {}
      
      state = const AsyncValue.data(null);
      print('✅ State cleared despite error');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
    String? department,
    String? position,
    String? address,
    String? city,
    String? province,
    String? zipCode,
  }) async {
    try {
      final currentUser = this.state.valueOrNull;
      if (currentUser == null) return;

      this.state = const AsyncValue.loading();

      await _supabase!.from('users').update({
        if (name != null) 'name': name,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
        if (department != null) 'department': department,
        if (position != null) 'position': position,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (province != null) 'state': province,
        if (zipCode != null) 'zip_code': zipCode,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser.id);

      // Reload user data from database
      await reloadUser();
    } catch (e) {
      this.state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _supabase!.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Update password in Supabase
      await _supabase!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _supabase!.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send password reset email: ${e.toString()}');
    }
  }

  Future<bool> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final userId = prefs.getString('userId');

      if (isLoggedIn && userId != null) {
        // Check if it's the hardcoded admin
        if (userId == '00000000-0000-0000-0000-000000000001') {
          print('🔑 Restoring hardcoded admin session');
          final user = UserModel(
            id: userId,
            email: 'admin@ssu.edu.ph',
            name: 'System Administrator',
            phoneNumber: '+639123456789',
            role: UserRole.admin,
            department: 'Administration',
            position: 'System Administrator',
            createdAt: DateTime.now(),
            isActive: true,
          );
          state = AsyncValue.data(user);
          try {
            await NotificationDataService.getAllNotifications(userId: user.id);
            NotificationDataService.startListening(userId: user.id);
          } catch (e) {
            print('⚠️  Notification listener setup failed while restoring admin: $e');
          }
          print('✅ Admin session restored');
          return true;
        }

        // Try to restore online Supabase session
        if (_supabase != null) {
          final user = _supabase!.auth.currentUser;
          if (user != null) {
            await _loadUserData(user.id);
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Providers
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAdmin ?? false;
});

final isStaffProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isStaff ?? false;
});

