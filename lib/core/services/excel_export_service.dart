import 'dart:convert';
import 'package:intl/intl.dart';
import 'analytics_service.dart';

class ExcelExportService {
  // Generate CSV content from task reports (Excel compatible)
  static String generateTaskReportCSV(List<TaskReport> reports) {
    try {
      print('📊 Generating CSV for ${reports.length} tasks...');

      // CSV Headers
      List<String> headers = [
        'Name',
        'Assign Bin',
        'Priority Level',
        'Status',
        'Completed Task',
        'Assign Date',
        'Completed Date',
      ];

      // Create CSV content
      StringBuffer csv = StringBuffer();

      // Add headers
      csv.writeln(headers.map(_escapeCsvValue).join(','));

      // Add data rows
      for (var report in reports) {
        List<String> row = [
          report.assignedStaffName ?? 'Unassigned',
          report.trashcanName,
          report.priority,
          report.status,
          report.status == 'completed' ? 'Yes' : 'No',
          _formatDate(report.createdAt),
          report.completedAt != null ? _formatDate(report.completedAt!) : 'N/A',
        ];
        csv.writeln(row.map(_escapeCsvValue).join(','));
      }

      print('✅ CSV generated successfully');
      return csv.toString();
    } catch (e) {
      print('❌ Error generating CSV: $e');
      return '';
    }
  }

  // Generate Excel-formatted HTML (can be opened in Excel)
  static String generateTaskReportHTML(List<TaskReport> reports) {
    try {
      print('📊 Generating HTML report for ${reports.length} tasks...');

      StringBuffer html = StringBuffer();

      html.writeln('<!DOCTYPE html>');
      html.writeln('<html>');
      html.writeln('<head>');
      html.writeln('<meta charset="utf-8">');
      html.writeln('<style>');
      html.writeln('table { border-collapse: collapse; width: 100%; }');
      html.writeln('th, td { border: 1px solid #000; padding: 8px; text-align: left; }');
      html.writeln('th { background-color: #4CAF50; color: white; font-weight: bold; }');
      html.writeln('tr:nth-child(even) { background-color: #f2f2f2; }');
      html.writeln('tr:hover { background-color: #e0e0e0; }');
      html.writeln('.high { color: #d32f2f; font-weight: bold; }');
      html.writeln('.urgent { color: #d32f2f; font-weight: bold; background-color: #ffcdd2; }');
      html.writeln('.completed { color: #388e3c; }');
      html.writeln('.pending { color: #f57c00; }');
      html.writeln('</style>');
      html.writeln('<title>Task Report</title>');
      html.writeln('</head>');
      html.writeln('<body>');

      html.writeln('<h1>EcoWaste Management - Task Report</h1>');
      html.writeln('<p>Generated: ${DateTime.now()}</p>');
      html.writeln('<p>Total Tasks: ${reports.length}</p>');

      html.writeln('<table>');
      html.writeln('<tr>');
      html.writeln('<th>Name</th>');
      html.writeln('<th>Assign Bin</th>');
      html.writeln('<th>Priority Level</th>');
      html.writeln('<th>Status</th>');
      html.writeln('<th>Completed Task</th>');
      html.writeln('<th>Assign Date</th>');
      html.writeln('<th>Completed Date</th>');
      html.writeln('</tr>');

      for (var report in reports) {
        final statusClass =
            report.status == 'completed' ? 'completed' : 'pending';

        html.writeln('<tr>');
        html.writeln(
            '<td>${_escapeHtml(report.assignedStaffName ?? 'Unassigned')}</td>');
        html.writeln('<td>${_escapeHtml(report.trashcanName)}</td>');
        html.writeln('<td>${_escapeHtml(report.priority)}</td>');
        html.writeln('<td>${_escapeHtml(report.status)}</td>');
        html.writeln(
            '<td class="$statusClass">${report.status == 'completed' ? 'Yes' : 'No'}</td>');
        html.writeln('<td>${_formatDate(report.createdAt)}</td>');
        html.writeln(
            '<td>${report.completedAt != null ? _formatDate(report.completedAt!) : 'N/A'}</td>');
        html.writeln('</tr>');
      }

      html.writeln('</table>');
      html.writeln('</body>');
      html.writeln('</html>');

      print('✅ HTML report generated successfully');
      return html.toString();
    } catch (e) {
      print('❌ Error generating HTML report: $e');
      return '';
    }
  }

