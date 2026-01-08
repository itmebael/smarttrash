import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/notification_data_service.dart';
import '../../../../core/services/activity_log_service.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/models/activity_log_model.dart';
import '../../../../core/utils/navigation_helper.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  List<NotificationModel> _notifications = [];
  List<ActivityLogModel> _activityLogs = [];
  bool _isLoading = true;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
      if (_selectedTabIndex == 0) {
        _loadNotifications();
      } else {
        _loadActivityLogs();
      }
    });
    _loadNotifications();
    _loadActivityLogs();
    final userId = ref.read(authProvider).value?.id;
    NotificationDataService.startListening(userId: userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Stop listening when page is disposed
    NotificationDataService.stopListening();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (_selectedTabIndex != 0) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = ref.read(authProvider).value?.id;
      final notifications =
          await NotificationDataService.getAllNotifications(userId: userId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadActivityLogs() async {
    if (_selectedTabIndex != 1) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final logs = await ActivityLogService.getAllActivityLogs(limit: 200);
      setState(() {
        _activityLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activity logs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await NotificationDataService.markAsRead(notificationId);
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await NotificationDataService.markAllAsRead();
    await _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? EcoGradients.backgroundGradient
              : EcoGradients.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _buildNotificationsList(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notifications & Activity',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (_selectedTabIndex == 0)
                IconButton(
                  onPressed: _markAllAsRead,
                  icon: const Icon(
                    Icons.done_all,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              if (_selectedTabIndex == 1)
                IconButton(
                  onPressed: _loadActivityLogs,
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  ),
                ),
            ],
          ),
        ),
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.secondaryBlue],
              ),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark
                ? AppTheme.textSecondary
                : AppTheme.lightTextSecondary,
            tabs: const [
              Tab(
                icon: Icon(Icons.notifications),
                text: 'Notifications',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Activity',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsList(bool isDark) {
    if (_selectedTabIndex == 0) {
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (_notifications.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: _notifications.length,
          itemBuilder: (context, index) {
            final notification = _notifications[index];
            return _buildNotificationCard(notification, isDark);
          },
        ),
      );
    } else {
      if (_isLoading) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (_activityLogs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'No activity logs',
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadActivityLogs,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: _activityLogs.length,
          itemBuilder: (context, index) {
            final log = _activityLogs[index];
            return _buildActivityLogCard(log, isDark);
          },
        ),
      );
    }
  }

  Widget _buildNotificationCard(NotificationModel notification, bool isDark) {
    return GestureDetector(
      onTap: () => _markAsRead(notification.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getNotificationColor(notification.type)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: _getNotificationColor(notification.type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textGray
                                : AppTheme.lightTextPrimary,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 10,
                    ),
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

  Widget _buildActivityLogCard(ActivityLogModel log, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: log.actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              log.actionIcon,
              color: log.actionColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${log.actionText} ${log.entityTypeText}',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textGray
                              : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: log.actionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        log.actionText,
                        style: TextStyle(
                          color: log.actionColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (log.userName != null)
                  Text(
                    'By: ${log.userName}',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                if (log.entityId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Entity ID: ${log.entityId!.substring(0, 8)}...',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatTime(log.createdAt),
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
