import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';

class ImprovedGoogleMapsWidget extends ConsumerStatefulWidget {
  final LatLng center;
  final double zoom;
  final List<TrashcanModel> trashcans;
  final Function(TrashcanModel)? onTrashcanSelected;
  final Function(LatLng)? onMapTapped;
  final bool showControls;

  const ImprovedGoogleMapsWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.trashcans = const [],
    this.onTrashcanSelected,
    this.onMapTapped,
    this.showControls = true,
  });

  @override
  ConsumerState<ImprovedGoogleMapsWidget> createState() =>
      _ImprovedGoogleMapsWidgetState();
}

class _ImprovedGoogleMapsWidgetState
    extends ConsumerState<ImprovedGoogleMapsWidget> {
  gmaps.GoogleMapController? _mapController;
  gmaps.MapType _currentMapType = gmaps.MapType.satellite;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Simulate initialization time
      await Future.delayed(const Duration(milliseconds: 1500));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
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
            // Google Maps or Error State
            if (_isLoading)
              _buildLoadingState()
            else if (_hasError)
              _buildErrorState()
            else
              _buildGoogleMap(),

            // Map info overlay
            if (!_isLoading && !_hasError) _buildMapInfo(),

            if (widget.showControls && !_isLoading && !_hasError)
              _buildMapControls(),
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
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Initializing Google Maps...',
              style: TextStyle(
                color: AppTheme.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'API Key: AIzaSyDBNGDYR2OHsYsiYrK0lNHREbGb2gCxFIs',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3)),
              ),
              child: const Text(
                'Loading map tiles and initializing markers...',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.dangerRed.withOpacity(0.1),
            AppTheme.warningOrange.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.dangerRed,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Google Maps Error',
                style: TextStyle(
                  color: AppTheme.dangerRed,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Failed to load Google Maps. This might be due to:',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Text(
                      '• Invalid API Key',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    Text(
                      '• Network connection issues',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    Text(
                      '• Google Maps service unavailable',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _initializeMap,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openInGoogleMaps(),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open in Browser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      onMapCreated: (gmaps.GoogleMapController controller) {
        _mapController = controller;
        setState(() {
          _isLoading = false;
          _hasError = false;
        });
      },
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(widget.center.latitude, widget.center.longitude),
        zoom: widget.zoom,
      ),
      mapType: _currentMapType,
      markers: _buildMarkers(),
      onTap: (gmaps.LatLng position) {
        widget.onMapTapped?.call(LatLng(position.latitude, position.longitude));
      },
      onCameraMove: (gmaps.CameraPosition position) {
        // Handle camera movement if needed
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // We'll add our own button
      zoomControlsEnabled: false, // We'll add our own controls
      mapToolbarEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      buildingsEnabled: true,
      trafficEnabled: false,
      liteModeEnabled: false,
    );
  }

  Set<gmaps.Marker> _buildMarkers() {
    return widget.trashcans.map((trashcan) {
      return gmaps.Marker(
        markerId: gmaps.MarkerId(trashcan.id),
        position: gmaps.LatLng(
          trashcan.coordinates.latitude,
          trashcan.coordinates.longitude,
        ),
        infoWindow: gmaps.InfoWindow(
          title: trashcan.name,
          snippet:
              'Status: ${trashcan.status.name.toUpperCase()}\nFill Level: ${trashcan.fillLevel}%',
        ),
        onTap: () {
          widget.onTrashcanSelected?.call(trashcan);
        },
        icon: _getMarkerIcon(trashcan.status),
      );
    }).toSet();
  }

  gmaps.BitmapDescriptor _getMarkerIcon(TrashcanStatus status) {
    // Use default markers with different colors
    switch (status) {
      case TrashcanStatus.empty:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen);
      case TrashcanStatus.half:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueOrange);
      case TrashcanStatus.full:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueRed);
      case TrashcanStatus.maintenance:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueBlue);
      case TrashcanStatus.offline:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueViolet);
      case TrashcanStatus.alive:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen);
    }
  }

  Widget _buildMapInfo() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Google Maps (${_currentMapType == gmaps.MapType.satellite ? 'Satellite' : 'Map'}) | ${widget.trashcans.length} trashcans (${widget.trashcans.length} visible)',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
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
          // Location button
          FloatingActionButton.small(
            onPressed: () {
              _mapController?.animateCamera(
                gmaps.CameraUpdate.newCameraPosition(
                  gmaps.CameraPosition(
                    target: gmaps.LatLng(
                        widget.center.latitude, widget.center.longitude),
                    zoom: widget.zoom,
                  ),
                ),
              );
            },
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: AppTheme.primaryGreen),
          ),
          const SizedBox(height: 8),
          // External map button
          FloatingActionButton.small(
            onPressed: () => _openInGoogleMaps(),
            backgroundColor: Colors.white,
            child: const Icon(Icons.open_in_new, color: AppTheme.primaryGreen),
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
        // Map type will be updated when the widget rebuilds
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

  Future<void> _openInGoogleMaps() async {
    final url =
        'https://www.google.com/maps?q=${widget.center.latitude},${widget.center.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

