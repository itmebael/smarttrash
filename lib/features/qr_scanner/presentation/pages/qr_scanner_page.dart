import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';

class QRScannerPage extends ConsumerWidget {
  const QRScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              // TODO: Implement flash toggle
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text(
              'QR Code Scanner',
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

