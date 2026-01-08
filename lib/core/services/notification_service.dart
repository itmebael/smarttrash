import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:permission_handler/permission_handler.dart'; // Temporarily disabled

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'smart_trashcan_channel';
  static const String _channelName = 'Smart Trashcan Notifications';
  static const String _channelDescription = 'Notifications for smart trashcan app';
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Create notification channel for Android
      await _createNotificationChannel();
      
      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ NotificationService initialization failed: $e');
      _isInitialized = false;
    }
  }

  static Future<void> _requestPermission() async {
    print(
        'Notification permission request temporarily disabled due to Windows build issues');
    // final status = await Permission.notification.request();
    // if (status.isDenied) {
    //   await Permission.notification.request();
    // }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Firebase messaging removed - using local notifications only

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      // Navigate to specific screen based on payload
      _handleNotificationNavigation(payload);
    }
  }

  // Firebase messaging methods removed - using local notifications only

  static Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    // Check if initialized before showing notification
    if (!_isInitialized) {
      print('⚠️  NotificationService not initialized. Attempting to initialize...');
      try {
        await initialize();
      } catch (e) {
        print('❌ Failed to initialize NotificationService: $e');
        return;
      }
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: data.toString(),
      );
      print('✅ Notification shown: $title');
    } catch (e) {
      print('❌ Error showing notification: $e');
    }
  }

  static void _handleNotificationNavigation(String payload) {
    // Parse payload and navigate to appropriate screen
    // This will be implemented based on your navigation structure
  }

  // Public methods
  static Future<String?> getFCMToken() async {
    // FCM token not available without Firebase
    return null;
  }

  static Future<void> subscribeToTopic(String topic) async {
    // Topic subscription not available without Firebase
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    // Topic unsubscription not available without Firebase
  }

  static Future<void> sendNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(title, body, data ?? {});
  }

  // Notification types for different scenarios
  static Future<void> notifyTrashcanFull({
    required String trashcanName,
    required String location,
  }) async {
    await sendNotification(
      title: '🚨 Trashcan Full Alert',
      body: '$trashcanName at $location is full and needs immediate attention.',
      data: {
        'type': 'trashcan_full',
        'trashcan_name': trashcanName,
        'location': location,
      },
    );
  }

  static Future<void> notifyTaskAssigned({
    required String taskTitle,
    required String trashcanName,
  }) async {
    await sendNotification(
      title: '📋 New Task Assigned',
      body: 'You have been assigned: $taskTitle for $trashcanName',
      data: {
        'type': 'task_assigned',
        'task_title': taskTitle,
        'trashcan_name': trashcanName,
      },
    );
  }

  static Future<void> notifyTaskCompleted({
    required String taskTitle,
    String? trashcanName,
  }) async {
    await sendNotification(
      title: '✅ Task Completed',
      body: trashcanName == null
          ? 'Task "$taskTitle" was completed.'
          : 'Task "$taskTitle" for $trashcanName was completed.',
      data: {
        'type': 'task_completed',
        'task_title': taskTitle,
        if (trashcanName != null) 'trashcan_name': trashcanName,
      },
    );
  }

  static Future<void> notifyTaskReminder({
    required String taskTitle,
    required String trashcanName,
  }) async {
    await sendNotification(
      title: '⏰ Task Reminder',
      body: 'Reminder: $taskTitle for $trashcanName is due soon.',
      data: {
        'type': 'task_reminder',
        'task_title': taskTitle,
        'trashcan_name': trashcanName,
      },
    );
  }

  static Future<void> notifyMaintenanceRequired({
    required String trashcanName,
    required String issue,
  }) async {
    await sendNotification(
      title: '🔧 Maintenance Required',
      body: '$trashcanName requires maintenance: $issue',
      data: {
        'type': 'maintenance_required',
        'trashcan_name': trashcanName,
        'issue': issue,
      },
    );
  }
}

