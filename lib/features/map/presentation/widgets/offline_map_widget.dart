import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';

class OfflineMapWidget extends ConsumerStatefulWidget {
  final LatLng center;
  final double zoom;
  final List<TrashcanModel> trashcans;
  final Function(TrashcanModel)? onTrashcanSelected;
  final Function(LatLng)? onMapTapped;
  final bool showControls;

  const OfflineMapWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.trashcans = const [],
    this.onTrashcanSelected,
    this.onMapTapped,
    this.showControls = true,
  });

  @override
  ConsumerState<OfflineMapWidget> createState() => _OfflineMapWidgetState();
}

class _OfflineMapWidgetState extends ConsumerState<OfflineMapWidget> {
  String _currentMapType = 'satellite';

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      height: isMobile
          ? screenHeight - 150 // Mobile: account for app bar
          : screenHeight - 200, // Desktop: account for sidebar
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralGray.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Offline Map Background
            _buildOfflineMap(),

            // Map markers
            ...widget.trashcans.map((trashcan) => _buildMapMarker(trashcan)),

            // Map info overlay
            _buildMapInfo(),

            if (widget.showControls) _buildMapControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineMap() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _currentMapType == 'satellite'
              ? [
                  const Color(0xFF0D4F3C), // Very dark green
                  const Color(0xFF1B5E20), // Dark green
                  const Color(0xFF2E7D32), // Medium dark green
                  const Color(0xFF4CAF50), // Medium green
                  const Color(0xFF66BB6A), // Light green
                  const Color(0xFF81C784), // Lighter green
                  const Color(0xFFA5D6A7), // Very light green
                ]
              : [
                  const Color(0xFFF1F8E9), // Very light green
                  const Color(0xFFE8F5E8), // Light green
                  const Color(0xFFC8E6C9), // Medium light green
                  const Color(0xFFA5D6A7), // Medium green
                  const Color(0xFF81C784), // Darker green
                  const Color(0xFF66BB6A), // Dark green
                  const Color(0xFF4CAF50), // Very dark green
                ],
        ),
      ),
      child: CustomPaint(
        painter: OfflineMapPainter(),
        child: Container(
          // Add offline indicator
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '🗺️ Offline Map - Samar State University',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapMarker(TrashcanModel trashcan) {
    // Calculate position on the map (simplified)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Simple positioning calculation
    final x =
        (trashcan.coordinates.longitude - widget.center.longitude) * 1000 +
            screenWidth / 2;
    final y = (widget.center.latitude - trashcan.coordinates.latitude) * 1000 +
        screenHeight / 2;

    return Positioned(
      left: x.clamp(0.0, screenWidth - 40),
      top: y.clamp(0.0, screenHeight - 40),
      child: GestureDetector(
        onTap: () => widget.onTrashcanSelected?.call(trashcan),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatusColor(trashcan.status),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(trashcan.status),
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMapInfo() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _currentMapType == 'satellite' ? Icons.satellite : Icons.map,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentMapType == 'satellite'
                      ? '🛰️ Satellite View'
                      : '🗺️ Street Map',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '📍 ${widget.trashcans.length} trashcans visible',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '🎓 Samar State University Campus',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
            Text(
              '📍 ${widget.center.latitude.toStringAsFixed(4)}, ${widget.center.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '📡 Offline Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 8,
      right: 8,
      child: Column(
        children: [
          // Map type toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapTypeButton(
                  '🛰️ Satellite',
                  Icons.satellite,
                  'satellite',
                ),
                _buildMapTypeButton(
                  '🗺️ Map',
                  Icons.map,
                  'map',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Location button
          FloatingActionButton.small(
            onPressed: () {
              // Center map on current location
              setState(() {
                // This would center the map on user's location
              });
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 8),
          // Refresh button
          FloatingActionButton.small(
            onPressed: () {
              // Refresh map data
              setState(() {
                // This would refresh the map
              });
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeButton(String label, IconData icon, String mapType) {
    final isSelected = _currentMapType == mapType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMapType = mapType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TrashcanStatus status) {
    switch (status) {
      case TrashcanStatus.empty:
        return AppTheme.successGreen;
      case TrashcanStatus.half:
        return AppTheme.warningOrange;
      case TrashcanStatus.full:
        return AppTheme.dangerRed;
      case TrashcanStatus.maintenance:
        return AppTheme.neutralGray;
      case TrashcanStatus.offline:
        return AppTheme.neutralGray;
      case TrashcanStatus.alive:
        return AppTheme.successGreen;
    }
  }

  IconData _getStatusIcon(TrashcanStatus status) {
    switch (status) {
      case TrashcanStatus.empty:
        return Icons.check_circle;
      case TrashcanStatus.half:
        return Icons.schedule;
      case TrashcanStatus.full:
        return Icons.warning;
      case TrashcanStatus.maintenance:
        return Icons.build;
      case TrashcanStatus.offline:
        return Icons.cloud_off;
      case TrashcanStatus.alive:
        return Icons.check_circle;
    }
  }
}

class OfflineMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5;

    // Draw grid lines
    const gridSize = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Add some map-like details
    final detailPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Draw some diagonal lines for texture
    for (double i = 0; i < size.width + size.height; i += 80) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(0, i),
        detailPaint,
      );
    }

    // Add some random dots for map texture
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 100.0) % size.width;
      final y = (i * 150.0) % size.height;
      canvas.drawCircle(Offset(x, y), 2.0, dotPaint);
    }

    // Add some building-like shapes for campus
    final buildingPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw some rectangular shapes to represent buildings
    final buildings = [
      Rect.fromLTWH(size.width * 0.3, size.height * 0.2, 40, 30),
      Rect.fromLTWH(size.width * 0.6, size.height * 0.3, 35, 25),
      Rect.fromLTWH(size.width * 0.2, size.height * 0.6, 45, 35),
      Rect.fromLTWH(size.width * 0.7, size.height * 0.5, 30, 40),
    ];

    for (final building in buildings) {
      canvas.drawRect(building, buildingPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

