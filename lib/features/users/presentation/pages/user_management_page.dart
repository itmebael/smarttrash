import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/user_service.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/user_card.dart';
import '../widgets/edit_user_dialog.dart';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() =>
      _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> {
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, admin, staff, active, inactive
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await UserService.getAllUsers();
      setState(() {
        _allUsers = users;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<UserModel> filtered = List.from(_allUsers);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.department?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply role/status filter
    switch (_selectedFilter) {
      case 'admin':
        filtered = filtered.where((user) => user.role == UserRole.admin).toList();
        break;
      case 'staff':
        filtered = filtered.where((user) => user.role == UserRole.staff).toList();
        break;
      case 'active':
        filtered = filtered.where((user) => user.isActive).toList();
        break;
      case 'inactive':
        filtered = filtered.where((user) => !user.isActive).toList();
        break;
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      final success = await UserService.toggleUserStatus(user.id, !user.isActive);
      if (success) {
        await _loadUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${user.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _editUser(UserModel user) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    );

    if (updated == true) {
      await _loadUsers();
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await UserService.deleteUser(user.id);
        if (success) {
          await _loadUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User deleted successfully'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
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
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                            ),
                          )
                        : _buildUserList(),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkGray.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: IconButton(
                  onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                    Text(
                      'Manage all users',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark
                  ? AppTheme.darkGray.withOpacity(0.3)
                  : Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('admin', 'Admin', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('staff', 'Staff', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Active', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('inactive', 'Inactive', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
          _applyFilters();
        });
      },
      backgroundColor: isDark
          ? AppTheme.darkGray.withOpacity(0.3)
          : Colors.white.withOpacity(0.5),
      selectedColor: AppTheme.primaryGreen.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected
            ? AppTheme.primaryGreen
            : (isDark ? AppTheme.textGray : AppTheme.lightTextPrimary),
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UserCard(
            user: user,
            onToggleStatus: () => _toggleUserStatus(user),
            onEdit: () => _editUser(user),
            onDelete: () => _deleteUser(user),
          ),
        );
      },
    );
  }
}
