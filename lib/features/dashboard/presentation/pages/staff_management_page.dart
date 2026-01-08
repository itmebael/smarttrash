import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/staff_data_service.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../widgets/staff_card.dart';
import '../widgets/create_staff_dialog.dart';

class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({super.key});

  @override
  ConsumerState<StaffManagementPage> createState() =>
      _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  List<UserModel> _staffMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffMembers();
  }

  void _loadStaffMembers() {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      // Load staff data from service
      final allStaff = StaffDataService.getAllStaff();
      setState(() {
        _staffMembers = allStaff;
        _isLoading = false;
      });
    });
  }

  void _addStaffMember(UserModel newStaff) {
    StaffDataService.addStaff(newStaff);
    setState(() {
      _staffMembers = StaffDataService.getAllStaff();
    });
  }

  void _removeStaffMember(String staffId) {
    StaffDataService.removeStaff(staffId);
    setState(() {
      _staffMembers = StaffDataService.getAllStaff();
    });
  }

  void _toggleStaffStatus(String staffId) {
    StaffDataService.toggleStaffStatus(staffId);
    setState(() {
      _staffMembers = StaffDataService.getAllStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
        ),
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateStaffDialog(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: EcoGradients.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
              )
            : _staffMembers.isEmpty
                ? _buildEmptyState()
                : _buildStaffList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateStaffDialog,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Staff'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: AppTheme.neutralGray.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Staff Members',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first staff member to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateStaffDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Staff Member'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Total Staff',
                  _staffMembers.length.toString(),
                  Icons.people,
                  AppTheme.primaryGreen,
                ),
                _buildStatItem(
                  'Active',
                  _staffMembers.where((s) => s.isActive).length.toString(),
                  Icons.check_circle,
                  AppTheme.accentGreen,
                ),
                _buildStatItem(
                  'Inactive',
                  _staffMembers.where((s) => !s.isActive).length.toString(),
                  Icons.pause_circle,
                  AppTheme.warningOrange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Staff list
          Text(
            'Staff Members',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _staffMembers.length,
            itemBuilder: (context, index) {
              final staff = _staffMembers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StaffCard(
                  staff: staff,
                  onToggleStatus: () => _toggleStaffStatus(staff.id),
                  onRemove: () => _removeStaffMember(staff.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.textGray,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
      ],
    );
  }

  void _showCreateStaffDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateStaffDialog(
        onStaffCreated: _addStaffMember,
      ),
    );
  }
}

