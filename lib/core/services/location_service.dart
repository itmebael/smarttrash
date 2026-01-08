// Temporarily disabled due to Windows build issues with geolocator
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class LocationService {
  // static Position? _currentPosition;
  // static bool _isLocationEnabled = false;

  static Future<void> initialize() async {
    print('LocationService temporarily disabled due to Windows build issues');
    // await _checkLocationPermission();
    // await _checkLocationService();
  }

  // static Future<bool> _checkLocationPermission() async {
  //   final status = await Permission.location.request();
  //   return status.isGranted;
  // }

  // static Future<bool> _checkLocationService() async {
  //   _isLocationEnabled = await Geolocator.isLocationServiceEnabled();
  //   return _isLocationEnabled;
  // }

  static Future<dynamic> getCurrentPosition() async {
    print('LocationService temporarily disabled - returning null position');
    return null;
    // try {
    //   if (!await _checkLocationPermission()) {
    //     throw Exception('Location permission denied');
    //   }

    //   if (!await _checkLocationService()) {
    //     throw Exception('Location service is disabled');
    //   }

    //   _currentPosition = await Geolocator.getCurrentPosition(
    //     desiredAccuracy: LocationAccuracy.high,
    //     timeLimit: const Duration(seconds: 10),
    //   );

    //   return _currentPosition;
    // } catch (e) {
    //   print('Error getting current position: $e');
    //   return null;
    // }
  }

  static Future<dynamic> getLastKnownPosition() async {
    print('LocationService temporarily disabled - returning null position');
    return null;
    // try {
    //   return await Geolocator.getLastKnownPosition();
    // } catch (e) {
    //   print('Error getting last known position: $e');
    //   return null;
    // }
  }

  static Future<bool> checkLocationEnabled() async {
    print('LocationService temporarily disabled - returning false');
    return false;
    // return await Geolocator.isLocationServiceEnabled();
  }

  static Future<bool> hasLocationPermission() async {
    print('LocationService temporarily disabled - returning false');
    return false;
    // final status = await Permission.location.status;
    // return status.isGranted;
  }

  static Future<dynamic> getLocationPermissionStatus() async {
    print('LocationService temporarily disabled - returning denied');
    return null;
    // return await Geolocator.checkPermission();
  }

  static Future<dynamic> requestLocationPermission() async {
    print('LocationService temporarily disabled - returning denied');
    return null;
    // return await Geolocator.requestPermission();
  }

  static Future<bool> openLocationSettings() async {
    print('LocationService temporarily disabled - returning false');
    return false;
    // return await Geolocator.openLocationSettings();
  }

  static Future<bool> openAppSettings() async {
    print('LocationService temporarily disabled - returning false');
    return false;
    // return await Geolocator.openAppSettings();
  }

  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Simple distance calculation without geolocator
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1Rad = startLatitude * (3.14159265359 / 180);
    final double lat2Rad = endLatitude * (3.14159265359 / 180);
    final double deltaLatRad =
        (endLatitude - startLatitude) * (3.14159265359 / 180);
    final double deltaLngRad =
        (endLongitude - startLongitude) * (3.14159265359 / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static Future<Stream<dynamic>> getPositionStream() async {
    print('LocationService temporarily disabled - returning empty stream');
    return const Stream.empty();
    // return Geolocator.getPositionStream(
    //   locationSettings: const LocationSettings(
    //     accuracy: LocationAccuracy.high,
    //     distanceFilter: 10, // Update every 10 meters
    //   ),
    // );
  }

  // Helper method to get distance in a readable format
  static String getDistanceText(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  // Helper method to check if location is within campus bounds
  static bool isWithinCampusBounds(
    double latitude,
    double longitude, {
    double campusCenterLat = 12.8797, // Samar State University coordinates
    double campusCenterLng = 124.8447,
    double radiusInMeters = 1000, // 1km radius
  }) {
    final distance = calculateDistance(
      campusCenterLat,
      campusCenterLng,
      latitude,
      longitude,
    );
    return distance <= radiusInMeters;
  }

  static dynamic get currentPosition => null; // _currentPosition;
  static bool get isLocationEnabled => false; // _isLocationEnabled;
}

