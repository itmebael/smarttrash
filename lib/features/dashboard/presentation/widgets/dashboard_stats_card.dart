import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const DashboardStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const Spacer(),
                    if (onTap != null)
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.neutralGray,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutralGray),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.neutralGray,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final String progressText;
  final Color progressColor;
  final IconData icon;
  final VoidCallback? onTap;

  const DashboardProgressCard({
    super.key,
    required this.title,
    required this.progress,
    required this.progressText,
    required this.progressColor,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: progressColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkGreen,
                                ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.neutralGray,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppTheme.lightGray,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  progressText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.neutralGray),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

