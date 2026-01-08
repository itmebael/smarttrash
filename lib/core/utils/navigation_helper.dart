import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

/// Helper class for consistent navigation behavior
class NavigationHelper {
  /// Navigate back to the appropriate dashboard based on user role
  static void navigateToDashboard(BuildContext context, WidgetRef ref) {
    print('=== NavigateToDashboard START ===');
    
    // First try currentUserProvider
    final user = ref.read(currentUserProvider);
    print('currentUserProvider: $user');
    
    if (user != null) {
      print('User found via currentUserProvider');
      print('User role: ${user.role}');
      
      if (user.role == UserRole.admin) {
        print('✅ Navigating to admin dashboard');
        context.go('/dashboard');
      } else {
        print('✅ Navigating to staff dashboard');
        context.go('/staff-dashboard');
      }
      return;
    }
    
    // Try to get user from auth state directly
    print('currentUserProvider was null, checking authProvider...');
    final authState = ref.read(authProvider);
    print('authProvider state: $authState');
    
    final userFromAuth = authState.when(
      data: (authUser) {
        print('Auth data: $authUser');
        return authUser;
      },
      loading: () {
        print('Auth loading...');
        return null;
      },
      error: (error, stack) {
        print('Auth error: $error');
        return null;
      },
    );
    
    if (userFromAuth != null) {
      print('✅ Got user from auth state: ${userFromAuth.email}');
      print('User role: ${userFromAuth.role}');
      
      if (userFromAuth.role == UserRole.admin) {
        print('✅ Navigating to admin dashboard');
        context.go('/dashboard');
      } else {
        print('✅ Navigating to staff dashboard');
        context.go('/staff-dashboard');
      }
      return;
    }
    
    // Last resort: check SharedPreferences
    print('Checking SharedPreferences...');
    _checkStoredSession(context);
  }
  
  static Future<void> _checkStoredSession(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      final userRole = prefs.getString('userRole') ?? '';
      
      print('Stored session - isLoggedIn: $isLoggedIn, role: $userRole');
      
      if (isLoggedIn && userRole.isNotEmpty) {
        if (userRole == 'admin') {
          print('✅ Using stored session - going to admin dashboard');
          if (context.mounted) {
            context.go('/dashboard');
          }
          return;
        } else if (userRole == 'staff') {
          print('✅ Using stored session - going to staff dashboard');
          if (context.mounted) {
            context.go('/staff-dashboard');
          }
          return;
        }
      }
    } catch (e) {
      print('Error checking stored session: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    // Only go to login if truly not authenticated
    print('❌ No valid session found - going to login');
    if (context.mounted) {
      context.go('/login');
    }
  }

  /// Get the dashboard route based on user role
  static String getDashboardRoute(WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    
    if (user != null) {
      final userRole = user.role;
      return userRole == UserRole.admin ? '/dashboard' : '/staff-dashboard';
    }
    
    return '/login';
  }

  /// Handle back navigation - always goes to appropriate dashboard
  static void handleBackNavigation(BuildContext context, WidgetRef ref) {
    navigateToDashboard(context, ref);
  }

  /// Create a standard back button that navigates to dashboard
  static Widget buildBackButton(BuildContext context, WidgetRef ref, {Color? color}) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: color),
      onPressed: () => navigateToDashboard(context, ref),
    );
  }
}

