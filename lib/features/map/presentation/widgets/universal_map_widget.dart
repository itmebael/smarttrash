import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';

enum MapProvider { googleMaps, openStreetMap, staticMap, offline }

class UniversalMapWidget extends ConsumerStatefulWidget {
  final LatLng center;
  final double zoom;
  final List<TrashcanModel> trashcans;
  final Function(TrashcanModel)? onTrashcanSelected;
  final Function(LatLng)? onMapTapped;
  final bool showControls;
  final MapProvider preferredProvider;

  const UniversalMapWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.trashcans = const [],
    this.onTrashcanSelected,
    this.onMapTapped,
    this.showControls = true,
    this.preferredProvider = MapProvider.googleMaps,
  });

  @override
  ConsumerState<UniversalMapWidget> createState() => _UniversalMapWidgetState();
}

class _UniversalMapWidgetState extends ConsumerState<UniversalMapWidget> {
  MapProvider _currentProvider = MapProvider.googleMaps;
  bool _isGoogleMapsAvailable = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentProvider = widget.preferredProvider;
    _checkGoogleMapsAvailability();
  }

  Future<void> _checkGoogleMapsAvailability() async {
    try {
      // Try to create a Google Maps controller to check availability
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isGoogleMapsAvailable = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isGoogleMapsAvailable = false;
        _errorMessage = 'Google Maps not available: ${e.toString()}';
        _currentProvider = MapProvider.openStreetMap;
      });
    }
  }

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
            _buildMap(),
            if (widget.showControls) _buildMapControls(),
            if (_errorMessage != null) _buildErrorMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    switch (_currentProvider) {
      case MapProvider.googleMaps:
        return _buildGoogleMap();
      case MapProvider.openStreetMap:
        return _buildOpenStreetMap();
      case MapProvider.staticMap:
        return _buildStaticMap();
      case MapProvider.offline:
        return _buildOfflineMap();
    }
  }

  Widget _buildGoogleMap() {
    if (!_isGoogleMapsAvailable) {
      return _buildFallbackMap();
    }

    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.center.latitude, widget.center.longitude),
        zoom: widget.zoom,
      ),
      onMapCreated: (controller) {
        // Controller is available for future use
      },
      onTap: (position) {
        widget.onMapTapped?.call(LatLng(position.latitude, position.longitude));
      },
      markers: _buildGoogleMarkers(),
      mapType: gmaps.MapType.satellite,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
    );
  }

  Set<gmaps.Marker> _buildGoogleMarkers() {
    return widget.trashcans.map((trashcan) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(trashcan.id),
        position: gmaps.LatLng(
          trashcan.coordinates.latitude,
          trashcan.coordinates.longitude,
        ),
        onTap: () => widget.onTrashcanSelected?.call(trashcan),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          _getGoogleHueForStatus(trashcan.status),
        ),
      );
    }).toSet();
  }

  Widget _buildOpenStreetMap() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // OpenStreetMap iframe
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _buildOSMIframe(),
          ),
          // Overlay markers
          ...widget.trashcans.map((trashcan) => _buildOSMMarker(trashcan)),
        ],
      ),
    );
  }

  Widget _buildOSMIframe() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'OpenStreetMap View',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.trashcans.length} trashcans in view',
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openInExternalMap(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in External Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOSMMarker(TrashcanModel trashcan) {
    // Calculate relative position for overlay marker
    const delta = 0.01;
    final minLon = widget.center.longitude - delta;
    final minLat = widget.center.latitude - delta;
    final maxLon = widget.center.longitude + delta;
    final maxLat = widget.center.latitude + delta;

    final x =
        ((trashcan.coordinates.longitude - minLon) / (maxLon - minLon)) * 100;
    final y =
        ((maxLat - trashcan.coordinates.latitude) / (maxLat - minLat)) * 100;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => widget.onTrashcanSelected?.call(trashcan),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: _getStatusColor(trashcan.status),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(trashcan.status),
            color: Colors.white,
            size: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStaticMap() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Static Map View',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Center: ${widget.center.latitude.toStringAsFixed(4)}, ${widget.center.longitude.toStringAsFixed(4)}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.trashcans.length} trashcans',
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openInExternalMap(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in External Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineMap() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralGray.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.offline_bolt,
              size: 48,
              color: AppTheme.warningOrange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Offline Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Map unavailable offline',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openInExternalMap(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in External Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningOrange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackMap() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Map View',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.trashcans.length} trashcans in area',
              style: const TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _openInExternalMap(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in External Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
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
          // Provider selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButton<MapProvider>(
              value: _currentProvider,
              onChanged: (provider) {
                if (provider != null) {
                  setState(() {
                    _currentProvider = provider;
                  });
                }
              },
              underline: const SizedBox(),
              items: MapProvider.values.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getProviderIcon(provider), size: 16),
                        const SizedBox(width: 4),
                        Text(_getProviderName(provider)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Refresh button
          FloatingActionButton.small(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
              _checkGoogleMapsAvailability();
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.warningOrange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.warningOrange),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              icon: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInExternalMap() async {
    final url =
        'https://www.google.com/maps?q=${widget.center.latitude},${widget.center.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open external map'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  IconData _getProviderIcon(MapProvider provider) {
    switch (provider) {
      case MapProvider.googleMaps:
        return Icons.map;
      case MapProvider.openStreetMap:
        return Icons.public;
      case MapProvider.staticMap:
        return Icons.image;
      case MapProvider.offline:
        return Icons.offline_bolt;
    }
  }

  String _getProviderName(MapProvider provider) {
    switch (provider) {
      case MapProvider.googleMaps:
        return 'Google';
      case MapProvider.openStreetMap:
        return 'OSM';
      case MapProvider.staticMap:
        return 'Static';
      case MapProvider.offline:
        return 'Offline';
    }
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

  double _getGoogleHueForStatus(TrashcanStatus status) {
    switch (status) {
      case TrashcanStatus.empty:
        return gmaps.BitmapDescriptor.hueGreen;
      case TrashcanStatus.half:
        return gmaps.BitmapDescriptor.hueOrange;
      case TrashcanStatus.full:
        return gmaps.BitmapDescriptor.hueRed;
      case TrashcanStatus.maintenance:
        return gmaps.BitmapDescriptor.hueAzure;
      case TrashcanStatus.offline:
        return gmaps.BitmapDescriptor.hueViolet;
      case TrashcanStatus.alive:
        return gmaps.BitmapDescriptor.hueGreen;
    }
  }
}

