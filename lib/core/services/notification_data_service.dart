import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class NotificationDataService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final List<NotificationModel> _notifications = [];
  static String? _currentUserId;
  static RealtimeChannel? _notificationChannel;
  static Function(NotificationModel)? _onNewNotificationCallback;

  static Future<List<NotificationModel>> getAllNotifications(
      {String? userId}) async {
    try {
      _currentUserId = userId ?? _supabase.auth.currentUser?.id;

      if (_currentUserId == null) {
        print('⚠️ No user id available, returning cached notifications');
        return List.from(_notifications);
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .or('user_id.eq.$_currentUserId,user_id.is.null')
          .order('created_at', ascending: false)
          .limit(100);

      _notifications.clear();
      for (final item in response) {
        try {
          _notifications.add(NotificationModel.fromMap(item));
        } catch (e) {
          print('⚠️ Error parsing notification: $e');
        }
      }

      return List.from(_notifications);
    } catch (e) {
      // Suppress verbose network errors - just return cached notifications
      final errorStr = e.toString();
      if (errorStr.contains('Failed host lookup') || 
          errorStr.contains('SocketException') ||
          errorStr.contains('No such host')) {
        // Offline mode - return cached data silently
        return List.from(_notifications);
      }
      // Only log non-network errors
      print('⚠️ Error fetching notifications: ${e.runtimeType}');
      return List.from(_notifications);
    }
  }

  static List<NotificationModel> getUnreadNotifications() {
    return _notifications
        .where((notification) => !notification.isRead)
        .toList();
  }

  static List<NotificationModel> getReadNotifications() {
    return _notifications.where((notification) => notification.isRead).toList();
  }

  static NotificationModel? getNotificationById(String id) {
    try {
      return _notifications.firstWhere((notification) => notification.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications
        .where((notification) => notification.type == type)
        .toList();
  }

  static List<NotificationModel> getNotificationsByPriority(
      NotificationPriority priority) {
    return _notifications
        .where((notification) => notification.priority == priority)
        .toList();
  }

  static void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification); // Add to beginning
  }

  static Future<void> markAsRead(String notificationId) async {
    try {
      // Update in database
      await _supabase.rpc('mark_notification_read', params: {
        'p_notification_id': notificationId,
      });

      // Update local cache
    final index = _notifications
        .indexWhere((notification) => notification.id == notificationId);
    if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
        isRead: true,
        readAt: DateTime.now(),
      );
    }
    } catch (e) {
      // Suppress verbose network errors
      final errorStr = e.toString();
      if (!errorStr.contains('Failed host lookup') && 
          !errorStr.contains('SocketException') &&
          !errorStr.contains('No such host')) {
        print('⚠️ Error marking notification as read: ${e.runtimeType}');
      }
      // Fallback to local update
      final index = _notifications
          .indexWhere((notification) => notification.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
      }
    }
  }

  static Future<void> markAllAsRead() async {
    try {
      if (_currentUserId == null) {
        final user = _supabase.auth.currentUser;
        _currentUserId = user?.id;
      }

      if (_currentUserId != null) {
        // Use database function to mark all as read
        await _supabase.rpc('mark_all_notifications_read', params: {
          'p_user_id': _currentUserId!,
        });
      }

      // Update local cache
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      // Suppress verbose network errors
      final errorStr = e.toString();
      if (!errorStr.contains('Failed host lookup') && 
          !errorStr.contains('SocketException') &&
          !errorStr.contains('No such host')) {
        print('⚠️ Error marking all as read: ${e.runtimeType}');
      }
      // Fallback to local update
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
    }
  }

  static void deleteNotification(String notificationId) {
    _notifications
        .removeWhere((notification) => notification.id == notificationId);
  }

  static int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  static int getTotalCount() {
    return _notifications.length;
  }

  static int getReadCount() {
    return _notifications.where((notification) => notification.isRead).length;
  }

  // Refresh notifications from database
  static Future<void> refresh() async {
    await getAllNotifications();
  }

  static Map<NotificationType, int> getTypeStats() {
    final Map<NotificationType, int> stats = {};
    for (final notification in _notifications) {
      stats[notification.type] = (stats[notification.type] ?? 0) + 1;
    }
    return stats;
  }

  static Map<NotificationPriority, int> getPriorityStats() {
    final Map<NotificationPriority, int> stats = {};
    for (final notification in _notifications) {
      stats[notification.priority] = (stats[notification.priority] ?? 0) + 1;
    }
    return stats;
  }

  // Helper method to create sample notifications
  static void createSampleNotifications() {
    // TODO: Implement if needed for testing purposes
  }

  // Set callback for new notifications (e.g., to show popup dialogs)
  static void setOnNewNotificationCallback(Function(NotificationModel)? callback) {
    _onNewNotificationCallback = callback;
  }

  // Start listening for real-time notifications
  static void startListening({String? userId, Function(NotificationModel)? onNewNotification}) {
    try {
      if (onNewNotification != null) {
        _onNewNotificationCallback = onNewNotification;
      }
      _currentUserId = userId ?? _supabase.auth.currentUser?.id;

      if (_currentUserId == null) {
        print('⚠️ No user id available, cannot listen for notifications');
        return;
      }

      _notificationChannel?.unsubscribe();

      _notificationChannel = _supabase
          .channel('notifications_$_currentUserId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final targetUserId = payload.newRecord['user_id']?.toString();
              if (targetUserId != null &&
                  targetUserId != _currentUserId &&
                  targetUserId.isNotEmpty) {
                return;
              }

              try {
                final notification = NotificationModel.fromMap(payload.newRecord);
                _notifications.insert(0, notification);

                print('🔔 New notification received: ${notification.title}');

                // Send local notification
                NotificationService.sendNotification(
                  title: notification.title,
                  body: notification.body,
                  data: notification.data,
                );

                // Call callback if set (for showing popup dialogs)
                if (_onNewNotificationCallback != null) {
                  Future.microtask(() {
                    try {
                      _onNewNotificationCallback!(notification);
                    } catch (e) {
                      print('⚠️ Error in notification callback: ${e.runtimeType}');
                    }
                  });
                }
              } catch (e) {
                print('⚠️ Error processing real-time notification: ${e.runtimeType}');
              }
            },
          )
          .subscribe();

      print('✅ Started listening for real-time notifications');
    } catch (e) {
      // Suppress verbose network errors
      final errorStr = e.toString();
      if (!errorStr.contains('Failed host lookup') && 
          !errorStr.contains('SocketException') &&
          !errorStr.contains('No such host')) {
        print('⚠️ Error starting notification listener: ${e.runtimeType}');
      }
      // Continue anyway - app can work offline
    }
  }

  // Stop listening for real-time notifications
  static void stopListening() {
    _notificationChannel?.unsubscribe();
    _notificationChannel = null;
    print('🛑 Stopped listening for real-time notifications');
  }
}

