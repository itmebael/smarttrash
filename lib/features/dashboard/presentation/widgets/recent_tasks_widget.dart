import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/task_model.dart';

class RecentTasksWidget extends StatelessWidget {
  const RecentTasksWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual data from providers
    final recentTasks = [
      TaskModel(
        id: '1',
        title: 'Empty Trashcan A-1',
        description: 'Empty the trashcan near the main entrance',
        trashcanId: 'tc1',
        trashcanName: 'Trashcan A-1',
        assignedStaffId: 'staff1',
        assignedStaffName: 'John Doe',
        createdByAdminId: 'admin1',
        createdByAdminName: 'Admin User',
        status: TaskStatus.pending,
        priority: TaskPriority.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        dueDate: DateTime.now().add(const Duration(hours: 4)),
      ),
      TaskModel(
        id: '2',
        title: 'Empty Trashcan B-2',
        description: 'Empty the trashcan near the library',
        trashcanId: 'tc2',
        trashcanName: 'Trashcan B-2',
        assignedStaffId: 'staff2',
        assignedStaffName: 'Jane Smith',
        createdByAdminId: 'admin1',
        createdByAdminName: 'Admin User',
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        dueDate: DateTime.now().add(const Duration(hours: 2)),
      ),
      TaskModel(
        id: '3',
        title: 'Empty Trashcan C-3',
        description: 'Empty the trashcan near the cafeteria',
        trashcanId: 'tc3',
        trashcanName: 'Trashcan C-3',
        assignedStaffId: 'staff1',
        assignedStaffName: 'John Doe',
        createdByAdminId: 'admin1',
        createdByAdminName: 'Admin User',
        status: TaskStatus.completed,
        priority: TaskPriority.low,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        completedAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.assignment,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Recent Tasks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/tasks'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          if (recentTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: AppTheme.neutralGray.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent tasks',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.neutralGray,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: recentTasks.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = recentTasks[index];
                return _TaskItem(task: task);
              },
            ),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final TaskModel task;

  const _TaskItem({required this.task});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(task.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkGreen,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.trashcanName ?? 'No location',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutralGray),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _PriorityChip(priority: task.priority),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(task.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.neutralGray,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            _getStatusIcon(task.status),
            color: _getStatusColor(task.status),
            size: 20,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return AppTheme.warningOrange;
      case TaskStatus.inProgress:
        return AppTheme.secondaryBlue;
      case TaskStatus.completed:
        return AppTheme.successGreen;
      case TaskStatus.cancelled:
        return AppTheme.dangerRed;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getPriorityColor(priority).withOpacity(0.3)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getPriorityColor(priority),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppTheme.successGreen;
      case TaskPriority.medium:
        return AppTheme.warningOrange;
      case TaskPriority.high:
        return AppTheme.dangerRed;
      case TaskPriority.urgent:
        return AppTheme.dangerRed;
    }
  }
}

