import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';

// Get all tasks report
final allTasksReportProvider = FutureProvider<List<TaskReport>>((ref) async {
  return await AnalyticsService.getAllTasksReport();
});

// Get tasks report by date range
final tasksReportByDateRangeProvider = FutureProvider.family<List<TaskReport>,
    ({DateTime startDate, DateTime endDate})>((ref, dateRange) async {
  return await AnalyticsService.getTasksReportByDateRange(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );
});

// Get filtered tasks report
final filteredTasksReportProvider = FutureProvider.family<List<TaskReport>,
    ({DateTime? startDate, DateTime? endDate, String? status, String? priority})>(
  (ref, params) async {
    return await AnalyticsService.getFilteredTasksReport(
      startDate: params.startDate,
      endDate: params.endDate,
      status: params.status,
      priority: params.priority,
    );
  },
);

// Get tasks by status
final tasksByStatusProvider = FutureProvider.family<List<TaskReport>, String>(
  (ref, status) async {
    return await AnalyticsService.getTasksByStatus(status);
  },
);

// Get tasks by priority
final tasksByPriorityProvider = FutureProvider.family<List<TaskReport>, String>(
  (ref, priority) async {
    return await AnalyticsService.getTasksByPriority(priority);
  },
);

// Get tasks by staff
final tasksByStaffProvider = FutureProvider.family<List<TaskReport>, String>(
  (ref, staffId) async {
    return await AnalyticsService.getTasksByStaff(staffId);
  },
);

// Get analytics statistics
final analyticsStatsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return await AnalyticsService.getAnalyticsStats();
});

// Get trashcan analytics
final trashcanAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return await AnalyticsService.getTrashcanAnalytics();
});

// Get completion analytics
final completionAnalyticsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return await AnalyticsService.getCompletionAnalytics();
});



