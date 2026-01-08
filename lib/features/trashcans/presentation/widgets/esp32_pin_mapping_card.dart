import 'package:flutter/material.dart';

import '../../../../core/models/esp32_hardware_model.dart';
import '../../../../core/theme/app_theme.dart';

class Esp32PinMappingCard extends StatelessWidget {
  final Esp32HardwareMapping mapping;

  const Esp32PinMappingCard({super.key, required this.mapping});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.memory, color: AppTheme.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'ESP32 Pin Mapping',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRow('Ultrasonic TRIG', mapping.ultrasonicTrigGpio),
            _buildRow('Ultrasonic ECHO', mapping.ultrasonicEchoGpio),
            const Divider(),
            _buildRow('GPS TX → RX2', mapping.gpsTxToRx2Gpio),
            _buildRow('GPS RX → TX2', mapping.gpsRxToTx2Gpio),
            const Divider(),
            _buildRow('SIM800L TXD → RX', mapping.sim800lTxdToRxGpio),
            _buildRow('SIM800L RXD → TX', mapping.sim800lRxdToTxGpio),
            const Divider(),
            _buildRowWithChip('Red LED (FULL)', mapping.redLedGpio, Colors.red),
            _buildRowWithChip(
                'Yellow LED (HALF)', mapping.yellowLedGpio, Colors.orange),
            _buildRowWithChip(
                'Green LED (EMPTY)', mapping.greenLedGpio, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, int gpio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.darkGreen),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'GPIO $gpio',
              style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowWithChip(String label, int gpio, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.darkGreen),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'GPIO $gpio',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


