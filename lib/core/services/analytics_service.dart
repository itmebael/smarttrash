import 'package:supabase_flutter/supabase_flutter.dart';

class TaskReport {
  final String trashcanName;
  final String? location;
  final String priority;
  final String? assignedStaffName;
  final String status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;
  final String? floor;
  final int? daysSinceCompletion;

  TaskReport({
    required this.trashcanName,
    this.location,
    required this.priority,
    this.assignedStaffName,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.notes,
    this.floor,
    this.daysSinceCompletion,
  });

  // Format time in 12-hour format (AM/PM)
  String get formattedTime {
    if (completedAt == null) return 'N/A';
    final hour = completedAt!.hour;
    final minute = completedAt!.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  // Calculate days since completion
  int? get daysSinceCompletionCalculated {
    if (completedAt == null) return null;
    final now = DateTime.now();
    final difference = now.difference(completedAt!);
    return difference.inDays;
  }

  // Extract floor from location
  static String? extractFloor(String? location) {
    if (location == null) return null;
    
    // Pattern 1: "1st Floor", "2nd Floor", "3rd Floor", "4th Floor", etc.
    final pattern1 = RegExp(r'(\d+)(st|nd|rd|th)\s+floor', caseSensitive: false);
    final match1 = pattern1.firstMatch(location);
    if (match1 != null) {
      return '${match1.group(1)}${match1.group(2)} Floor';
    }
    
    // Pattern 2: "Floor 1", "Floor 2", etc.
    final pattern2 = RegExp(r'floor\s+(\d+)', caseSensitive: false);
    final match2 = pattern2.firstMatch(location);
    if (match2 != null) {
      return 'Floor ${match2.group(1)}';
    }
    
    // Pattern 3: Any number followed by "floor"
    final pattern3 = RegExp(r'(\d+).*floor', caseSensitive: false);
    final match3 = pattern3.firstMatch(location);
    if (match3 != null) {
      return '${match3.group(1)} Floor';
    }
    
    // Pattern 4: Return the part after the last dash
    if (location.contains(' - ')) {
      return location.split(' - ').last;
    }
    
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'Name': assignedStaffName ?? 'Unassigned',
      'Assign Bin': trashcanName,
      'Priority Level': priority,
      'Status': status,
      'Completed Task': status == 'completed' ? 'Yes' : 'No',
      'Assign Date': createdAt.toString().split('.')[0],
      'Completed Date': completedAt?.toString().split('.')[0] ?? 'N/A',
      'Time': formattedTime,
      'Days Since Completion': daysSinceCompletion ?? daysSinceCompletionCalculated ?? 'N/A',
      'Floor': floor ?? 'N/A',
    };
  }
}

class AnalyticsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Helper function to filter and create TaskReport - ensures only active trashcans
  static TaskReport? _createTaskReportFiltered({
    required Map<String, dynamic> task,
    Map<String, dynamic>? trashcan,
    Map<String, dynamic>? staff,
  }) {
    // Filter out tasks with inactive trashcans for accuracy
    if (trashcan != null) {
      final isActive = trashcan['is_active'] as bool? ?? true;
      if (!isActive) {
        print('⚠️ Filtering out task ${task['id']} - associated trashcan is inactive');
        return null;
      }
    }
    
    return _createTaskReport(task: task, trashcan: trashcan, staff: staff);
  }

  // Helper function to create TaskReport with floor and days calculation
  static TaskReport _createTaskReport({
    required Map<String, dynamic> task,
    Map<String, dynamic>? trashcan,
    Map<String, dynamic>? staff,
  }) {
    // Validate trashcan data - ensure it exists and is active
    if (trashcan == null) {
      print('⚠️ Warning: Task ${task['id']} has no associated trashcan');
    } else {
      final isActive = trashcan['is_active'] as bool? ?? true;
      if (!isActive) {
        print('⚠️ Warning: Task ${task['id']} is associated with inactive trashcan ${trashcan['name']}');
      }
    }

    final location = trashcan?['location'] as String?;
    final trashcanName = trashcan?['name'] as String?;
    final isActive = trashcan?['is_active'] as bool? ?? true;
    
    // Validate trashcan name - ensure it's not null or empty
    final validTrashcanName = (trashcanName != null && trashcanName.isNotEmpty)
        ? trashcanName
        : 'Unknown Bin';
    
    // Log warning if trashcan is inactive
    if (!isActive && trashcan != null) {
      print('⚠️ Warning: Task ${task['id']} is associated with inactive trashcan $validTrashcanName');
    }
    
    final completedAt = task['completed_at'] != null
        ? DateTime.parse(task['completed_at'])
        : null;
    
    // Calculate days since completion
    int? daysSinceCompletion;
    if (completedAt != null) {
      final now = DateTime.now();
      final difference = now.difference(completedAt);
      daysSinceCompletion = difference.inDays;
    }

    return TaskReport(
      trashcanName: validTrashcanName,
      location: location,
      priority: task['priority']?.toString() ?? 'medium',
      assignedStaffName: staff?['name'],
      status: task['status']?.toString() ?? 'pending',
      createdAt: DateTime.parse(task['created_at']),
      completedAt: completedAt,
      notes: task['completion_notes'],
      floor: TaskReport.extractFloor(location),
      daysSinceCompletion: daysSinceCompletion,
    );
  }

  // Get all tasks with related data
  static Future<List<TaskReport>> getAllTasksReport() async {
    try {
      print('📊 Fetching all tasks report...');

      final response = await _supabase
          .from('tasks')
          .select('''
            id,
            title,
            priority,
            status,
            created_at,
            completed_at,
            completion_notes,
            trashcan_id,
            assigned_staff_id,
            trashcans!inner(name, location, status, is_active, device_id),
            assigned_staff:assigned_staff_id(name),
            created_by:created_by_admin_id(name)
          ''')
          .order('created_at', ascending: false);

      final reports = (response as List).map((task) {
        final trashcan = task['trashcans'] as Map<String, dynamic>?;
        final staff = task['assigned_staff'] as Map<String, dynamic>?;
        return _createTaskReport(task: task, trashcan: trashcan, staff: staff);
      }).toList();

      print('✅ Fetched ${reports.length} tasks');
      return reports;
    } catch (e) {
      print('❌ Error fetching tasks report: $e');
      return [];
    }
  }

  // Get filtered tasks report
  static Future<List<TaskReport>> getFilteredTasksReport({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? priority,
  }) async {
    try {
      print('📊 Fetching filtered tasks report...');
      
      var query = _supabase.from('tasks').select('''
            id,
            title,
            priority,
            status,
            created_at,
            completed_at,
            completion_notes,
            trashcan_id,
            assigned_staff_id,
            trashcans!inner(name, location, status, is_active, device_id),
            assigned_staff:assigned_staff_id(name),
            created_by:created_by_admin_id(name)
          ''');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      if (priority != null && priority != 'all') {
        query = query.eq('priority', priority);
      }
      
      final response = await query.order('created_at', ascending: false);

      final reports = (response as List).map((task) {
        final trashcan = task['trashcans'] as Map<String, dynamic>?;
        final staff = task['assigned_staff'] as Map<String, dynamic>?;
        return _createTaskReportFiltered(task: task, trashcan: trashcan, staff: staff);
      }).whereType<TaskReport>().toList();

      print('✅ Fetched ${reports.length} filtered tasks');
      return reports;
    } catch (e) {
      print('❌ Error fetching filtered tasks report: $e');
      return [];
    }
  }

  // Get tasks report by date range
  static Future<List<TaskReport>> getTasksReportByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      print('📊 Fetching tasks report from ${startDate.toString().split(' ')[0]} to ${endDate.toString().split(' ')[0]}...');

      final response = await _supabase
          .from('tasks')
          .select('''
            id,
            title,
            priority,
            status,
            created_at,
            completed_at,
            completion_notes,
            trashcan_id,
            assigned_staff_id,
            trashcans!inner(name, location, status, is_active, device_id),
            assigned_staff:assigned_staff_id(name),
            created_by:created_by_admin_id(name)
          ''')
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .order('created_at', ascending: false);

      final reports = (response as List).map((task) {
        final trashcan = task['trashcans'] as Map<String, dynamic>?;
        final staff = task['assigned_staff'] as Map<String, dynamic>?;
        return _createTaskReportFiltered(task: task, trashcan: trashcan, staff: staff);
      }).whereType<TaskReport>().toList();

      print('✅ Fetched ${reports.length} tasks for date range');
      return reports;
    } catch (e) {
      print('❌ Error fetching tasks report: $e');
      return [];
    }
  }

  // Get tasks by status
  static Future<List<TaskReport>> getTasksByStatus(String status) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('''
            id,
            title,
            priority,
            status,
            created_at,
            completed_at,
            completion_notes,
            trashcan_id,
            assigned_staff_id,
            trashcans!inner(name, location, status, is_active, device_id),
            assigned_staff:assigned_staff_id(name),
            created_by:created_by_admin_id(name)
          ''')
          .eq('status', status)
          .order('created_at', ascending: false);

      final reports = (response as List).map((task) {
        final trashcan = task['trashcans'] as Map<String, dynamic>?;
        final staff = task['assigned_staff'] as Map<String, dynamic>?;
        return _createTaskReportFiltered(task: task, trashcan: trashcan, staff: staff);
      }).whereType<TaskReport>().toList();

      return reports;
    } catch (e) {
      print('❌ Error fetching tasks by status: $e');
      return [];
    }
  }

  // Get tasks by priority
  static Future<List<TaskReport>> getTasksByPriority(String priority) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('''
            id,
            title,
            priority,
            status,
            created_at,
            completed_at,
            completion_notes,
            trashcan_id,
            assigned_staff_id,
            trashcans!inner(name, location, status, is_active, device_id),
            assigned_staff:assigned_staff_id(name),
            created_by:created_by_admin_id(name)
          ''')
          .eq('priority', priority)
          .order('created_at', ascending: false);

      final reports = (response as List).map((task) {
        final trashcan = task['trashcans'] as Map<String, dynamic>?;
        final staff = task['assigned_staff'] as Map<String, dynamic>?;
        return _createTaskReportFiltered(task: task, trashcan: trashcan, staff: staff);
      }).whereType<TaskReport>().toList();

      return reports;
    } catch (e) {
      print('❌ Error fetching tasks by priority: $e');
      return [];
    }
  }

  // Get tasks assigned to specific staff
  static Future<List<TaskReport>> getTasksByStaff(String staffId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('''
            id,
            title,
            priority,
            status,
            created_at,
            completed_at,
            completion_notes,
            trashcan_id,
            assigned_staff_id,
            trashcans!inner(name, location, status, is_active, device_id),
            users(name)
          ''')
          .eq('assigned_staff_id', staffId)
          .order('created_at', ascending: false);

      final reports = (response as List).map((task) {
        final trashcan = task['trashcans'] as Map<String, dynamic>?;
        final staff = task['users'] as Map<String, dynamic>?;
        return _createTaskReportFiltered(task: task, trashcan: trashcan, staff: staff);
      }).whereType<TaskReport>().toList();

      return reports;
    } catch (e) {
      print('❌ Error fetching tasks by staff: $e');
      return [];
    }
  }

  // Get analytics statistics
  static Future<Map<String, dynamic>> getAnalyticsStats() async {
    try {
      print('📊 Fetching analytics statistics...');

      // Fetch all tasks with status and priority
      final allTasksResponse = await _supabase
          .from('tasks')
          .select('status, priority');

      // Supabase always returns a List
      final allTasks = allTasksResponse as List;
      
      print('📊 Fetched ${allTasks.length} tasks from database');
      
      // Count tasks by status
      int completedTasks = 0;
      int pendingTasks = 0;
      int inProgressTasks = 0;
      int highPriorityTasks = 0;
      int urgentTasks = 0;

      for (var task in allTasks) {
        if (task is! Map) {
          print('⚠️ Task is not a Map: ${task.runtimeType}');
          continue;
        }
        
        final status = task['status']?.toString().toLowerCase() ?? '';
        final priority = task['priority']?.toString().toLowerCase() ?? '';

        // Count by status
        if (status == 'completed') {
          completedTasks++;
          print('✅ Found completed task');
        }
        if (status == 'pending') pendingTasks++;
        if (status == 'in_progress') inProgressTasks++;

        // Count by priority
        if (priority == 'high') highPriorityTasks++;
        if (priority == 'urgent') urgentTasks++;
      }

      final totalTasks = allTasks.length;

      print('✅ Analytics stats - Total: $totalTasks, Completed: $completedTasks, Pending: $pendingTasks, In Progress: $inProgressTasks');

      return {
        'total_tasks': totalTasks,
        'completed_tasks': completedTasks,
        'pending_tasks': pendingTasks,
        'in_progress_tasks': inProgressTasks,
        'high_priority_tasks': highPriorityTasks,
        'urgent_tasks': urgentTasks,
        'completion_rate': totalTasks > 0
            ? (completedTasks / totalTasks * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e, stackTrace) {
      print('❌ Error getting analytics stats: $e');
      print('Stack trace: $stackTrace');
      return {
        'total_tasks': 0,
        'completed_tasks': 0,
        'pending_tasks': 0,
        'in_progress_tasks': 0,
        'high_priority_tasks': 0,
        'urgent_tasks': 0,
        'completion_rate': '0',
      };
    }
  }

  // Get trashcan analytics
  static Future<Map<String, dynamic>> getTrashcanAnalytics() async {
    try {
      print('📊 Fetching trashcan analytics...');

      final response = await _supabase
          .from('trashcans')
          .select('''
            id,
            name,
            status,
            fill_level,
            location,
            last_updated_at
          ''');

      final trashcans = response as List;

      int empty = 0;
      int half = 0;
      int full = 0;
      int maintenance = 0;

      for (var bin in trashcans) {
        switch (bin['status']) {
          case 'empty':
            empty++;
            break;
          case 'half':
            half++;
            break;
          case 'full':
            full++;
            break;
          case 'maintenance':
            maintenance++;
            break;
        }
      }

      return {
        'total_bins': trashcans.length,
        'empty': empty,
        'half': half,
        'full': full,
        'maintenance': maintenance,
      };
    } catch (e) {
      print('❌ Error getting trashcan analytics: $e');
      return {
        'total_bins': 0,
        'empty': 0,
        'half': 0,
        'full': 0,
        'maintenance': 0,
      };
    }
  }

  // Get completion analytics
  static Future<Map<String, dynamic>> getCompletionAnalytics() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('''
            id,
            status,
            priority,
            completed_at,
            created_at
          ''')
          .eq('status', 'completed');

      final completedTasks = response as List;

      if (completedTasks.isEmpty) {
        return {
          'total_completed': 0,
          'average_completion_time_hours': 0,
          'today_completed': 0,
          'this_week_completed': 0,
          'this_month_completed': 0,
        };
      }

      int todayCount = 0;
      int weekCount = 0;
      int monthCount = 0;
      double totalHours = 0;
      int count = 0;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekAgo = now.subtract(const Duration(days: 7));
      final monthAgo = now.subtract(const Duration(days: 30));

      for (var task in completedTasks) {
        final createdAt = DateTime.parse(task['created_at']);
        final completedAt = DateTime.parse(task['completed_at']);
        final difference = completedAt.difference(createdAt);
        final hours = difference.inHours.toDouble();

        totalHours += hours;
        count++;

        final completedDate = DateTime(
          completedAt.year,
          completedAt.month,
          completedAt.day,
        );

        if (completedDate == today) todayCount++;
        if (completedAt.isAfter(weekAgo)) weekCount++;
        if (completedAt.isAfter(monthAgo)) monthCount++;
      }

      return {
        'total_completed': completedTasks.length,
        'average_completion_time_hours':
            (totalHours / count).toStringAsFixed(1),
        'today_completed': todayCount,
        'this_week_completed': weekCount,
        'this_month_completed': monthCount,
      };
    } catch (e) {
      print('❌ Error getting completion analytics: $e');
      return {
        'total_completed': 0,
        'average_completion_time_hours': 0,
        'today_completed': 0,
        'this_week_completed': 0,
        'this_month_completed': 0,
      };
    }
  }
}

