import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/navigation_helper.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement export reports
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text(
              'Reports & Analytics',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This feature will be implemented soon',
              style: TextStyle(color: AppTheme.neutralGray),
            ),
          ],
        ),
      ),
    );
  }
}

