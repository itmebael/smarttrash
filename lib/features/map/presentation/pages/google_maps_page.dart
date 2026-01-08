import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../providers/simple_map_provider.dart';
import '../widgets/enhanced_google_maps_widget.dart';

class GoogleMapsPage extends ConsumerStatefulWidget {
  const GoogleMapsPage({super.key});

  @override
  ConsumerState<GoogleMapsPage> createState() => _GoogleMapsPageState();
}

class _GoogleMapsPageState extends ConsumerState<GoogleMapsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrashcans();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTrashcans() async {
    try {
      await ref.read(simpleMapProvider.notifier).loadTrashcans();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load trashcans: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(simpleMapProvider);
    final mapNotifier = ref.read(simpleMapProvider.notifier);

    return ResponsiveLayout(
      currentRoute: '/map',
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // Enhanced Google Maps
            _buildGoogleMaps(mapState, mapNotifier),

            // Loading indicator
            if (mapState.isLoading) _buildLoadingOverlay(),

            // Map controls
            _buildMapControls(),

            // Selected trashcan info
            if (mapState.selectedTrashcan != null)
              _buildTrashcanInfoCard(mapState.selectedTrashcan!),

            // Error message
            if (mapState.error != null) _buildErrorMessage(mapState.error!),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Google Maps - EcoWaste Manager'),
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
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
          onPressed: () => _showFilterBottomSheet(),
          tooltip: 'Filter trashcans',
        ),
      ],
    );
  }

  Widget _buildGoogleMaps(
      SimpleMapState mapState, SimpleMapNotifier mapNotifier) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: EnhancedGoogleMapsWidget(
            center: mapState.centerPosition,
            zoom: mapState.zoom,
            trashcans: mapNotifier.filteredTrashcans,
            onTrashcanSelected: (trashcan) =>
                mapNotifier.selectTrashcan(trashcan),
            onMapTapped: (_) => mapNotifier.clearSelection(),
            showControls: true,
            showTraffic: false,
            showBuildings: true,
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'Loading Google Maps...',
                style: TextStyle(
                  color: AppTheme.darkBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Initializing satellite imagery and markers',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: () => _showCurrentLocation(),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location,
                      color: AppTheme.primaryGreen),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  onPressed: () => _resetView(),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.center_focus_strong,
                      color: AppTheme.primaryGreen),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrashcanInfoCard(TrashcanModel trashcan) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getStatusColor(trashcan.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getStatusIcon(trashcan.status),
                            color: _getStatusColor(trashcan.status),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trashcan.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.textGray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trashcan.location,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => ref
                              .read(simpleMapProvider.notifier)
                              .clearSelection(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateTrashcanStatus(
                                trashcan.id, TrashcanStatus.empty),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Set Empty'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateTrashcanStatus(
                                trashcan.id, TrashcanStatus.half),
                            icon: const Icon(Icons.schedule, size: 18),
                            label: const Text('Set Medium'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.warningOrange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _updateTrashcanStatus(
                                trashcan.id, TrashcanStatus.full),
                            icon: const Icon(Icons.warning, size: 18),
                            label: const Text('Set Full'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dangerRed,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(String error) {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange, width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Map error: $error',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _loadTrashcans(),
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
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
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showCurrentLocation() {
    ref
        .read(simpleMapProvider.notifier)
        .setCenterPosition(const LatLng(12.8797, 124.8447));
    ref.read(simpleMapProvider.notifier).setZoom(18.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centered on SSU campus'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetView() {
    ref
        .read(simpleMapProvider.notifier)
        .setCenterPosition(const LatLng(12.8797, 124.8447));
    ref.read(simpleMapProvider.notifier).setZoom(16.0);
  }

  void _updateTrashcanStatus(String trashcanId, TrashcanStatus status) {
    ref
        .read(simpleMapProvider.notifier)
        .updateTrashcanStatus(trashcanId, status);
  }

  void _showFilterBottomSheet() {
    final mapState = ref.read(simpleMapProvider);
    final mapNotifier = ref.read(simpleMapProvider.notifier);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 24),
            _buildFilterItem(
              'Full Trashcans',
              mapState.showFullTrashcans,
              AppTheme.dangerRed,
              () => mapNotifier.toggleFullTrashcans(),
            ),
            _buildFilterItem(
              'Medium Trashcans',
              mapState.showHalfTrashcans,
              AppTheme.warningOrange,
              () => mapNotifier.toggleHalfTrashcans(),
            ),
            _buildFilterItem(
              'Empty Trashcans',
              mapState.showEmptyTrashcans,
              AppTheme.successGreen,
              () => mapNotifier.toggleEmptyTrashcans(),
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
}

