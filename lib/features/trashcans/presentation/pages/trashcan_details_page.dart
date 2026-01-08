import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/esp32_hardware_model.dart';
import '../widgets/esp32_pin_mapping_card.dart';

class TrashcanDetailsPage extends ConsumerWidget {
  final String trashcanId;

  const TrashcanDetailsPage({super.key, required this.trashcanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapping = Esp32HardwareMapping.fromDefaults();

    return Scaffold(
      appBar: AppBar(title: const Text('Trashcan Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.delete_outline,
                  size: 40,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trashcan ID: $trashcanId',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Smart hardware configuration below',
                        style: TextStyle(color: AppTheme.neutralGray),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Esp32PinMappingCard(mapping: mapping),
          ],
        ),
      ),
    );
  }
}

