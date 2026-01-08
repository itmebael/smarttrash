import 'dart:convert';
import 'package:http/http.dart' as http;
import 'email_service.dart';

/// Test service for debugging email sending
class EmailTestService {
  /// Test sending an email directly via EmailJS
  static Future<Map<String, dynamic>> testEmailSending({
    required String toEmail,
    required String staffName,
    required String taskTitle,
  }) async {
    try {
      print('🧪 Testing EmailJS email sending...');
      print('   To: $toEmail');
      print('   Staff Name: $staffName');
      print('   Task Title: $taskTitle');
      
      final response = await http.post(
        Uri.parse(EmailService.emailjsApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': EmailService.emailjsServiceId,
          'template_id': EmailService.emailjsTemplateId,
          'user_id': EmailService.emailjsPublicKey,
          'template_params': {
            'to_email': toEmail,
            'to_name': staffName,
            'subject': 'Test: $taskTitle',
            'staff_name': staffName,
            'task_title': taskTitle,
            'task_description': 'This is a test task description',
            'trashcan_name': 'Test Bin',
            'location': 'Test Location',
            'priority': 'MEDIUM',
            'due_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
            'estimated_duration': '30',
            'assigned_date': DateTime.now().toIso8601String(),
            'company_name': 'Smart Trash Management System',
            'app_link': 'https://your-app-link.com/tasks',
          },
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📧 Response Status: ${response.statusCode}');
      print('📧 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'status': response.statusCode,
            'data': data,
            'message': 'Email sent successfully!',
          };
        } catch (e) {
          return {
            'success': true,
            'status': response.statusCode,
            'data': response.body,
            'message': 'Email sent (response not JSON)',
          };
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'status': response.statusCode,
            'error': errorData,
            'message': 'Email sending failed',
          };
        } catch (e) {
          return {
            'success': false,
            'status': response.statusCode,
            'error': response.body,
            'message': 'Email sending failed',
          };
        }
      }
    } catch (e) {
      print('❌ Test email error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error testing email',
      };
    }
  }
}


