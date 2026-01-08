import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/notification_model.dart';

class NotificationPopupDialog extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const NotificationPopupDialog({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? EcoGradients.glassGradient
              : EcoGradients.lightGlassGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getNotificationColor(notification.type).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getNotificationColor(notification.type).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon and close button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getNotificationColor(notification.type).withOpacity(0.2),
                    _getNotificationColor(notification.type).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textGray
                                : AppTheme.lightTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                notification.body,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textGray
                      : AppTheme.lightTextPrimary,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppTheme.darkGray.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDismiss ?? () => Navigator.of(context).pop(),
                    child: Text(
                      'Dismiss',
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onViewDetails ??
                        () {
                          Navigator.of(context).pop();
                          // Navigate to notifications page
                          // You can customize this navigation
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getNotificationColor(notification.type),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.trashcanFull:
        return AppTheme.dangerRed;
      case NotificationType.taskAssigned:
        return AppTheme.secondaryBlue;
      case NotificationType.taskReminder:
        return AppTheme.warningOrange;
      case NotificationType.taskCompleted:
        return AppTheme.successGreen;
      case NotificationType.systemAlert:
        return AppTheme.primaryGreen;
      case NotificationType.maintenanceRequired:
        return AppTheme.warningOrange;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.trashcanFull:
        return Icons.warning;
      case NotificationType.taskAssigned:
        return Icons.assignment;
      case NotificationType.taskReminder:
        return Icons.schedule;
      case NotificationType.taskCompleted:
        return Icons.check_circle;
      case NotificationType.systemAlert:
        return Icons.info;
      case NotificationType.maintenanceRequired:
        return Icons.build;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}


