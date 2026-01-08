import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';

class LeafletMapWidget extends ConsumerStatefulWidget {
  final ll.LatLng center;
  final double zoom;
  final List<TrashcanModel> trashcans;
  final ll.LatLng? selectedLocation;
  final Function(TrashcanModel)? onTrashcanSelected;
  final Function(ll.LatLng)? onMapTapped;
  final Function(ll.LatLng)? onMapLongPress;
  final bool showControls;

  const LeafletMapWidget({
    super.key,
    required this.center,
    this.zoom = 17.0,
    this.trashcans = const [],
    this.selectedLocation,
    this.onTrashcanSelected,
    this.onMapTapped,
    this.onMapLongPress,
    this.showControls = true,
  });

  @override
  ConsumerState<LeafletMapWidget> createState() => _LeafletMapWidgetState();
}

class _LeafletMapWidgetState extends ConsumerState<LeafletMapWidget> {
  final MapController _controller = MapController();
  bool _useSatellite = true; // Default to satellite view

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: widget.zoom,
              onTap: (tapPosition, point) => widget.onMapTapped
                  ?.call(ll.LatLng(point.latitude, point.longitude)),
              onLongPress: (tapPosition, point) => widget.onMapLongPress
                  ?.call(ll.LatLng(point.latitude, point.longitude)),
            ),
            children: [
              // Satellite imagery tile layer
              TileLayer(
                urlTemplate: _useSatellite
                    ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
                    : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: _useSatellite ? const [] : const ['a', 'b', 'c'],
                userAgentPackageName: 'com.smarttrash.app',
                maxNativeZoom: 20,
                maxZoom: 22,
                errorTileCallback: (tile, error, stackTrace) {
                  // Suppress tile loading errors in console
                  // These are non-critical and occur during rapid navigation
                },
              ),
              // Add labels overlay for satellite view
              if (_useSatellite)
                TileLayer(
                  urlTemplate: 'https://mt1.google.com/vt/lyrs=h&x={x}&y={y}&z={z}',
                  userAgentPackageName: 'com.smarttrash.app',
                  maxNativeZoom: 20,
                  maxZoom: 22,
                  backgroundColor: Colors.transparent,
                ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),
          if (widget.showControls) _buildControls(),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    
    // Add trashcan markers
    for (var t in widget.trashcans) {
      markers.add(
        Marker(
          point: ll.LatLng(t.coordinates.latitude, t.coordinates.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => widget.onTrashcanSelected?.call(t),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.delete,
                  size: 40,
                  color: _statusColor(t.status),
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                Positioned(
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(t.fillLevel * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(t.status),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Add selected location marker
    if (widget.selectedLocation != null) {
      markers.add(
        Marker(
          point: widget.selectedLocation!,
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.add_location_alt,
                size: 50,
                color: Colors.purple.shade600,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.7),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return markers;
  }

  Widget _buildControls() {
    return Positioned(
      top: 8,
      right: 8,
      child: Column(
        children: [
          FloatingActionButton.small(
            heroTag: 'map_type',
            onPressed: () {
              setState(() {
                _useSatellite = !_useSatellite;
              });
            },
            backgroundColor: Colors.white,
            child: Icon(
              _useSatellite ? Icons.map : Icons.satellite,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'my_location',
            onPressed: () {
              _controller.move(widget.center, widget.zoom);
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  Color _statusColor(TrashcanStatus status) {
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
}



