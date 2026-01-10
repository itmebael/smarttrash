import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:permission_handler/permission_handler.dart'; // Temporarily disabled

import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/safe_local_storage.dart' as safe_storage;
// import 'core/services/location_service.dart'; // Temporarily disabled
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences FIRST (needed by Supabase)
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
    print('✅ SharedPreferences initialized');
  } catch (e) {
    print('⚠️ SharedPreferences initialization error: $e');
  }

  // Initialize Supabase
  print('🚀 Initializing Supabase connection...');
  print('📡 URL: https://ssztyskjcoilweqmheef.supabase.co');
  
  // Supabase configuration
  const supabaseUrl = 'https://ssztyskjcoilweqmheef.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzenR5c2tqY29pbHdlcW1oZWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgxODkxMjYsImV4cCI6MjA3Mzc2NTEyNn0.yP0Qihye9C7AiAhVN5_PBziCzfvgRlBu_dcdX9L9SSQ';
  
  print('🔑 Anon Key length: ${supabaseAnonKey.length} characters');
  print('🔑 First 20 chars: ${supabaseAnonKey.substring(0, 20)}...');
  
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
        // Use our safe local storage if prefs is available, otherwise let Supabase use default (which might fail)
        // or provide a dummy implementation if prefs is null
        localStorage: prefs != null ? safe_storage.SafeLocalStorage(prefs) : const safe_storage.EmptyLocalStorage(),
      ),
      debug: true,
    );
    
    print('✅ Supabase initialized successfully!');
    
    // Test connection by checking if we can reach the database
    try {
      await Supabase.instance.client
          .from('users')
          .select('*')
          .limit(1);
      print('✅ Database connection verified - Online mode active');
      print('✅ Ready to save and fetch data');
    } catch (dbError) {
      print('⚠️  Database connection issue: $dbError');
      print('⚠️  Please run the database migrations first');
      print('📋 Instructions:');
      print('   1. Go to: https://app.supabase.com/project/ssztyskjcoilweqmheef/editor');
      print('   2. Open SQL Editor');
      print('   3. Run the migrations from supabase/migrations/');
    }
    
  } catch (e) {
    print('❌ Supabase initialization failed!');
    print('Error: $e');
    print('\n⚠️  CRITICAL: App cannot connect to database');
    print('The app will not be able to save or fetch data online.');
    print('\n📋 Required Steps:');
    print('   1. Check internet connection');
    print('   2. Verify Supabase project is active');
    print('   3. Run database migrations');
    print('   4. Create admin account');
    print('\nSee: supabase/CREATE_ADMIN_ACCOUNT.md for detailed setup');
  }

  // Initialize services
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Notification service initialization failed: $e');
  }

  // Temporarily disabled due to Windows build issues
  // try {
  //   await LocationService.initialize();
  // } catch (e) {
  //   print('Location service initialization failed: $e');
  // }

  // Request permissions
  await _requestPermissions();

  runApp(const ProviderScope(child: EcoWasteManagerApp()));
}

Future<void> _requestPermissions() async {
  print('Permission requests temporarily disabled due to Windows build issues');
  // await [
  //   Permission.location,
  //   Permission.notification,
  //   Permission.camera,
  // ].request();
}

class EcoWasteManagerApp extends ConsumerWidget {
  const EcoWasteManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'EcoWaste Manager - SSU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode:
          themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: AppRouter.router,
    );
  }
}

