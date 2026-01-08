import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/staff_tasks_service.dart';

/// Provider for staff tasks service
final staffTasksServiceProvider = Provider<StaffTasksService>((ref) {
  final supabase = Supabase.instance.client;
  return StaffTasksService(supabase);
});

/// Provider for fetching tasks assigned to a specific staff member
final staffTasksProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, staffId) async {
  final service = ref.watch(staffTasksServiceProvider);
  return service.getStaffTasks(staffId);
});

/// Provider for fetching task statistics
final staffTaskStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, staffId) async {
  final service = ref.watch(staffTasksServiceProvider);
  return service.getTaskStatistics(staffId);
});

/// Provider for fetching pending tasks count
final pendingTasksProvider = FutureProvider.family<int, String>((ref, staffId) async {
  final service = ref.watch(staffTasksServiceProvider);
  return service.getPendingTasksCount(staffId);
});

/// Provider for fetching completed today count
final completedTodayProvider = FutureProvider.family<int, String>((ref, staffId) async {
  final service = ref.watch(staffTasksServiceProvider);
  return service.getCompletedTodayCount(staffId);
});

/// Provider for fetching in-progress tasks count
final inProgressTasksProvider = FutureProvider.family<int, String>((ref, staffId) async {
  final service = ref.watch(staffTasksServiceProvider);
  return service.getInProgressCount(staffId);
});

/// Provider for fetching recent activity
final staffRecentActivityProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, staffId) async {
  final service = ref.watch(staffTasksServiceProvider);
  return service.getRecentActivity(staffId);
});

