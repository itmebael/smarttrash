# Email Integration Guide

## Overview

Your email service is now configured with:
- **Service ID**: `service_uo9e3xj`
- **Template ID**: `template_8ixe808`
- **API Key**: `NxsdgyvCGJ90Qm2cz`

## Quick Start

### 1. Send Email When Task is Assigned

```dart
import 'package:ecowaste_manager_app/core/services/task_email_integration.dart';
import 'package:ecowaste_manager_app/core/models/task_model.dart';

// After creating a task
final task = await taskService.createTask(...);

// Send email notification
await TaskEmailIntegration.notifyTaskAssignment(
  task: task,
  staffName: 'John Doe',
  staffEmail: 'john.doe@example.com',
  location: 'Building A - 1st Floor',
);
```

### 2. Direct Email Service Usage

```dart
import 'package:ecowaste_manager_app/core/services/email_service.dart';
import 'package:ecowaste_manager_app/core/models/task_model.dart';

// Send email directly
final success = await EmailService.sendTaskAssignmentEmail(
  task: task,
  staffName: 'John Doe',
  staffEmail: 'john.doe@example.com',
  location: 'Building A - 1st Floor',
);

if (success) {
  print('Email sent successfully!');
}
```

### 3. Verify Email Service

```dart
// Test connection before sending
final isConnected = await EmailService.verifyConnection();
if (isConnected) {
  print('Email service is ready!');
}
```

## Integration with Task Service

Update your `task_service.dart` to automatically send emails:

```dart
import 'package:ecowaste_manager_app/core/services/task_email_integration.dart';

Future<TaskModel> createTask({
  required String title,
  required String description,
  required String assignedStaffId,
  required String createdByAdminId,
  String? trashcanId,
  String priority = 'medium',
  DateTime? dueDate,
  int? estimatedDuration,
}) async {
  try {
    // Create task using RPC
    final taskId = await _supabase.rpc('create_task', params: {...});
    
    // Fetch the created task
    final task = await getTaskById(taskId);
    
    // Get staff email
    final staffResponse = await _supabase
        .from('users')
        .select('name, email')
        .eq('id', assignedStaffId)
        .single();
    
    // Send email notification (non-blocking)
    TaskEmailIntegration.notifyTaskAssignment(
      task: task,
      staffName: staffResponse['name'],
      staffEmail: staffResponse['email'],
      location: task.trashcanName,
    ).catchError((e) {
      print('Email notification failed: $e');
      // Don't throw - email failure shouldn't break task creation
    });
    
    return task;
  } catch (e) {
    print('Error creating task: $e');
    rethrow;
  }
}
```

## Email Template Variables

Your EmailJS template should include these variables:

- `to_email` - Recipient email address
- `to_name` - Staff member's name
- `subject` - Email subject line
- `message_html` - HTML email body
- `message_text` - Plain text email body
- `task_title` - Task title
- `task_description` - Task description
- `trashcan_name` - Trashcan name
- `location` - Location of trashcan
- `priority` - Task priority (LOW, MEDIUM, HIGH, URGENT)
- `due_date` - Due date (ISO format)
- `estimated_duration` - Estimated duration in minutes
- `assigned_date` - Assignment date (ISO format)
- `company_name` - Company name
- `app_link` - Link to view task in app

## Configuration

### Update Sender Email

Edit `lib/core/services/email_service.dart`:

```dart
static const String fromEmail = 'your-verified-email@yourdomain.com';
static const String fromName = 'Your Company Name';
```

### Update App Link

Edit `lib/core/services/email_template_service.dart`:

```dart
static const String appLink = 'https://your-app-link.com/tasks';
```

## Testing

### Test Email Sending

```dart
void testEmail() async {
  final testTask = TaskModel(
    id: 'test-id',
    title: 'Test Task',
    description: 'This is a test task',
    status: TaskStatus.pending,
    priority: TaskPriority.medium,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final success = await EmailService.sendTaskAssignmentEmail(
    task: testTask,
    staffName: 'Test User',
    staffEmail: 'test@example.com',
    location: 'Test Location',
  );
  
  print(success ? 'Email sent!' : 'Email failed');
}
```

## Troubleshooting

### Email Not Sending

1. **Check API Key**: Verify your API key is correct
2. **Check Service ID**: Ensure service ID matches your EmailJS service
3. **Check Template ID**: Verify template ID exists in your EmailJS account
4. **Check Email Address**: Ensure recipient email is valid
5. **Check Network**: Verify internet connection

### Common Errors

- **401 Unauthorized**: API key is invalid
- **400 Bad Request**: Template parameters are missing or invalid
- **404 Not Found**: Service ID or Template ID doesn't exist
- **500 Server Error**: EmailJS service issue (try again later)

## EmailJS Setup

If you need to set up EmailJS:

1. Go to [EmailJS.com](https://www.emailjs.com)
2. Create an account
3. Add your email service (Gmail, Outlook, etc.)
4. Create an email template
5. Get your Service ID, Template ID, and Public Key
6. Update the constants in `email_service.dart`

## Security Notes

⚠️ **Important**: 
- Never commit API keys to public repositories
- Use environment variables for production
- Consider using Supabase Edge Functions for server-side email sending
- Validate email addresses before sending

## Next Steps

1. ✅ Email service is configured
2. ✅ Templates are ready
3. ⏳ Integrate with task creation
4. ⏳ Test email sending
5. ⏳ Monitor email delivery


