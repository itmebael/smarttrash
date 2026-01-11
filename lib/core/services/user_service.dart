import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all users from database
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => UserModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching users: $e');
      return [];
    }
  }

  /// Fetch users by role
  static Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('role', role.name)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => UserModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching users by role: $e');
      return [];
    }
  }

  /// Fetch active users only
  static Future<List<UserModel>> getActiveUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => UserModel.fromMap(data))
          .toList();
    } catch (e) {
      print('❌ Error fetching active users: $e');
      return [];
    }
  }

  /// Get user by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      print('❌ Error fetching user: $e');
      return null;
    }
  }

  /// Update user profile
  static Future<bool> updateUser({
    required String userId,
    String? name,
    String? phoneNumber,
    String? department,
    String? position,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    int? age,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (department != null) updateData['department'] = department;
      if (position != null) updateData['position'] = position;
      if (address != null) updateData['address'] = address;
      if (city != null) updateData['city'] = city;
      if (state != null) updateData['state'] = state;
      if (zipCode != null) updateData['zip_code'] = zipCode;
      if (age != null) updateData['age'] = age;

      await _supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ Error updating user: $e');
      return false;
    }
  }

  /// Toggle user active status
  static Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _supabase
          .from('users')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ Error toggling user status: $e');
      return false;
    }
  }

  /// Delete user (Hard delete)
  static Future<bool> deleteUser(String userId) async {
    try {
      await _supabase
          .from('users')
          .delete()
          .eq('id', userId);

      return true;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return false;
    }
  }

  /// Get user statistics
  static Future<Map<String, int>> getUserStats() async {
    try {
      final allUsers = await getAllUsers();
      return {
        'total': allUsers.length,
        'admin': allUsers.where((u) => u.role == UserRole.admin).length,
        'staff': allUsers.where((u) => u.role == UserRole.staff).length,
        'active': allUsers.where((u) => u.isActive).length,
        'inactive': allUsers.where((u) => !u.isActive).length,
      };
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {
        'total': 0,
        'admin': 0,
        'staff': 0,
        'active': 0,
        'inactive': 0,
      };
    }
  }
}
