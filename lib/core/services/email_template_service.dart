import 'package:intl/intl.dart';

/// Service for generating email templates for task assignments
class EmailTemplateService {
  static const String companyName = 'Smart Trash Management System';
  static const String appLink = 'https://your-app-link.com/tasks'; // Update with your actual app link

  /// Generate HTML email template for task assignment
  static String generateTaskAssignmentEmailHTML({
    required String staffName,
    required String taskTitle,
    String? taskDescription,
    required String trashcanName,
    required String location,
    required String priority,
    DateTime? dueDate,
    int? estimatedDuration,
    DateTime? assignedDate,
  }) {
    final assignedDateStr = assignedDate != null
        ? DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(assignedDate)
        : DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(DateTime.now());

    final dueDateStr = dueDate != null
        ? DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(dueDate)
        : null;

    final durationStr = estimatedDuration != null
        ? '$estimatedDuration minutes'
        : null;

    // Priority badge class
    String priorityClass = 'priority-medium';
    switch (priority.toLowerCase()) {
      case 'urgent':
        priorityClass = 'priority-urgent';
        break;
      case 'high':
        priorityClass = 'priority-high';
        break;
      case 'low':
        priorityClass = 'priority-low';
        break;
      default:
        priorityClass = 'priority-medium';
    }

    final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>New Task Assigned</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f4f4f4;
        }
        .email-container {
            background-color: #ffffff;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            background: linear-gradient(135deg, #10b981 0%, #059669 100%);
            color: white;
            padding: 20px;
            border-radius: 8px 8px 0 0;
            margin: -30px -30px 30px -30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            font-size: 24px;
        }
        .task-details {
            background-color: #f9fafb;
            border-left: 4px solid #10b981;
            padding: 20px;
            margin: 20px 0;
            border-radius: 4px;
        }
        .detail-row {
            margin: 10px 0;
            display: flex;
            align-items: flex-start;
        }
        .detail-label {
            font-weight: bold;
            color: #374151;
            min-width: 120px;
        }
        .detail-value {
            color: #1f2937;
            flex: 1;
        }
        .priority-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: bold;
            text-transform: uppercase;
        }
        .priority-urgent {
            background-color: #fee2e2;
            color: #991b1b;
        }
        .priority-high {
            background-color: #fef3c7;
            color: #92400e;
        }
        .priority-medium {
            background-color: #dbeafe;
            color: #1e40af;
        }
        .priority-low {
            background-color: #e5e7eb;
            color: #374151;
        }
        .action-button {
            display: inline-block;
            background-color: #10b981;
            color: white;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 6px;
            margin: 20px 0;
            font-weight: bold;
            text-align: center;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
            color: #6b7280;
            font-size: 14px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>📋 New Task Assigned</h1>
        </div>
        
        <p>Hi <strong>${_escapeHtml(staffName)}</strong>,</p>
        
        <p>Thank you for your continued dedication! A new task has been assigned to you, and we appreciate your prompt attention to this matter.</p>
        
        <div class="task-details">
            <h2 style="margin-top: 0; color: #1f2937;">Task Details</h2>
            
            <div class="detail-row">
                <span class="detail-label">📝 Task Title:</span>
                <span class="detail-value"><strong>${_escapeHtml(taskTitle)}</strong></span>
            </div>
            
            ${taskDescription != null ? '''
            <div class="detail-row">
                <span class="detail-label">📄 Description:</span>
                <span class="detail-value">${_escapeHtml(taskDescription)}</span>
            </div>
            ''' : ''}
            
            <div class="detail-row">
                <span class="detail-label">📍 Location:</span>
                <span class="detail-value">${_escapeHtml(trashcanName)} - ${_escapeHtml(location)}</span>
            </div>
            
            <div class="detail-row">
                <span class="detail-label">⚡ Priority:</span>
                <span class="detail-value">
                    <span class="priority-badge $priorityClass">${priority.toUpperCase()}</span>
                </span>
            </div>
            
            ${dueDateStr != null ? '''
            <div class="detail-row">
                <span class="detail-label">📅 Due Date:</span>
                <span class="detail-value"><strong>${_escapeHtml(dueDateStr)}</strong></span>
            </div>
            ''' : ''}
            
            ${durationStr != null ? '''
            <div class="detail-row">
                <span class="detail-label">⏱️ Estimated Duration:</span>
                <span class="detail-value">${_escapeHtml(durationStr)}</span>
            </div>
            ''' : ''}
            
            <div class="detail-row">
                <span class="detail-label">📆 Assigned On:</span>
                <span class="detail-value">${_escapeHtml(assignedDateStr)}</span>
            </div>
        </div>
        
        <p><strong>Next Steps:</strong></p>
        <ul>
            <li>Please review the task details above</li>
            <li>Plan your schedule accordingly to meet the deadline</li>
            <li>Update the task status in the app once you begin work</li>
            <li>Contact your supervisor if you have any questions</li>
        </ul>
        
        <div style="text-align: center;">
            <a href="$appLink" class="action-button">View Task in App</a>
        </div>
        
        <p>We trust you'll handle this task with your usual professionalism. If you have any questions or need assistance, please don't hesitate to reach out.</p>
        
        <p>Best regards,<br>
        <strong>The $companyName Team</strong></p>
        
        <div class="footer">
            <p>This is an automated notification. Please do not reply to this email.</p>
            <p>If you have questions, please contact your supervisor directly.</p>
        </div>
    </div>
</body>
</html>
''';

    return html;
  }

  /// Generate plain text email template for task assignment
  static String generateTaskAssignmentEmailText({
    required String staffName,
    required String taskTitle,
    String? taskDescription,
    required String trashcanName,
    required String location,
    required String priority,
    DateTime? dueDate,
    int? estimatedDuration,
    DateTime? assignedDate,
  }) {
    final assignedDateStr = assignedDate != null
        ? DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(assignedDate)
        : DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(DateTime.now());

    final dueDateStr = dueDate != null
        ? DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(dueDate)
        : null;

    final durationStr = estimatedDuration != null
        ? '$estimatedDuration minutes'
        : null;

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('                    NEW TASK ASSIGNED');
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln();
    buffer.writeln('Hi $staffName,');
    buffer.writeln();
    buffer.writeln('Thank you for your continued dedication! A new task has been assigned');
    buffer.writeln('to you, and we appreciate your prompt attention to this matter.');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('TASK DETAILS');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln();
    buffer.writeln('Task Title: $taskTitle');
    buffer.writeln();

    if (taskDescription != null) {
      buffer.writeln('Description: $taskDescription');
      buffer.writeln();
    }

    buffer.writeln('Location: $trashcanName - $location');
    buffer.writeln();
    buffer.writeln('Priority: ${priority.toUpperCase()}');
    buffer.writeln();

    if (dueDateStr != null) {
      buffer.writeln('Due Date: $dueDateStr');
      buffer.writeln();
    }

    if (durationStr != null) {
      buffer.writeln('Estimated Duration: $durationStr');
      buffer.writeln();
    }

    buffer.writeln('Assigned On: $assignedDateStr');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('NEXT STEPS');
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln();
    buffer.writeln('• Please review the task details above');
    buffer.writeln('• Plan your schedule accordingly to meet the deadline');
    buffer.writeln('• Update the task status in the app once you begin work');
    buffer.writeln('• Contact your supervisor if you have any questions');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln();
    buffer.writeln('View Task in App: $appLink');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln();
    buffer.writeln('We trust you\'ll handle this task with your usual professionalism.');
    buffer.writeln('If you have any questions or need assistance, please don\'t hesitate');
    buffer.writeln('to reach out.');
    buffer.writeln();
    buffer.writeln('Best regards,');
    buffer.writeln('The $companyName Team');
    buffer.writeln();
    buffer.writeln('───────────────────────────────────────────────────────────────');
    buffer.writeln('This is an automated notification. Please do not reply to this email.');
    buffer.writeln('If you have questions, please contact your supervisor directly.');
    buffer.writeln('═══════════════════════════════════════════════════════════════');

    return buffer.toString();
  }

  /// Escape HTML special characters
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Generate email subject line
  static String generateEmailSubject({
    required String taskTitle,
    required String priority,
  }) {
    final priorityEmoji = switch (priority.toLowerCase()) {
      'urgent' => '🚨',
      'high' => '⚠️',
      'medium' => '📋',
      'low' => '📝',
      _ => '📋',
    };

    return '$priorityEmoji New Task Assigned: $taskTitle';
  }

  /// Generate email from TaskModel (convenience method)
  static Map<String, String> generateEmailFromTask({
    required taskModel,
    required String staffName,
    required String staffEmail,
    String? location,
  }) {
    // Import TaskModel if needed
    final taskTitle = taskModel.title;
    final taskDescription = taskModel.description;
    final trashcanName = taskModel.trashcanName ?? 'Unknown Location';
    final taskLocation = location ?? taskModel.trashcanName ?? 'Location not specified';
    final priority = taskModel.priorityString;
    final dueDate = taskModel.dueDate;
    final estimatedDuration = taskModel.estimatedDuration;
    final assignedDate = taskModel.createdAt;

    final subject = generateEmailSubject(
      taskTitle: taskTitle,
      priority: priority,
    );

    final htmlBody = generateTaskAssignmentEmailHTML(
      staffName: staffName,
      taskTitle: taskTitle,
      taskDescription: taskDescription.isNotEmpty ? taskDescription : null,
      trashcanName: trashcanName,
      location: taskLocation,
      priority: priority,
      dueDate: dueDate,
      estimatedDuration: estimatedDuration,
      assignedDate: assignedDate,
    );

    final textBody = generateTaskAssignmentEmailText(
      staffName: staffName,
      taskTitle: taskTitle,
      taskDescription: taskDescription.isNotEmpty ? taskDescription : null,
      trashcanName: trashcanName,
      location: taskLocation,
      priority: priority,
      dueDate: dueDate,
      estimatedDuration: estimatedDuration,
      assignedDate: assignedDate,
    );

    return {
      'to': staffEmail,
      'subject': subject,
      'html': htmlBody,
      'text': textBody,
    };
  }
}

