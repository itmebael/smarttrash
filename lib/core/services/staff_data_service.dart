import '../models/user_model.dart';

class StaffDataService {
  // TODO: Replace with actual data from API/database
  static final List<UserModel> _staffMembers = [];

  static List<UserModel> getAllStaff() {
    return List.from(_staffMembers);
  }

  static List<UserModel> getActiveStaff() {
    return _staffMembers.where((staff) => staff.isActive).toList();
  }

  static List<UserModel> getInactiveStaff() {
    return _staffMembers.where((staff) => !staff.isActive).toList();
  }

  static UserModel? getStaffById(String id) {
    try {
      return _staffMembers.firstWhere((staff) => staff.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<UserModel> getStaffByDepartment(String department) {
    return _staffMembers
        .where((staff) => staff.department == department)
        .toList();
  }

  static void addStaff(UserModel newStaff) {
    _staffMembers.add(newStaff);
  }

  static void updateStaff(UserModel updatedStaff) {
    final index =
        _staffMembers.indexWhere((staff) => staff.id == updatedStaff.id);
    if (index != -1) {
      _staffMembers[index] = updatedStaff;
    }
  }

  static void removeStaff(String staffId) {
    _staffMembers.removeWhere((staff) => staff.id == staffId);
  }

  static void toggleStaffStatus(String staffId) {
    final index = _staffMembers.indexWhere((staff) => staff.id == staffId);
    if (index != -1) {
      _staffMembers[index] = _staffMembers[index].copyWith(
        isActive: !_staffMembers[index].isActive,
      );
    }
  }

  static List<String> getDepartments() {
    return _staffMembers
        .map((staff) => staff.department)
        .where((dept) => dept != null)
        .cast<String>()
        .toSet()
        .toList();
  }

  static Map<String, int> getDepartmentStats() {
    final Map<String, int> stats = {};
    for (final staff in _staffMembers) {
      if (staff.department != null) {
        stats[staff.department!] = (stats[staff.department!] ?? 0) + 1;
      }
    }
    return stats;
  }

  static Map<String, int> getPositionStats() {
    final Map<String, int> stats = {};
    for (final staff in _staffMembers) {
      if (staff.position != null) {
        stats[staff.position!] = (stats[staff.position!] ?? 0) + 1;
      }
    }
    return stats;
  }

  static int getTotalStaffCount() {
    return _staffMembers.length;
  }

  static int getActiveStaffCount() {
    return _staffMembers.where((staff) => staff.isActive).length;
  }

  static int getInactiveStaffCount() {
    return _staffMembers.where((staff) => !staff.isActive).length;
  }
}


