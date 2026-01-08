# Analytics & Excel Export Guide

## Overview
The analytics system provides comprehensive task reports with real data from the Supabase database. Reports can be exported in multiple formats: CSV, TSV, HTML, and JSON.

## Features

### ✅ Real-Time Data Fetching
- Fetches actual task data from database
- Includes trashcan names, locations, and staff assignments
- Real-time statistics and metrics

### ✅ Multiple Export Formats
- **CSV** - Excel/Google Sheets compatible
- **TSV** - Tab-separated values
- **HTML** - Formatted table report with styling
- **JSON** - Structured data format

### ✅ Report Customization
- Filter by date range
- Filter by status (completed, pending, in_progress)
- Filter by priority (low, medium, high, urgent)
- Filter by assigned staff

### ✅ Summary Statistics
- Total tasks
- Completed/Pending/In-Progress counts
- High priority and urgent task counts
- Completion rates

## File Structure

### New Services

#### 1. **AnalyticsService** (`lib/core/services/analytics_service.dart`)

```dart
// Get all tasks report
List<TaskReport> reports = await AnalyticsService.getAllTasksReport();

// Get tasks by date range
List<TaskReport> reports = await AnalyticsService.getTasksReportByDateRange(
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2025, 1, 31),
);

// Get tasks by status
List<TaskReport> completed = await AnalyticsService.getTasksByStatus('completed');

// Get tasks by priority
List<TaskReport> urgent = await AnalyticsService.getTasksByPriority('urgent');

// Get tasks by staff
List<TaskReport> staffTasks = await AnalyticsService.getTasksByStaff(staffId);

// Get analytics statistics
Map<String, dynamic> stats = await AnalyticsService.getAnalyticsStats();

// Get trashcan analytics
Map<String, dynamic> binStats = await AnalyticsService.getTrashcanAnalytics();

// Get completion analytics
Map<String, dynamic> completion = await AnalyticsService.getCompletionAnalytics();
```

#### 2. **ExcelExportService** (`lib/core/services/excel_export_service.dart`)

```dart
// Generate CSV
String csv = ExcelExportService.generateTaskReportCSV(reports);

// Generate Excel-compatible HTML
String html = ExcelExportService.generateTaskReportHTML(reports);

// Generate JSON
String json = ExcelExportService.generateTaskReportJSON(reports);

// Generate TSV
String tsv = ExcelExportService.generateTaskReportTSV(reports);

// Get file extension
String ext = ExcelExportService.getFileExtension('csv'); // Returns: .csv

// Get MIME type
String mime = ExcelExportService.getMimeType('csv'); // Returns: text/csv

// Generate filename with timestamp
String filename = ExcelExportService.generateFilename('csv');
// Returns: task_report_2025-01-11_143022.csv

// Get summary statistics
Map<String, dynamic> summary = ExcelExportService.generateSummaryStats(reports);
```

### New Providers

#### 3. **Analytics Provider** (`lib/core/providers/analytics_provider.dart`)

```dart
// Watch all tasks report (auto-updates)
final reportAsync = ref.watch(allTasksReportProvider);

// Watch tasks by date range
final rangeReportAsync = ref.watch(tasksReportByDateRangeProvider((
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime(2025, 1, 31),
)));

// Watch tasks by status
final statusReportAsync = ref.watch(tasksByStatusProvider('completed'));

// Watch analytics statistics
final statsAsync = ref.watch(analyticsStatsProvider);

// Watch trashcan analytics
final binStatsAsync = ref.watch(trashcanAnalyticsProvider);

// Watch completion metrics
final completionAsync = ref.watch(completionAnalyticsProvider);
```

## TaskReport Model

Each task in the report contains:

```dart
class TaskReport {
  final String trashcanName;        // e.g., "Bin 1"
  final String? location;           // e.g., "Building A"
  final String priority;            // "low", "medium", "high", "urgent"
  final String? assignedStaffName;  // Staff member name
  final String status;              // "pending", "in_progress", "completed"
  final DateTime createdAt;         // Task creation date
  final DateTime? completedAt;      // Task completion date
  final String? notes;              // Additional notes
}
```