  // Generate JSON format
  static String generateTaskReportJSON(List<TaskReport> reports) {
    try {
      print('📊 Generating JSON report for ${reports.length} tasks...');

      final reportMaps = reports.map((r) => r.toMap()).toList();

      final jsonData = {
        'report_date': DateTime.now().toIso8601String(),
        'total_tasks': reports.length,
        'tasks': reportMaps,
      };

      final jsonString =
          jsonEncode(jsonData);
      print('✅ JSON report generated successfully');
      return jsonString;
    } catch (e) {
      print('❌ Error generating JSON report: $e');
      return '';
    }
  }

  // Generate tab-separated values (TSV) - also Excel compatible
  static String generateTaskReportTSV(List<TaskReport> reports) {
    try {
      print('📊 Generating TSV for ${reports.length} tasks...');

      // TSV Headers
      List<String> headers = [
        'Name',
        'Assign Bin',
        'Priority Level',
        'Status',
        'Completed Task',
        'Assign Date',
        'Completed Date',
      ];

      StringBuffer tsv = StringBuffer();

      // Add headers
      tsv.writeln(headers.join('\t'));

      // Add data rows
      for (var report in reports) {
        List<String> row = [
          report.assignedStaffName ?? 'Unassigned',
          report.trashcanName,
          report.priority,
          report.status,
          report.status == 'completed' ? 'Yes' : 'No',
          _formatDate(report.createdAt),
          report.completedAt != null ? _formatDate(report.completedAt!) : 'N/A',
        ];
        tsv.writeln(row.join('\t'));
      }

      print('✅ TSV generated successfully');
      return tsv.toString();
    } catch (e) {
      print('❌ Error generating TSV: $e');
      return '';
    }
  }

  // Get file extension based on format
  static String getFileExtension(String format) {
    switch (format) {
      case 'csv':
        return '.csv';
      case 'tsv':
        return '.tsv';
      case 'html':
        return '.html';
      case 'json':
        return '.json';
      default:
        return '.csv';
    }
  }

  // Get MIME type based on format
  static String getMimeType(String format) {
    switch (format) {
      case 'csv':
        return 'text/csv';
      case 'tsv':
        return 'text/tab-separated-values';
      case 'html':
        return 'text/html';
      case 'json':
        return 'application/json';
      default:
        return 'text/plain';
    }
  }

  // Generate filename with timestamp
  static String generateFilename(String format) {
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    return 'task_report_$timestamp${getFileExtension(format)}';
  }

  // Helper function to escape CSV values
  static String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // Helper function to format dates
  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  // Helper function to escape HTML
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  // Generate summary statistics
  static Map<String, dynamic> generateSummaryStats(List<TaskReport> reports) {
    try {
      int completed = 0;
      int pending = 0;
      int inProgress = 0;
      int highPriority = 0;
      int urgentPriority = 0;

      for (var report in reports) {
        if (report.status == 'completed') completed++;
        if (report.status == 'pending') pending++;
        if (report.status == 'in_progress') inProgress++;
        if (report.priority == 'high') highPriority++;
        if (report.priority == 'urgent') urgentPriority++;
      }

      return {
        'total': reports.length,
        'completed': completed,
        'pending': pending,
        'in_progress': inProgress,
        'high_priority': highPriority,
        'urgent_priority': urgentPriority,
        'completion_rate': reports.isNotEmpty
            ? ((completed / reports.length) * 100).toStringAsFixed(1)
            : '0',
      };
    } catch (e) {
      print('❌ Error generating summary stats: $e');
      return {};
    }
  }
}



