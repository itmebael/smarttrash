import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/theme/app_theme.dart';

class LocationPickerDialog extends ConsumerStatefulWidget {
  final LatLng? initialLocation;
  final double initialZoom;

  const LocationPickerDialog({
    super.key,
    this.initialLocation,
    this.initialZoom = 17.0,
  });

  @override
  ConsumerState<LocationPickerDialog> createState() =>
      _LocationPickerDialogState();
}

class _LocationPickerDialogState extends ConsumerState<LocationPickerDialog> {
  LatLng? _selectedLocation;
  late LatLng _centerPosition;
  late double _zoom;
  gmaps.GoogleMapController? _googleMapController;
  MapController? _leafletMapController;
  bool _useSatellite = true;

  @override
  void initState() {
    super.initState();
    _centerPosition = widget.initialLocation ??
        const LatLng(12.8797, 124.8447); // SSU default
    _zoom = widget.initialZoom;
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 40 : 60,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Expanded(child: _buildMap()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_location, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Trashcan Location',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap on the map to place the trashcan',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.zero,
          child: kIsWeb || defaultTargetPlatform == TargetPlatform.windows
              ? _buildLeafletMap()
              : _buildGoogleMap(),
        ),
          // Info overlay - Always show to indicate satellite mode
          Positioned(
            top: 16,
            left: 16,
            right: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _useSatellite 
                    ? AppTheme.primaryGreen.withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedLocation != null ? Icons.location_on : Icons.satellite,
                    color: _useSatellite ? Colors.white : AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedLocation != null 
                              ? 'Selected Coordinates' 
                              : '🛰️ Satellite View Active',
                          style: TextStyle(
                            fontSize: 11,
                            color: _useSatellite ? Colors.white70 : AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedLocation != null
                              ? 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                                'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                              : 'Tap anywhere on the map',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _useSatellite ? Colors.white : AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Map controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'toggle_satellite',
                onPressed: () {
                  setState(() {
                    _useSatellite = !_useSatellite;
                  });
                },
                backgroundColor: _useSatellite ? AppTheme.primaryGreen : Colors.white,
                tooltip: _useSatellite ? 'Switch to Map View' : 'Switch to Satellite View',
                child: Icon(
                  _useSatellite ? Icons.satellite : Icons.map,
                  color: _useSatellite ? Colors.white : AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'my_location',
                onPressed: _centerOnLocation,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location,
                    color: AppTheme.primaryGreen),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMap() {
    final markers = <gmaps.Marker>{};

    if (_selectedLocation != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('selected_location'),
          position: gmaps.LatLng(
            _selectedLocation!.latitude,
            _selectedLocation!.longitude,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueGreen,
          ),
          infoWindow: const gmaps.InfoWindow(
            title: '🗑️ New Trashcan Location',
            snippet: 'This is where the trashcan will be placed',
          ),
        ),
      );
    }

    return gmaps.GoogleMap(
      onMapCreated: (controller) {
        _googleMapController = controller;
      },
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(_centerPosition.latitude, _centerPosition.longitude),
        zoom: _zoom,
      ),
      mapType: _useSatellite ? gmaps.MapType.satellite : gmaps.MapType.normal,
      markers: markers,
      onTap: (position) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      buildingsEnabled: true,
    );
  }

  Widget _buildLeafletMap() {
    _leafletMapController ??= MapController();

    final markers = <Marker>[];

    if (_selectedLocation != null) {
      markers.add(
        Marker(
          point: _selectedLocation!,
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.delete,
                size: 50,
                color: AppTheme.successGreen,
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
                    color: AppTheme.successGreen,
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

    return FlutterMap(
      mapController: _leafletMapController,
      options: MapOptions(
        initialCenter: _centerPosition,
        initialZoom: _zoom,
        onTap: (tapPosition, point) {
          setState(() {
            _selectedLocation = point;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate: _useSatellite
              ? 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}'
              : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: _useSatellite ? const [] : const ['a', 'b', 'c'],
          userAgentPackageName: 'com.smarttrash.app',
          maxNativeZoom: 20,
          maxZoom: 22,
          errorTileCallback: (tile, error, stackTrace) {
            print('❌ Tile loading error: $error');
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
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(
            _useSatellite ? Icons.satellite : Icons.map,
            color: AppTheme.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _useSatellite 
                  ? '🛰️ Satellite view active - Tap to place trashcan marker'
                  : '🗺️ Map view - Tap to place trashcan marker',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _selectedLocation == null
                ? null
                : () => Navigator.of(context).pop(_selectedLocation),
            icon: const Icon(Icons.add_location, size: 18),
            label: const Text('Use This Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              disabledBackgroundColor: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _centerOnLocation() {
    if (_selectedLocation != null) {
      if (_googleMapController != null) {
        _googleMapController!.animateCamera(
          gmaps.CameraUpdate.newCameraPosition(
            gmaps.CameraPosition(
              target: gmaps.LatLng(
                _selectedLocation!.latitude,
                _selectedLocation!.longitude,
              ),
              zoom: 18.0,
            ),
          ),
        );
      } else if (_leafletMapController != null) {
        _leafletMapController!.move(_selectedLocation!, 18.0);
      }
    }
  }
}

// Helper function to show the location picker
Future<LatLng?> showLocationPicker(
  BuildContext context, {
  LatLng? initialLocation,
  double initialZoom = 17.0,
}) async {
  return showDialog<LatLng>(
    context: context,
    barrierDismissible: false,
    builder: (context) => LocationPickerDialog(
      initialLocation: initialLocation,
      initialZoom: initialZoom,
    ),
  );
}

