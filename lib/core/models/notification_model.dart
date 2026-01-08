// Removed Firebase dependency - using Supabase now

enum NotificationType {
  trashcanFull,
  taskAssigned,
  taskReminder,
  taskCompleted,
  systemAlert,
  maintenanceRequired,
}

enum NotificationPriority { low, medium, high, urgent }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final String? userId;
  final String? trashcanId;
  final String? taskId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? imageUrl;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    this.userId,
    this.trashcanId,
    this.taskId,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.imageUrl,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    NotificationType _parseType(dynamic value) {
      final raw = value?.toString().toLowerCase() ?? '';
      switch (raw) {
        case 'trashcan_full':
        case 'trashcanfull':
          return NotificationType.trashcanFull;
        case 'task_assigned':
        case 'taskassigned':
          return NotificationType.taskAssigned;
        case 'task_reminder':
        case 'taskreminder':
          return NotificationType.taskReminder;
        case 'task_completed':
        case 'taskcompleted':
          return NotificationType.taskCompleted;
        case 'maintenance_required':
        case 'maintenancerequired':
          return NotificationType.maintenanceRequired;
        case 'system_alert':
        case 'systemalert':
        default:
          return NotificationType.systemAlert;
      }
    }

    NotificationPriority _parsePriority(dynamic value) {
      final raw = value?.toString().toLowerCase() ?? '';
      switch (raw) {
        case 'low':
          return NotificationPriority.low;
        case 'high':
          return NotificationPriority.high;
        case 'urgent':
          return NotificationPriority.urgent;
        case 'medium':
        default:
          return NotificationPriority.medium;
      }
    }

    DateTime _parseDate(dynamic value) {
      try {
        if (value == null) return DateTime.now();
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final createdAtValue = map['created_at'] ?? map['createdAt'];
    final readAtValue = map['read_at'] ?? map['readAt'];

    return NotificationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      type: _parseType(map['type']),
      priority: _parsePriority(map['priority']),
      userId: map['user_id']?.toString() ?? map['userId'],
      trashcanId: map['trashcan_id']?.toString() ?? map['trashcanId'],
      taskId: map['task_id']?.toString() ?? map['taskId'],
      data: map['data'] is Map<String, dynamic>
          ? map['data'] as Map<String, dynamic>
          : map['data'],
      isRead: map['is_read'] ?? map['isRead'] ?? false,
      createdAt: _parseDate(createdAtValue),
      readAt: readAtValue != null ? _parseDate(readAtValue) : null,
      imageUrl: map['image_url'] ?? map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'userId': userId,
      'trashcanId': trashcanId,
      'taskId': taskId,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    String? userId,
    String? trashcanId,
    String? taskId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
      trashcanId: trashcanId ?? this.trashcanId,
      taskId: taskId ?? this.taskId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  // Helper methods
  bool get isHighPriority =>
      priority == NotificationPriority.high ||
      priority == NotificationPriority.urgent;
  bool get isUrgent => priority == NotificationPriority.urgent;

  String get typeText {
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

  String get priorityText {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.medium:
        return 'Medium';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }
}

