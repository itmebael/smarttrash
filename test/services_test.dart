import 'package:flutter_test/flutter_test.dart';
import 'package:ecowaste_manager_app/core/services/staff_data_service.dart';
import 'package:ecowaste_manager_app/core/services/notification_data_service.dart';
import 'package:ecowaste_manager_app/core/models/user_model.dart';
import 'package:ecowaste_manager_app/core/models/notification_model.dart';

void main() {
  group('Staff Data Service Tests', () {
    test('should return all staff members', () {
      final staff = StaffDataService.getAllStaff();
      expect(staff, isNotEmpty);
      expect(staff.length, greaterThan(0));
    });

    test('should return active staff members', () {
      final activeStaff = StaffDataService.getActiveStaff();
      expect(activeStaff, isNotEmpty);
      expect(activeStaff.every((staff) => staff.isActive), isTrue);
    });

    test('should return inactive staff members', () {
      final inactiveStaff = StaffDataService.getInactiveStaff();
      expect(inactiveStaff.every((staff) => !staff.isActive), isTrue);
    });

    test('should get staff by ID', () {
      final staff = StaffDataService.getStaffById('staff_001');
      expect(staff, isNotNull);
      expect(staff!.id, equals('staff_001'));
    });

    test('should get staff by department', () {
      final maintenanceStaff =
          StaffDataService.getStaffByDepartment('Maintenance');
      expect(maintenanceStaff, isNotEmpty);
      expect(
          maintenanceStaff.every((staff) => staff.department == 'Maintenance'),
          isTrue);
    });

    test('should add new staff member', () {
      final initialCount = StaffDataService.getTotalStaffCount();
      final newStaff = UserModel(
        id: 'test_staff',
        email: 'test@ssu.edu.ph',
        name: 'Test Staff',
        phoneNumber: '+639123456789',
        role: UserRole.staff,
        createdAt: DateTime.now(),
      );

      StaffDataService.addStaff(newStaff);
      expect(StaffDataService.getTotalStaffCount(), equals(initialCount + 1));

      // Clean up
      StaffDataService.removeStaff('test_staff');
    });

    test('should toggle staff status', () {
      final staff = StaffDataService.getStaffById('staff_001');
      final initialStatus = staff!.isActive;

      StaffDataService.toggleStaffStatus('staff_001');
      final updatedStaff = StaffDataService.getStaffById('staff_001');
      expect(updatedStaff!.isActive, equals(!initialStatus));

      // Reset status
      StaffDataService.toggleStaffStatus('staff_001');
    });
  });

  group('Notification Data Service Tests', () {
    test('should return all notifications', () async {
      final notifications = await NotificationDataService.getAllNotifications();
      expect(notifications, isNotEmpty);
      expect(notifications.length, greaterThan(0));
    });

    test('should return unread notifications', () {
      final unreadNotifications =
          NotificationDataService.getUnreadNotifications();
      expect(unreadNotifications, isNotEmpty);
      expect(unreadNotifications.every((notification) => !notification.isRead),
          isTrue);
    });

    test('should return read notifications', () {
      final readNotifications = NotificationDataService.getReadNotifications();
      expect(readNotifications.every((notification) => notification.isRead),
          isTrue);
    });

    test('should get notification by ID', () {
      final notification =
          NotificationDataService.getNotificationById('notif_001');
      expect(notification, isNotNull);
      expect(notification!.id, equals('notif_001'));
    });

    test('should get notifications by type', () {
      final trashcanNotifications =
          NotificationDataService.getNotificationsByType(
              NotificationType.trashcanFull);
      expect(trashcanNotifications, isNotEmpty);
      expect(
          trashcanNotifications.every((notification) =>
              notification.type == NotificationType.trashcanFull),
          isTrue);
    });

    test('should mark notification as read', () {
      final notification =
          NotificationDataService.getNotificationById('notif_001');
      final initialReadStatus = notification!.isRead;

      NotificationDataService.markAsRead('notif_001');
      final updatedNotification =
          NotificationDataService.getNotificationById('notif_001');
      expect(updatedNotification!.isRead, isTrue);

      // Reset status if it was initially unread
      if (!initialReadStatus) {
        // This would require a reset method in the service
      }
    });

    test('should get unread count', () {
      final unreadCount = NotificationDataService.getUnreadCount();
      expect(unreadCount, greaterThanOrEqualTo(0));
    });

    test('should get total count', () {
      final totalCount = NotificationDataService.getTotalCount();
      expect(totalCount, greaterThan(0));
    });
  });
}

