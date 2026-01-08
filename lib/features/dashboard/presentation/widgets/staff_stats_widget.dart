import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/services/staff_data_service.dart';

class StaffStatsWidget extends ConsumerWidget {
  const StaffStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final totalStaff = StaffDataService.getTotalStaffCount();
    final activeStaff = StaffDataService.getActiveStaffCount();
    final inactiveStaff = StaffDataService.getInactiveStaffCount();
    final departmentStats = StaffDataService.getDepartmentStats();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Staff Statistics',
                style: TextStyle(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total staff count
          _buildStatCard(
            'Total Staff',
            totalStaff.toString(),
            Icons.people_outline,
            AppTheme.primaryGreen,
            isDark,
          ),

          const SizedBox(height: 16),

          // Active vs Inactive
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active',
                  activeStaff.toString(),
                  Icons.check_circle,
                  AppTheme.primaryGreen,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Inactive',
                  inactiveStaff.toString(),
                  Icons.cancel,
                  AppTheme.dangerRed,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Department breakdown
          Text(
            'By Department',
            style: TextStyle(
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          ...departmentStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondary
                          : AppTheme.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


