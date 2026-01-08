import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/smart_bin_model.dart';

class SmartBinService {
  final SupabaseClient _supabase;

  SmartBinService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Get all smart bins
  Future<List<SmartBinModel>> getAllSmartBins() async {
    try {
      print('📡 Fetching all smart bins...');
      
      final response = await _supabase
          .from('smart_bin')
          .select()
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} smart bins');
      
      return (response as List)
          .map((bin) => SmartBinModel.fromMap(bin))
          .toList();
    } catch (e) {
      print('❌ Error fetching smart bins: $e');
      return [];
    }
  }

  /// Get latest status for each smart bin (most recent entry)
  Future<List<SmartBinModel>> getLatestSmartBinStatus() async {
    try {
      print('📡 Fetching latest smart bin status...');
      
      // Get the most recent entry for each bin ID
      final response = await _supabase
          .rpc('get_latest_smart_bin_status')
          .select();

      print('✅ Fetched latest status for ${response.length} smart bins');
      
      return (response as List)
          .map((bin) => SmartBinModel.fromMap(bin))
          .toList();
    } catch (e) {
      print('⚠️  RPC function not found, using fallback: $e');
      // Fallback to getting all bins
      return await getAllSmartBins();
    }
  }

  /// Get smart bin by ID
  Future<SmartBinModel?> getSmartBinById(int id) async {
    try {
      print('📡 Fetching smart bin #$id...');
      
      final response = await _supabase
          .from('smart_bin')
          .select()
          .eq('id', id)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      print('✅ Fetched smart bin #$id');
      
      return SmartBinModel.fromMap(response);
    } catch (e) {
      print('❌ Error fetching smart bin #$id: $e');
      return null;
    }
  }

  /// Get smart bins with location data only
  Future<List<SmartBinModel>> getSmartBinsWithLocation() async {
    try {
      print('📡 Fetching smart bins with location...');
      
      final response = await _supabase
          .from('smart_bin')
          .select()
          .not('latitude', 'is', null)
          .not('longitude', 'is', null)
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} smart bins with location');
      
      return (response as List)
          .map((bin) => SmartBinModel.fromMap(bin))
          .toList();
    } catch (e) {
      print('❌ Error fetching smart bins with location: $e');
      return [];
    }
  }

  /// Get smart bins by status
  Future<List<SmartBinModel>> getSmartBinsByStatus(SmartBinStatus status) async {
    try {
      print('📡 Fetching smart bins with status: ${status.name}...');
      
      final allBins = await getLatestSmartBinStatus();
      final filteredBins = allBins.where((bin) => bin.status == status).toList();

      print('✅ Found ${filteredBins.length} smart bins with status: ${status.name}');
      
      return filteredBins;
    } catch (e) {
      print('❌ Error fetching smart bins by status: $e');
      return [];
    }
  }

  /// Get smart bins that need attention (high, full, overflow)
  Future<List<SmartBinModel>> getSmartBinsNeedingAttention() async {
    try {
      print('📡 Fetching smart bins needing attention...');
      
      final allBins = await getLatestSmartBinStatus();
      final urgentBins = allBins.where((bin) =>
          bin.status == SmartBinStatus.high ||
          bin.status == SmartBinStatus.full ||
          bin.status == SmartBinStatus.overflow).toList();

      print('✅ Found ${urgentBins.length} smart bins needing attention');
      
      return urgentBins;
    } catch (e) {
      print('❌ Error fetching smart bins needing attention: $e');
      return [];
    }
  }

  /// Listen to real-time updates
  Stream<List<SmartBinModel>> watchSmartBins() {
    return _supabase
        .from('smart_bin')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((bin) => SmartBinModel.fromMap(bin)).toList());
  }

  /// Insert test data for demonstration
  Future<void> insertTestBin({
    required double distanceCm,
    double? latitude,
    double? longitude,
    String? status,
  }) async {
    try {
      print('📝 Inserting test smart bin...');
      
      await _supabase.from('smart_bin').insert({
        'distance_cm': distanceCm,
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
      });

      print('✅ Test smart bin inserted');
    } catch (e) {
      print('❌ Error inserting test smart bin: $e');
      rethrow;
    }
  }
}

