import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trashcan_model.dart';

class DesktopOnlineMapWidget extends ConsumerStatefulWidget {
  final LatLng center;
  final double zoom;
  final List<TrashcanModel> trashcans;
  final Function(TrashcanModel)? onTrashcanSelected;
  final Function(LatLng)? onMapTapped;
  final bool showControls;

  const DesktopOnlineMapWidget({
    super.key,
    required this.center,
    this.zoom = 15.0,
    this.trashcans = const [],
    this.onTrashcanSelected,
    this.onMapTapped,
    this.showControls = true,
  });

  @override
  ConsumerState<DesktopOnlineMapWidget> createState() =>
      _DesktopOnlineMapWidgetState();
}

class _DesktopOnlineMapWidgetState
    extends ConsumerState<DesktopOnlineMapWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _error = 'Failed to load map: ${error.description}';
            });
          },
        ),
      )
      ..loadHtmlString(_generateMapHTML());
  }

  String _generateMapHTML() {
    final markers = widget.trashcans.map((trashcan) {
      final statusColor = _getStatusColor(trashcan.status);

      return '''
        L.marker([$trashcan.coordinates.latitude, $trashcan.coordinates.longitude])
          .addTo(map)
          .bindPopup(`
            <div style="font-family: Arial, sans-serif; padding: 8px;">
              <h3 style="margin: 0 0 8px 0; color: #333;">${trashcan.name}</h3>
              <p style="margin: 4px 0; color: #666;">Status: <span style="color: $statusColor; font-weight: bold;">${trashcan.status.name.toUpperCase()}</span></p>
              <p style="margin: 4px 0; color: #666;">Fill Level: ${(trashcan.fillLevel * 100).toInt()}%</p>
              <p style="margin: 4px 0; color: #666;">Location: ${trashcan.location}</p>
            </div>
          `)
          .openPopup();
      ''';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>EcoWaste Manager Map</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
        body { margin: 0; padding: 0; font-family: Arial, sans-serif; }
        #map { height: 100vh; width: 100%; }
        .leaflet-popup-content { font-family: Arial, sans-serif; }
        .loading { 
            position: absolute; 
            top: 50%; 
            left: 50%; 
            transform: translate(-50%, -50%); 
            background: white; 
            padding: 20px; 
            border-radius: 8px; 
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 1000;
        }
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #4CAF50;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 10px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <div id="loading" class="loading">
        <div class="spinner"></div>
        <div>Loading Online Map...</div>
    </div>

    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        // Initialize map
        const map = L.map('map').setView([$widget.center.latitude, $widget.center.longitude], ${widget.zoom.toInt()});
        
        // Add satellite tile layer (Esri World Imagery)
        L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
            attribution: '© Esri, Maxar, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community',
            maxZoom: 19
        }).addTo(map);
        
        // Add street tile layer as overlay
        const streetLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors',
            maxZoom: 19,
            opacity: 0.7
        });
        
        // Layer control
        const baseMaps = {
            "Satellite": L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
                attribution: '© Esri, Maxar, GeoEye, Earthstar Geographics, CNES/Airbus DS, USDA, USGS, AeroGRID, IGN, and the GIS User Community',
                maxZoom: 19
            }),
            "Street": L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap contributors',
                maxZoom: 19
            })
        };
        
        L.control.layers(baseMaps).addTo(map);
        
        // Add markers for trashcans
        $markers
        
        // Add click handler for map
        map.on('click', function(e) {
            console.log('Map clicked at:', e.latlng.lat, e.latlng.lng);
        });
        
        // Hide loading when map is ready
        map.whenReady(function() {
            document.getElementById('loading').style.display = 'none';
        });
        
        // Add error handling
        map.on('tileerror', function(e) {
            console.error('Tile loading error:', e);
        });
    </script>
</body>
</html>
    ''';
  }

  Color _getStatusColor(TrashcanStatus status) {
    switch (status) {
      case TrashcanStatus.empty:
        return AppTheme.emptyStatus;
      case TrashcanStatus.half:
        return AppTheme.halfStatus;
      case TrashcanStatus.full:
        return AppTheme.fullStatus;
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
        return Icons.check_circle_outline;
      case TrashcanStatus.half:
        return Icons.schedule;
      case TrashcanStatus.full:
        return Icons.warning_amber;
      case TrashcanStatus.maintenance:
        return Icons.build;
      case TrashcanStatus.offline:
        return Icons.cloud_off;
      case TrashcanStatus.alive:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView with online map
        WebViewWidget(controller: _controller),

        // Loading indicator
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),

        // Error message
        if (_error != null)
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initializeWebView();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        // Map info overlay
        Positioned(
          top: 20,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🌐 Online Map - Samar State University',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Trashcans: ${widget.trashcans.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Online Mode',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