## Report Output Example

### CSV Format
```
Trashcan,Location,Priority,Assigned To,Status,Created Date,Completed Date,Notes
Bin 1,Building A,high,John Doe,completed,2025-01-10 14:30:00,2025-01-10 15:45:00,Cleaned successfully
Bin 2,Building B,urgent,Jane Smith,in_progress,2025-01-11 09:15:00,Pending,
Bin 3,Building C,medium,Unassigned,pending,2025-01-11 10:00:00,Pending,Needs inspection
```

### HTML Format
Formatted table with:
- Green header row
- Alternating row colors
- Highlight urgent/high priority tasks
- Styled status indicators
- Professional layout

### JSON Format
```json
{
  "report_date": "2025-01-11T14:30:00.000Z",
  "total_tasks": 15,
  "tasks": [
    {
      "Trashcan": "Bin 1",
      "Location": "Building A",
      "Priority": "high",
      "Assigned To": "John Doe",
      "Status": "completed",
      "Created Date": "2025-01-10 14:30:00",
      "Completed Date": "2025-01-10 15:45:00",
      "Notes": "Cleaned successfully"
    }
  ]
}
```

## Usage Examples

### Get Report and Download CSV

```dart
// Fetch report
final reports = await AnalyticsService.getAllTasksReport();

// Generate CSV
final csv = ExcelExportService.generateTaskReportCSV(reports);

// Generate filename
final filename = ExcelExportService.generateFilename('csv');

// Save or share (using file_saver or similar package)
// saveFile(filename, csv);
```

### Display Statistics

```dart
final stats = await AnalyticsService.getAnalyticsStats();

print('Total Tasks: ${stats['total_tasks']}');
print('Completed: ${stats['completed_tasks']}');
print('Pending: ${stats['pending_tasks']}');
print('In Progress: ${stats['in_progress_tasks']}');
print('Completion Rate: ${stats['completion_rate']}%');
```

### Generate Summary

```dart
final reports = await AnalyticsService.getAllTasksReport();
final summary = ExcelExportService.generateSummaryStats(reports);

print('Total: ${summary['total']}');
print('Completed: ${summary['completed']}');
print('Pending: ${summary['pending']}');
print('High Priority: ${summary['high_priority']}');
print('Urgent: ${summary['urgent_priority']}');
print('Completion Rate: ${summary['completion_rate']}%');
```

## Export Formats Comparison

| Format | Excel Compatible | Formatting | Best For |
|--------|-----------------|-----------|----------|
| CSV | ✅ Yes | No | Data import/export |
| TSV | ✅ Yes | No | Data analysis |
| HTML | ✅ Yes (Open with Excel) | ✅ Yes | Print-friendly reports |
| JSON | ❌ No | Structured | API integration |

## Analytics Queries

### Get Completed Tasks Today
```dart
final now = DateTime.now();
final today = DateTime(now.year, now.month, now.day);
final tomorrow = today.add(Duration(days: 1));

final todayTasks = await AnalyticsService.getTasksReportByDateRange(
  startDate: today,
  endDate: tomorrow,
);
```

### Get High Priority Tasks
```dart
final highPriority = await AnalyticsService.getTasksByPriority('high');
final urgent = await AnalyticsService.getTasksByPriority('urgent');
```

### Get Staff Performance
```dart
final staffTasks = await AnalyticsService.getTasksByStaff(staffId);
final completed = staffTasks.where((t) => t.status == 'completed').length;
final total = staffTasks.length;
final performance = (completed / total * 100).toStringAsFixed(1);
```

## Downloading Reports

To implement download functionality in Flutter:

```dart
// For Web
import 'dart:html' as html;

void downloadReport(String content, String filename, String mimeType) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrl(blob);
  html.window.open(url, filename);
  html.Url.revokeObjectUrl(url);
}

// Usage
final csv = ExcelExportService.generateTaskReportCSV(reports);
final filename = ExcelExportService.generateFilename('csv');
final mimeType = ExcelExportService.getMimeType('csv');
downloadReport(csv, filename, mimeType);
```

