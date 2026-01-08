import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return GestureDetector(
      onTap: () => themeNotifier.toggleTheme(),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isDark
              ? EcoGradients.glassGradient
              : EcoGradients.lightGlassGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : AppTheme.lightBorder,
            width: 1,
          ),
          boxShadow: isDark
              ? EcoShadows.light
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isDark ? 'Dark' : 'Light',
              style: TextStyle(
                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedThemeToggle extends ConsumerStatefulWidget {
  const AnimatedThemeToggle({super.key});

  @override
  ConsumerState<AnimatedThemeToggle> createState() =>
      _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends ConsumerState<AnimatedThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return GestureDetector(
      onTap: () {
        _animationController.forward().then((_) {
          themeNotifier.toggleTheme();
          _animationController.reverse();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isDark
              ? EcoGradients.glassGradient
              : EcoGradients.lightGlassGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : AppTheme.lightBorder,
            width: 1,
          ),
          boxShadow: isDark
              ? EcoShadows.light
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotationAnimation.value * 3.14159, // 180 degrees
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color:
                        isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDark ? 'Dark' : 'Light',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textGray
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


