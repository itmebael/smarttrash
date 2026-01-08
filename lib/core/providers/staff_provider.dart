import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/supabase_staff_service.dart';

// Get all staff
final allStaffProvider = FutureProvider<List<UserModel>>((ref) async {
  return await SupabaseStaffService.getAllStaff();
});

// Get active staff only
final activeStaffProvider = FutureProvider<List<UserModel>>((ref) async {
  return await SupabaseStaffService.getActiveStaff();
});

// Get staff count
final staffCountProvider = FutureProvider<int>((ref) async {
  return await SupabaseStaffService.getStaffCount();
});

// Get active staff count
final activeStaffCountProvider = FutureProvider<int>((ref) async {
  return await SupabaseStaffService.getActiveStaffCount();
});

// Get staff statistics
final staffStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  return await SupabaseStaffService.getStaffStatistics();
});

// Search staff
final searchStaffProvider =
    FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.isEmpty) {
    return await SupabaseStaffService.getAllStaff();
  }
  return await SupabaseStaffService.searchStaff(query);
});

// Get staff by department
final staffByDepartmentProvider =
    FutureProvider.family<List<UserModel>, String>((ref, department) async {
  return await SupabaseStaffService.getStaffByDepartment(department);
});

// Get staff by ID
final staffByIdProvider =
    FutureProvider.family<UserModel?, String>((ref, id) async {
  return await SupabaseStaffService.getStaffById(id);
});