## Date Filtering Examples

```dart
// Last 7 days
final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
final reports = await AnalyticsService.getTasksReportByDateRange(
  startDate: sevenDaysAgo,
  endDate: DateTime.now(),
);

// Current month
final now = DateTime.now();
final startOfMonth = DateTime(now.year, now.month, 1);
final endOfMonth = DateTime(now.year, now.month + 1, 0);
final monthReports = await AnalyticsService.getTasksReportByDateRange(
  startDate: startOfMonth,
  endDate: endOfMonth,
);

// Last quarter
final quarterAgo = DateTime.now().subtract(Duration(days: 90));
final quarterReports = await AnalyticsService.getTasksReportByDateRange(
  startDate: quarterAgo,
  endDate: DateTime.now(),
);
```

## Performance Tips

1. **Cache Results** - Use Riverpod providers to cache results
2. **Limit Date Range** - Smaller ranges load faster
3. **Filter Before Export** - Get specific data, not everything
4. **Batch Operations** - Export multiple filters at once

## Error Handling

All services include error handling:

```dart
try {
  final reports = await AnalyticsService.getAllTasksReport();
  final csv = ExcelExportService.generateTaskReportCSV(reports);
  // Download or display
} catch (e) {
  print('Error: $e');
  // Show error to user
}
```

## Database Queries Reference

### Get Task Count by Status
```sql
SELECT status, COUNT(*) as count
FROM tasks
GROUP BY status;
```

### Get Average Completion Time
```sql
SELECT 
  AVG(EXTRACT(EPOCH FROM (completed_at - created_at)) / 3600) as avg_hours
FROM tasks
WHERE status = 'completed';
```

### Get Tasks by Staff
```sql
SELECT 
  u.name,
  COUNT(t.id) as total_tasks,
  COUNT(CASE WHEN t.status = 'completed' THEN 1 END) as completed
FROM users u
LEFT JOIN tasks t ON u.id = t.assigned_staff_id
WHERE u.role = 'staff'
GROUP BY u.id, u.name;
```

## Integration with UI

### In Analytics Page

```dart
class AnalyticsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(allTasksReportProvider);
    final statsAsync = ref.watch(analyticsStatsProvider);

    return reportAsync.when(
      data: (reports) {
        final csv = ExcelExportService.generateTaskReportCSV(reports);
        
        return Column(
          children: [
            // Display stats
            statsAsync.when(
              data: (stats) => Text('Total: ${stats['total_tasks']}'),
              ...
            ),
            
            // Download button
            ElevatedButton(
              onPressed: () => _downloadCSV(csv),
              child: const Text('Download CSV'),
            ),
            
            // Tasks table
            TasksTable(reports: reports),
          ],
        );
      },
      ...
    );
  }
}
```

## Testing

```dart
// Mock analytics
void testAnalytics() {
  final mockReports = [
    TaskReport(
      trashcanName: 'Bin 1',
      location: 'Building A',
      priority: 'high',
      assignedStaffName: 'John',
      status: 'completed',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    ),
  ];

  final csv = ExcelExportService.generateTaskReportCSV(mockReports);
  expect(csv.contains('Bin 1'), true);
  expect(csv.contains('high'), true);
}
```

## Troubleshooting

### Issue: Empty Reports
- Check if tasks exist in database
- Verify date range is correct
- Ensure user has read permissions

### Issue: Export File Empty
- Verify reports list is not empty
- Check format is correct
- Ensure no exceptions during generation

### Issue: Slow Report Generation
- Use date range filter
- Limit to specific status/priority
- Consider pagination for large datasets

## Future Enhancements

- [ ] Real-time data updates
- [ ] Advanced filtering UI
- [ ] Scheduled reports
- [ ] Email report delivery
- [ ] Chart visualizations
- [ ] Data trend analysis
- [ ] Staff performance ranking
- [ ] Predictive analytics

---

**Version:** 1.0  
**Last Updated:** 2025-01-11  
**Status:** Production Ready ✅



