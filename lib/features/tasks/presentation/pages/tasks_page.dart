import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/trashcan_model.dart';
import '../../../../core/services/task_service.dart';
import '../../../../core/services/trashcan_service.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/task_completion_verification_dialog.dart';
import '../widgets/completed_task_details_dialog.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final _taskService = TaskService();
  List<TaskModel> _allTasks = [];
  bool _isLoading = true;

  int _selectedFilter = 0; // 0: All, 1: Pending, 2: In Progress, 3: Completed
  final List<String> _filterLabels = [
    'All',
    'Pending',
    'In Progress',
    'Completed'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      setState(() => _isLoading = true);
      
      final user = ref.read(authProvider).value;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      List<TaskModel> tasks;
      if (user.isAdmin) {
        // Admin sees all tasks
        tasks = await _taskService.getAllTasks();
      } else {
        // Staff sees only their assigned tasks
        tasks = await _taskService.getTasksByStaffId(user.id);
      }

      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading tasks: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<TaskModel> get _filteredTasks {
    switch (_selectedFilter) {
      case 1:
        return _allTasks
            .where((task) => task.status == TaskStatus.pending)
            .toList();
      case 2:
        return _allTasks
            .where((task) => task.status == TaskStatus.inProgress)
            .toList();
      case 3:
        return _allTasks
            .where((task) => task.status == TaskStatus.completed)
            .toList();
      default:
        return _allTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? EcoGradients.backgroundGradient
              : EcoGradients.lightBackgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildFilterTabs(),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _buildTasksList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ref.watch(authProvider).value?.isAdmin == true
          ? FloatingActionButton.extended(
              onPressed: () => _loadTasks(),
              backgroundColor: AppTheme.primaryGreen,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Refresh',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final isDark = ref.watch(isDarkModeProvider);
    final user = ref.watch(authProvider).value;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? EcoShadows.light : EcoShadows.light,
            ),
            child: const Icon(
              Icons.assignment,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.isAdmin == true ? 'All Tasks' : 'My Tasks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                ),
                Text(
                  user?.isAdmin == true
                      ? 'Manage all assigned tasks'
                      : 'Manage your assigned tasks',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Row(
        children: _filterLabels.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = _selectedFilter == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppTheme.secondaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasksList() {
    final filteredTasks = _filteredTasks;

    if (filteredTasks.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return _buildTaskCard(task, index);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = ref.watch(isDarkModeProvider);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no tasks in this category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, int index) {
    final isDark = ref.watch(isDarkModeProvider);
    final user = ref.watch(authProvider).value;
    final isStaff = user?.isStaff ?? false;

    return TweenAnimationBuilder<double>(
      key: ValueKey('task_card_${task.id}'),
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: InkWell(
        key: ValueKey('task_inkwell_${task.id}'),
        onTap: task.status == TaskStatus.completed
            ? () => _showCompletedTaskDetails(task)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _getPriorityColor(task.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPriorityIcon(task.priority),
                    color: _getPriorityColor(task.priority),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.textGray
                              : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (task.trashcanName != null)
                        Text(
                          task.trashcanName!,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusChip(task.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.description,
              style: TextStyle(
                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Due: ${_formatDateTime(task.dueDate)}',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
                if (task.estimatedDuration != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.estimatedDuration} min',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const Spacer(),
                if (isStaff && task.status != TaskStatus.completed && task.status != TaskStatus.cancelled)
                  ElevatedButton(
                    onPressed: () => _updateTaskStatus(task),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      task.status == TaskStatus.pending ? 'Start' : 'Complete',
                      style: const TextStyle(
                        inherit: false,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            if (task.assignedStaffName != null && user?.isAdmin == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned to: ${task.assignedStaffName}',
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }

  void _showCompletedTaskDetails(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => CompletedTaskDetailsDialog(task: task),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    String label;

    switch (status) {
      case TaskStatus.pending:
        color = AppTheme.warningOrange;
        label = 'Pending';
        break;
      case TaskStatus.inProgress:
        color = AppTheme.secondaryBlue;
        label = 'In Progress';
        break;
      case TaskStatus.completed:
        color = AppTheme.successGreen;
        label = 'Completed';
        break;
      case TaskStatus.cancelled:
        color = AppTheme.dangerRed;
        label = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
      case TaskPriority.urgent:
        return AppTheme.dangerRed;
      case TaskPriority.medium:
        return AppTheme.warningOrange;
      case TaskPriority.low:
        return AppTheme.secondaryBlue;
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
      case TaskPriority.urgent:
        return Icons.priority_high;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'No due date';

    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  Future<void> _updateTaskStatus(TaskModel task) async {
    if (task.status == TaskStatus.pending) {
      // Start task - no verification needed
      try {
        await _taskService.updateTaskStatus(
          taskId: task.id,
          status: 'in_progress',
        );

        await _loadTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task started successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update task: $e'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    } else {
      // Complete task - show verification dialog
      await _showCompletionVerificationDialog(task);
    }
  }

  Future<void> _showCompletionVerificationDialog(TaskModel task) async {
    TrashcanModel? trashcan;
    
    // Fetch trashcan data if task has trashcan_id
    if (task.trashcanId != null) {
      try {
        final trashcanService = TrashcanService();
        final trashcans = await trashcanService.getAllTrashcans();
        if (trashcans.isNotEmpty) {
          try {
            trashcan = trashcans.firstWhere(
              (t) => t.id == task.trashcanId,
            );
          } catch (e) {
            // Trashcan not found in list, try to get by ID
            trashcan = await trashcanService.getTrashcanById(task.trashcanId!);
          }
        }
      } catch (e) {
        print('Error loading trashcan: $e');
      }
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TaskCompletionVerificationDialog(
        task: task,
        trashcan: trashcan,
      ),
    );

    if (result == true && mounted) {
      // Task was completed successfully, reload tasks
      await _loadTasks();
    }
  }
}
