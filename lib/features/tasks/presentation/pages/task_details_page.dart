import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/utils/navigation_helper.dart';

class TaskDetailsPage extends ConsumerWidget {
  final TaskModel task;

  const TaskDetailsPage({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 8.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Task ID: ${task.id}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24.0),

            // Task Information
            _buildInfoSection(
              context,
              'Description',
              task.description,
              Icons.description,
            ),

            const SizedBox(height: 16.0),

            _buildInfoSection(
              context,
              'Status',
              _getStatusText(task.status),
              _getStatusIcon(task.status),
            ),

            const SizedBox(height: 16.0),

            _buildInfoSection(
              context,
              'Priority',
              _getPriorityText(task.priority),
              _getPriorityIcon(task.priority),
            ),

            const SizedBox(height: 16.0),

            _buildInfoSection(
              context,
              'Assigned To',
              task.assignedStaffName ?? 'Unassigned',
              Icons.person,
            ),

            const SizedBox(height: 16.0),

            _buildInfoSection(
              context,
              'Due Date',
              task.dueDate != null ? _formatDate(task.dueDate!) : 'Not set',
              Icons.calendar_today,
            ),

            const SizedBox(height: 16.0),
            _buildInfoSection(
              context,
              'Created At',
              _formatDate(task.createdAt),
              Icons.access_time,
            ),

            if (task.completedAt != null) ...[
              const SizedBox(height: 16.0),
              _buildInfoSection(
                context,
                'Completed At',
                _formatDate(task.completedAt!),
                Icons.check_circle,
              ),
            ],

            const SizedBox(height: 32.0),

            // Action Buttons
            if (task.status == TaskStatus.pending) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement start task functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Starting task...'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ],

            if (task.status == TaskStatus.inProgress) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement complete task functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Completing task...'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Complete Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.neutralGray,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.hourglass_empty;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

