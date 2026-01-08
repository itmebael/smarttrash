import 'package:latlong2/latlong.dart';

enum TrashcanStatus { empty, half, full, maintenance, offline, alive }

class TrashcanModel {
  final String id;
  final String name;
  final String location;
  final String locationName; // Human-readable location name
  final LatLng coordinates;
  final TrashcanStatus status;
  final double fillLevel; // 0.0 to 1.0
  final DateTime lastEmptiedAt;
  final DateTime lastUpdatedAt;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final bool isOnline;
  final String? qrCode;
  final Map<String, dynamic>? sensorData;
  final String? notes;
  final DateTime createdAt;
  final String? deviceId;
  final String? sensorType;
  final int? batteryLevel;
  final bool isActive;

  const TrashcanModel({
    required this.id,
    required this.name,
    required this.location,
    required this.locationName,
    required this.coordinates,
    required this.status,
    required this.fillLevel,
    required this.lastEmptiedAt,
    required this.lastUpdatedAt,
    this.assignedStaffId,
    this.assignedStaffName,
    this.isOnline = true,
    this.qrCode,
    this.sensorData,
    this.notes,
    required this.createdAt,
    this.deviceId,
    this.sensorType,
    this.batteryLevel,
    this.isActive = true,
  });

  factory TrashcanModel.fromMap(Map<String, dynamic> map) {
    return TrashcanModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      locationName: map['locationName'] ?? map['location_name'] ?? map['location'] ?? '',
      coordinates: LatLng(
        map['coordinates']['latitude'] ?? 0.0,
        map['coordinates']['longitude'] ?? 0.0,
      ),
      status: TrashcanStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TrashcanStatus.empty,
      ),
      fillLevel: (map['fillLevel'] ?? 0.0).toDouble(),
      lastEmptiedAt: DateTime.parse(map['lastEmptiedAt']),
      lastUpdatedAt: DateTime.parse(map['lastUpdatedAt']),
      assignedStaffId: map['assignedStaffId'],
      assignedStaffName: map['assignedStaffName'],
      isOnline: map['isOnline'] ?? true,
      qrCode: map['qrCode'],
      sensorData: map['sensorData'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Factory constructor for Supabase data
  factory TrashcanModel.fromSupabaseMap(Map<String, dynamic> map) {
    // Parse coordinates - Supabase might store as JSON string or object
    LatLng coords;
    if (map['coordinates'] != null) {
      if (map['coordinates'] is Map) {
        coords = LatLng(
          (map['coordinates']['latitude'] ?? 0.0).toDouble(),
          (map['coordinates']['longitude'] ?? 0.0).toDouble(),
        );
      } else if (map['latitude'] != null && map['longitude'] != null) {
        coords = LatLng(
          (map['latitude'] ?? 0.0).toDouble(),
          (map['longitude'] ?? 0.0).toDouble(),
        );
      } else {
        coords = const LatLng(0.0, 0.0);
      }
    } else if (map['latitude'] != null && map['longitude'] != null) {
      coords = LatLng(
        (map['latitude'] ?? 0.0).toDouble(),
        (map['longitude'] ?? 0.0).toDouble(),
      );
    } else {
      coords = const LatLng(0.0, 0.0);
    }

    return TrashcanModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      location: map['location'] ?? map['location_name'] ?? '',
      locationName: map['location_name'] ?? map['locationName'] ?? map['location'] ?? '',
      coordinates: coords,
      status: _parseStatus(map['status']),
      fillLevel: (map['fill_level'] ?? map['fillLevel'] ?? 0.0).toDouble(),
      lastEmptiedAt: map['last_emptied_at'] != null 
          ? DateTime.parse(map['last_emptied_at'])
          : DateTime.now(),
      lastUpdatedAt: map['updated_at'] != null || map['last_updated_at'] != null
          ? DateTime.parse(map['updated_at'] ?? map['last_updated_at'])
          : DateTime.now(),
      assignedStaffId: map['assigned_staff_id'] ?? map['assignedStaffId'],
      assignedStaffName: map['assigned_staff_name'] ?? map['assignedStaffName'],
      isOnline: map['is_online'] ?? map['isOnline'] ?? true,
      qrCode: map['qr_code'] ?? map['qrCode'],
      sensorData: map['sensor_data'] ?? map['sensorData'],
      notes: map['notes'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      deviceId: map['device_id'] ?? map['deviceId'],
      sensorType: map['sensor_type'] ?? map['sensorType'],
      batteryLevel: map['battery_level'] ?? map['batteryLevel'],
      isActive: map['is_active'] ?? map['isActive'] ?? true,
    );
  }

  static TrashcanStatus _parseStatus(String? status) {
    if (status == null) return TrashcanStatus.empty;
    
    switch (status.toLowerCase()) {
      case 'empty':
        return TrashcanStatus.empty;
      case 'half':
      case 'half_full':
        return TrashcanStatus.half;
      case 'full':
        return TrashcanStatus.full;
      case 'maintenance':
        return TrashcanStatus.maintenance;
      case 'offline':
        return TrashcanStatus.offline;
      case 'alive':
        return TrashcanStatus.alive;
      default:
        return TrashcanStatus.empty;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'location_name': locationName,
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'status': status.name,
      'fill_level': fillLevel,
      'last_emptied_at': lastEmptiedAt.toIso8601String(),
      'updated_at': lastUpdatedAt.toIso8601String(),
      'assigned_staff_id': assignedStaffId,
      'assigned_staff_name': assignedStaffName,
      'is_online': isOnline,
      'qr_code': qrCode,
      'sensor_data': sensorData,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TrashcanModel copyWith({
    String? id,
    String? name,
    String? location,
    String? locationName,
    LatLng? coordinates,
    TrashcanStatus? status,
    double? fillLevel,
    DateTime? lastEmptiedAt,
    DateTime? lastUpdatedAt,
    String? assignedStaffId,
    String? assignedStaffName,
    bool? isOnline,
    String? qrCode,
    Map<String, dynamic>? sensorData,
    String? notes,
    DateTime? createdAt,
    String? deviceId,
    String? sensorType,
    int? batteryLevel,
    bool? isActive,
  }) {
    return TrashcanModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      locationName: locationName ?? this.locationName,
      coordinates: coordinates ?? this.coordinates,
      status: status ?? this.status,
      fillLevel: fillLevel ?? this.fillLevel,
      lastEmptiedAt: lastEmptiedAt ?? this.lastEmptiedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      isOnline: isOnline ?? this.isOnline,
      qrCode: qrCode ?? this.qrCode,
      sensorData: sensorData ?? this.sensorData,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      deviceId: deviceId ?? this.deviceId,
      sensorType: sensorType ?? this.sensorType,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isActive: isActive ?? this.isActive,
    );
  }

  // Helper methods
  bool get isFull => status == TrashcanStatus.full;
  bool get isHalf => status == TrashcanStatus.half;
  bool get isEmpty => status == TrashcanStatus.empty;
  bool get isMaintenance => status == TrashcanStatus.maintenance;
  bool get isOffline => status == TrashcanStatus.offline;
  bool get isAlive => status == TrashcanStatus.alive;

  bool get needsAttention => isFull || (isHalf && _isOverdue());

  bool _isOverdue() {
    final hoursSinceLastEmptied =
        DateTime.now().difference(lastEmptiedAt).inHours;
    return hoursSinceLastEmptied > 24; // Overdue if not emptied in 24 hours
  }

  String get statusText {
    switch (status) {
      case TrashcanStatus.empty:
        return 'Empty';
      case TrashcanStatus.half:
        return 'Half Full';
      case TrashcanStatus.full:
        return 'Full';
      case TrashcanStatus.maintenance:
        return 'Maintenance';
      case TrashcanStatus.offline:
        return 'Offline';
      case TrashcanStatus.alive:
        return 'Alive';
    }
  }

  String get fillLevelText {
    return '${(fillLevel * 100).round()}%';
  }

  String get batteryStatusText {
    if (batteryLevel == null) return 'N/A';
    if (batteryLevel! >= 80) return 'Good';
    if (batteryLevel! >= 50) return 'Fair';
    if (batteryLevel! >= 20) return 'Low';
    return 'Critical';
  }

  bool get needsBatteryReplace => batteryLevel != null && batteryLevel! < 20;

  String get sensorTypeDisplay => sensorType ?? 'Unknown';
}

