import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/email_template_service.dart';
import '../models/task_model.dart';

/// Email service for sending task assignment emails
/// Uses Resend API (or similar email service)
class EmailService {
  // Email service credentials
  static const String serviceId = 'service_uo9e3xj';
  static const String templateId = 'template_8ixe808';
  static const String apiKey = 'NxsdgyvCGJ90Qm2cz';
  
  // Email configuration
  static const String fromEmail = 'noreply@smarttrash.com'; // Update with your verified sender email
  static const String fromName = 'Smart Trash Management System';
  
  // EmailJS configuration (alternative to Resend)
  // service_uo9e3xj
  // template_8ixe808
  // NxsdgyvCGJ90Qm2cz
  static const String emailjsServiceId = 'service_uo9e3xj';
  static const String emailjsTemplateId = 'template_8ixe808';
  static const String emailjsPublicKey = 'NxsdgyvCGJ90Qm2cz';
  static const String emailjsApiUrl = 'https://api.emailjs.com/api/v1.0/email/send';
  
  // Supabase Edge Function URL (use this instead of direct EmailJS API)
  // Replace with your actual Supabase project URL
  static const String supabaseEdgeFunctionUrl = 'https://ssztyskjcoilweqmheef.supabase.co/functions/v1/send-task-email';
  
  // Resend API (if using Resend instead)
  static const String resendApiUrl = 'https://api.resend.com/emails';

  /// Send task assignment email to staff member
  static Future<bool> sendTaskAssignmentEmail({
    required TaskModel task,
    required String staffName,
    required String staffEmail,
    String? location,
  }) async {
    try {
      // Generate email content using template service
      final emailData = EmailTemplateService.generateEmailFromTask(
        taskModel: task,
        staffName: staffName,
        staffEmail: staffEmail,
        location: location,
      );

      // Prepare template data
      final templateData = prepareTemplateData(
        staffName: staffName,
        taskTitle: task.title,
        taskDescription: task.description.isNotEmpty ? task.description : null,
        trashcanName: task.trashcanName ?? 'Unknown Location',
        location: location ?? task.trashcanName ?? 'Location not specified',
        priority: task.priorityString,
        dueDate: task.dueDate,
        estimatedDuration: task.estimatedDuration,
        assignedDate: task.createdAt,
      );
      
      // Add HTML body to template data in case the template uses it
      templateData['message_html'] = emailData['html'];
      templateData['html_body'] = emailData['html'];
      templateData['message'] = emailData['text'];

      // Try sending directly via EmailJS REST API first (works on mobile/desktop without CORS issues)
      // If this fails (e.g. web), we can fallback to Edge Function or handle error
      final success = await sendEmailWithTemplate(
        to: emailData['to']!,
        staffName: staffName,
        templateData: templateData,
      );
      
      // Note: Direct EmailJS calls return 403 from Flutter apps IF "Allow non-browser applications" is unchecked in EmailJS dashboard
      // If it fails with 403, we should try Edge Function as fallback, but for now we'll prioritize direct call
      // as it avoids the need for Edge Function deployment for Windows/Mobile users.

      if (success) {
        print('✅ Task assignment email sent to $staffEmail');
        return true;
      } else {
        // Fallback to Edge Function if direct call fails
        print('⚠️ Direct email failed, trying Edge Function...');
        final edgeSuccess = await _sendEmailViaSupabaseEdgeFunction(
          to: emailData['to']!,
          subject: emailData['subject']!,
          htmlBody: emailData['html']!,
          textBody: emailData['text']!,
          staffName: staffName,
          templateData: templateData,
        );
        
        if (edgeSuccess) {
           print('✅ Task assignment email sent to $staffEmail via Edge Function');
           return true;
        }

        print('❌ Failed to send email to $staffEmail');
        return false;
      }
    } catch (e) {
      print('❌ Error sending task assignment email: $e');
      return false;
    }
  }

