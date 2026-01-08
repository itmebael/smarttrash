import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/models/task_model.dart';

class CompletedTaskDetailsDialog extends ConsumerStatefulWidget {
  final TaskModel task;

  const CompletedTaskDetailsDialog({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<CompletedTaskDetailsDialog> createState() =>
      _CompletedTaskDetailsDialogState();
}

class _CompletedTaskDetailsDialogState
    extends ConsumerState<CompletedTaskDetailsDialog> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _verificationData;
  double? _staffRating;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerificationData();
  }

  Future<void> _loadVerificationData() async {
    try {
      setState(() => _isLoading = true);

      // Fetch verification data from task_completion_verifications table
      final verificationResponse = await _supabase
          .from('task_completion_verifications')
          .select('*')
          .eq('task_id', widget.task.id)
          .order('verified_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (verificationResponse != null) {
        setState(() {
          _verificationData = Map<String, dynamic>.from(verificationResponse);
        });
      }

      // Fetch staff rating if task has assigned staff
      if (widget.task.assignedStaffId != null) {
        try {
          final staffResponse = await _supabase
              .from('users')
              .select('rating')
              .eq('id', widget.task.assignedStaffId!)
              .single();

          setState(() {
            _staffRating = (staffResponse['rating'] as num?)?.toDouble();
          });
        } catch (e) {
          print('Error fetching staff rating: $e');
        }
      }
    } catch (e) {
      print('Error loading verification data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getVerificationType() {
    if (_verificationData == null) {
      // Try to parse from completion_notes
      final notes = widget.task.completionNotes ?? '';
      if (notes.contains('Manual') || notes.contains('manual')) {
        return 'Manual';
      }
      return 'Automatic';
    }

    final status = _verificationData!['verification_status'] as String?;
    final isWithinRange = _verificationData!['is_within_range'] as bool?;

    if (status == 'manual_override') {
      return 'Manual';
    } else if (isWithinRange == true) {
      return 'Automatic';
    } else {
      return 'Manual';
    }
  }

  String? _getPhotoUrl() {
    String? photoUrl;
    
    if (_verificationData != null) {
      photoUrl = _verificationData!['photo_url'] as String?;
    } else {
      // Try to parse from completion_notes
      final notes = widget.task.completionNotes ?? '';
      if (notes.contains('Photo evidence:')) {
        final parts = notes.split('Photo evidence:');
        if (parts.length > 1) {
          photoUrl = parts[1].trim();
        }
      }
    }
    
    // If photoUrl is a path (not a full URL), convert it to a public URL
    if (photoUrl != null && !photoUrl.startsWith('http')) {
      try {
        final publicUrl = _supabase.storage
            .from('task-completion-photos')
            .getPublicUrl(photoUrl);
        return publicUrl;
      } catch (e) {
        print('Error getting public URL: $e');
        return photoUrl; // Return original if conversion fails
      }
    }
    
    return photoUrl;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppTheme.successGreen,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Completed',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                          ),
                        ),
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Verification Type
                          _buildInfoCard(
                            'Verification Type',
                            _getVerificationType(),
                            _getVerificationType() == 'Automatic'
                                ? Icons.verified
                                : Icons.verified_user,
                            _getVerificationType() == 'Automatic'
                                ? AppTheme.successGreen
                                : AppTheme.primaryGreen,
                            isDark,
                          ),
                          const SizedBox(height: 16),
                          
                          // Photo Section
                          if (_getPhotoUrl() != null) ...[
                            _buildPhotoSection(_getPhotoUrl()!, isDark),
                            const SizedBox(height: 16),
                          ],
                          
                          // Staff Rating (show if staff assigned, and allow admin to rate)
                          if (widget.task.assignedStaffName != null && widget.task.assignedStaffId != null) ...[
                            _buildRatingSection(
                              widget.task.assignedStaffName!,
                              widget.task.assignedStaffId!,
                              _staffRating,
                              isDark,
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Task Details
                          _buildTaskDetails(isDark),
                        ],
                      ),
              ),
            ),
            // Close Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      inherit: false,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
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
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String photoUrl, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.photo_camera,
                color: AppTheme.secondaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Completion Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: isDark ? AppTheme.darkGray : Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: isDark ? AppTheme.darkGray : Colors.grey[200],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.dangerRed,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(String staffName, String staffId, double? rating, bool isDark) {
    final user = ref.watch(authProvider).value;
    final isAdmin = user?.isAdmin ?? false;
    final currentRating = rating ?? 0.0;

    return InkWell(
      onTap: isAdmin ? () => _showRatingDialog(staffId, staffName, currentRating) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.warningOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.warningOrange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.star,
                color: AppTheme.warningOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Staff Rating',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(Tap to Rate)',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryGreen,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$staffName',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < currentRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.warningOrange,
                          size: 20,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        currentRating > 0
                            ? '${currentRating.toStringAsFixed(1)}/5.0'
                            : 'Not Rated',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isAdmin)
              const Icon(
                Icons.edit,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(String staffId, String staffName, double currentRating) {
    double selectedRating = currentRating > 0 ? currentRating : 3.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate Staff Member'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    staffName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ref.watch(isDarkModeProvider)
                          ? AppTheme.textGray
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final rating = index + 1.0;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedRating = rating;
                          });
                        },
                        child: Icon(
                          rating <= selectedRating ? Icons.star : Icons.star_border,
                          color: AppTheme.warningOrange,
                          size: 40,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${selectedRating.toStringAsFixed(1)} / 5.0',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ref.watch(isDarkModeProvider)
                          ? AppTheme.textGray
                          : AppTheme.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(inherit: false),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _updateStaffRating(staffId, selectedRating);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rating updated to ${selectedRating.toStringAsFixed(1)}/5'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                      // Reload rating
                      await _loadVerificationData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Save Rating',
                    style: TextStyle(
                      color: Colors.white,
                      inherit: false,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateStaffRating(String staffId, double rating) async {
    try {
      // Try using the SQL function first (if it exists)
      try {
        await _supabase.rpc(
          'update_staff_rating',
          params: {
            'p_staff_id': staffId,
            'p_rating': rating,
          },
        );
      } catch (rpcError) {
        // Fallback to direct update if function doesn't exist
        print('RPC function not available, using direct update: $rpcError');
        await _supabase
            .from('users')
            .update({'rating': rating})
            .eq('id', staffId);
      }
    } catch (e) {
      print('Error updating rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating rating: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Widget _buildTaskDetails(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Completed At', _formatDateTime(widget.task.completedAt), isDark),
          if (widget.task.assignedStaffName != null)
            _buildDetailRow('Completed By', widget.task.assignedStaffName!, isDark),
          if (widget.task.completionNotes != null && !widget.task.completionNotes!.contains('Photo evidence:'))
            _buildDetailRow('Notes', widget.task.completionNotes!, isDark),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

