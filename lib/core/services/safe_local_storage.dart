import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A safe implementation of LocalStorage that uses an existing SharedPreferences instance
/// This avoids the LateInitializationError in the default SharedPreferencesLocalStorage
class SafeLocalStorage extends LocalStorage {
  final SharedPreferences prefs;
  final String key;

  SafeLocalStorage(this.prefs, {this.key = 'supabase_auth_token'});

  @override
  Future<void> initialize() async {
    // No-op: SharedPreferences is already initialized
  }

  @override
  Future<bool> hasAccessToken() async {
    return prefs.containsKey(key);
  }

  @override
  Future<String?> accessToken() async {
    return prefs.getString(key);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await prefs.setString(key, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    await prefs.remove(key);
  }
}

/// A dummy implementation of LocalStorage for when SharedPreferences fails to initialize
class EmptyLocalStorage extends LocalStorage {
  const EmptyLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<void> persistSession(String persistSessionString) async {}

  @override
  Future<void> removePersistedSession() async {}
}