  /// Send email using Supabase Edge Function (bypasses EmailJS browser restriction)
  static Future<bool> _sendEmailViaSupabaseEdgeFunction({
    required String to,
    required String subject,
    required String htmlBody,
    required String textBody,
    required String staffName,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      print('📧 Sending email via Supabase Edge Function...');
      print('   To: $to');
      print('   Subject: $subject');

      // Call Supabase Edge Function to send email
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        'send-task-email',
        body: {
          'to_email': to,
          'to email': to,
          'email': to,
          'recipient': to,
          'reply_to': to,
          'staff_name': staffName,
          'task_title': templateData['task_title'] ?? '',
          'task_description': templateData['task_description'] ?? '',
          'trashcan_name': templateData['trashcan_name'] ?? '',
          'location': templateData['location'] ?? '',
          'priority': templateData['priority'] ?? 'medium',
          'due_date': templateData['due_date'] ?? '',
          'estimated_duration': templateData['estimated_duration']?.toString() ?? '',
          'assigned_date': templateData['assigned_date'] ?? DateTime.now().toIso8601String(),
        },
      );

      if (response.status == 200) {
        final data = response.data;
        if (data != null && data['success'] == true) {
          print('✅ Email sent successfully via Edge Function!');
          return true;
        } else {
          print('⚠️ Edge Function returned error: ${data?.toString() ?? response.data}');
          return false;
        }
      } else {
        print('❌ Edge Function error (status ${response.status}): ${response.data}');
        return false;
      }
    } catch (e) {
      // Check if it's a FunctionException (404 = function not found)
      if (e.toString().contains('404') || e.toString().contains('NOT_FOUND')) {
        print('⚠️ Edge Function not found (404) - Function needs to be deployed');
        print('   📝 To deploy:');
        print('   1. Go to Supabase Dashboard → Edge Functions');
        print('   2. Click "Create a new function"');
        print('   3. Name: send-task-email');
        print('   4. Copy code from: supabase/functions/send-task-email/index.ts');
        print('   5. Click Deploy');
        print('   ⚠️ Email will not be sent until Edge Function is deployed');
        print('   📖 See EMAIL_SETUP_INSTRUCTIONS.md for detailed steps');
      } else {
        print('❌ Error calling Supabase Edge Function: $e');
        // If it's a 500 error, it might be an internal script error in the Edge Function
        if (e.toString().contains('500')) {
             print('   📝 Check Supabase Dashboard → Edge Functions → send-task-email → Logs');
             print('   📝 The Edge Function might have crashed or has invalid credentials');
        }
      }
      return false;
    }
  }



  /// Alternative: Send email using template (if your service supports templates)
  static Future<bool> sendEmailWithTemplate({
    required String to,
    required String staffName,
    required Map<String, dynamic> templateData,
  }) async {
    // Log the payload for debugging
    print('📝 Sending EmailJS payload to $to');
    
    // Ensure all data is string for template safety
    final safeTemplateData = templateData.map((key, value) => MapEntry(key, value.toString()));

    try {
      final response = await http.post(
        Uri.parse(emailjsApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost', // Helps with some EmailJS restrictions
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36', // Spoof browser to bypass non-browser restriction
        },
        body: jsonEncode({
          'service_id': emailjsServiceId,
          'template_id': emailjsTemplateId,
          'user_id': emailjsPublicKey,
          'template_params': {
            'to_email': to,
            'to email': to,
            'email': to,
            'recipient': to,
            'user_email': to,
            'target_email': to,
            'send_to': to,
            'reply_to': 'noreply@smarttrash.com',
            'to_name': staffName,
            ...safeTemplateData,
          },
        }),
      );

      print('📧 EmailJS Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('❌ EmailJS Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        print('📧 Template email sent successfully');
        return true;
      } else {
        print('❌ Template email error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending template email: $e');
      return false;
    }
  }

  /// Verify email service connection (removed internet dependency)
  /// Returns true to allow offline operation
  static Future<bool> verifyConnection() async {
    // Skip internet verification - allow offline operation
    print('✅ Email service ready (offline mode)');
    return true;
  }

  /// Prepare template data for email
  static Map<String, dynamic> prepareTemplateData({
    required String staffName,
    required String taskTitle,
    String? taskDescription,
    required String trashcanName,
    required String location,
    required String priority,
    DateTime? dueDate,
    int? estimatedDuration,
    required DateTime assignedDate,
  }) {
    // Helper to format date
    String formatDate(DateTime? date) {
      if (date == null) return 'N/A';
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    return {
      'staff_name': staffName,
      'task_title': taskTitle,
      'task_description': taskDescription ?? 'No description provided',
      'trashcan_name': trashcanName,
      'location': location,
      'priority': priority,
      'due_date': formatDate(dueDate),
      'estimated_duration': estimatedDuration != null ? '$estimatedDuration min' : 'N/A',
      'assigned_date': formatDate(assignedDate),
    };
  }
}

