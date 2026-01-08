import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../providers/simple_map_provider.dart';
import '../widgets/enhanced_google_maps_widget.dart';
import '../widgets/leaflet_map_widget.dart';
import '../widgets/location_picker_dialog.dart';

class SimpleMapPage extends ConsumerStatefulWidget {
  const SimpleMapPage({super.key});

  @override
  ConsumerState<SimpleMapPage> createState() => _SimpleMapPageState();
}

class _SimpleMapPageState extends ConsumerState<SimpleMapPage> {
  gmaps.GoogleMapController? _mapController;
  gmaps.MapType _currentMapType = gmaps.MapType.satellite;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrashcans();
    });
  }

  Future<void> _loadTrashcans() async {
    try {
      print('🗺️ Starting to load trashcans...');
      await ref.read(simpleMapProvider.notifier).loadTrashcans();
      final count = ref.read(simpleMapProvider).trashcans.length;
      print('✅ Loaded $count trashcans successfully');
      
      if (mounted && count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Loaded $count trashcans'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error loading trashcans: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trashcans: $e'),
            backgroundColor: AppTheme.dangerRed,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _loadTrashcans(),
            ),
          ),
        );
      }
    }
  }

  Widget _buildPlatformMap(
      SimpleMapState mapState, SimpleMapNotifier mapNotifier) {
    // Web: Leaflet map via flutter_map
    if (kIsWeb) {
      return LeafletMapWidget(
        center: mapState.centerPosition,
        zoom: mapState.zoom,
        trashcans: mapNotifier.filteredTrashcans,
        selectedLocation: mapState.selectedLocation,
        onTrashcanSelected: (trashcan) => mapNotifier.selectTrashcan(trashcan),
        onMapTapped: (_) {
          mapNotifier.clearSelection();
          mapNotifier.setSelectedLocation(null);
        },
        onMapLongPress: (position) => _handleMapLongPress(position, mapNotifier),
        showControls: true,
      );
    }

    // Android/iOS: enhanced Google Maps
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return EnhancedGoogleMapsWidget(
        center: mapState.centerPosition,
        zoom: mapState.zoom,
        trashcans: mapNotifier.filteredTrashcans,
        selectedLocation: mapState.selectedLocation,
        onTrashcanSelected: (trashcan) => mapNotifier.selectTrashcan(trashcan),
        onMapTapped: (_) {
          mapNotifier.clearSelection();
          mapNotifier.setSelectedLocation(null);
        },
        onMapLongPress: (position) => _handleMapLongPress(position, mapNotifier),
        showControls: true,
        showTraffic: false,
        showBuildings: true,
      );
    }

    // Windows/macOS/Linux: Leaflet map fallback
    return LeafletMapWidget(
      center: mapState.centerPosition,
      zoom: mapState.zoom,
      trashcans: mapNotifier.filteredTrashcans,
      selectedLocation: mapState.selectedLocation,
      onTrashcanSelected: (trashcan) => mapNotifier.selectTrashcan(trashcan),
      onMapTapped: (_) {
        mapNotifier.clearSelection();
        mapNotifier.setSelectedLocation(null);
      },
      onMapLongPress: (position) => _handleMapLongPress(position, mapNotifier),
      showControls: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(simpleMapProvider);
    final mapNotifier = ref.read(simpleMapProvider.notifier);

    ref.listen(simpleMapProvider, (previous, next) {
      if (_mapController == null) return;
      final prevCenter = previous?.centerPosition;
      final prevZoom = previous?.zoom;
      if (prevCenter != next.centerPosition || prevZoom != next.zoom) {
        _animateToCamera(next.centerPosition, next.zoom);
      }
    });

    // Debug: Map state - Loading: ${mapState.isLoading}, Trashcans: ${mapState.trashcans.length}

    return ResponsiveLayout(
      currentRoute: '/map',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EcoWaste Manager Map'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadTrashcans(),
              tooltip: 'Refresh trashcans',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () =>
                  _showFilterBottomSheet(context, mapNotifier, mapState),
              tooltip: 'Filter trashcans',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Platform-specific online map
            _buildPlatformMap(mapState, mapNotifier),

            // Loading indicator
            if (mapState.isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                ),
              ),

            // Debug info
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _mapDebugLabel(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            // Error message
            if (mapState.error != null)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Online map error: ${mapState.error}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _loadTrashcans(),
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/fallback-map'),
                              icon: const Icon(Icons.list, size: 16),
                              label: const Text('List View'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showLocationInfo(),
                              icon: const Icon(Icons.open_in_new, size: 16),
                              label: const Text('Location Info'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.orange,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // No trashcans message
            if (!mapState.isLoading &&
                mapState.trashcans.isEmpty &&
                mapState.error == null)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No trashcans found. Tap refresh to reload.',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _loadTrashcans(),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

            // Selected trashcan info
            if (mapState.selectedTrashcan != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: _buildTrashcanInfoCard(mapState.selectedTrashcan!),
              ),

            // Additional controls
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    onPressed: () => _showCurrentLocation(mapNotifier),
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location,
                        color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: () => _resetView(mapNotifier),
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.center_focus_strong,
                        color: AppTheme.primaryGreen),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    onPressed: () => _toggleMapType(),
                    backgroundColor: Colors.white,
                    child: Icon(
                      _currentMapType == gmaps.MapType.satellite
                          ? Icons.map
                          : Icons.satellite,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            // Add new bin button
            Positioned(
              bottom: 100,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () => _showAddBinDialog(mapNotifier),
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_location),
                label: const Text('Add Bin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _animateToCamera(LatLng center, double zoom) async {
    // This method is now handled by the UniversalMapWidget
    // Keeping for compatibility but functionality moved to the widget
  }

  void _showLocationInfo() {
    final mapState = ref.read(simpleMapProvider);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('📍 Location Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎓 Samar State University Campus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                  'Latitude: ${mapState.centerPosition.latitude.toStringAsFixed(6)}'),
              Text(
                  'Longitude: ${mapState.centerPosition.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 12),
              const Text(
                'This online map displays within the application and shows all trashcan locations on campus.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.wifi, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Online Mode - Real-time satellite imagery',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrashcanInfoCard(TrashcanModel trashcan) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(trashcan.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(trashcan.status),
                    color: _getStatusColor(trashcan.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trashcan.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              AppTheme.textGray, // Black for better visibility
                        ),
                      ),
                      Text(
                        trashcan.location,
                        style: const TextStyle(
                          color: AppTheme
                              .textSecondary, // Dark gray for secondary text
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.read(simpleMapProvider.notifier).clearSelection(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Status',
                    _statusDisplay(trashcan.status),
                    _getStatusColor(trashcan.status),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Fill Level',
                    '${(trashcan.fillLevel * 100).toInt()}%',
                    _getStatusColor(trashcan.status),
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Last Emptied',
                    _formatDate(trashcan.lastEmptiedAt),
                    AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quick actions: set status and assign
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(simpleMapProvider.notifier)
                        .updateTrashcanStatus(
                            trashcan.id, TrashcanStatus.empty),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Set Empty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(simpleMapProvider.notifier)
                        .updateTrashcanStatus(trashcan.id, TrashcanStatus.half),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Set Medium'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(simpleMapProvider.notifier)
                        .updateTrashcanStatus(trashcan.id, TrashcanStatus.full),
                    icon: const Icon(Icons.warning, size: 16),
                    label: const Text('Set Full'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _promptUltrasonic(trashcan),
                    icon: const Icon(Icons.sensors, size: 18),
                    label: const Text('Update from Ultrasonic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _promptAssignStaff(trashcan),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Assign Staff'),
                  ),
                ),
              ],
            ),
            if (trashcan.assignedStaffName?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned to: ${trashcan.assignedStaffName}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary, // Dark gray for labels
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(
      BuildContext context, SimpleMapNotifier notifier, SimpleMapState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Trashcans',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildFilterItem(
              'Full Trashcans',
              state.showFullTrashcans,
              AppTheme.dangerRed,
              () => notifier.toggleFullTrashcans(),
            ),
            _buildFilterItem(
              'Medium Trashcans',
              state.showHalfTrashcans,
              AppTheme.warningOrange,
              () => notifier.toggleHalfTrashcans(),
            ),
            _buildFilterItem(
              'Empty Trashcans',
              state.showEmptyTrashcans,
              AppTheme.successGreen,
              () => notifier.toggleEmptyTrashcans(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(
      String title, bool isEnabled, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isEnabled ? color : Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
      title: Text(title),
      trailing: Switch(
        value: isEnabled,
        onChanged: (_) => onTap(),
        activeColor: color,
      ),
      onTap: onTap,
    );
  }

  void _showCurrentLocation(SimpleMapNotifier notifier) {
    // For now, center on SSU coordinates
    notifier.setCenterPosition(const LatLng(12.8797, 124.8447));
    notifier.setZoom(18.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centered on SSU campus'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetView(SimpleMapNotifier notifier) {
    notifier.setCenterPosition(const LatLng(12.8797, 124.8447));
    notifier.setZoom(16.0);
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == gmaps.MapType.satellite
          ? gmaps.MapType.normal
          : gmaps.MapType.satellite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_currentMapType == gmaps.MapType.satellite
            ? 'Switched to Satellite View'
            : 'Switched to Normal View'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
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

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
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

  void _promptUltrasonic(TrashcanModel trashcan) {
    final distanceCtrl = TextEditingController();
    final heightCtrl = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update from Ultrasonic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: distanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Measured distance (cm)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: heightCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bin height (cm)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final d = double.tryParse(distanceCtrl.text.trim());
                final h = double.tryParse(heightCtrl.text.trim());
                if (d == null || h == null || h <= 0) return;
                await ref
                    .read(simpleMapProvider.notifier)
                    .updateFromUltrasonic(trashcan.id, d, h);
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _promptAssignStaff(TrashcanModel trashcan) {
    final nameCtrl = TextEditingController(text: trashcan.assignedStaffName);
    final idCtrl = TextEditingController(text: trashcan.assignedStaffId);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Staff'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Staff name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(labelText: 'Staff ID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final id = idCtrl.text.trim();
                if (name.isEmpty || id.isEmpty) return;
                await ref
                    .read(simpleMapProvider.notifier)
                    .assignTrashcanToStaff(trashcan.id, id, name);
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  String _mapDebugLabel() {
    final mapState = ref.watch(simpleMapProvider);
    final trashcanCount = mapState.trashcans.length;
    final filteredCount =
        ref.read(simpleMapProvider.notifier).filteredTrashcans.length;
    final mapTypeName =
        _currentMapType == gmaps.MapType.satellite ? 'Satellite' : 'Normal';

    return 'Google Maps ($mapTypeName) | $trashcanCount trashcans ($filteredCount visible)';
  }

  void _handleMapLongPress(LatLng position, SimpleMapNotifier notifier) {
    // Set the selected location to show a marker
    notifier.setSelectedLocation(position);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('📍 Location selected! Tap "Add Bin" to create a trashcan here.'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'ADD BIN',
          textColor: Colors.white,
          onPressed: () {
            _showAddBinDialog(notifier, preFilledPosition: position);
          },
        ),
      ),
    );
  }

  void _showAddBinDialog(SimpleMapNotifier notifier, {LatLng? preFilledPosition}) {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();
    final deviceIdCtrl = TextEditingController();
    final sensorTypeCtrl = TextEditingController(text: 'Ultrasonic');

    // Pre-fill with provided position or current map center
    final position = preFilledPosition ?? ref.read(simpleMapProvider).centerPosition;
    latCtrl.text = position.latitude.toStringAsFixed(6);
    lngCtrl.text = position.longitude.toStringAsFixed(6);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_location, color: AppTheme.primaryGreen),
              SizedBox(width: 8),
              Text('Add New Trashcan'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bin Name *',
                    hintText: 'e.g., Main Building Bin A',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Location *',
                    hintText: 'e.g., SSU Main Campus',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Latitude *',
                          prefixIcon: Icon(Icons.public),
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: lngCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Longitude *',
                          prefixIcon: Icon(Icons.public),
                        ),
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final selectedLocation = await showLocationPicker(
                      context,
                      initialLocation: position,
                      initialZoom: 17.0,
                    );
                    
                    if (selectedLocation != null && mounted) {
                      latCtrl.text = selectedLocation.latitude.toStringAsFixed(6);
                      lngCtrl.text = selectedLocation.longitude.toStringAsFixed(6);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '✅ Location selected: ${selectedLocation.latitude.toStringAsFixed(4)}, ${selectedLocation.longitude.toStringAsFixed(4)}',
                          ),
                          backgroundColor: AppTheme.successGreen,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.satellite),
                  label: const Text('📍 Select Location on Satellite Map'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deviceIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Device ID (Optional)',
                    hintText: 'e.g., TC-001',
                    prefixIcon: Icon(Icons.device_hub),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sensorTypeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sensor Type (Optional)',
                    hintText: 'e.g., Ultrasonic',
                    prefixIcon: Icon(Icons.sensors),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppTheme.primaryGreen, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Click "Select Location on Map" to choose the exact position using satellite view',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final location = locationCtrl.text.trim();
                final lat = double.tryParse(latCtrl.text.trim());
                final lng = double.tryParse(lngCtrl.text.trim());

                if (name.isEmpty || location.isEmpty || lat == null || lng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Please fill all required fields'),
                      backgroundColor: AppTheme.dangerRed,
                    ),
                  );
                  return;
                }

                final deviceId = deviceIdCtrl.text.trim().isEmpty
                    ? null
                    : deviceIdCtrl.text.trim();
                final sensorType = sensorTypeCtrl.text.trim().isEmpty
                    ? null
                    : sensorTypeCtrl.text.trim();

                Navigator.of(context).pop();

                // Show loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('💾 Saving trashcan to database...'),
                      ],
                    ),
                    duration: Duration(seconds: 5),
                    backgroundColor: AppTheme.secondaryBlue,
                  ),
                );

                print('🗑️ Attempting to add trashcan: $name at ($lat, $lng)');
                
                final trashcanId = await notifier.addNewTrashcan(
                  name: name,
                  location: location,
                  latitude: lat,
                  longitude: lng,
                  deviceId: deviceId,
                  sensorType: sensorType,
                );

                print('🗑️ Add trashcan result: $trashcanId');

                if (!mounted) return;

                if (trashcanId != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('✅ Trashcan "$name" saved to database!'),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.successGreen,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  // Center map on new trashcan
                  notifier.setCenterPosition(LatLng(lat, lng));
                  notifier.setZoom(18.0);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text('❌ Failed to save trashcan to database'),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.dangerRed,
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'RETRY',
                        textColor: Colors.white,
                        onPressed: () => _showAddBinDialog(notifier, preFilledPosition: LatLng(lat, lng)),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save Trashcan to Database'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

