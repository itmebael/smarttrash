import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

/// Service to fetch staff accounts from database
class StaffFetchService {
  final SupabaseClient _supabase;

  StaffFetchService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Get all staff accounts
  Future<List<UserModel>> getAllStaff() async {
    try {
      print('📡 Fetching all staff accounts...');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .order('created_at', ascending: false);

      print('✅ Fetched ${response.length} staff accounts');
      
      return (response as List)
          .map((staff) => UserModel.fromMap(staff))
          .toList();
    } catch (e) {
      print('❌ Error fetching staff: $e');
      return [];
    }
  }

  /// Get active staff only
  Future<List<UserModel>> getActiveStaff() async {
    try {
      print('📡 Fetching active staff accounts...');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .eq('is_active', true)
          .order('name', ascending: true);

      print('✅ Fetched ${response.length} active staff accounts');
      
      return (response as List)
          .map((staff) => UserModel.fromMap(staff))
          .toList();
    } catch (e) {
      print('❌ Error fetching active staff: $e');
      return [];
    }
  }

  /// Get staff by ID
  Future<UserModel?> getStaffById(String id) async {
    try {
      print('📡 Fetching staff with ID: $id');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .eq('role', 'staff')
          .single();

      print('✅ Staff found: ${response['name']}');
      
      return UserModel.fromMap(response);
    } catch (e) {
      print('❌ Error fetching staff by ID: $e');
      return null;
    }
  }

  /// Get staff by email
  Future<UserModel?> getStaffByEmail(String email) async {
    try {
      print('📡 Fetching staff with email: $email');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .eq('role', 'staff')
          .single();

      print('✅ Staff found: ${response['name']}');
      
      return UserModel.fromMap(response);
    } catch (e) {
      print('❌ Error fetching staff by email: $e');
      return null;
    }
  }

  /// Get staff count
  Future<int> getStaffCount() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff');

      return (response as List).length;
    } catch (e) {
      print('❌ Error counting staff: $e');
      return 0;
    }
  }

  /// Get staff by department
  Future<List<UserModel>> getStaffByDepartment(String department) async {
    try {
      print('📡 Fetching staff from department: $department');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .eq('department', department)
          .eq('is_active', true)
          .order('name', ascending: true);

      print('✅ Found ${response.length} staff in $department');
      
      return (response as List)
          .map((staff) => UserModel.fromMap(staff))
          .toList();
    } catch (e) {
      print('❌ Error fetching staff by department: $e');
      return [];
    }
  }

  /// Search staff by name or email
  Future<List<UserModel>> searchStaff(String query) async {
    try {
      print('📡 Searching staff with query: $query');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .order('name', ascending: true);

      print('✅ Found ${response.length} matching staff');
      
      return (response as List)
          .map((staff) => UserModel.fromMap(staff))
          .toList();
    } catch (e) {
      print('❌ Error searching staff: $e');
      return [];
    }
  }

  /// Check if staff account exists
  Future<bool> staffExists(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .eq('role', 'staff');

      return (response as List).isNotEmpty;
    } catch (e) {
      print('❌ Error checking staff existence: $e');
      return false;
    }
  }

  /// Get staff summary (counts)
  Future<Map<String, int>> getStaffSummary() async {
    try {
      final allStaff = await getAllStaff();
      final activeStaff = allStaff.where((s) => s.isActive).length;
      final inactiveStaff = allStaff.length - activeStaff;

      return {
        'total': allStaff.length,
        'active': activeStaff,
        'inactive': inactiveStaff,
      };
    } catch (e) {
      print('❌ Error getting staff summary: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  /// Watch staff changes in real-time
  Stream<List<UserModel>> watchStaff() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('role', 'staff')
        .order('created_at', ascending: false)
        .map((data) => data.map((staff) => UserModel.fromMap(staff)).toList());
  }
}









