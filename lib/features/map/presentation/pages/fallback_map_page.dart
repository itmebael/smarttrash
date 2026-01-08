import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../providers/simple_map_provider.dart';

class FallbackMapPage extends ConsumerWidget {
  const FallbackMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapState = ref.watch(simpleMapProvider);
    final mapNotifier = ref.read(simpleMapProvider.notifier);

    return ResponsiveLayout(
      currentRoute: '/fallback-map',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Map View'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadTrashcans(ref),
              tooltip: 'Refresh trashcans',
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFf8f9fa),
                Color(0xFFe9ecef),
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map Status Card
                _buildMapStatusCard(context),

                const SizedBox(height: 20),

                // Trashcan List
                _buildTrashcanList(context, mapNotifier.filteredTrashcans),

                const SizedBox(height: 20),

                // External Map Options
                _buildExternalMapOptions(context, mapState.centerPosition),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: AppTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Map Service Unavailable',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBlue,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Interactive map is temporarily unavailable. Use the list view below or open in external map.',
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can still view trashcan locations and details in the list below.',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashcanList(
      BuildContext context, List<TrashcanModel> trashcans) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trashcan Locations',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
        ),
        const SizedBox(height: 16),
        if (trashcans.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 48,
                    color: AppTheme.neutralGray,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No trashcans found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try refreshing or check your connection',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trashcans.length,
            itemBuilder: (context, index) {
              final trashcan = trashcans[index];
              return _buildTrashcanCard(context, trashcan);
            },
          ),
      ],
    );
  }

  Widget _buildTrashcanCard(BuildContext context, TrashcanModel trashcan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _getStatusColor(trashcan.status).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(trashcan.status).withOpacity(0.1),
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
                    fontSize: 16,
                    color: AppTheme.darkBlue,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(trashcan.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trashcan.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(trashcan.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(trashcan.fillLevel * 100).toInt()}% full',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _openTrashcanInMap(trashcan),
            icon: const Icon(Icons.open_in_new),
            color: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildExternalMapOptions(BuildContext context, LatLng center) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open in External Map',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildExternalMapButton(
                context,
                'Google Maps',
                Icons.map,
                AppTheme.primaryGreen,
                () => _openInGoogleMaps(center),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExternalMapButton(
                context,
                'OpenStreetMap',
                Icons.public,
                AppTheme.secondaryBlue,
                () => _openInOpenStreetMap(center),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExternalMapButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadTrashcans(WidgetRef ref) async {
    try {
      await ref.read(simpleMapProvider.notifier).loadTrashcans();
    } catch (e) {
      // Error loading trashcans
    }
  }

  Future<void> _openTrashcanInMap(TrashcanModel trashcan) async {
    final url =
        'https://www.google.com/maps?q=${trashcan.coordinates.latitude},${trashcan.coordinates.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInGoogleMaps(LatLng center) async {
    final url =
        'https://www.google.com/maps?q=${center.latitude},${center.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openInOpenStreetMap(LatLng center) async {
    final url =
        'https://www.openstreetmap.org/?mlat=${center.latitude}&mlon=${center.longitude}&zoom=15';
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
}

