import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/models/trashcan_model.dart';

class SimpleMapState {
  final List<TrashcanModel> trashcans;
  final TrashcanModel? selectedTrashcan;
  final LatLng centerPosition;
  final double zoom;
  final bool isLoading;
  final String? error;
  final bool showFullTrashcans;
  final bool showHalfTrashcans;
  final bool showEmptyTrashcans;
  final LatLng? selectedLocation; // For showing temporary marker on long-press

  const SimpleMapState({
    this.trashcans = const [],
    this.selectedTrashcan,
    this.centerPosition =
        const LatLng(12.8797, 124.8447), // Samar State University coordinates
    this.zoom = 17.0, // Closer zoom for university campus
    this.isLoading = false,
    this.error,
    this.showFullTrashcans = true,
    this.showHalfTrashcans = true,
    this.showEmptyTrashcans = true,
    this.selectedLocation,
  });

  SimpleMapState copyWith({
    List<TrashcanModel>? trashcans,
    TrashcanModel? selectedTrashcan,
    LatLng? centerPosition,
    double? zoom,
    bool? isLoading,
    String? error,
    bool? showFullTrashcans,
    bool? showHalfTrashcans,
    bool? showEmptyTrashcans,
    LatLng? selectedLocation,
    bool clearSelectedLocation = false,
  }) {
    return SimpleMapState(
      trashcans: trashcans ?? this.trashcans,
      selectedTrashcan: selectedTrashcan ?? this.selectedTrashcan,
      centerPosition: centerPosition ?? this.centerPosition,
      zoom: zoom ?? this.zoom,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      showFullTrashcans: showFullTrashcans ?? this.showFullTrashcans,
      showHalfTrashcans: showHalfTrashcans ?? this.showHalfTrashcans,
      showEmptyTrashcans: showEmptyTrashcans ?? this.showEmptyTrashcans,
      selectedLocation: clearSelectedLocation ? null : (selectedLocation ?? this.selectedLocation),
    );
  }
}

class SimpleMapNotifier extends StateNotifier<SimpleMapState> {
  SupabaseClient? _supabase;
  bool _isOfflineMode = false;

  SimpleMapNotifier() : super(const SimpleMapState()) {
    _initializeSupabase();
  }

  void _initializeSupabase() {
    try {
      _supabase = Supabase.instance.client;
      // Supabase client initialized
    } catch (e) {
      // Supabase not available - using offline mode
      _isOfflineMode = true;
      _supabase = null;
    }
  }

