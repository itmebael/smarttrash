import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/notification_data_service.dart';
import '../../../../core/models/notification_model.dart';

class NotificationStatsWidget extends ConsumerWidget {
  const NotificationStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final totalNotifications = NotificationDataService.getTotalCount();
    final unreadNotifications = NotificationDataService.getUnreadCount();
    final readNotifications = NotificationDataService.getReadCount();
    final typeStats = NotificationDataService.getTypeStats();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Notification Statistics',
                style: TextStyle(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total notifications count
          _buildStatCard(
            'Total Notifications',
            totalNotifications.toString(),
            Icons.notifications,
            AppTheme.primaryGreen,
            isDark,
          ),

          const SizedBox(height: 16),

          // Unread vs Read
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Unread',
                  unreadNotifications.toString(),
                  Icons.notifications_active,
                  AppTheme.warningOrange,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Read',
                  readNotifications.toString(),
                  Icons.notifications_off,
                  AppTheme.textSecondary,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Notification types breakdown
          Text(
            'By Type',
            style: TextStyle(
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          ...typeStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getNotificationIcon(entry.key),
                        size: 16,
                        color: _getNotificationColor(entry.key),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getNotificationTypeName(entry.key),
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textSecondary
                              : AppTheme.lightTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(entry.key)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: TextStyle(
                        color: _getNotificationColor(entry.key),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.trashcanFull:
        return AppTheme.dangerRed;
      case NotificationType.taskAssigned:
        return AppTheme.primaryGreen;
      case NotificationType.taskReminder:
        return AppTheme.warningOrange;
      case NotificationType.taskCompleted:
        return AppTheme.primaryGreen;
      case NotificationType.systemAlert:
        return AppTheme.secondaryBlue;
      case NotificationType.maintenanceRequired:
        return AppTheme.dangerRed;
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
        return Icons.settings;
      case NotificationType.maintenanceRequired:
        return Icons.build;
    }
  }

  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.trashcanFull:
        return 'Trashcan Full';
      case NotificationType.taskAssigned:
        return 'Task Assigned';
      case NotificationType.taskReminder:
        return 'Task Reminder';
      case NotificationType.taskCompleted:
        return 'Task Completed';
      case NotificationType.systemAlert:
        return 'System Alert';
      case NotificationType.maintenanceRequired:
        return 'Maintenance Required';
    }
  }
}


