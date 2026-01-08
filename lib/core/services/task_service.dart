import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/trashcan_model.dart';
import 'notification_service.dart';
import 'task_email_integration.dart';

class TaskService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all tasks (admin view)
  Future<List<TaskModel>> getAllTasks() async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('''
            *,
            assigned_staff:assigned_staff_id(id, name, email),
            created_by:created_by_admin_id(id, name, email),
            trashcans(id, name, location)
          ''')
          .order('created_at', ascending: false);

      return (response as List)
          .map((task) => TaskModel.fromSupabaseMap(task))
          .toList();
    } catch (e) {
      print('Error getting all tasks: $e');
      throw Exception('Failed to get tasks: $e');
    }
  }

  // Get tasks assigned to a specific staff member
  Future<List<TaskModel>> getTasksByStaffId(String staffId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('''
            *,
            assigned_staff:assigned_staff_id(id, name, email),
            created_by:created_by_admin_id(id, name, email),
            trashcans(id, name, location)
          ''')
          .eq('assigned_staff_id', staffId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((task) => TaskModel.fromSupabaseMap(task))
          .toList();
    } catch (e) {
      print('Error getting tasks for staff: $e');
      throw Exception('Failed to get staff tasks: $e');
    }
  }

  // Get tasks by status
  Future<List<TaskModel>> getTasksByStatus(String status) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('''
            *,
            assigned_staff:assigned_staff_id(id, name, email),
            created_by:created_by_admin_id(id, name, email),
            trashcans(id, name, location)
          ''')
          .eq('status', status)
          .order('created_at', ascending: false);

      return (response as List)
          .map((task) => TaskModel.fromSupabaseMap(task))
          .toList();
    } catch (e) {
      print('Error getting tasks by status: $e');
      throw Exception('Failed to get tasks by status: $e');
    }
  }

  // Create a new task (uses RPC function that creates notifications automatically)
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
      print('📋 Creating task: $title for staff: $assignedStaffId');
      
      // Use RPC function that automatically creates notifications
      final taskId = await _supabase.rpc('create_task', params: {
        'p_title': title,
        'p_description': description,
        'p_assigned_staff_id': assignedStaffId,
        'p_created_by_admin_id': createdByAdminId,
        'p_trashcan_id': trashcanId,
        'p_priority': priority,
        'p_due_date': dueDate?.toIso8601String(),
      });

      print('✅ Task created with ID: $taskId');

      // Fetch the created task with all relations
      final response = await _supabase
          .from('tasks')
          .select('''
            *,
            assigned_staff:assigned_staff_id(id, name, email),
            created_by:created_by_admin_id(id, name, email),
            trashcans(id, name, location)
          ''')
          .eq('id', taskId)
          .single();

      final task = TaskModel.fromSupabaseMap(response);
      print('✅ Task fetched successfully: ${task.title}');
      
      // Local notification for admin context
      NotificationService.notifyTaskAssigned(
        taskTitle: task.title,
        trashcanName: task.trashcanName ?? 'assigned location',
      );
      
      // Send email notification to assigned staff (non-blocking)
      if (task.assignedStaffId != null && task.assignedStaffName != null) {
        try {
          // Get staff email from the response
          final staffEmail = response['assigned_staff']?['email'];
          if (staffEmail != null && staffEmail.toString().isNotEmpty) {
            print('📧 Sending email notification to $staffEmail...');
            // Import and use email integration
            await TaskEmailIntegration.notifyTaskAssignment(
              task: task,
              staffName: task.assignedStaffName!,
              staffEmail: staffEmail.toString(),
              location: task.trashcanName ?? response['trashcans']?['location']?.toString(),
            );
          } else {
            print('⚠️ Staff email not found, skipping email notification');
          }
        } catch (e) {
          print('⚠️ Error sending email notification (non-critical): $e');
          // Don't throw - email failure shouldn't break task creation
        }
      }
      
      return task;
    } catch (e) {
      print('❌ Error creating task: $e');
      // Fallback to direct insert if RPC fails
      try {
        print('⚠️  Falling back to direct insert...');
        final taskData = {
          'title': title,
          'description': description,
          'assigned_staff_id': assignedStaffId,
          'created_by_admin_id': createdByAdminId,
          'trashcan_id': trashcanId,
          'priority': priority,
          'status': 'pending',
          'due_date': dueDate?.toIso8601String(),
          'estimated_duration': estimatedDuration,
        };

        // Insert without join first to avoid foreign key relationship issues
        final insertResponse = await _supabase
            .from('tasks')
            .insert(taskData)
            .select()
            .single();

        // Fetch the created task with all relations separately
        final response = await _supabase
            .from('tasks')
            .select('''
              *,
              assigned_staff:assigned_staff_id(id, name, email),
              created_by:created_by_admin_id(id, name, email)
            ''')
            .eq('id', insertResponse['id'])
            .single();

        // Manually fetch trashcan if trashcan_id exists
        if (trashcanId != null) {
          try {
            final trashcanResponse = await _supabase
                .from('trashcans')
                .select('id, name, location')
                .eq('id', trashcanId)
                .single();
            response['trashcan'] = trashcanResponse;
          } catch (e) {
            print('⚠️  Could not fetch trashcan: $e');
            response['trashcan'] = null;
          }
        } else {
          response['trashcan'] = null;
        }

        // Manually create notification for assigned staff
        try {
          await _supabase.from('notifications').insert({
            'title': '📋 New Task Assigned',
            'body': 'You have been assigned: $title',
            'type': 'task_assigned',
            'priority': priority,
            'user_id': assignedStaffId,
            'task_id': response['id'],
            if (trashcanId != null) 'trashcan_id': trashcanId,
          });
          print('✅ Notification created for staff');
          NotificationService.notifyTaskAssigned(
            taskTitle: title,
            trashcanName: response['trashcan']?['name'] ?? 'assigned location',
          );
        } catch (notifError) {
          print('⚠️  Failed to create notification: $notifError');
        }

        return TaskModel.fromSupabaseMap(response);
      } catch (fallbackError) {
        print('❌ Fallback insert also failed: $fallbackError');
        throw Exception('Failed to create task: $e');
      }
    }
  }

  // Update task status
  Future<TaskModel> updateTaskStatus({
    required String taskId,
    required String status,
    String? completionNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'in_progress') {
        updateData['started_at'] = DateTime.now().toIso8601String();
      } else if (status == 'completed') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
        if (completionNotes != null) {
          updateData['completion_notes'] = completionNotes;
        }
      }

      final response = await _supabase
          .from('tasks')
          .update(updateData)
          .eq('id', taskId)
          .select('''
            *,
            assigned_staff:assigned_staff_id(id, name, email),
            created_by:created_by_admin_id(id, name, email),
            trashcans(id, name, location)
          ''')
          .single();

      final task = TaskModel.fromSupabaseMap(response);

      if (status == 'completed') {
        try {
          final recipientIds = <String>{};
          final adminId = response['created_by_admin_id']?.toString();
          final staffId = response['assigned_staff_id']?.toString();
          if (adminId != null && adminId.isNotEmpty) {
            recipientIds.add(adminId);
          }
          if (staffId != null && staffId.isNotEmpty) {
            recipientIds.add(staffId);
          }

          for (final recipientId in recipientIds) {
            await _supabase.from('notifications').insert({
              'title': '✅ Task Completed',
              'body': '"${task.title}" has been marked completed.',
              'type': 'task_completed',
              'priority': response['priority'] ?? 'medium',
              'user_id': recipientId,
              'task_id': response['id'],
              if (response['trashcan_id'] != null)
                'trashcan_id': response['trashcan_id'],
            });
          }
        } catch (notifError) {
          print('⚠️  Failed to create completion notification: $notifError');
        }

        NotificationService.notifyTaskCompleted(
          taskTitle: task.title,
          trashcanName: task.trashcanName,
        );
      }

      return task;
    } catch (e) {
      print('Error updating task status: $e');
      throw Exception('Failed to update task status: $e');
    }
  }

  // Update task
  Future<TaskModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? assignedStaffId,
    String? trashcanId,
    String? priority,
    String? status,
    DateTime? dueDate,
    int? estimatedDuration,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (assignedStaffId != null) {
        updateData['assigned_staff_id'] = assignedStaffId;
      }
      if (trashcanId != null) updateData['trashcan_id'] = trashcanId;
      if (priority != null) updateData['priority'] = priority;
      if (status != null) updateData['status'] = status;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (estimatedDuration != null) {
        updateData['estimated_duration'] = estimatedDuration;
      }

      final response = await _supabase
          .from('tasks')
          .update(updateData)
          .eq('id', taskId)
          .select('''
            *,
            assigned_staff:assigned_staff_id(id, name, email),
            created_by:created_by_admin_id(id, name, email),
            trashcans(id, name, location)
          ''')
          .single();

      return TaskModel.fromSupabaseMap(response);
    } catch (e) {
      print('Error updating task: $e');
      throw Exception('Failed to update task: $e');
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      print('Error deleting task: $e');
      throw Exception('Failed to delete task: $e');
    }
  }

  // Get all staff members (for task assignment)
  Future<List<UserModel>> getAllStaff() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List).map((user) => UserModel.fromMap(user)).toList();
    } catch (e) {
      print('Error getting staff members: $e');
      throw Exception('Failed to get staff members: $e');
    }
  }

  // Get all trashcans (for task assignment)
  Future<List<TrashcanModel>> getAllTrashcans() async {
    try {
      final response = await _supabase
          .from('trashcans')
          .select()
          .order('name', ascending: true);

      return (response as List)
          .map((trashcan) => TrashcanModel.fromSupabaseMap(trashcan))
          .toList();
    } catch (e) {
      print('Error getting trashcans: $e');
      throw Exception('Failed to get trashcans: $e');
    }
  }

  // Get task statistics
  Future<Map<String, int>> getTaskStatistics({String? staffId}) async {
    try {
      var query = _supabase.from('tasks').select('status');

      if (staffId != null) {
        query = query.eq('assigned_staff_id', staffId);
      }

      final response = await query;
      final tasks = response as List;

      return {
        'total': tasks.length,
        'pending': tasks.where((t) => t['status'] == 'pending').length,
        'in_progress': tasks.where((t) => t['status'] == 'in_progress').length,
        'completed': tasks.where((t) => t['status'] == 'completed').length,
        'cancelled': tasks.where((t) => t['status'] == 'cancelled').length,
      };
    } catch (e) {
      print('Error getting task statistics: $e');
      throw Exception('Failed to get task statistics: $e');
    }
  }

  // Stream tasks (real-time updates)
  Stream<List<TaskModel>> streamTasks({String? staffId}) {
    try {
      var query = _supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);

      return query.map((data) {
        return data.map((task) => TaskModel.fromSupabaseMap(task)).toList();
      });
    } catch (e) {
      print('Error streaming tasks: $e');
      throw Exception('Failed to stream tasks: $e');
    }
  }
}

