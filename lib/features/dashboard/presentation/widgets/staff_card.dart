import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';

class StaffCard extends ConsumerWidget {
  final UserModel staff;
  final VoidCallback onToggleStatus;
  final VoidCallback onRemove;

  const StaffCard({
    super.key,
    required this.staff,
    required this.onToggleStatus,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: staff.isActive
              ? AppTheme.primaryGreen.withOpacity(0.2)
              : AppTheme.neutralGray.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: staff.isActive
                  ? AppTheme.primaryGreen.withOpacity(0.1)
                  : AppTheme.neutralGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: staff.isActive
                    ? AppTheme.primaryGreen.withOpacity(0.3)
                    : AppTheme.neutralGray.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: staff.profileImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: staff.profileImageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: staff.isActive
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : AppTheme.neutralGray.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: staff.isActive
                              ? AppTheme.primaryGreen
                              : AppTheme.neutralGray,
                          size: 24,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: staff.isActive
                            ? AppTheme.primaryGreen.withOpacity(0.1)
                            : AppTheme.neutralGray.withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          color: staff.isActive
                              ? AppTheme.primaryGreen
                              : AppTheme.neutralGray,
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: staff.isActive
                          ? AppTheme.primaryGreen
                          : AppTheme.neutralGray,
                      size: 24,
                    ),
            ),
          ),

          const SizedBox(width: 16),

          // Staff info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        staff.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textGray,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: staff.isActive
                            ? AppTheme.accentGreen.withOpacity(0.1)
                            : AppTheme.warningOrange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        staff.isActive ? 'Active' : 'Inactive',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: staff.isActive
                                  ? AppTheme.accentGreen
                                  : AppTheme.warningOrange,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  staff.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  staff.phoneNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                if (staff.age != null ||
                    staff.department != null ||
                    staff.position != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (staff.age != null) ...[
                        const Icon(
                          Icons.cake,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${staff.age} years',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (staff.department != null) ...[
                        const Icon(
                          Icons.business,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            staff.department!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (staff.position != null) ...[
                        const Icon(
                          Icons.work,
                          size: 12,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            staff.position!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Joined ${_formatDate(staff.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    if (staff.lastLoginAt != null) ...[
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.login,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Last login ${_formatDate(staff.lastLoginAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Actions
          Column(
            children: [
              IconButton(
                onPressed: onToggleStatus,
                icon: Icon(
                  staff.isActive ? Icons.pause : Icons.play_arrow,
                  color: staff.isActive
                      ? AppTheme.warningOrange
                      : AppTheme.primaryGreen,
                ),
                tooltip: staff.isActive ? 'Deactivate' : 'Activate',
              ),
              IconButton(
                onPressed: () => _showRemoveDialog(context),
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.dangerRed,
                ),
                tooltip: 'Remove Staff',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  void _showRemoveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Staff Member',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textGray,
                fontWeight: FontWeight.bold,
              ),
        ),
        content: Text(
          'Are you sure you want to remove ${staff.name} from the staff list? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.neutralGray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRemove();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

