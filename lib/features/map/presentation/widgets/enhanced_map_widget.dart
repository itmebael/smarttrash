import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';

class EnhancedMapWidget extends ConsumerStatefulWidget {
  final LatLng center;
  final double zoom;
  final List<TrashcanModel> trashcans;
  final Function(TrashcanModel)? onTrashcanSelected;
  final Function(LatLng)? onMapTapped;
  final bool showControls;

  const EnhancedMapWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.trashcans = const [],
    this.onTrashcanSelected,
    this.onMapTapped,
    this.showControls = true,
  });

  @override
  ConsumerState<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends ConsumerState<EnhancedMapWidget> {
  // gmaps.GoogleMapController? _mapController; // Available for future use
  bool _isGoogleMapsAvailable = true;
  String? _errorMessage;
  gmaps.MapType _currentMapType = gmaps.MapType.satellite;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkGoogleMapsAvailability();
  }

  Future<void> _checkGoogleMapsAvailability() async {
    try {
      // Simulate a delay to check if Google Maps loads
      await Future.delayed(const Duration(seconds: 3));

      // If we get here without error, Google Maps is available
      if (mounted) {
        setState(() {
          _isGoogleMapsAvailable = true;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGoogleMapsAvailable = false;
          _isLoading = false;
          _errorMessage = 'Google Maps not available: ${e.toString()}';
        });
      }
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
            if (_isLoading)
              _buildLoadingState()
            else if (_isGoogleMapsAvailable)
              _buildGoogleMap()
            else
              _buildFallbackMap(),
            if (widget.showControls && !_isLoading) _buildMapControls(),
            if (_errorMessage != null) _buildErrorMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.1),
            AppTheme.secondaryBlue.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading Map...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Initializing map services',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.center.latitude, widget.center.longitude),
        zoom: widget.zoom,
      ),
      onMapCreated: (controller) {
        // _mapController = controller; // Available for future use
        _isLoading = false;
      },
      onTap: (position) {
        widget.onMapTapped?.call(LatLng(position.latitude, position.longitude));
      },
      markers: _buildGoogleMarkers(),
      mapType: _currentMapType,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: false,
      liteModeEnabled: false,
      onCameraMove: (position) {
        // Handle camera movement if needed
      },
      onCameraIdle: () {
        // Handle camera idle if needed
      },
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
        infoWindow: gmaps.InfoWindow(
          title: trashcan.name,
          snippet:
              '${trashcan.status.name.toUpperCase()} - ${(trashcan.fillLevel * 100).toInt()}% full',
        ),
      );
    }).toSet();
  }

  Widget _buildFallbackMap() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.1),
            AppTheme.secondaryBlue.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: AppTheme.warningOrange,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Interactive Map Unavailable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Google Maps service is not available.\nUsing alternative view.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _buildTrashcanList(),
              const SizedBox(height: 20),
              _buildExternalMapButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrashcanList() {
    if (widget.trashcans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No trashcans found in this area',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Trashcans in Area (${widget.trashcans.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.trashcans.length,
              itemBuilder: (context, index) {
                final trashcan = widget.trashcans[index];
                return _buildTrashcanListItem(trashcan);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashcanListItem(TrashcanModel trashcan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getStatusColor(trashcan.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(trashcan.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getStatusColor(trashcan.status),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getStatusIcon(trashcan.status),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trashcan.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.darkBlue,
                  ),
                ),
                Text(
                  '${(trashcan.fillLevel * 100).toInt()}% full',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openTrashcanInExternalMap(trashcan),
            icon: const Icon(Icons.open_in_new, size: 16),
            color: AppTheme.primaryGreen,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExternalMapButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openInGoogleMaps(),
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Google Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openInOpenStreetMap(),
            icon: const Icon(Icons.public, size: 16),
            label: const Text('OpenStreetMap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
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
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapTypeButton(
                  'Satellite',
                  Icons.satellite,
                  gmaps.MapType.satellite,
                ),
                _buildMapTypeButton(
                  'Map',
                  Icons.map,
                  gmaps.MapType.normal,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Refresh button
          FloatingActionButton.small(
            onPressed: () {
              setState(() {
                _isLoading = true;
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

  Widget _buildMapTypeButton(
      String label, IconData icon, gmaps.MapType mapType) {
    final isSelected = _currentMapType == mapType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentMapType = mapType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
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

  Future<void> _openInGoogleMaps() async {
    final url =
        'https://www.google.com/maps?q=${widget.center.latitude},${widget.center.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInOpenStreetMap() async {
    final url =
        'https://www.openstreetmap.org/?mlat=${widget.center.latitude}&mlon=${widget.center.longitude}&zoom=15';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openTrashcanInExternalMap(TrashcanModel trashcan) async {
    final url =
        'https://www.google.com/maps?q=${trashcan.coordinates.latitude},${trashcan.coordinates.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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

