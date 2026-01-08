import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_log_model.dart';

class ActivityLogService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all activity logs with user information
  static Future<List<ActivityLogModel>> getAllActivityLogs({
    int limit = 100,
    String? userId,
  }) async {
    try {
      var query = _supabase
          .from('activity_logs')
          .select('*, users(name, email)');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => ActivityLogModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching activity logs: $e');
      return [];
    }
  }

  /// Fetch activity logs for a specific user
  static Future<List<ActivityLogModel>> getUserActivityLogs(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('activity_logs')
          .select('*, users(name, email)')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => ActivityLogModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching user activity logs: $e');
      return [];
    }
  }

  /// Fetch activity logs by entity type
  static Future<List<ActivityLogModel>> getActivityLogsByEntityType(
    String entityType, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('activity_logs')
          .select('*, users(name, email)')
          .eq('entity_type', entityType)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => ActivityLogModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching activity logs by entity type: $e');
      return [];
    }
  }

  /// Get activity log statistics
  static Future<Map<String, int>> getActivityStats() async {
    try {
      final allLogs = await getAllActivityLogs(limit: 1000);
      return {
        'total': allLogs.length,
        'inserts': allLogs.where((l) => l.action.toUpperCase() == 'INSERT').length,
        'updates': allLogs.where((l) => l.action.toUpperCase() == 'UPDATE').length,
        'deletes': allLogs.where((l) => l.action.toUpperCase() == 'DELETE').length,
        'users': allLogs.where((l) => l.entityType.toLowerCase() == 'users').length,
        'trashcans': allLogs.where((l) => l.entityType.toLowerCase() == 'trashcans').length,
        'tasks': allLogs.where((l) => l.entityType.toLowerCase() == 'tasks').length,
      };
    } catch (e) {
      print('❌ Error getting activity stats: $e');
      return {
        'total': 0,
        'inserts': 0,
        'updates': 0,
        'deletes': 0,
        'users': 0,
        'trashcans': 0,
        'tasks': 0,
      };
    }
  }
}
