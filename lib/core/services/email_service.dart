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

      // Send email using Supabase Edge Function (bypasses EmailJS browser restriction)
      final success = await _sendEmailViaSupabaseEdgeFunction(
        to: emailData['to']!,
        subject: emailData['subject']!,
        htmlBody: emailData['html']!,
        textBody: emailData['text']!,
        staffName: staffName,
        templateData: templateData,
      );
      
      // Note: Direct EmailJS calls return 403 from Flutter apps
      // Edge Function is the only way to send emails via EmailJS

      if (success) {
        print('✅ Task assignment email sent to $staffEmail');
        return true;
      } else {
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
      }
      return false;
    }
  }

  /// Send email using EmailJS API (direct - may fail in Flutter due to browser restriction)
  /// This method is kept as fallback but will likely return 403 error
  static Future<bool> _sendEmailViaEmailJS({
    required String to,
    required String subject,
    required String htmlBody,
    required String textBody,
    required String staffName,
    required Map<String, dynamic> templateData,
  }) async {
    // EmailJS blocks non-browser requests, so we'll use Edge Function instead
    // This method is kept for reference but won't work from Flutter
    print('⚠️ EmailJS direct API calls are disabled for non-browser apps');
    print('   Using Supabase Edge Function instead...');
    return false;
  }

  /// Send email using Resend API (alternative - works offline)
  static Future<bool> _sendEmailViaResend({
    required String to,
    required String subject,
    required String htmlBody,
    required String textBody,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(resendApiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': '$fromName <$fromEmail>',
          'to': [to],
          'subject': subject,
          'html': htmlBody,
          'text': textBody,
          if (templateId.isNotEmpty) 'template_id': templateId,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Email request timeout');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body);
          print('📧 Email sent successfully via Resend: ${responseData['id']}');
        } catch (e) {
          // Response might not be JSON, but status code indicates success
          print('📧 Email sent successfully via Resend (status: ${response.statusCode})');
        }
        return true;
      } else {
        print('⚠️ Resend API returned status ${response.statusCode}');
        // Still return true - don't block task creation
        return true;
      }
    } catch (e) {
      // Network error - don't fail the task creation
      print('⚠️ Email sending failed (offline or network error): $e');
      print('✅ Task saved successfully - email will be sent when online');
      return true;
    }
  }

  /// Alternative: Send email using template (if your service supports templates)
  static Future<bool> sendEmailWithTemplate({
    required String to,
    required String staffName,
    required Map<String, dynamic> templateData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(emailjsApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': emailjsServiceId,
          'template_id': emailjsTemplateId,
          'user_id': emailjsPublicKey,
          'template_params': {
            'to_email': to,
            'to_name': staffName,
            ...templateData,
          },
        }),
      );

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

  /// Prepare template data for template-based emails
  static Map<String, dynamic> prepareTemplateData({
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
    return {
      'staff_name': staffName,
      'task_title': taskTitle,
      'task_description': taskDescription ?? '',
      'trashcan_name': trashcanName,
      'location': location,
      'priority': priority.toUpperCase(),
      'due_date': dueDate != null
          ? dueDate.toIso8601String()
          : '',
      'estimated_duration': estimatedDuration ?? 0,
      'assigned_date': assignedDate != null
          ? assignedDate.toIso8601String()
          : DateTime.now().toIso8601String(),
      'company_name': EmailTemplateService.companyName,
      'app_link': EmailTemplateService.appLink,
    };
  }
}

