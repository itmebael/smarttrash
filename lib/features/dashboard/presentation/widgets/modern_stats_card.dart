import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ModernStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool? trendUp;

  const ModernStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: EcoGradients.glassGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              if (trend != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (trendUp == true
                            ? AppTheme.successGreen
                            : AppTheme.dangerRed)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp == true
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: trendUp == true
                            ? AppTheme.successGreen
                            : AppTheme.dangerRed,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: trendUp == true
                                  ? AppTheme.successGreen
                                  : AppTheme.dangerRed,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

