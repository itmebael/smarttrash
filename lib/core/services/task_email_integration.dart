import '../services/email_service.dart';
import '../models/task_model.dart';

/// Integration service to send emails when tasks are assigned
class TaskEmailIntegration {
  /// Send email notification when task is assigned
  /// Call this method after creating a task
  static Future<void> notifyTaskAssignment({
    required TaskModel task,
    required String staffName,
    required String staffEmail,
    String? location,
  }) async {
    if (staffEmail.isEmpty) {
      print('⚠️ Staff email is empty, skipping email notification');
      return;
    }

    try {
      final success = await EmailService.sendTaskAssignmentEmail(
        task: task,
        staffName: staffName,
        staffEmail: staffEmail,
        location: location,
      );

      if (success) {
        print('✅ Task assignment email sent successfully to $staffEmail');
      } else {
        print('❌ Failed to send task assignment email to $staffEmail');
      }
    } catch (e) {
      print('❌ Error in task email notification: $e');
      // Don't throw - email failure shouldn't break task creation
    }
  }

  /// Verify email service before sending
  static Future<bool> verifyEmailService() async {
    return await EmailService.verifyConnection();
  }
}

