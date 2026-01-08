import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';

class EnhancedGoogleMapsWidget extends ConsumerStatefulWidget {
  final LatLng center;
  final double zoom;
  final List<TrashcanModel> trashcans;
  final LatLng? selectedLocation;
  final Function(TrashcanModel)? onTrashcanSelected;
  final Function(LatLng)? onMapTapped;
  final Function(LatLng)? onMapLongPress;
  final bool showControls;
  final bool showTraffic;
  final bool showBuildings;

  const EnhancedGoogleMapsWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.trashcans = const [],
    this.selectedLocation,
    this.onTrashcanSelected,
    this.onMapTapped,
    this.onMapLongPress,
    this.showControls = true,
    this.showTraffic = false,
    this.showBuildings = true,
  });

  @override
  ConsumerState<EnhancedGoogleMapsWidget> createState() =>
      _EnhancedGoogleMapsWidgetState();
}

class _EnhancedGoogleMapsWidgetState
    extends ConsumerState<EnhancedGoogleMapsWidget>
    with TickerProviderStateMixin {
  gmaps.GoogleMapController? _mapController;
  gmaps.MapType _currentMapType = gmaps.MapType.satellite;
  bool _isLoading = true;
  bool _showTraffic = false;
  bool _showBuildings = true;
  final bool _showMyLocation = true;
  Set<gmaps.Marker> _markers = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _initializeMap();
  }

  @override
  void didUpdateWidget(EnhancedGoogleMapsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update markers when selectedLocation changes
    if (oldWidget.selectedLocation != widget.selectedLocation ||
        oldWidget.trashcans != widget.trashcans) {
      _updateMarkers();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate initialization time
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _isLoading = false;
    });

    _animationController.forward();
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neutralGray.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Google Maps
            if (_isLoading) _buildLoadingState() else _buildGoogleMap(),

            // Map info overlay with animation
            if (!_isLoading) _buildAnimatedMapInfo(),

            // Enhanced controls
            if (widget.showControls && !_isLoading) _buildEnhancedControls(),

            // Loading overlay
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withOpacity(0.1),
            AppTheme.secondaryBlue.withOpacity(0.1),
            AppTheme.warningOrange.withOpacity(0.05),
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
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    strokeWidth: 4,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Initializing Google Maps...',
                    style: TextStyle(
                      color: AppTheme.darkBlue,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading satellite imagery and markers',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleMap() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: gmaps.GoogleMap(
            onMapCreated: (gmaps.GoogleMapController controller) {
              _mapController = controller;
              _updateMarkers();
            },
            initialCameraPosition: gmaps.CameraPosition(
              target:
                  gmaps.LatLng(widget.center.latitude, widget.center.longitude),
              zoom: widget.zoom,
            ),
            mapType: _currentMapType,
            markers: _markers,
            onTap: (gmaps.LatLng position) {
              widget.onMapTapped
                  ?.call(LatLng(position.latitude, position.longitude));
            },
            onLongPress: (gmaps.LatLng position) {
              widget.onMapLongPress
                  ?.call(LatLng(position.latitude, position.longitude));
            },
            onCameraMove: (gmaps.CameraPosition position) {
              // Handle camera movement
            },
            myLocationEnabled: _showMyLocation,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
            trafficEnabled: _showTraffic,
            buildingsEnabled: _showBuildings,
            indoorViewEnabled: true,
            liteModeEnabled: false,
          ),
        );
      },
    );
  }

  void _updateMarkers() async {
    final markers = <gmaps.Marker>{};
    
    // Add trashcan markers
    for (var trashcan in widget.trashcans) {
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId(trashcan.id),
          position: gmaps.LatLng(
            trashcan.coordinates.latitude,
            trashcan.coordinates.longitude,
          ),
          infoWindow: gmaps.InfoWindow(
            title: '🗑️ ${trashcan.name}',
            snippet:
                'Status: ${_statusDisplay(trashcan.status)}\nFill Level: ${(trashcan.fillLevel * 100).toInt()}%',
          ),
          onTap: () {
            widget.onTrashcanSelected?.call(trashcan);
            _animateToMarker(trashcan);
          },
          icon: await _getTrashcanMarkerIcon(trashcan.status),
        ),
      );
    }
    
    // Add temporary marker for selected location
    if (widget.selectedLocation != null) {
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('selected_location'),
          position: gmaps.LatLng(
            widget.selectedLocation!.latitude,
            widget.selectedLocation!.longitude,
          ),
          infoWindow: const gmaps.InfoWindow(
            title: '📍 Selected Location',
            snippet: 'Tap "Add Bin" to create a trashcan here',
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            gmaps.BitmapDescriptor.hueViolet,
          ),
          alpha: 0.8,
        ),
      );
    }
    
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }
  
  Future<gmaps.BitmapDescriptor> _getTrashcanMarkerIcon(TrashcanStatus status) async {
    // Use colored markers with trashcan-like hues
    switch (status) {
      case TrashcanStatus.empty:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen);
      case TrashcanStatus.half:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueOrange);
      case TrashcanStatus.full:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed);
      case TrashcanStatus.maintenance:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueBlue);
      case TrashcanStatus.offline:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueViolet);
      case TrashcanStatus.alive:
        return gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen);
    }
  }

  void _animateToMarker(TrashcanModel trashcan) {
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(
          target: gmaps.LatLng(
            trashcan.coordinates.latitude,
            trashcan.coordinates.longitude,
          ),
          zoom: 18.0,
        ),
      ),
    );
  }


  String _statusDisplay(TrashcanStatus status) {
    switch (status) {
      case TrashcanStatus.empty:
        return 'EMPTY';
      case TrashcanStatus.half:
        return 'MEDIUM';
      case TrashcanStatus.full:
        return 'FULL';
      case TrashcanStatus.maintenance:
        return 'MAINTENANCE';
      case TrashcanStatus.offline:
        return 'OFFLINE';
      case TrashcanStatus.alive:
        return 'ALIVE';
    }
  }

  Widget _buildAnimatedMapInfo() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Positioned(
          top: 12,
          left: 12,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Google Maps (${_currentMapType == gmaps.MapType.satellite ? 'Satellite' : 'Map'})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.trashcans.length} trashcans',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedControls() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Positioned(
          top: 12,
          right: 12,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                // Map type toggle
                _buildMapTypeControls(),
                const SizedBox(height: 8),
                // Location controls
                _buildLocationControls(),
                const SizedBox(height: 8),
                // Layer controls
                _buildLayerControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTypeControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
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
          _buildMapTypeButton(
            'Hybrid',
            Icons.layers,
            gmaps.MapType.hybrid,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationControls() {
    return Row(
      children: [
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
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: () {
            _mapController?.animateCamera(
              gmaps.CameraUpdate.zoomIn(),
            );
          },
          backgroundColor: Colors.white,
          child: const Icon(Icons.zoom_in, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          onPressed: () {
            _mapController?.animateCamera(
              gmaps.CameraUpdate.zoomOut(),
            );
          },
          backgroundColor: Colors.white,
          child: const Icon(Icons.zoom_out, color: AppTheme.primaryGreen),
        ),
      ],
    );
  }

  Widget _buildLayerControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLayerButton(
            'Traffic',
            Icons.traffic,
            _showTraffic,
            () => setState(() => _showTraffic = !_showTraffic),
          ),
          _buildLayerButton(
            'Buildings',
            Icons.location_city,
            _showBuildings,
            () => setState(() => _showBuildings = !_showBuildings),
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
          borderRadius: BorderRadius.circular(8),
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

  Widget _buildLayerButton(
      String label, IconData icon, bool isEnabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? AppTheme.secondaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isEnabled ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isEnabled ? Colors.white : AppTheme.textSecondary,
                fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      ),
    );
  }
}


