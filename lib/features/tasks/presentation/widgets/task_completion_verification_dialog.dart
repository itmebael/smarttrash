import 'dart:math' as math;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/trashcan_model.dart';
import '../../../../core/services/task_service.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';

class TaskCompletionVerificationDialog extends ConsumerStatefulWidget {
  final TaskModel task;
  final TrashcanModel? trashcan;

  const TaskCompletionVerificationDialog({
    super.key,
    required this.task,
    this.trashcan,
  });

  @override
  ConsumerState<TaskCompletionVerificationDialog> createState() =>
      _TaskCompletionVerificationDialogState();
}

class _TaskCompletionVerificationDialogState
    extends ConsumerState<TaskCompletionVerificationDialog> {
  bool _isVerifying = false;
  bool _locationCaptured = false;
  double? _currentLatitude;
  double? _currentLongitude;
  double? _distanceFromBin;
  bool _isWithinRange = false;
  bool _manualOverride = false; // Manual verification flag
  String? _errorMessage;
  
  // Photo capture
  File? _capturedPhoto;
  Uint8List? _capturedPhotoBytes; // For web compatibility
  bool _isUploadingPhoto = false;
  String? _photoUrl;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _captureLocation();
    // Initialize map after a short delay to ensure widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.trashcan != null) {
        _mapController.move(widget.trashcan!.coordinates, 16.0);
      }
    });
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      // Try to get actual GPS location
      // Note: LocationService is temporarily disabled, so we'll use a simulated location
      // In production with geolocator enabled, use:
      // final position = await LocationService.getCurrentPosition();
      // _currentLatitude = position.latitude;
      // _currentLongitude = position.longitude;
      
      // Simulate location capture with slight offset from trashcan
      await Future.delayed(const Duration(seconds: 2));
      
      if (widget.trashcan != null) {
        // Simulate GPS location near trashcan (for demo)
        // In production, get actual GPS coordinates
        // Add small random offset to simulate being near the bin
        final random = math.Random();
        final offsetLat = (random.nextDouble() - 0.5) * 0.0005; // ~50 meters
        final offsetLng = (random.nextDouble() - 0.5) * 0.0005;
        
        _currentLatitude = widget.trashcan!.coordinates.latitude + offsetLat;
        _currentLongitude = widget.trashcan!.coordinates.longitude + offsetLng;
        
        // Calculate distance from bin
        _distanceFromBin = _calculateDistance(
          _currentLatitude!,
          _currentLongitude!,
          widget.trashcan!.coordinates.latitude,
          widget.trashcan!.coordinates.longitude,
        );
        
        // Check if within acceptable range (5cm = 0.05 meters)
        _isWithinRange = _distanceFromBin! <= 0.05;
        _locationCaptured = true;
        
        // Haptic feedback when location is captured
        HapticFeedback.mediumImpact();
        
        // If within range, automatically enable completion (success)
        if (_isWithinRange) {
          // Success haptic feedback
          HapticFeedback.heavyImpact();
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location verified! You are within range. You can now complete the task.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.successGreen,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
        
        // Update map to show both locations
        setState(() {});
        
        // Center map to show both trashcan and user location after a short delay
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _currentLatitude != null && _currentLongitude != null && widget.trashcan != null) {
            try {
              final bounds = LatLngBounds(
                LatLng(
                  math.min(widget.trashcan!.coordinates.latitude, _currentLatitude!),
                  math.min(widget.trashcan!.coordinates.longitude, _currentLongitude!),
                ),
                LatLng(
                  math.max(widget.trashcan!.coordinates.latitude, _currentLatitude!),
                  math.max(widget.trashcan!.coordinates.longitude, _currentLongitude!),
                ),
              );
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(50),
                ),
              );
            } catch (e) {
              print('Error centering map: $e');
            }
          }
        });
      } else {
        _errorMessage = 'Trashcan location not available';
      }
    } catch (e) {
      _errorMessage = 'Failed to capture location: $e';
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Haversine formula to calculate distance in meters
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (3.14159265359 / 180);

  Future<void> _completeTask() async {
    // Allow completion if within range OR manual override is enabled
    if (!_locationCaptured && !_manualOverride) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location verification or use manual verification'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    if (!_isWithinRange && !_manualOverride) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You are ${_distanceFromBin!.toStringAsFixed(0)} meters away from the bin. '
            'Please move closer or use manual verification if you are at the correct location.',
          ),
          backgroundColor: AppTheme.warningOrange,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    try {
      setState(() {
        _isVerifying = true;
      });

      final taskService = TaskService();
      String notes = 'Location verified: ${_distanceFromBin!.toStringAsFixed(1)}m from bin';
      if (_photoUrl != null) {
        notes += '\nPhoto evidence: $_photoUrl';
      }
      
      await taskService.updateTaskStatus(
        taskId: widget.task.id,
        status: 'completed',
        completionNotes: notes,
      );

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task completed successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing task: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (fixed)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify Bin Position',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            ),
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please verify that the bin is back in the correct position. '
                              'This ensures the bin is properly placed at its designated location.',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Map - Show assigned trashcan and user GPS location
                    if (widget.trashcan != null)
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark 
                                ? AppTheme.borderColor 
                                : AppTheme.lightBorder,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            SizedBox.expand(
                              child: FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: widget.trashcan!.coordinates,
                                  initialZoom: 16.0,
                                  minZoom: 10.0,
                                  maxZoom: 20.0,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.all,
                                  ),
                                ),
                                children: [
                                  // Map tiles (same as admin dashboard)
                                  TileLayer(
                                    urlTemplate:
                                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                                    userAgentPackageName: 'com.example.ecowaste_manager_app',
                                    errorTileCallback: (tile, error, stackTrace) {
                                      print('Tile loading error: $error');
                                    },
                                    maxZoom: 18,
                                    minZoom: 1,
                                  ),
                                // Markers layer
                                MarkerLayer(
                                  markers: [
                                    // Trashcan marker
                                    Marker(
                                      key: ValueKey('trashcan_${widget.trashcan!.id}'),
                                      point: widget.trashcan!.coordinates,
                                      width: 50,
                                      height: 80,
                                      child: _buildTrashcanMarker(widget.trashcan!),
                                    ),
                                    // User GPS location marker - if location captured
                                    if (_locationCaptured && _currentLatitude != null && _currentLongitude != null)
                                      Marker(
                                        key: ValueKey('user_location_${_currentLatitude}_${_currentLongitude}'),
                                        point: LatLng(_currentLatitude!, _currentLongitude!),
                                        width: 50,
                                        height: 80,
                                        child: _buildUserLocationMarker(),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            ),
                            // Center button to fit both markers
                            if (_locationCaptured && _currentLatitude != null && _currentLongitude != null)
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: FloatingActionButton.small(
                                  onPressed: () {
                                    try {
                                      final bounds = LatLngBounds(
                                        LatLng(
                                          math.min(widget.trashcan!.coordinates.latitude, _currentLatitude!),
                                          math.min(widget.trashcan!.coordinates.longitude, _currentLongitude!),
                                        ),
                                        LatLng(
                                          math.max(widget.trashcan!.coordinates.latitude, _currentLatitude!),
                                          math.max(widget.trashcan!.coordinates.longitude, _currentLongitude!),
                                        ),
                                      );
                                      _mapController.fitCamera(
                                        CameraFit.bounds(
                                          bounds: bounds,
                                          padding: const EdgeInsets.all(50),
                                        ),
                                      );
                                    } catch (e) {
                                      print('Error centering map: $e');
                                    }
                                  },
                                  backgroundColor: AppTheme.primaryGreen,
                                  child: const Icon(Icons.my_location, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkGray : AppTheme.lightSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 48,
                                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Trashcan location not available',
                                style: TextStyle(
                                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    
                    // Location Status
                    if (_isVerifying)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Capturing your location...',
                              style: TextStyle(
                                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isWithinRange
                              ? AppTheme.successGreen.withOpacity(0.1)
                              : AppTheme.warningOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isWithinRange
                                ? AppTheme.successGreen
                                : AppTheme.warningOrange,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isWithinRange ? Icons.check_circle : Icons.warning,
                              color: _isWithinRange
                                  ? AppTheme.successGreen
                                  : AppTheme.warningOrange,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isWithinRange
                                        ? 'Location Verified ✓ (Automatic)'
                                        : 'Too Far From Bin',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isWithinRange
                                          ? AppTheme.successGreen
                                          : AppTheme.warningOrange,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isWithinRange
                                        ? 'You are within 5cm range! Task can be completed automatically.'
                                        : 'Distance from bin: ${(_distanceFromBin! * 100).toStringAsFixed(1)} cm (Range: 5cm)',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Manual verification button (if not within range)
                            if (!_isWithinRange && _locationCaptured)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _manualOverride = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.white),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Manual verification enabled. You can now complete the task.',
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: AppTheme.successGreen,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.verified_user, size: 16),
                                  label: const Text(
                                    'Manual Verify',
                                    style: TextStyle(
                                      inherit: false,
                                      color: AppTheme.primaryGreen,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryGreen,
                                    side: const BorderSide(color: AppTheme.primaryGreen),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // Manual override status
                    if (_manualOverride && !_isVerifying)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryGreen,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user,
                              color: AppTheme.primaryGreen,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manually Verified ✓',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'You have manually confirmed the bin is in the correct position.',
                                    style: TextStyle(
                                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _manualOverride = false;
                                });
                              },
                              color: AppTheme.primaryGreen,
                            ),
                          ],
                        ),
                      ),
                    // Error message
                    if (_errorMessage != null && !_isVerifying && !_manualOverride)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.dangerRed,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: AppTheme.dangerRed,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    
                    // Photo Capture Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkGray : AppTheme.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark 
                              ? AppTheme.borderColor 
                              : AppTheme.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: AppTheme.primaryGreen,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Capture Bin Photo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Take a photo of the bin to verify its position. This photo will be saved as evidence.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_capturedPhoto != null)
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryGreen,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb && _capturedPhotoBytes != null
                                    ? Image.memory(
                                        _capturedPhotoBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : _capturedPhoto != null
                                        ? Image.file(
                                            _capturedPhoto!,
                                            fit: BoxFit.cover,
                                          )
                                        : _photoUrl != null
                                            ? Image.network(
                                                _photoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(Icons.error),
                                                  );
                                                },
                                              )
                                            : const SizedBox(),
                              ),
                            )
                          else
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark ? AppTheme.lightGray : AppTheme.lightBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark 
                                      ? AppTheme.borderColor 
                                      : AppTheme.lightBorder,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      size: 48,
                                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No photo captured',
                                      style: TextStyle(
                                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUploadingPhoto ? null : _capturePhoto,
                              icon: _isUploadingPhoto
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt),
                              label: Text(
                                _isUploadingPhoto
                                    ? 'Uploading...'
                                    : _capturedPhoto == null
                                        ? 'Capture Photo'
                                        : 'Retake Photo',
                                style: const TextStyle(
                                  inherit: false,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (_photoUrl != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppTheme.successGreen,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Photo saved successfully',
                                      style: TextStyle(
                                        color: AppTheme.successGreen,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Action Buttons (fixed at bottom)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isVerifying ? null : () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(inherit: false),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isVerifying || (!_locationCaptured && !_manualOverride) || (!_isWithinRange && !_manualOverride)
                          ? null
                          : _completeTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                        : const Text(
                            'Complete Task',
                            style: TextStyle(
                              inherit: false,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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

  Future<void> _capturePhoto() async {
    try {
      XFile? photo;
      
      if (kIsWeb) {
        // On web, use gallery source as camera requires delegates
        // Users can select a file from their device
        photo = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
        );
      } else {
        // On mobile, try camera first, fallback to gallery
        try {
          photo = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            maxWidth: 1920,
          );
        } catch (cameraError) {
          // If camera fails, fallback to gallery
          photo = await _picker.pickImage(
            source: ImageSource.gallery,
            imageQuality: 85,
            maxWidth: 1920,
          );
        }
      }

      if (photo != null) {
        // Haptic feedback when photo is captured
        if (!kIsWeb) {
          HapticFeedback.mediumImpact();
        }
        
        if (kIsWeb) {
          // For web, read bytes instead of File
          final bytes = await photo.readAsBytes();
          setState(() {
            _capturedPhotoBytes = bytes;
            _isUploadingPhoto = true;
          });
          // Upload to Supabase storage (web)
          await _uploadPhotoBytes(bytes, photo.name);
        } else {
          // On mobile, path is always available
          final photoPath = photo.path;
          setState(() {
            _capturedPhoto = File(photoPath);
            _isUploadingPhoto = true;
          });
          // Upload to Supabase storage (mobile)
          await _uploadPhoto(photoPath);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: ${e.toString()}'),
            backgroundColor: AppTheme.dangerRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Future<void> _uploadPhotoBytes(Uint8List bytes, String originalFileName) async {
    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Generate file path: {staff_id}/{task_id}/{timestamp}.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}/${widget.task.id}/$timestamp.jpg';

      // Upload to Supabase storage (web) - convert bytes to file-like object
      await _supabase.storage
          .from('task-completion-photos')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final urlResponse = _supabase.storage
          .from('task-completion-photos')
          .getPublicUrl(fileName);
      
      setState(() {
        _photoUrl = urlResponse;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      print('❌ Upload error details: $e');
      if (mounted) {
        String errorMessage = 'Error uploading photo';
        if (e.toString().contains('403')) {
          errorMessage = 'Permission denied. Please check storage bucket policies.';
        } else if (e.toString().contains('413')) {
          errorMessage = 'File too large. Maximum size is 10MB.';
        } else {
          errorMessage = 'Error uploading photo: ${e.toString()}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.dangerRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  Widget _buildTrashcanMarker(TrashcanModel trashcan) {
    final statusColor = _getTrashcanStatusColor(trashcan.status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.delete,
            color: Colors.white,
            size: 20,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            trashcan.name,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getTrashcanStatusColor(TrashcanStatus status) {
    switch (status) {
      case TrashcanStatus.empty:
        return AppTheme.successGreen;
      case TrashcanStatus.half:
        return AppTheme.warningOrange;
      case TrashcanStatus.full:
        return AppTheme.dangerRed;
      case TrashcanStatus.maintenance:
        return AppTheme.secondaryBlue;
      case TrashcanStatus.offline:
        return AppTheme.neutralGray;
      case TrashcanStatus.alive:
        return AppTheme.successGreen;
    }
  }

  Widget _buildUserLocationMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location,
            color: Colors.white,
            size: 20,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            'You',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadPhoto(String photoPath) async {
    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Generate file path: {staff_id}/{task_id}/{timestamp}.jpg
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}/${widget.task.id}/$timestamp.jpg';
      final file = File(photoPath);

      // Upload to Supabase storage
      await _supabase.storage
          .from('task-completion-photos')
          .upload(fileName, file);

      // Get public URL
      final urlResponse = _supabase.storage
          .from('task-completion-photos')
          .getPublicUrl(fileName);

      setState(() {
        _photoUrl = urlResponse;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      print('❌ Upload error details: $e');
      String errorMessage = 'Error uploading photo';
      if (e.toString().contains('403')) {
        errorMessage = 'Permission denied. Please check storage bucket policies.';
      } else if (e.toString().contains('413')) {
        errorMessage = 'File too large. Maximum size is 10MB.';
      } else {
        errorMessage = 'Error uploading photo: ${e.toString()}';
      }
      setState(() {
        _isUploadingPhoto = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.dangerRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

