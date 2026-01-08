import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';

class TrashcanStatusOverview extends ConsumerWidget {
  const TrashcanStatusOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock data - replace with actual data from providers
    final trashcanStats = {
      TrashcanStatus.empty: 8,
      TrashcanStatus.half: 8,
      TrashcanStatus.full: 8,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: EcoShadows.light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.delete_outline,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Trashcan Status Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status indicators (excluding maintenance and offline)
          ...TrashcanStatus.values
              .where((status) => 
                  status != TrashcanStatus.maintenance && 
                  status != TrashcanStatus.offline)
              .map((status) {
            final count = trashcanStats[status] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StatusIndicator(
                status: status,
                count: count,
                total: trashcanStats.values.reduce((a, b) => a + b),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: 'Total',
                  value:
                      trashcanStats.values.reduce((a, b) => a + b).toString(),
                  color: AppTheme.darkGreen,
                ),
                _SummaryItem(
                  label: 'Available',
                  value: trashcanStats[TrashcanStatus.empty].toString(),
                  color: AppTheme.successGreen,
                ),
                _SummaryItem(
                  label: 'Full',
                  value: trashcanStats[TrashcanStatus.full].toString(),
                  color: AppTheme.dangerRed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final TrashcanStatus status;
  final int count;
  final int total;

  const _StatusIndicator({
    required this.status,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getStatusColor(status),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getStatusText(status),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.darkGray),
          ),
        ),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppTheme.lightGray,
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(status)),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TrashcanStatus status) {
    switch (status) {
      case TrashcanStatus.empty:
        return AppTheme.emptyStatus;
      case TrashcanStatus.half:
        return AppTheme.halfStatus;
      case TrashcanStatus.full:
        return AppTheme.fullStatus;
      case TrashcanStatus.maintenance:
        return AppTheme.secondaryBlue;
      case TrashcanStatus.offline:
        return AppTheme.neutralGray;
      case TrashcanStatus.alive:
        return AppTheme.successGreen;
    }
  }

  String _getStatusText(TrashcanStatus status) {
    switch (status) {
      case TrashcanStatus.empty:
        return 'Empty';
      case TrashcanStatus.half:
        return 'Half Full';
      case TrashcanStatus.full:
        return 'Full';
      case TrashcanStatus.maintenance:
        return 'Maintenance';
      case TrashcanStatus.offline:
        return 'Offline';
      case TrashcanStatus.alive:
        return 'Alive';
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.neutralGray),
        ),
      ],
    );
  }
}

