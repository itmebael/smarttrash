import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/models/user_model.dart';

class UserCard extends ConsumerWidget {
  final UserModel user;
  final VoidCallback onToggleStatus;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.onToggleStatus,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? EcoGradients.glassGradient
            : EcoGradients.lightGlassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: user.isActive
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : AppTheme.neutralGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    fontSize: 14,
                  ),
                ),
                if (user.department != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${user.department}${user.position != null ? ' • ${user.position}' : ''}',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: user.isActive
                  ? AppTheme.successGreen.withOpacity(0.2)
                  : AppTheme.dangerRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: user.isActive ? AppTheme.successGreen : AppTheme.dangerRed,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Actions
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: onToggleStatus,
                child: Row(
                  children: [
                    Icon(
                      user.isActive ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(user.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onDelete,
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppTheme.dangerRed),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppTheme.dangerRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
