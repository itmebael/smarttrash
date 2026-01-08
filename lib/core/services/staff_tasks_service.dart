import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to fetch staff-specific tasks and activities from the database
class StaffTasksService {
  final SupabaseClient _supabase;

  StaffTasksService(this._supabase);

  /// Fetch all tasks assigned to a specific staff member
  Future<List<Map<String, dynamic>>> getStaffTasks(String staffId) async {
    try {
      print('📋 Fetching tasks for staff: $staffId');
      print('🔍 Current auth user: ${_supabase.auth.currentUser?.id}');

      // First, fetch tasks
      final tasksResponse = await _supabase
          .from('tasks')
          .select('''
            id,
            title,
            description,
            priority,
            status,
            created_at,
            completed_at,
            due_date,
            trashcan_id,
            assigned_staff_id
          ''')
          .eq('assigned_staff_id', staffId)
          .order('created_at', ascending: false);

      print('✅ Fetched ${tasksResponse.length} tasks for staff');
      if (tasksResponse.isEmpty) {
        print('⚠️  No tasks found for staff ID: $staffId');
        print('🔍 Checking if staff ID matches auth user ID...');
        print('   Staff ID: $staffId');
        print('   Auth User ID: ${_supabase.auth.currentUser?.id}');
      }

      // Fetch trashcans for all trashcan_ids
      final trashcanIds = tasksResponse
          .where((task) => task['trashcan_id'] != null)
          .map((task) => task['trashcan_id'] as String)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> trashcansMap = {};
      if (trashcanIds.isNotEmpty) {
        final trashcansResponse = await _supabase
            .from('trashcans')
            .select('id, name, location, latitude, longitude')
            .inFilter('id', trashcanIds);

        for (final trashcan in trashcansResponse) {
          trashcansMap[trashcan['id'] as String] = Map<String, dynamic>.from(trashcan);
        }
      }

      // Merge trashcan data into tasks
      final result = tasksResponse.map((task) {
        final taskMap = Map<String, dynamic>.from(task);
        final trashcanId = task['trashcan_id'] as String?;
        if (trashcanId != null && trashcansMap.containsKey(trashcanId)) {
          taskMap['trashcans'] = trashcansMap[trashcanId];
        } else {
          taskMap['trashcans'] = null;
        }
        return taskMap;
      }).toList();

      return result;
    } catch (e) {
      print('❌ Error fetching staff tasks: $e');
      rethrow;
    }
  }

  /// Fetch pending tasks (to show as "Tasks Pending")
  Future<int> getPendingTasksCount(String staffId) async {
    try {
      print('📋 Fetching pending tasks count for staff: $staffId');

      final response = await _supabase
          .from('tasks')
          .select('id')
          .eq('assigned_staff_id', staffId)
          .eq('status', 'pending')
          .count();

      final count = response.count;
      print('✅ Pending tasks: $count');
      return count;
    } catch (e) {
      print('❌ Error fetching pending tasks count: $e');
      return 0;
    }
  }

  /// Fetch completed tasks today
  Future<int> getCompletedTodayCount(String staffId) async {
    try {
      print('📋 Fetching completed today count for staff: $staffId');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _supabase
          .from('tasks')
          .select('id')
          .eq('assigned_staff_id', staffId)
          .eq('status', 'completed')
          .gte('completed_at', startOfDay.toIso8601String())
          .lt('completed_at', endOfDay.toIso8601String())
          .count();

      final count = response.count;
      print('✅ Completed today: $count');
      return count;
    } catch (e) {
      print('❌ Error fetching completed today count: $e');
      return 0;
    }
  }

  /// Fetch in-progress tasks
  Future<int> getInProgressCount(String staffId) async {
    try {
      print('📋 Fetching in-progress tasks count for staff: $staffId');

      final response = await _supabase
          .from('tasks')
          .select('id')
          .eq('assigned_staff_id', staffId)
          .eq('status', 'in_progress')
          .count();

      final count = response.count;
      print('✅ In progress: $count');
      return count;
    } catch (e) {
      print('❌ Error fetching in-progress tasks count: $e');
      return 0;
    }
  }

  /// Fetch recent activity for staff (last 5 tasks)
  Future<List<Map<String, dynamic>>> getRecentActivity(String staffId) async {
    try {
      print('📋 Fetching recent activity for staff: $staffId');

      // First, fetch tasks
      final tasksResponse = await _supabase
          .from('tasks')
          .select('''
            id,
            title,
            status,
            completed_at,
            updated_at,
            trashcan_id
          ''')
          .eq('assigned_staff_id', staffId)
          .order('updated_at', ascending: false)
          .limit(5);

      print('✅ Fetched ${tasksResponse.length} recent activities');

      // Fetch trashcans for all trashcan_ids
      final trashcanIds = tasksResponse
          .where((task) => task['trashcan_id'] != null)
          .map((task) => task['trashcan_id'] as String)
          .toSet()
          .toList();

      Map<String, Map<String, dynamic>> trashcansMap = {};
      if (trashcanIds.isNotEmpty) {
        final trashcansResponse = await _supabase
            .from('trashcans')
            .select('id, name, location, latitude, longitude')
            .inFilter('id', trashcanIds);

        for (final trashcan in trashcansResponse) {
          trashcansMap[trashcan['id'] as String] = Map<String, dynamic>.from(trashcan);
        }
      }

      // Merge trashcan data into tasks
      final result = tasksResponse.map((task) {
        final taskMap = Map<String, dynamic>.from(task);
        final trashcanId = task['trashcan_id'] as String?;
        if (trashcanId != null && trashcansMap.containsKey(trashcanId)) {
          taskMap['trashcans'] = trashcansMap[trashcanId];
        } else {
          taskMap['trashcans'] = null;
        }
        return taskMap;
      }).toList();

      return result;
    } catch (e) {
      print('❌ Error fetching recent activity: $e');
      rethrow;
    }
  }

  /// Get task statistics for the staff member
  Future<Map<String, int>> getTaskStatistics(String staffId) async {
    try {
      print('📊 Fetching task statistics for staff: $staffId');

      final pending = await getPendingTasksCount(staffId);
      final completedToday = await getCompletedTodayCount(staffId);
      final inProgress = await getInProgressCount(staffId);

      final stats = {
        'pending': pending,
        'completedToday': completedToday,
        'inProgress': inProgress,
        'total': pending + completedToday + inProgress,
      };

      print('✅ Task statistics: $stats');
      return stats;
    } catch (e) {
      print('❌ Error fetching task statistics: $e');
      return {
        'pending': 0,
        'completedToday': 0,
        'inProgress': 0,
        'total': 0,
      };
    }
  }
}

