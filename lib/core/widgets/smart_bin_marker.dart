import 'package:flutter/material.dart';
import '../models/smart_bin_model.dart';
import '../theme/app_theme.dart';

class SmartBinMarker extends StatelessWidget {
  final SmartBinModel bin;
  final VoidCallback? onTap;
  final bool showLabel;

  const SmartBinMarker({
    super.key,
    required this.bin,
    this.onTap,
    this.showLabel = false,
  });

  Color _getStatusColor() {
    switch (bin.status) {
      case SmartBinStatus.empty:
        return AppTheme.successGreen;
      case SmartBinStatus.low:
        return const Color(0xFF4CAF50);
      case SmartBinStatus.medium:
        return AppTheme.warningOrange;
      case SmartBinStatus.high:
        return const Color(0xFFFF9800);
      case SmartBinStatus.full:
        return AppTheme.dangerRed;
      case SmartBinStatus.overflow:
        return const Color(0xFF8B0000);
      case SmartBinStatus.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated marker with pulse effect
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.8, end: 1.0),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color,
                        color.withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Fill level indicator
                      ClipOval(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Fill level animation
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: bin.fillPercentage),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Container(
                                    height: 50 * value,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.3),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Trash icon
                      Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 24,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          if (showLabel) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${(bin.fillPercentage * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Bottom sheet widget to show smart bin details
class SmartBinDetailsSheet extends StatelessWidget {
  final SmartBinModel bin;

  const SmartBinDetailsSheet({super.key, required this.bin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status indicator
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getStatusColor(bin.status),
                      _getStatusColor(bin.status).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(bin.status).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bin.name,
                      style: TextStyle(
                        color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          bin.statusEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          bin.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(bin.status),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Fill level progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fill Level',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(bin.fillPercentage * 100).toInt()}%',
                    style: TextStyle(
                      color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: bin.fillPercentage),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 12,
                      backgroundColor: isDark
                          ? AppTheme.borderColor
                          : AppTheme.lightBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(bin.status),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Details grid
          Row(
            children: [
              Expanded(
                child: _DetailCard(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${bin.distanceCm.toStringAsFixed(1)} cm',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailCard(
                  icon: Icons.access_time,
                  label: 'Updated',
                  value: _formatTime(bin.createdAt),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          if (bin.hasLocation) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DetailCard(
                    icon: Icons.location_on,
                    label: 'Latitude',
                    value: bin.latitude!.toStringAsFixed(4),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailCard(
                    icon: Icons.location_on,
                    label: 'Longitude',
                    value: bin.longitude!.toStringAsFixed(4),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Action button
          if (bin.status == SmartBinStatus.full ||
              bin.status == SmartBinStatus.overflow)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Create task to empty bin
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.assignment, color: Colors.white),
                label: const Text('Create Collection Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(SmartBinStatus status) {
    switch (status) {
      case SmartBinStatus.empty:
        return AppTheme.successGreen;
      case SmartBinStatus.low:
        return const Color(0xFF4CAF50);
      case SmartBinStatus.medium:
        return AppTheme.warningOrange;
      case SmartBinStatus.high:
        return const Color(0xFFFF9800);
      case SmartBinStatus.full:
        return AppTheme.dangerRed;
      case SmartBinStatus.overflow:
        return const Color(0xFF8B0000);
      case SmartBinStatus.unknown:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.borderColor.withOpacity(0.2)
            : AppTheme.lightBorder.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.borderColor : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppTheme.primaryGreen : AppTheme.secondaryBlue,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}












