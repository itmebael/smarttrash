import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EcoButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isOutlined;

  const EcoButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.padding,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ??
        (isOutlined ? Colors.transparent : AppTheme.primaryGreen);
    final effectiveTextColor =
        textColor ?? (isOutlined ? AppTheme.primaryGreen : Colors.white);

    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          elevation: isOutlined ? 0 : 2,
          shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isOutlined
                ? const BorderSide(color: AppTheme.primaryGreen, width: 2)
                : BorderSide.none,
          ),
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: effectiveTextColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: effectiveTextColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class EcoIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final bool isLoading;

  const EcoIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? AppTheme.primaryGreen;
    final effectiveIconColor = iconColor ?? Colors.white;
    final effectiveSize = size ?? 24;

    return Tooltip(
      message: tooltip ?? '',
      child: SizedBox(
        width: 48,
        height: 48,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: effectiveIconColor,
            elevation: 2,
            shadowColor: AppTheme.primaryGreen.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.zero,
          ),
          child: isLoading
              ? SizedBox(
                  width: effectiveSize * 0.6,
                  height: effectiveSize * 0.6,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      effectiveIconColor,
                    ),
                  ),
                )
              : Icon(icon, size: effectiveSize, color: effectiveIconColor),
        ),
      ),
    );
  }
}

class EcoFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? iconColor;

  const EcoFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? AppTheme.primaryGreen,
      foregroundColor: iconColor ?? Colors.white,
      elevation: 4,
      child: Icon(icon),
    );
  }
}

