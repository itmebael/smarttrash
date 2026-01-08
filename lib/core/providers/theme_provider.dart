import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeMode {
  dark,
  light,
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.dark);

  void toggleTheme() {
    state = state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
  }

  void setTheme(AppThemeMode mode) {
    state = mode;
  }

  bool get isDark => state == AppThemeMode.dark;
  bool get isLight => state == AppThemeMode.light;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

// Convenience providers
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider) == AppThemeMode.dark;
});

final isLightModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider) == AppThemeMode.light;
});

