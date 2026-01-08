import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/staff_tasks_provider.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/trashcan_model.dart';
import '../../../../core/services/task_service.dart';
import '../../../../core/utils/navigation_helper.dart';

class TaskAssignmentPage extends ConsumerStatefulWidget {
  const TaskAssignmentPage({super.key});

  @override
  ConsumerState<TaskAssignmentPage> createState() =>
      _TaskAssignmentPageState();
}

class _TaskAssignmentPageState extends ConsumerState<TaskAssignmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taskService = TaskService();
  
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  UserModel? _selectedStaff;
  TrashcanModel? _selectedTrashcan;
  int? _estimatedDuration; // in minutes

  List<UserModel> _staffMembers = [];
  List<TrashcanModel> _trashcans = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);
      
      final staff = await _taskService.getAllStaff();
      final allTrashcans = await _taskService.getAllTrashcans();
      
      // Filter out offline bins - only show bins that are online
      final onlineTrashcans = allTrashcans.where((trashcan) {
        return trashcan.isOnline && trashcan.status != TrashcanStatus.offline;
      }).toList();
      
      if (!mounted) return;
      setState(() {
        _staffMembers = staff;
        _trashcans = onlineTrashcans;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildAssignmentForm(isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Assign Task',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormCard(
              title: 'Task Details',
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Task Title',
                  hint: 'Enter task title',
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter task description',
                  isDark: isDark,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFormCard(
              title: 'Assignment Details',
              children: [
                _buildStaffSelector(isDark),
                const SizedBox(height: 16),
                _buildTrashcanSelector(isDark),
                const SizedBox(height: 16),
                _buildPrioritySelector(isDark),
                const SizedBox(height: 16),
                _buildDateSelector(isDark),
                const SizedBox(height: 16),
                _buildDurationField(isDark),
              ],
            ),
            const SizedBox(height: 30),
            _buildAssignButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color:
                  isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
            filled: true,
            fillColor: isDark
                ? AppTheme.backgroundGreen.withOpacity(0.1)
                : AppTheme.lightBackground.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign to Staff',
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<UserModel>(
          value: _selectedStaff,
          onChanged: (value) {
            setState(() {
              _selectedStaff = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a staff member';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppTheme.backgroundGreen.withOpacity(0.1)
                : AppTheme.lightBackground.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
          ),
          dropdownColor: isDark ? AppTheme.backgroundGreen : Colors.white,
          items: _staffMembers.map((staff) {
            return DropdownMenuItem(
              value: staff,
              child: Text(
                '${staff.name} - ${staff.position ?? 'Staff'}',
                style: TextStyle(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                ),
              ),
            );
          }).toList(),
          hint: Text(
            _staffMembers.isEmpty ? 'No staff available' : 'Select staff member',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrashcanSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trashcan Location',
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<TrashcanModel>(
          value: _selectedTrashcan,
          onChanged: (value) {
            setState(() {
              _selectedTrashcan = value;
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark
                ? AppTheme.backgroundGreen.withOpacity(0.1)
                : AppTheme.lightBackground.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
          ),
          dropdownColor: isDark ? AppTheme.backgroundGreen : Colors.white,
          items: _trashcans.map((trashcan) {
            return DropdownMenuItem(
              value: trashcan,
              child: Text(
                '${trashcan.name} - ${trashcan.locationName}',
                style: TextStyle(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                ),
              ),
            );
          }).toList(),
          hint: Text(
            _trashcans.isEmpty ? 'No trashcans available' : 'Select trashcan',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Level',
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: TaskPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getPriorityColor(priority).withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? _getPriorityColor(priority)
                          : AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getPriorityIcon(priority),
                        color: isSelected
                            ? _getPriorityColor(priority)
                            : (isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary),
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        priority.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? _getPriorityColor(priority)
                              : (isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.lightTextSecondary),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date',
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_selectedDate),
              );
              if (time != null) {
                setState(() {
                  _selectedDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.backgroundGreen.withOpacity(0.1)
                  : AppTheme.lightBackground.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color:
                        isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Estimated Duration',
              style: TextStyle(
                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional, in minutes)',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., 30, 60, 120',
            hintStyle: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
            filled: true,
            fillColor: isDark
                ? AppTheme.backgroundGreen.withOpacity(0.1)
                : AppTheme.lightBackground.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _estimatedDuration = int.tryParse(value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildAssignButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _assignTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Assign Task',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    try {
      await _taskService.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedStaffId: _selectedStaff!.id,
        createdByAdminId: user.id,
        trashcanId: _selectedTrashcan?.id,
        priority: _selectedPriority.name,
        dueDate: _selectedDate,
        estimatedDuration: _estimatedDuration,
      );

      if (!mounted) return;
      
      // Invalidate staff tasks provider so assigned staff sees the new task
      ref.invalidate(staffTasksProvider(_selectedStaff!.id));
      ref.invalidate(staffTaskStatsProvider(_selectedStaff!.id));
      ref.invalidate(pendingTasksProvider(_selectedStaff!.id));
      
      // Show success message with action to go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Task assigned successfully to ${_selectedStaff!.name}!'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'VIEW TASKS',
            textColor: Colors.white,
            onPressed: () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
      
      // Clear the form for next task
      if (mounted) {
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedStaff = null;
          _selectedTrashcan = null;
          _selectedPriority = TaskPriority.medium;
          _selectedDate = DateTime.now().add(const Duration(days: 1));
          _estimatedDuration = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign task: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
        return AppTheme.neonPurple;
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
}
