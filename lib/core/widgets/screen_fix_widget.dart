import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class ScreenFixWidget extends StatelessWidget {
  final Widget child;
  final bool enableSafeArea;
  final bool preventBlackScreen;
  final Color? backgroundColor;

  const ScreenFixWidget({
    super.key,
    required this.child,
    this.enableSafeArea = true,
    this.preventBlackScreen = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        color: preventBlackScreen
            ? (backgroundColor ?? AppTheme.backgroundGreen)
            : null,
        child: enableSafeArea ? SafeArea(child: child) : child,
      ),
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final double? maxWidth;
  final double? maxHeight;
  final bool enableScroll;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.maxWidth,
    this.maxHeight,
    this.enableScroll = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    Widget content = Container(
      padding: padding ?? EdgeInsets.all(isMobile ? 16 : 24),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? (isMobile ? double.infinity : 1200),
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: child,
    );

    if (enableScroll) {
      content = SingleChildScrollView(child: content);
    }

    return content;
  }
}

class NoBlackScreenWrapper extends StatelessWidget {
  final Widget child;
  final Color? fallbackColor;

  const NoBlackScreenWrapper({
    super.key,
    required this.child,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: fallbackColor ?? AppTheme.backgroundGreen,
      child: child,
    );
  }
}

class LoadingStateWidget extends StatelessWidget {
  final String message;
  final bool showSpinner;
  final Color? spinnerColor;
  final IconData? icon;

  const LoadingStateWidget({
    super.key,
    this.message = 'Loading...',
    this.showSpinner = true,
    this.spinnerColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundGreen,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 48, color: AppTheme.primaryGreen),
              const SizedBox(height: 16),
            ] else if (showSpinner) ...[
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  spinnerColor ?? AppTheme.primaryGreen,
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData? icon;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundGreen,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon ?? Icons.error_outline,
                  size: 64, color: AppTheme.dangerRed),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
                textAlign: TextAlign.center,
              ),
              if (details != null) ...[
                const SizedBox(height: 8),
                Text(
                  details!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundGreen,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon ?? Icons.inbox_outlined,
                  size: 64, color: AppTheme.neutralGray),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

