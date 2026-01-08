# Analytics & Export - Quick Reference

## Quick Start

### Get All Reports
```dart
final reports = await AnalyticsService.getAllTasksReport();
```

### Export to CSV
```dart
final csv = ExcelExportService.generateTaskReportCSV(reports);
// Save or download csv
```

### Export to HTML
```dart
final html = ExcelExportService.generateTaskReportHTML(reports);
// Save or open in browser
```

### Export to JSON
```dart
final json = ExcelExportService.generateTaskReportJSON(reports);
// Use in API or analytics tools
```

## Common Queries

### Get Completed Tasks
```dart
final completed = await AnalyticsService.getTasksByStatus('completed');
```

### Get High Priority Tasks
```dart
final urgent = await AnalyticsService.getTasksByPriority('urgent');
final high = await AnalyticsService.getTasksByPriority('high');
```

### Get Specific Staff Tasks
```dart
final staffTasks = await AnalyticsService.getTasksByStaff(staffId);
```

### Get Last 7 Days
```dart
final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
final reports = await AnalyticsService.getTasksReportByDateRange(
  startDate: sevenDaysAgo,
  endDate: DateTime.now(),
);
```

### Get Statistics
```dart
final stats = await AnalyticsService.getAnalyticsStats();
print('Total: ${stats['total_tasks']}');
print('Completed: ${stats['completed_tasks']}');
print('Rate: ${stats['completion_rate']}%');
```

## Export File Names

### Auto-Generated
```dart
ExcelExportService.generateFilename('csv');  // task_report_2025-01-11_143022.csv
ExcelExportService.generateFilename('html'); // task_report_2025-01-11_143022.html
ExcelExportService.generateFilename('json'); // task_report_2025-01-11_143022.json
ExcelExportService.generateFilename('tsv');  // task_report_2025-01-11_143022.tsv
```

## Report Columns

| Column | Example | Notes |
|--------|---------|-------|
| Trashcan | Bin 1 | Device name |
| Location | Building A | Physical location |
| Priority | high | low/medium/high/urgent |
| Assigned To | John Doe | Staff name or "Unassigned" |
| Status | completed | pending/in_progress/completed |
| Created Date | 2025-01-10 14:30:00 | Task creation time |
| Completed Date | 2025-01-10 15:45:00 | Completion time or "Pending" |
| Notes | Cleaned successfully | Additional notes |

## In Riverpod Widget

### Simple Usage
```dart
class ReportPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(allTasksReportProvider);
    
    return reportAsync.when(
      data: (reports) => Text('Tasks: ${reports.length}'),
      loading: () => CircularProgressIndicator(),
      error: (e, st) => Text('Error: $e'),
    );
  }
}
```

### With Statistics
```dart
final statsAsync = ref.watch(analyticsStatsProvider);
statsAsync.when(
  data: (stats) => Column(
    children: [
      Text('Total: ${stats['total_tasks']}'),
      Text('Done: ${stats['completed_tasks']}'),
      Text('Rate: ${stats['completion_rate']}%'),
    ],
  ),
  loading: () => Loader(),
  error: (e, st) => ErrorWidget(),
);
```

## Summary Statistics

```dart
final summary = ExcelExportService.generateSummaryStats(reports);

summary['total']              // 15
summary['completed']          // 10
summary['pending']            // 3
summary['in_progress']        // 2
summary['high_priority']      // 4
summary['urgent_priority']    // 2
summary['completion_rate']    // "66.7"
```

## Providers Quick List

```dart
allTasksReportProvider              // All tasks
analyticsStatsProvider              // Statistics
trashcanAnalyticsProvider           // Bin status
completionAnalyticsProvider         // Completion metrics
tasksByStatusProvider('completed')  // Filter by status
tasksByPriorityProvider('urgent')   // Filter by priority
tasksByStaffProvider(staffId)       // Filter by staff
tasksReportByDateRangeProvider(...)  // Filter by date
```

## Filter Examples

### Status Values
- `'pending'` - Not yet started
- `'in_progress'` - Currently being worked on
- `'completed'` - Finished

### Priority Values
- `'low'` - Low priority
- `'medium'` - Normal priority
- `'high'` - High priority
- `'urgent'` - Urgent priority

### Trashcan Status
- `'empty'` - No waste
- `'half'` - Half full
- `'full'` - Needs emptying
- `'maintenance'` - Under maintenance

## TaskReport Properties

```dart
report.trashcanName        // String: "Bin 1"
report.location            // String?: "Building A"
report.priority            // String: "high"
report.assignedStaffName   // String?: "John Doe"
report.status              // String: "completed"
report.createdAt           // DateTime: 2025-01-10...
report.completedAt         // DateTime?: 2025-01-10...
report.notes               // String?: "Comments here"

// Convert to map
report.toMap()  // Returns: {'Trashcan': 'Bin 1', ...}
```

