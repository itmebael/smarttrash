import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trashcan_model.dart';

class TrashcanService {
  final SupabaseClient _supabase;

  TrashcanService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Get all trashcans
  Future<List<TrashcanModel>> getAllTrashcans() async {
    try {
      print('📡 Fetching all trashcans...');
      
      final response = await _supabase
          .from('trashcans')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} trashcans');
      
      return (response as List)
          .map((trashcan) => TrashcanModel.fromSupabaseMap(trashcan))
          .toList();
    } catch (e) {
      print('❌ Error fetching trashcans: $e');
      return [];
    }
  }

  /// Get trashcan by ID
  Future<TrashcanModel?> getTrashcanById(String id) async {
    try {
      print('📡 Fetching trashcan #$id...');
      
      final response = await _supabase
          .from('trashcans')
          .select()
          .eq('id', id)
          .single();

      print('✅ Fetched trashcan #$id');
      
      return TrashcanModel.fromSupabaseMap(response);
    } catch (e) {
      print('❌ Error fetching trashcan #$id: $e');
      return null;
    }
  }

  /// Get trashcans by status
  Future<List<TrashcanModel>> getTrashcansByStatus(TrashcanStatus status) async {
    try {
      print('📡 Fetching trashcans with status: ${status.name}...');
      
      final response = await _supabase
          .from('trashcans')
          .select()
          .eq('status', status.name)
          .eq('is_active', true)
          .order('last_updated_at', ascending: false);

      print('✅ Found ${response.length} trashcans with status: ${status.name}');
      
      return (response as List)
          .map((trashcan) => TrashcanModel.fromSupabaseMap(trashcan))
          .toList();
    } catch (e) {
      print('❌ Error fetching trashcans by status: $e');
      return [];
    }
  }

  /// Get trashcans needing attention (full or maintenance)
  Future<List<TrashcanModel>> getTrashcansNeedingAttention() async {
    try {
      print('📡 Fetching trashcans needing attention...');
      
      final response = await _supabase
          .from('trashcans')
          .select()
          .inFilter('status', ['full', 'maintenance'])
          .eq('is_active', true)
          .order('last_updated_at', ascending: false);

      print('✅ Found ${response.length} trashcans needing attention');
      
      return (response as List)
          .map((trashcan) => TrashcanModel.fromSupabaseMap(trashcan))
          .toList();
    } catch (e) {
      print('❌ Error fetching trashcans needing attention: $e');
      return [];
    }
  }

  /// Get trashcans with low battery
  Future<List<TrashcanModel>> getTrashcansWithLowBattery() async {
    try {
      print('📡 Fetching trashcans with low battery...');
      
      final response = await _supabase
          .from('trashcans')
          .select()
          .lt('battery_level', 20)
          .eq('is_active', true)
          .order('battery_level', ascending: true);

      print('✅ Found ${response.length} trashcans with low battery');
      
      return (response as List)
          .map((trashcan) => TrashcanModel.fromSupabaseMap(trashcan))
          .toList();
    } catch (e) {
      print('❌ Error fetching trashcans with low battery: $e');
      return [];
    }
  }

  /// Get trashcans by device ID
  Future<TrashcanModel?> getTrashcanByDeviceId(String deviceId) async {
    try {
      print('📡 Fetching trashcan with device ID: $deviceId...');
      
      final response = await _supabase
          .from('trashcans')
          .select()
          .eq('device_id', deviceId)
          .single();

      print('✅ Found trashcan with device ID: $deviceId');
      
      return TrashcanModel.fromSupabaseMap(response);
    } catch (e) {
      print('❌ Error fetching trashcan by device ID: $e');
      return null;
    }
  }

  /// Update trashcan status
  Future<bool> updateTrashcanStatus(String id, TrashcanStatus status, double fillLevel) async {
    try {
      print('📝 Updating trashcan #$id status to ${status.name}...');
      
      await _supabase
          .from('trashcans')
          .update({
            'status': status.name,
            'fill_level': fillLevel,
            'last_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      print('✅ Updated trashcan #$id status');
      return true;
    } catch (e) {
      print('❌ Error updating trashcan status: $e');
      return false;
    }
  }

  /// Update battery level
  Future<bool> updateBatteryLevel(String id, int batteryLevel) async {
    try {
      print('📝 Updating trashcan #$id battery level to $batteryLevel%...');
      
      await _supabase
          .from('trashcans')
          .update({
            'battery_level': batteryLevel,
            'last_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      print('✅ Updated trashcan #$id battery level');
      return true;
    } catch (e) {
      print('❌ Error updating battery level: $e');
      return false;
    }
  }

  /// Mark trashcan as emptied
  Future<bool> markAsEmptied(String id) async {
    try {
      print('📝 Marking trashcan #$id as emptied...');
      
      await _supabase
          .from('trashcans')
          .update({
            'status': 'empty',
            'fill_level': 0.0,
            'last_emptied_at': DateTime.now().toIso8601String(),
            'last_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      print('✅ Marked trashcan #$id as emptied');
      return true;
    } catch (e) {
      print('❌ Error marking trashcan as emptied: $e');
      return false;
    }
  }

  /// Listen to real-time updates
  Stream<List<TrashcanModel>> watchTrashcans() {
    return _supabase
        .from('trashcans')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .map((data) => data.map((trashcan) => TrashcanModel.fromSupabaseMap(trashcan)).toList());
  }

  /// Insert new trashcan
  Future<String?> insertTrashcan({
    required String name,
    required String location,
    required double latitude,
    required double longitude,
    String? deviceId,
    String? sensorType,
    String? notes,
  }) async {
    try {
      print('📝 Inserting new trashcan: $name...');
      
      final response = await _supabase
          .from('trashcans')
          .insert({
            'name': name,
            'location': location,
            'latitude': latitude,
            'longitude': longitude,
            'device_id': deviceId,
            'sensor_type': sensorType,
            'notes': notes,
            'status': 'empty',
            'fill_level': 0.0,
            'is_active': true,
          })
          .select()
          .single();

      print('✅ Inserted trashcan: $name');
      return response['id'];
    } catch (e) {
      print('❌ Error inserting trashcan: $e');
      return null;
    }
  }

  /// Deactivate trashcan
  Future<bool> deactivateTrashcan(String id) async {
    try {
      print('📝 Deactivating trashcan #$id...');
      
      await _supabase
          .from('trashcans')
          .update({
            'is_active': false,
            'last_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      print('✅ Deactivated trashcan #$id');
      return true;
    } catch (e) {
      print('❌ Error deactivating trashcan: $e');
      return false;
    }
  }

  /// Get statistics
  Future<Map<String, int>> getTrashcanStatistics() async {
    try {
      print('📊 Fetching trashcan statistics...');
      
      final all = await getAllTrashcans();
      
      final stats = {
        'total': all.length,
        'empty': all.where((t) => t.status == TrashcanStatus.empty).length,
        'half': all.where((t) => t.status == TrashcanStatus.half).length,
        'full': all.where((t) => t.status == TrashcanStatus.full).length,
        'maintenance': all.where((t) => t.status == TrashcanStatus.maintenance).length,
        'lowBattery': all.where((t) => t.needsBatteryReplace).length,
      };

      print('✅ Statistics: $stats');
      return stats;
    } catch (e) {
      print('❌ Error fetching statistics: $e');
      return {
        'total': 0,
        'empty': 0,
        'half': 0,
        'full': 0,
        'maintenance': 0,
        'lowBattery': 0,
      };
    }
  }
}

