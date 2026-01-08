import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseStaffService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get all staff members from database
  static Future<List<UserModel>> getAllStaff() async {
    try {
      print('📥 Fetching all staff from database...');
      
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .order('created_at', ascending: false);

      final staffList = (response as List)
          .map((staff) => UserModel.fromMap(staff))
          .toList();

      print('✅ Fetched ${staffList.length} staff members');
      return staffList;
    } catch (e) {
      print('❌ Error fetching staff: $e');
      return [];
    }
  }

  // Get active staff members
  static Future<List<UserModel>> getActiveStaff() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((staff) => UserModel.fromMap(staff))
          .toList();
    } catch (e) {
      print('❌ Error fetching active staff: $e');
      return [];
    }
  }

  // Get staff by ID
  static Future<UserModel?> getStaffById(String id) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .eq('role', 'staff')
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      print('❌ Error fetching staff by ID: $e');
      return null;
    }
  }

  // Get staff by department
  static Future<List<UserModel>> getStaffByDepartment(String department) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .eq('department', department)
          .order('created_at', ascending: false);

      return (response as List)
          .map((staff) => UserModel.fromMap(staff))
          .toList();
    } catch (e) {
      print('❌ Error fetching staff by department: $e');
      return [];
    }
  }

  // Create a new staff member
  static Future<bool> createStaff({
    required String email,
    required String name,
    required String phoneNumber,
    String? password,
    int? age,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? department,
    String? position,
    DateTime? dateOfBirth,
    String? emergencyContact,
    String? emergencyPhone,
  }) async {
    try {
      print('📝 Creating new staff: $name ($email)');

      // If password provided, use Supabase auth
      if (password != null && password.isNotEmpty) {
        final authResponse = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
            'phone_number': phoneNumber,
            'role': 'staff',
          },
        );

        if (authResponse.user != null) {
          // Insert into users table
          await _supabase.from('users').insert({
            'id': authResponse.user!.id,
            'email': email,
            'name': name,
            'phone_number': phoneNumber,
            'role': 'staff',
            'age': age,
            'address': address,
            'city': city,
            'state': state,
            'zip_code': zipCode,
            'department': department,
            'position': position,
            'date_of_birth': dateOfBirth?.toIso8601String(),
            'emergency_contact': emergencyContact,
            'emergency_phone': emergencyPhone,
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
          });

          print('✅ Staff created successfully with ID: ${authResponse.user!.id}');
          return true;
        }
      } else {
        // Just insert into users table without auth
        await _supabase.from('users').insert({
          'email': email,
          'name': name,
          'phone_number': phoneNumber,
          'role': 'staff',
          'age': age,
          'address': address,
          'city': city,
          'state': state,
          'zip_code': zipCode,
          'department': department,
          'position': position,
          'date_of_birth': dateOfBirth?.toIso8601String(),
          'emergency_contact': emergencyContact,
          'emergency_phone': emergencyPhone,
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        });

        print('✅ Staff created successfully');
        return true;
      }

      return false;
    } catch (e) {
      print('❌ Error creating staff: $e');
      return false;
    }
  }

  // Update staff member
  static Future<bool> updateStaff({
    required String id,
    String? name,
    String? phoneNumber,
    int? age,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? department,
    String? position,
    String? profileImageUrl,
    String? emergencyContact,
    String? emergencyPhone,
  }) async {
    try {
      print('✏️ Updating staff: $id');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (age != null) updates['age'] = age;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;
      if (state != null) updates['state'] = state;
      if (zipCode != null) updates['zip_code'] = zipCode;
      if (department != null) updates['department'] = department;
      if (position != null) updates['position'] = position;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;
      if (emergencyContact != null) updates['emergency_contact'] = emergencyContact;
      if (emergencyPhone != null) updates['emergency_phone'] = emergencyPhone;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', id)
          .eq('role', 'staff');

      print('✅ Staff updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating staff: $e');
      return false;
    }
  }

  // Toggle staff status (active/inactive)
  static Future<bool> toggleStaffStatus(String id) async {
    try {
      print('🔄 Toggling staff status: $id');

      // Get current status
      final response = await _supabase
          .from('users')
          .select('is_active')
          .eq('id', id)
          .single();

      final currentStatus = response['is_active'] as bool;
      final newStatus = !currentStatus;

      await _supabase
          .from('users')
          .update({
            'is_active': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);

      print('✅ Staff status toggled: $newStatus');
      return true;
    } catch (e) {
      print('❌ Error toggling staff status: $e');
      return false;
    }
  }

  // Delete staff member
  static Future<bool> deleteStaff(String id) async {
    try {
      print('🗑️ Deleting staff: $id');

      await _supabase.from('users').delete().eq('id', id).eq('role', 'staff');

      print('✅ Staff deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting staff: $e');
      return false;
    }
  }

  // Get staff statistics
  static Future<Map<String, int>> getStaffStatistics() async {
    try {
      final total = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'staff');

      final active = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'staff')
          .eq('is_active', true);

      final inactive = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'staff')
          .eq('is_active', false);

      return {
        'total': total.length,
        'active': active.length,
        'inactive': inactive.length,
      };
    } catch (e) {
      print('❌ Error getting staff statistics: $e');
      return {'total': 0, 'active': 0, 'inactive': 0};
    }
  }

  // Get staff by search query
  static Future<List<UserModel>> searchStaff(String query) async {
    try {
      print('🔍 Searching staff: $query');

      final response = await _supabase
          .from('users')
          .select()
          .eq('role', 'staff')
          .or('name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((staff) => UserModel.fromMap(staff))
          .toList();
    } catch (e) {
      print('❌ Error searching staff: $e');
      return [];
    }
  }

  // Get staff count
  static Future<int> getStaffCount() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'staff');

      return response.length;
    } catch (e) {
      print('❌ Error getting staff count: $e');
      return 0;
    }
  }

  // Get active staff count
  static Future<int> getActiveStaffCount() async {
    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('role', 'staff')
          .eq('is_active', true);

      return response.length;
    } catch (e) {
      print('❌ Error getting active staff count: $e');
      return 0;
    }
  }
}

