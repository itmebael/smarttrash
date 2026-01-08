import 'package:latlong2/latlong.dart';

enum SmartBinStatus {
  empty,
  low,
  medium,
  high,
  full,
  overflow,
  unknown;

  static SmartBinStatus fromDistance(double distanceCm) {
    // Assuming bin height is 100cm
    // Distance from sensor to trash
    if (distanceCm >= 80) return SmartBinStatus.empty;      // 0-20% full
    if (distanceCm >= 60) return SmartBinStatus.low;        // 20-40% full
    if (distanceCm >= 40) return SmartBinStatus.medium;     // 40-60% full
    if (distanceCm >= 20) return SmartBinStatus.high;       // 60-80% full
    if (distanceCm >= 5) return SmartBinStatus.full;        // 80-95% full
    return SmartBinStatus.overflow;                         // 95-100% full
  }

  static SmartBinStatus fromString(String? status) {
    if (status == null) return SmartBinStatus.unknown;
    try {
      return SmartBinStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == status.toLowerCase(),
        orElse: () => SmartBinStatus.unknown,
      );
    } catch (e) {
      return SmartBinStatus.unknown;
    }
  }
}

class SmartBinModel {
  final int id;
  final double distanceCm;
  final double? latitude;
  final double? longitude;
  final String? statusText;
  final DateTime createdAt;

  const SmartBinModel({
    required this.id,
    required this.distanceCm,
    this.latitude,
    this.longitude,
    this.statusText,
    required this.createdAt,
  });

  // Calculate fill percentage (0.0 to 1.0)
  double get fillPercentage {
    // Assuming bin height is 100cm
    const binHeight = 100.0;
    final fillLevel = binHeight - distanceCm;
    return (fillLevel / binHeight).clamp(0.0, 1.0);
  }

  // Get status based on distance
  SmartBinStatus get status {
    if (statusText != null && statusText!.isNotEmpty) {
      return SmartBinStatus.fromString(statusText);
    }
    return SmartBinStatus.fromDistance(distanceCm);
  }

  // Get coordinates as LatLng
  LatLng? get coordinates {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }

  // Check if has valid location
  bool get hasLocation => latitude != null && longitude != null;

  // Get display name
  String get name => 'SmartBin #$id';

  // Create from Supabase map
  factory SmartBinModel.fromMap(Map<String, dynamic> map) {
    return SmartBinModel(
      id: map['id'] is int ? map['id'] : int.parse(map['id'].toString()),
      distanceCm: map['distance_cm'] is double 
          ? map['distance_cm'] 
          : double.parse(map['distance_cm'].toString()),
      latitude: map['latitude'] != null 
          ? (map['latitude'] is double 
              ? map['latitude'] 
              : double.tryParse(map['latitude'].toString()))
          : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] is double
              ? map['longitude']
              : double.tryParse(map['longitude'].toString()))
          : null,
      statusText: map['status']?.toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
    );
  }

  // Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'distance_cm': distanceCm,
      'latitude': latitude,
      'longitude': longitude,
      'status': statusText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Get status emoji
  String get statusEmoji {
    switch (status) {
      case SmartBinStatus.empty:
        return '✅';
      case SmartBinStatus.low:
        return '🟢';
      case SmartBinStatus.medium:
        return '🟡';
      case SmartBinStatus.high:
        return '🟠';
      case SmartBinStatus.full:
        return '🔴';
      case SmartBinStatus.overflow:
        return '⚠️';
      case SmartBinStatus.unknown:
        return '❓';
    }
  }

  // Get friendly status text
  String get statusLabel {
    return '${status.name.toUpperCase()} (${(fillPercentage * 100).toInt()}%)';
  }

  // Copy with
  SmartBinModel copyWith({
    int? id,
    double? distanceCm,
    double? latitude,
    double? longitude,
    String? statusText,
    DateTime? createdAt,
  }) {
    return SmartBinModel(
      id: id ?? this.id,
      distanceCm: distanceCm ?? this.distanceCm,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      statusText: statusText ?? this.statusText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}












