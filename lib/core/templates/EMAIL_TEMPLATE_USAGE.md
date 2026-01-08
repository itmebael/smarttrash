# Email Template Usage Guide

## Overview

This email template system generates professional HTML and plain text emails when tasks are assigned to staff members.

## Files

- `lib/core/templates/task_assignment_email_template.html` - HTML template (reference)
- `lib/core/templates/task_assignment_email_template.txt` - Plain text template (reference)
- `lib/core/services/email_template_service.dart` - Service for generating emails

## Usage

### Basic Usage

```dart
import 'package:smarttrash/core/services/email_template_service.dart';

// Generate HTML email
final htmlEmail = EmailTemplateService.generateTaskAssignmentEmailHTML(
  staffName: 'John Doe',
  taskTitle: 'Empty Trashcan at Building A',
  taskDescription: 'Please empty the trashcan located at the main entrance.',
  trashcanName: 'Main Entrance Bin',
  location: 'Building A - 1st Floor',
  priority: 'high',
  dueDate: DateTime.now().add(Duration(days: 1)),
  estimatedDuration: 30,
  assignedDate: DateTime.now(),
);

// Generate plain text email
final textEmail = EmailTemplateService.generateTaskAssignmentEmailText(
  staffName: 'John Doe',
  taskTitle: 'Empty Trashcan at Building A',
  taskDescription: 'Please empty the trashcan located at the main entrance.',
  trashcanName: 'Main Entrance Bin',
  location: 'Building A - 1st Floor',
  priority: 'high',
  dueDate: DateTime.now().add(Duration(days: 1)),
  estimatedDuration: 30,
  assignedDate: DateTime.now(),
);

// Generate subject line
final subject = EmailTemplateService.generateEmailSubject(
  taskTitle: 'Empty Trashcan at Building A',
  priority: 'high',
);
```

### Using with TaskModel

```dart
import 'package:smarttrash/core/services/email_template_service.dart';
import 'package:smarttrash/core/models/task_model.dart';

// Assuming you have a TaskModel instance
final task = TaskModel(...);
final staffName = 'John Doe';
final staffEmail = 'john.doe@example.com';

// Generate complete email
final emailData = EmailTemplateService.generateEmailFromTask(
  taskModel: task,
  staffName: staffName,
  staffEmail: staffEmail,
  location: 'Building A - 1st Floor', // Optional
);

// emailData contains:
// - 'to': recipient email
// - 'subject': email subject
// - 'html': HTML email body
// - 'text': plain text email body
```

## Integration with Email Service

To send emails, you'll need to integrate with an email service provider. Here are some options:

### Option 1: Supabase Edge Functions (Recommended)

Create a Supabase Edge Function to send emails:

```typescript
// supabase/functions/send-task-email/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  const { to, subject, html, text } = await req.json()
  
  // Use a service like Resend, SendGrid, or Mailgun
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${Deno.env.get('RESEND_API_KEY')}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: 'noreply@yourcompany.com',
      to: [to],
      subject: subject,
      html: html,
      text: text,
    }),
  })
  
  return new Response(JSON.stringify({ success: true }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

### Option 2: Flutter Email Package

```dart
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendTaskAssignmentEmail({
  required String to,
  required String subject,
  required String htmlBody,
  required String textBody,
}) async {
  final smtpServer = gmail('your-email@gmail.com', 'your-app-password');
  
  final message = Message()
    ..from = Address('noreply@yourcompany.com', 'Smart Trash System')
    ..recipients.add(to)
    ..subject = subject
    ..html = htmlBody
    ..text = textBody;
  
  try {
    final sendReport = await send(message, smtpServer);
    print('Email sent: ${sendReport.toString()}');
  } catch (e) {
    print('Error sending email: $e');
  }
}
```

### Option 3: Direct API Integration

```dart
import 'package:http/http.dart' as http;

Future<void> sendEmailViaAPI({
  required String to,
  required String subject,
  required String htmlBody,
  required String textBody,
}) async {
  final response = await http.post(
    Uri.parse('https://api.your-email-service.com/send'),
    headers: {
      'Authorization': 'Bearer YOUR_API_KEY',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'to': to,
      'subject': subject,
      'html': htmlBody,
      'text': textBody,
    }),
  );
  
  if (response.statusCode == 200) {
    print('Email sent successfully');
  } else {
    print('Failed to send email: ${response.body}');
  }
}
```

## Template Variables

The templates support the following variables:

- `{{staff_name}}` - Staff member's name
- `{{task_title}}` - Task title
- `{{task_description}}` - Task description (optional)
- `{{trashcan_name}}` - Trashcan name
- `{{location}}` - Location of the trashcan
- `{{priority}}` - Task priority (low, medium, high, urgent)
- `{{due_date}}` - Due date (optional)
- `{{estimated_duration}}` - Estimated duration in minutes (optional)
- `{{assigned_date}}` - Date and time when task was assigned
- `{{app_link}}` - Link to view task in the app
- `{{company_name}}` - Company name

## Customization

### Change Company Name

Edit `lib/core/services/email_template_service.dart`:

```dart
static const String companyName = 'Your Company Name';
```

### Change App Link

Edit `lib/core/services/email_template_service.dart`:

```dart
static const String appLink = 'https://your-app-link.com/tasks';
```

### Customize Email Styling

Edit the HTML template in `generateTaskAssignmentEmailHTML()` method to change colors, fonts, or layout.

## Example Output

### HTML Email
- Professional green-themed design
- Responsive layout
- Task details in a highlighted box
- Priority badge with color coding
- Call-to-action button
- Footer with disclaimer

### Plain Text Email
- Clean ASCII formatting
- All task details clearly listed
- Easy to read in any email client
- No HTML dependencies

## Testing

To test the email templates:

```dart
void main() {
  final html = EmailTemplateService.generateTaskAssignmentEmailHTML(
    staffName: 'Test User',
    taskTitle: 'Test Task',
    trashcanName: 'Test Bin',
    location: 'Test Location',
    priority: 'high',
  );
  
  print(html); // View in browser or email client
}
```

## Notes

- The service automatically escapes HTML to prevent XSS attacks
- Dates are formatted in a user-friendly format
- Priority badges are color-coded for visual clarity
- Both HTML and plain text versions are generated for maximum compatibility
- The templates are designed to work with most email clients