  Future<void> loadTrashcans() async {
    try {
      print('📍 SimpleMapProvider: Starting to load trashcans...');
      state = state.copyWith(isLoading: true, error: null);

      if (_isOfflineMode || _supabase == null) {
        print('⚠️ SimpleMapProvider: Offline mode or Supabase not available');
        final trashcans = <TrashcanModel>[];
        state = state.copyWith(trashcans: trashcans, isLoading: false);
        print('📊 SimpleMapProvider: Loaded ${trashcans.length} mock trashcans');
        return;
      }

      print('🔄 SimpleMapProvider: Fetching from Supabase...');
      final response = await _supabase!.from('trashcans').select().eq('is_active', true);
      print('📦 SimpleMapProvider: Got response with ${response.length} items');
      
      final trashcans = response.map((data) {
        return TrashcanModel.fromMap(data);
      }).toList();

      state = state.copyWith(trashcans: trashcans, isLoading: false);
      print('✅ SimpleMapProvider: Successfully loaded ${trashcans.length} trashcans');
    } catch (e) {
      print('❌ SimpleMapProvider: Error loading trashcans: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      final trashcans = <TrashcanModel>[];
      state = state.copyWith(
          trashcans: trashcans,
          isLoading: false,
          error: 'Failed to load trashcans: ${e.toString()}');
      print('📊 SimpleMapProvider: Fallback - Loaded ${trashcans.length} mock trashcans');
    }
  }

  Future<void> updateTrashcanStatus(
    String trashcanId,
    TrashcanStatus status,
  ) async {
    try {
      if (_supabase != null) {
        await _supabase!.from('trashcans').update({
          'status': status.name,
          'lastUpdatedAt': DateTime.now().toIso8601String(),
        }).eq('id', trashcanId);
      }

      // Update local state
      final updatedTrashcans = state.trashcans.map((trashcan) {
        if (trashcan.id == trashcanId) {
          return trashcan.copyWith(
            status: status,
            lastUpdatedAt: DateTime.now(),
          );
        }
        return trashcan;
      }).toList();

      state = state.copyWith(trashcans: updatedTrashcans);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> assignTrashcanToStaff(
    String trashcanId,
    String staffId,
    String staffName,
  ) async {
    try {
      if (_supabase != null) {
        await _supabase!.from('trashcans').update({
          'assignedStaffId': staffId,
          'assignedStaffName': staffName,
          'lastUpdatedAt': DateTime.now().toIso8601String(),
        }).eq('id', trashcanId);
      }

      final updated = state.trashcans.map((t) {
        if (t.id == trashcanId) {
          return t.copyWith(
            assignedStaffId: staffId,
            assignedStaffName: staffName,
            lastUpdatedAt: DateTime.now(),
          );
        }
        return t;
      }).toList();

      state = state.copyWith(trashcans: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateFromUltrasonic(
    String trashcanId,
    double measuredDistanceCm,
    double binHeightCm,
  ) async {
    try {
      final level = (1.0 - (measuredDistanceCm / binHeightCm)).clamp(0.0, 1.0);
      TrashcanStatus status;
      if (level >= 0.8) {
        status = TrashcanStatus.full;
      } else if (level >= 0.4) {
        status = TrashcanStatus.half;
      } else {
        status = TrashcanStatus.empty;
      }

      if (_supabase != null) {
        await _supabase!.from('trashcans').update({
          'fillLevel': level,
          'status': status.name,
          'lastUpdatedAt': DateTime.now().toIso8601String(),
        }).eq('id', trashcanId);
      }

      final updated = state.trashcans.map((t) {
        if (t.id == trashcanId) {
          return t.copyWith(
            fillLevel: level,
            status: status,
            lastUpdatedAt: DateTime.now(),
          );
        }
        return t;
      }).toList();

      state = state.copyWith(trashcans: updated);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<String?> addNewTrashcan({
    required String name,
    required String location,
    required double latitude,
    required double longitude,
    String? deviceId,
    String? sensorType,
  }) async {
    try {
      print('📍 addNewTrashcan called with:');
      print('   Name: $name');
      print('   Location: $location');
      print('   Lat: $latitude, Lng: $longitude');
      print('   Device ID: $deviceId');
      print('   Sensor Type: $sensorType');
      
      if (_supabase == null) {
        print('❌ Supabase client is null!');
        throw Exception('Database not available');
      }

      print('🔄 Calling add_trashcan RPC function...');
      
      // Call the Supabase RPC function to add trashcan
      final response = await _supabase!.rpc('add_trashcan', params: {
        'p_name': name,
        'p_location': location,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_device_id': deviceId,
        'p_sensor_type': sensorType,
      });

      print('✅ RPC response: $response');
      print('   Response type: ${response.runtimeType}');
      
      final trashcanId = response as String;

      print('💾 Trashcan saved with ID: $trashcanId');
      print('🔄 Reloading trashcans list...');
      
      // Reload trashcans to get the updated list
      await loadTrashcans();
      
      print('✅ Trashcan list reloaded. Total count: ${state.trashcans.length}');

      return trashcanId;
    } catch (e, stackTrace) {
      print('❌ ERROR in addNewTrashcan:');
      print('   Error: $e');
      print('   Type: ${e.runtimeType}');
      print('   Stack trace: $stackTrace');
      
      state = state.copyWith(error: 'Failed to add trashcan: ${e.toString()}');
      return null;
    }
  }

  void selectTrashcan(TrashcanModel trashcan) {
    state = state.copyWith(selectedTrashcan: trashcan);
  }

  void clearSelection() {
    state = state.copyWith(selectedTrashcan: null);
  }

  void setSelectedLocation(LatLng? location) {
    if (location == null) {
      state = state.copyWith(clearSelectedLocation: true);
    } else {
      state = state.copyWith(selectedLocation: location);
    }
  }

  void setCenterPosition(LatLng position) {
    state = state.copyWith(centerPosition: position);
  }

  void setZoom(double zoom) {
    state = state.copyWith(zoom: zoom);
  }

  void toggleFullTrashcans() {
    state = state.copyWith(showFullTrashcans: !state.showFullTrashcans);
  }

  void toggleHalfTrashcans() {
    state = state.copyWith(showHalfTrashcans: !state.showHalfTrashcans);
  }

  void toggleEmptyTrashcans() {
    state = state.copyWith(showEmptyTrashcans: !state.showEmptyTrashcans);
  }

  void showOnlyStatus(TrashcanStatus status) {
    final showFull = status == TrashcanStatus.full;
    final showHalf = status == TrashcanStatus.half;
    final showEmpty = status == TrashcanStatus.empty;
    state = state.copyWith(
      showFullTrashcans: showFull,
      showHalfTrashcans: showHalf,
      showEmptyTrashcans: showEmpty,
    );
  }

  List<TrashcanModel> get filteredTrashcans {
    return state.trashcans.where((trashcan) {
      switch (trashcan.status) {
        case TrashcanStatus.full:
          return state.showFullTrashcans;
        case TrashcanStatus.half:
          return state.showHalfTrashcans;
        case TrashcanStatus.empty:
          return state.showEmptyTrashcans;
        case TrashcanStatus.maintenance:
          return true; // Always show maintenance trashcans
        case TrashcanStatus.offline:
          return true; // Always show offline trashcans
        case TrashcanStatus.alive:
          return state.showEmptyTrashcans; // Treat alive as empty
      }
    }).toList();
  }
}

final simpleMapProvider =
    StateNotifierProvider<SimpleMapNotifier, SimpleMapState>(
  (ref) => SimpleMapNotifier(),
);

final trashcansProvider = Provider<List<TrashcanModel>>((ref) {
  return ref.watch(simpleMapProvider).trashcans;
});

final selectedTrashcanProvider = Provider<TrashcanModel?>((ref) {
  return ref.watch(simpleMapProvider).selectedTrashcan;
});

final filteredTrashcansProvider = Provider<List<TrashcanModel>>((ref) {
  final notifier = ref.watch(simpleMapProvider.notifier);
  return notifier.filteredTrashcans;
});



