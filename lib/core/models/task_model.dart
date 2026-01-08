// Task model aligned with Supabase database schema

enum TaskStatus { pending, inProgress, completed, cancelled }

enum TaskPriority { low, medium, high, urgent }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String? trashcanId;
  final String? trashcanName;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? createdByAdminId;
  final String? createdByAdminName;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? dueDate;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completionNotes;
  final int? estimatedDuration;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    this.trashcanId,
    this.trashcanName,
    this.assignedStaffId,
    this.assignedStaffName,
    this.createdByAdminId,
    this.createdByAdminName,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.startedAt,
    this.completedAt,
    this.completionNotes,
    this.estimatedDuration,
  });

  // Factory constructor for Supabase data with joins
  factory TaskModel.fromSupabaseMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      trashcanId: map['trashcan_id'],
      trashcanName: map['trashcan'] != null 
          ? (map['trashcan'] is Map 
              ? map['trashcan']['name'] ?? map['trashcan']['location'] 
              : null)
          : null,
      assignedStaffId: map['assigned_staff_id'],
      assignedStaffName: map['assigned_staff'] != null 
          ? (map['assigned_staff'] is Map ? map['assigned_staff']['name'] : null)
          : null,
      createdByAdminId: map['created_by_admin_id'],
      createdByAdminName: map['created_by'] != null 
          ? (map['created_by'] is Map ? map['created_by']['name'] : null)
          : null,
      status: _parseStatus(map['status']),
      priority: _parsePriority(map['priority']),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      startedAt: map['started_at'] != null ? DateTime.parse(map['started_at']) : null,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
      completionNotes: map['completion_notes'],
      estimatedDuration: map['estimated_duration'],
    );
  }

  // Legacy fromMap for backward compatibility
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel.fromSupabaseMap(map);
  }

  static TaskStatus _parseStatus(String? status) {
    if (status == null) return TaskStatus.pending;
    
    switch (status.toLowerCase()) {
      case 'pending':
        return TaskStatus.pending;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  static TaskPriority _parsePriority(String? priority) {
    if (priority == null) return TaskPriority.medium;
    
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  String get statusString {
    switch (status) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  String get priorityString {
    switch (priority) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.urgent:
        return 'urgent';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'trashcan_id': trashcanId,
      'assigned_staff_id': assignedStaffId,
      'created_by_admin_id': createdByAdminId,
      'status': statusString,
      'priority': priorityString,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'completion_notes': completionNotes,
      'estimated_duration': estimatedDuration,
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? trashcanId,
    String? trashcanName,
    String? assignedStaffId,
    String? assignedStaffName,
    String? createdByAdminId,
    String? createdByAdminName,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    DateTime? startedAt,
    DateTime? completedAt,
    String? completionNotes,
    int? estimatedDuration,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      trashcanId: trashcanId ?? this.trashcanId,
      trashcanName: trashcanName ?? this.trashcanName,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      createdByAdminId: createdByAdminId ?? this.createdByAdminId,
      createdByAdminName: createdByAdminName ?? this.createdByAdminName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dueDate: dueDate ?? this.dueDate,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completionNotes: completionNotes ?? this.completionNotes,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }

  // Helper methods
  bool get isPending => status == TaskStatus.pending;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isCancelled => status == TaskStatus.cancelled;

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  Duration? get duration {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  String get statusText {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get priorityText {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }
}

