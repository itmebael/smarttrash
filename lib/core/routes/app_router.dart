import 'package:ecowaste_manager_app/features/auth/presentation/pages/cool_login_page.dart';
import 'package:ecowaste_manager_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/staff_register_page.dart';
import '../../features/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/staff_dashboard_page.dart';
import '../../features/dashboard/presentation/pages/staff_management_page.dart';
import '../../features/users/presentation/pages/user_management_page.dart';
import '../../features/map/presentation/pages/simple_map_page.dart';
import '../../features/map/presentation/pages/google_maps_page.dart';
import '../../features/tasks/presentation/pages/task_details_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/tasks/presentation/pages/task_assignment_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/staff/presentation/pages/create_staff_account_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../models/task_model.dart';
import '../../features/trashcans/presentation/pages/trashcan_details_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    // Remove redirect logic - handle in auth state listeners instead
    routes: [
      // Onboarding route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      // Authentication routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const CoolLoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/staff-register',
        name: 'staff-register',
        builder: (context, state) => const StaffRegisterPage(),
      ),

      // Main app routes
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: '/staff-dashboard',
        name: 'staff-dashboard',
        builder: (context, state) => const StaffDashboardPage(),
      ),
      // Removed cool-dashboard route (cleanup)
      GoRoute(
        path: '/staff-management',
        name: 'staff-management',
        builder: (context, state) => const StaffManagementPage(),
      ),
      GoRoute(
        path: '/user-management',
        name: 'user-management',
        builder: (context, state) => const UserManagementPage(),
      ),

      // Map routes
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const SimpleMapPage(),
      ),
      GoRoute(
        path: '/google-maps',
        name: 'google-maps',
        builder: (context, state) => const GoogleMapsPage(),
      ),
      // Removed green-ui route (cleanup)

      // Task routes
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) => const TasksPage(),
      ),
      GoRoute(
        path: '/tasks/:taskId',
        name: 'task-details',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          // TODO: Create a task from taskId or pass a mock task
          return TaskDetailsPage(
            task: TaskModel(
              id: taskId,
              title: 'Sample Task',
              description: 'Task description',
              trashcanId: 'trashcan1',
              trashcanName: 'Sample Trashcan',
              assignedStaffId: 'staff1',
              assignedStaffName: 'Staff Member',
              createdByAdminId: 'admin1',
              createdByAdminName: 'Admin User',
              status: TaskStatus.pending,
              priority: TaskPriority.medium,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              dueDate: DateTime.now().add(const Duration(days: 1)),
            ),
          );
        },
      ),

      // Task assignment routes
      GoRoute(
        path: '/task-assignment',
        name: 'task-assignment',
        builder: (context, state) => const TaskAssignmentPage(),
      ),

      // Staff creation routes
      GoRoute(
        path: '/create-staff',
        name: 'create-staff',
        builder: (context, state) => const CreateStaffAccountPage(),
      ),

      // Notification routes
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),

      // Report routes
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsPage(),
      ),

      // Profile routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),

      // Analytics routes
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),

      // Settings routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),

      // Removed QR Scanner route

      // Trashcan routes
      GoRoute(
        path: '/trashcans/:trashcanId',
        name: 'trashcan-details',
        builder: (context, state) {
          final trashcanId = state.pathParameters['trashcanId']!;
          return TrashcanDetailsPage(trashcanId: trashcanId);
        },
      ),
    ],
    errorBuilder: (context, state) {
      // Immediately redirect to dashboard instead of showing error page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
      return const MaterialApp(
          home: SizedBox.shrink()); // Return empty widget while redirecting
    },
  );
}