## Export Methods

```dart
// CSV (Excel/Sheets compatible)
ExcelExportService.generateTaskReportCSV(reports)

// HTML (Formatted, printable)
ExcelExportService.generateTaskReportHTML(reports)

// JSON (Structured data)
ExcelExportService.generateTaskReportJSON(reports)

// TSV (Tab-separated)
ExcelExportService.generateTaskReportTSV(reports)

// Summary stats
ExcelExportService.generateSummaryStats(reports)

// Get info
ExcelExportService.getFileExtension(format)  // ".csv"
ExcelExportService.getMimeType(format)       // "text/csv"
ExcelExportService.generateFilename(format)  // "task_report_..."
```

## Common Combinations

### Get All & Export
```dart
final reports = await AnalyticsService.getAllTasksReport();
final csv = ExcelExportService.generateTaskReportCSV(reports);
// Download csv
```

### Get Completed & Export
```dart
final completed = await AnalyticsService.getTasksByStatus('completed');
final html = ExcelExportService.generateTaskReportHTML(completed);
// Save html
```

### Get Monthly Stats
```dart
final now = DateTime.now();
final start = DateTime(now.year, now.month, 1);
final end = DateTime(now.year, now.month + 1, 0);

final monthly = await AnalyticsService.getTasksReportByDateRange(
  startDate: start,
  endDate: end,
);

final summary = ExcelExportService.generateSummaryStats(monthly);
```

### Staff Performance
```dart
final staffTasks = await AnalyticsService.getTasksByStaff(staffId);
final completed = staffTasks.where((t) => t.status == 'completed').length;
final rate = (completed / staffTasks.length * 100).toStringAsFixed(1);
print('Performance: $rate%');
```

## Error Handling

```dart
try {
  final reports = await AnalyticsService.getAllTasksReport();
  final csv = ExcelExportService.generateTaskReportCSV(reports);
  // Use csv
} catch (e) {
  print('Error: $e');
  // Show error to user
}
```

## Date Functions

```dart
// Today
final today = DateTime.now();

// Yesterday
final yesterday = today.subtract(Duration(days: 1));

// Last 7 days
final sevenDaysAgo = today.subtract(Duration(days: 7));

// Last 30 days
final thirtyDaysAgo = today.subtract(Duration(days: 30));

// This month
final startOfMonth = DateTime(today.year, today.month, 1);
final endOfMonth = DateTime(today.year, today.month + 1, 0);

// Last quarter
final quarterAgo = today.subtract(Duration(days: 90));

// Last year
final yearAgo = today.subtract(Duration(days: 365));
```

## Useful Snippets

### Count by Status
```dart
final all = await AnalyticsService.getAllTasksReport();
final completed = all.where((t) => t.status == 'completed').length;
final pending = all.where((t) => t.status == 'pending').length;
final inProgress = all.where((t) => t.status == 'in_progress').length;
```

### Filter High Priority
```dart
final all = await AnalyticsService.getAllTasksReport();
final highPriority = all.where((t) => 
  t.priority == 'high' || t.priority == 'urgent'
).toList();
```

### Group by Trashcan
```dart
final all = await AnalyticsService.getAllTasksReport();
final byBin = <String, List<TaskReport>>{};
for (var report in all) {
  byBin.putIfAbsent(report.trashcanName, () => []).add(report);
}
```

### Average Completion Time
```dart
final completed = await AnalyticsService.getTasksByStatus('completed');
int totalHours = 0;
for (var task in completed) {
  final diff = task.completedAt!.difference(task.createdAt);
  totalHours += diff.inHours;
}
final average = totalHours / completed.length;
```

## File Sizes (Approximate)

- CSV: ~1KB per 10 tasks
- HTML: ~3KB per 10 tasks
- JSON: ~2KB per 10 tasks
- TSV: ~1KB per 10 tasks

## Debug Tips

```dart
// Check data fetching
print('Reports: ${reports.length}');

// Check stats
print('Stats: $stats');

// Check export
print('CSV length: ${csv.length}');

// Check format
print('CSV starts with: ${csv.substring(0, 50)}');

// List all statuses
final statuses = reports.map((r) => r.status).toSet();
print('Statuses: $statuses');

// List all priorities
final priorities = reports.map((r) => r.priority).toSet();
print('Priorities: $priorities');
```

## Performance Notes

- ~100ms for 100 tasks
- ~500ms for 1000 tasks
- Use date filtering for large datasets
- Cache results with Riverpod
- CSV faster than HTML export

---

**Bookmark this page for quick reference!**

**For detailed docs:** See `ANALYTICS_EXPORT_GUIDE.md`  
**For implementation:** See `ANALYTICS_IMPLEMENTATION_SUMMARY.md`



