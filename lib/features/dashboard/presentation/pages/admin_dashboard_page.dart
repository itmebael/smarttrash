import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/trashcan_provider.dart';
import '../../../../core/models/trashcan_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/task_model.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/task_service.dart';
import '../../../../core/services/notification_data_service.dart';
import '../../../../core/widgets/theme_toggle.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../tasks/presentation/widgets/completed_task_details_dialog.dart';
import '../widgets/notification_popup_dialog.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TaskService _taskService = TaskService();
  List<TaskModel> _completedTasks = [];
  bool _isLoadingTasks = true;
  String? _taskError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _cardAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _cardAnimationController.forward();
    _animationController.forward();
    _loadCompletedTasks();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    final userId = ref.read(authProvider).value?.id;
    if (userId != null) {
      print('🔔 Admin Dashboard: Initializing notifications for user: $userId');
      
      // Load existing notifications
      NotificationDataService.getAllNotifications(userId: userId).then((_) {
        print('✅ Admin Dashboard: Loaded existing notifications');
      });
      
      // Start listening for new notifications with callback
      NotificationDataService.startListening(
        userId: userId,
        onNewNotification: (notification) {
          print('🔔 Admin Dashboard: New notification received, showing popup...');
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showNotificationPopup(notification);
              }
            });
          }
        },
      );
      
      print('✅ Admin Dashboard: Notification listening started');
    } else {
      print('⚠️ Admin Dashboard: No user ID available for notifications');
    }
  }

  void _showNotificationPopup(NotificationModel notification) {
    if (!mounted) {
      print('⚠️ Admin Dashboard: Cannot show popup - widget not mounted');
      return;
    }
    
    print('📢 Admin Dashboard: Showing notification popup for: ${notification.title}');
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => NotificationPopupDialog(
        notification: notification,
        onDismiss: () {
          print('👆 Admin Dashboard: Notification popup dismissed');
          Navigator.of(context).pop();
        },
        onViewDetails: () {
          print('👆 Admin Dashboard: View details clicked, navigating to notifications');
          Navigator.of(context).pop();
          context.go('/notifications');
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    NotificationDataService.stopListening();
    super.dispose();
  }

  Future<void> _loadCompletedTasks() async {
    try {
      setState(() {
        _isLoadingTasks = true;
        _taskError = null;
      });
      final tasks = await _taskService.getTasksByStatus('completed');
      setState(() {
        _completedTasks = tasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      // Suppress verbose network errors
      final errorStr = e.toString();
      String userFriendlyError;
      
      if (errorStr.contains('Failed host lookup') || 
          errorStr.contains('SocketException') ||
          errorStr.contains('No such host') ||
          errorStr.contains('ClientException')) {
        userFriendlyError = 'No internet connection. Showing cached data.';
      } else {
        userFriendlyError = 'Unable to load tasks. Please check your connection.';
      }
      
      setState(() {
        _isLoadingTasks = false;
        _taskError = userFriendlyError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    // Listen to auth state changes and redirect to login if user becomes null
    ref.listen<AsyncValue<UserModel?>>(authProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user == null && mounted) {
            // User logged out, redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement('/login');
              }
            });
          }
        },
        loading: () {},
        error: (error, stackTrace) {},
      );
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? EcoGradients.backgroundGradient
              : EcoGradients.lightBackgroundGradient,
        ),
        child: Stack(
          children: [
            // Animated background elements
            _buildAnimatedBackground(),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _selectedIndex == 0
                          ? _buildDashboardContent()
                          : _buildPlaceholderContent(),
                    ),
                    _buildBottomNavigation(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Animated floating orbs with admin colors
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              top: 100 + (50 * _animationController.value),
              right: -100 + (80 * _animationController.value),
              child: Transform.rotate(
                angle: _animationController.value * 0.5,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryGreen.withOpacity(0.1),
                        AppTheme.primaryGreen.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              bottom: 200 - (30 * _animationController.value),
              left: -150 + (60 * _animationController.value),
              child: Transform.rotate(
                angle: -_animationController.value * 0.3,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.neonPurple.withOpacity(0.08),
                        AppTheme.neonPurple.withOpacity(0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Grid pattern
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final isDark = ref.watch(isDarkModeProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    final padding = ResponsiveHelper.getPadding(context);
    final margin = ResponsiveHelper.getMargin(context);

    return Container(
      margin: margin,
      padding: padding,
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Admin Profile Section with logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isDark ? EcoShadows.neon : EcoShadows.light,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, Admin!',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.textSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'System Administrator',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: isDark
                                      ? AppTheme.textGray
                                      : AppTheme.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const AnimatedThemeToggle(),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHeaderButton(
                        icon: Icons.assignment,
                        onTap: () => context.go('/task-assignment'),
                        label: 'Assign Task',
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        icon: Icons.notifications_outlined,
                        onTap: () => context.go('/notifications'),
                        badge: true,
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        icon: Icons.person_add,
                        onTap: () => context.go('/create-staff'),
                        label: 'Add Staff',
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        icon: Icons.people,
                        onTap: () => context.go('/user-management'),
                        label: 'Users',
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderButton(
                        icon: Icons.logout,
                        onTap: () async {
                  // Show confirmation dialog
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(inherit: false),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(inherit: false),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (shouldLogout == true && context.mounted) {
                    // Show loading indicator
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                    
                    try {
                      // Perform logout with timeout
                      try {
                        await ref.read(authProvider.notifier).logout()
                            .timeout(
                              const Duration(seconds: 5),
                              onTimeout: () {
                                print('⚠️  Logout timeout - proceeding anyway');
                              },
                            );
                      } catch (e) {
                        print('Logout timeout or error: $e');
                      }
                    } catch (e) {
                      print('Logout error: $e');
                    } finally {
                      // Close loading dialog
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      
                      // Always navigate to login, even if logout failed
                      if (context.mounted) {
                        // Navigate to login page
                        context.pushReplacement('/login');
                      }
                    }
                  }
                },
              ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                // Admin Profile Section with logo
                Container(
                  width: isMobile ? 50 : 60,
                  height: isMobile ? 50 : 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: isDark ? EcoShadows.neon : EcoShadows.light,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      fit: BoxFit.cover,
                      width: isMobile ? 50 : 60,
                      height: isMobile ? 50 : 60,
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 20),
                // Welcome Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, Admin!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'System Administrator',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: isDark
                                  ? AppTheme.textGray
                                  : AppTheme.lightTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 18 : 22,
                            ),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Row(
                  children: [
                    const AnimatedThemeToggle(),
                    SizedBox(width: isMobile ? 8 : 12),
                    if (!isMobile)
                      _buildHeaderButton(
                        icon: Icons.assignment,
                        onTap: () => context.go('/task-assignment'),
                        label: 'Assign Task',
                      ),
                    if (!isMobile) SizedBox(width: isMobile ? 8 : 12),
                    _buildHeaderButton(
                      icon: Icons.notifications_outlined,
                      onTap: () => context.go('/notifications'),
                      badge: true,
                    ),
                    if (!isMobile) SizedBox(width: isMobile ? 8 : 12),
                    if (!isMobile)
                      _buildHeaderButton(
                        icon: Icons.person_add,
                        onTap: () => context.go('/create-staff'),
                        label: 'Add Staff',
                      ),
                    if (!isMobile) SizedBox(width: isMobile ? 8 : 12),
                    if (!isMobile)
                      _buildHeaderButton(
                        icon: Icons.people,
                        onTap: () => context.go('/user-management'),
                        label: 'Users',
                      ),
                    if (!isMobile) SizedBox(width: isMobile ? 8 : 12),
                    _buildHeaderButton(
                      icon: Icons.logout,
                      onTap: () async {
                        // Show confirmation dialog
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(inherit: false),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(inherit: false),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true && context.mounted) {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                          
                          try {
                            // Perform logout with timeout
                            try {
                              await ref.read(authProvider.notifier).logout()
                                  .timeout(
                                    const Duration(seconds: 5),
                                    onTimeout: () {
                                      print('⚠️  Logout timeout - proceeding anyway');
                                    },
                                  );
                            } catch (e) {
                              print('Logout timeout or error: $e');
                            }
                          } catch (e) {
                            print('Logout error: $e');
                          } finally {
                            // Close loading dialog
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                            
                            // Always navigate to login, even if logout failed
                            if (context.mounted) {
                              // Navigate to login page
                              context.pushReplacement('/login');
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    bool badge = false,
    String? label,
  }) {
    final isDark = ref.watch(isDarkModeProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isDark
              ? EcoGradients.glassGradient
              : EcoGradients.lightGlassGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.borderColor : AppTheme.lightBorder,
            width: 1,
          ),
          boxShadow: isDark
              ? EcoShadows.light
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: label != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color:
                        isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textGray
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Icon(
                    icon,
                    color:
                        isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    size: 20,
                  ),
                  if (badge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.dangerRed.withOpacity(0.6),
                              blurRadius: 4,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    final padding = ResponsiveHelper.getPadding(context);
    final spacing = ResponsiveHelper.getCardSpacing(context);
    
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Overview Stats
            _buildAdminOverview(),

            SizedBox(height: spacing * 2),

            // System Status
            _buildSystemStatus(),

            SizedBox(height: spacing * 2),

            // Completed Tasks
            _buildCompletedTasks(),

            SizedBox(height: spacing * 2),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOverview() {
    final isDark = ref.watch(isDarkModeProvider);
    // Fetch real data from trashcans provider
    final trashcansAsync = ref.watch(trashcansProvider);

    return trashcansAsync.when(
      data: (trashcans) {
        final totalTrashcans = trashcans.length;
        final fullTrashcans =
            trashcans.where((t) => t.status == TrashcanStatus.full).length;
        final emptyTrashcans =
            trashcans.where((t) => t.status == TrashcanStatus.empty).length;
        final halfTrashcans =
            trashcans.where((t) => t.status == TrashcanStatus.half).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: ResponsiveHelper.getTitleFontSize(context),
                  ),
            ),
            SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
            ResponsiveHelper.isMobile(context)
                ? Column(
                    children: [
                      _buildAdminStatCard(
                        title: 'Total Trashcans',
                        value: totalTrashcans.toString(),
                        icon: Icons.delete_outline,
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
                      _buildAdminStatCard(
                        title: 'Full Trashcans',
                        value: fullTrashcans.toString(),
                        icon: Icons.warning,
                        color: AppTheme.dangerRed,
                      ),
                      SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
                      _buildAdminStatCard(
                        title: 'Empty Trashcans',
                        value: emptyTrashcans.toString(),
                        icon: Icons.check_circle,
                        color: AppTheme.successGreen,
                      ),
                      SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
                      _buildAdminStatCard(
                        title: 'Half Full',
                        value: halfTrashcans.toString(),
                        icon: Icons.info,
                        color: AppTheme.warningOrange,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAdminStatCard(
                              title: 'Total Trashcans',
                              value: totalTrashcans.toString(),
                              icon: Icons.delete_outline,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getCardSpacing(context)),
                          Expanded(
                            child: _buildAdminStatCard(
                              title: 'Full Trashcans',
                              value: fullTrashcans.toString(),
                              icon: Icons.warning,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAdminStatCard(
                              title: 'Empty Trashcans',
                              value: emptyTrashcans.toString(),
                              icon: Icons.check_circle,
                              color: AppTheme.successGreen,
                            ),
                          ),
                          SizedBox(width: ResponsiveHelper.getCardSpacing(context)),
                          Expanded(
                            child: _buildAdminStatCard(
                              title: 'Half Full',
                              value: halfTrashcans.toString(),
                              icon: Icons.info,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.dangerRed,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading data',
                style: TextStyle(
                  color: AppTheme.dangerRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(trashcansProvider),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Retry',
                  style: TextStyle(
                    inherit: false,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = ref.watch(isDarkModeProvider);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: isDark
                  ? EcoGradients.glassGradient
                  : EcoGradients.lightGlassGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    Text(
                      value,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.textGray
                                    : AppTheme.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSystemStatus() {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Status',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatusIndicator(
                  'Online', AppTheme.successGreen, Icons.check_circle),
              const SizedBox(width: 16),
              _buildStatusIndicator(
                  'Monitoring', AppTheme.primaryGreen, Icons.visibility),
              const SizedBox(width: 16),
              _buildStatusIndicator(
                  'Alerts', AppTheme.warningOrange, Icons.notifications),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTasks() {
    final isDark = ref.watch(isDarkModeProvider);
    final tasksToShow = _completedTasks.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Completed Tasks',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDark
                          ? AppTheme.textGray
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: AppTheme.primaryGreen,
                ),
                tooltip: 'Refresh tasks',
                onPressed: _loadCompletedTasks,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingTasks)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              ),
            )
          else if (_taskError != null)
            Text(
              'Unable to load tasks: $_taskError',
              style: TextStyle(
                color: AppTheme.dangerRed,
              ),
            )
          else if (tasksToShow.isEmpty)
            Text(
              'No completed tasks yet.',
              style: TextStyle(
                color:
                    isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            )
          else
            Column(
              children: tasksToShow.map((task) {
                return Container(
                  key: ValueKey('completed_task_${task.id}'),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? EcoGradients.glassGradient
                        : EcoGradients.lightGlassGradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.successGreen.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.successGreen,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textGray
                                    : AppTheme.lightTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.trashcanName ?? 'No location',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.lightTextSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.completedAt != null
                                  ? 'Completed ${_formatDateTime(task.completedAt!)}'
                                  : 'Completed',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.lightTextSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (task.assignedStaffName != null) ...[
                        Chip(
                          key: ValueKey('staff_chip_${task.id}'),
                          label: Text(
                            task.assignedStaffName!,
                            style: const TextStyle(
                              inherit: false,
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor:
                              AppTheme.successGreen.withOpacity(0.1),
                          side: BorderSide(
                            color: AppTheme.successGreen.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        key: ValueKey('show_button_${task.id}'),
                        onPressed: () => _showTaskDetails(task),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(
                            inherit: false,
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text(
                          'Show',
                          style: TextStyle(
                            inherit: false,
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 8),
          Text(
            'Total completed: ${_completedTasks.length}',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, Color color, IconData icon) {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final isDark = ref.watch(isDarkModeProvider);
    final trashcansAsync = ref.watch(trashcansProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Trashcan Updates',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                onPressed: () => ref.invalidate(trashcansProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          trashcansAsync.when(
            data: (trashcans) {
              if (trashcans.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: isDark
                              ? AppTheme.textSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trashcan activity',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Sort by last updated and take top 5
              final recentTrashcans = [...trashcans];
              recentTrashcans.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
              final topRecent = recentTrashcans.take(5).toList();

              return Column(
                children: topRecent.map((trashcan) {
                  Color getStatusColor(TrashcanStatus status) {
                    switch (status) {
                      case TrashcanStatus.empty:
                        return AppTheme.successGreen;
                      case TrashcanStatus.half:
                        return AppTheme.warningOrange;
                      case TrashcanStatus.full:
                        return AppTheme.dangerRed;
                      case TrashcanStatus.maintenance:
                        return AppTheme.secondaryBlue;
                      case TrashcanStatus.offline:
                        return AppTheme.neutralGray;
                      case TrashcanStatus.alive:
                        return AppTheme.successGreen;
                    }
                  }

                  String getStatusEmoji(TrashcanStatus status) {
                    switch (status) {
                      case TrashcanStatus.empty:
                        return '✅';
                      case TrashcanStatus.half:
                        return '🟡';
                      case TrashcanStatus.full:
                        return '🔴';
                      case TrashcanStatus.maintenance:
                        return '🔧';
                      case TrashcanStatus.offline:
                        return '⚫';
                      case TrashcanStatus.alive:
                        return '🟢';
                    }
                  }

                  final statusColor = getStatusColor(trashcan.status);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor.withOpacity(0.1),
                          statusColor.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getStatusEmoji(trashcan.status),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trashcan.name,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.textGray
                                      : AppTheme.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trashcan.location,
                                style: TextStyle(
                                  color: isDark
                                      ? AppTheme.textSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              trashcan.statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(trashcan.lastUpdatedAt),
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.lightTextSecondary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error loading activity',
                style: TextStyle(
                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const Icon(
                    Icons.map,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'SSU Campus Map',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: isDark
                              ? AppTheme.textGray
                              : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              height: 600,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildActualMap(),
                    ),
                    // Loading indicator
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'SSU Campus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMapStatCard(
                        'Total Locations', '0', Icons.location_on),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMapStatCard(
                        'Active Points', '0', Icons.radio_button_checked),
                  ),
                ],
              ),
            ),
            // Bin Status Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildBinStatusSection(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBinStatusSection() {
    final isDark = ref.watch(isDarkModeProvider);
    final trashcansAsync = ref.watch(trashcansProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark
            ? EcoGradients.glassGradient
            : EcoGradients.lightGlassGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.delete_outline,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Trashcan Status',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isDark
                          ? AppTheme.textGray
                          : AppTheme.lightTextPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: AppTheme.primaryGreen,
                ),
                onPressed: () {
                  ref.invalidate(trashcansProvider);
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          trashcansAsync.when(
            data: (trashcans) {
              if (trashcans.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: isDark
                              ? AppTheme.textSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No trashcans available',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: trashcans.map((trashcan) => _buildTrashcanContainer(trashcan)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.dangerRed,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading trashcans',
                      style: TextStyle(
                        color: AppTheme.dangerRed,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashcanContainer(TrashcanModel trashcan) {
    final isDark = ref.watch(isDarkModeProvider);
    
    Color getTrashcanColor(TrashcanStatus status) {
      switch (status) {
        case TrashcanStatus.empty:
          return AppTheme.successGreen;
        case TrashcanStatus.half:
          return AppTheme.warningOrange;
        case TrashcanStatus.full:
          return AppTheme.dangerRed;
        case TrashcanStatus.maintenance:
          return AppTheme.secondaryBlue;
        case TrashcanStatus.offline:
          return AppTheme.neutralGray;
        case TrashcanStatus.alive:
          return AppTheme.successGreen;
      }
                  }

    String getStatusEmoji(TrashcanStatus status) {
      switch (status) {
        case TrashcanStatus.empty:
          return '✅';
        case TrashcanStatus.half:
          return '🟡';
        case TrashcanStatus.full:
          return '🔴';
        case TrashcanStatus.maintenance:
          return '🔧';
                      case TrashcanStatus.offline:
                        return '⚫';
                      case TrashcanStatus.alive:
                        return '🟢';
                    }
                  }

    final trashcanColor = getTrashcanColor(trashcan.status);

    return GestureDetector(
      onTap: () => _showTrashcanStatusDetails(trashcan),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              trashcanColor.withOpacity(0.15),
              trashcanColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: trashcanColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: trashcanColor.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: trashcanColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: trashcanColor,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  getStatusEmoji(trashcan.status),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              trashcan.name,
              style: TextStyle(
                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              trashcan.statusText.toUpperCase(),
              style: TextStyle(
                color: trashcanColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: trashcan.fillLevel,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(trashcanColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trashcan.fillLevelText,
              style: TextStyle(
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrashcanStatusDetails(TrashcanModel trashcan) {
    final isDark = ref.watch(isDarkModeProvider);
    
    Color getTrashcanColor(TrashcanStatus status) {
      switch (status) {
        case TrashcanStatus.empty:
          return AppTheme.successGreen;
        case TrashcanStatus.half:
          return AppTheme.warningOrange;
        case TrashcanStatus.full:
          return AppTheme.dangerRed;
        case TrashcanStatus.maintenance:
          return AppTheme.secondaryBlue;
        case TrashcanStatus.offline:
          return AppTheme.neutralGray;
        case TrashcanStatus.alive:
          return AppTheme.successGreen;
      }
                  }

    String getStatusEmoji(TrashcanStatus status) {
      switch (status) {
        case TrashcanStatus.empty:
          return '✅';
        case TrashcanStatus.half:
          return '🟡';
        case TrashcanStatus.full:
          return '🔴';
        case TrashcanStatus.maintenance:
          return '🔧';
                      case TrashcanStatus.offline:
                        return '⚫';
                      case TrashcanStatus.alive:
                        return '🟢';
                    }
                  }

    final trashcanColor = getTrashcanColor(trashcan.status);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 550),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkGray : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: trashcanColor.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: trashcanColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: trashcanColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: trashcanColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: trashcanColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trashcan.name,
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textGray
                                    : AppTheme.lightTextPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  getStatusEmoji(trashcan.status),
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  trashcan.statusText.toUpperCase(),
                                  style: TextStyle(
                                    color: trashcanColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark
                              ? AppTheme.textGray
                              : AppTheme.lightTextPrimary,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Fill Level
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: trashcanColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: trashcanColor.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fill Level',
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.textGray
                                    : AppTheme.lightTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              trashcan.fillLevelText,
                              style: TextStyle(
                                color: trashcanColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: trashcan.fillLevel,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(trashcanColor),
                            minHeight: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Details Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildDetailItem(
                        isDark,
                        'Location',
                        trashcan.location,
                        Icons.place,
                        AppTheme.primaryGreen,
                      ),
                      _buildDetailItem(
                        isDark,
                        'Status',
                        trashcan.statusText,
                        Icons.info_outline,
                        trashcanColor,
                      ),
                      _buildDetailItem(
                        isDark,
                        'Latitude',
                        trashcan.coordinates.latitude.toStringAsFixed(6),
                        Icons.my_location,
                        AppTheme.secondaryBlue,
                      ),
                      _buildDetailItem(
                        isDark,
                        'Longitude',
                        trashcan.coordinates.longitude.toStringAsFixed(6),
                        Icons.location_on,
                        AppTheme.secondaryBlue,
                      ),
                      if (trashcan.deviceId != null)
                        _buildDetailItem(
                          isDark,
                          'Device ID',
                          trashcan.deviceId!,
                          Icons.devices,
                          AppTheme.neonPurple,
                        ),
                      if (trashcan.sensorType != null)
                        _buildDetailItem(
                          isDark,
                          'Sensor Type',
                          trashcan.sensorTypeDisplay,
                          Icons.sensors,
                          AppTheme.primaryGreen,
                        ),
                      _buildDetailItem(
                        isDark,
                        'Last Updated',
                        _formatDateTime(trashcan.lastUpdatedAt),
                        Icons.access_time,
                        AppTheme.warningOrange,
                      ),
                    ],
                  ),
                  
                  if (trashcan.notes != null && trashcan.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? AppTheme.borderColor.withOpacity(0.3) 
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark 
                              ? AppTheme.borderColor 
                              : AppTheme.lightBorder,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textGray
                                  : AppTheme.lightTextPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trashcan.notes!,
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Navigate to map location
                            setState(() => _selectedIndex = 1);
                          },
                          icon: const Icon(Icons.map, color: Colors.white),
                          label: const Text(
                            'View on Map',
                            style: TextStyle(
                              inherit: false,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => ref.invalidate(trashcansProvider),
                          icon: Icon(Icons.refresh, color: trashcanColor),
                          label: Text(
                            'Refresh',
                            style: TextStyle(
                              inherit: false,
                              color: trashcanColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: trashcanColor, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? color.withOpacity(0.15) 
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.textGray
                        : AppTheme.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showTaskDetails(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => CompletedTaskDetailsDialog(task: task),
    );
  }

  Widget _buildActualMap() {
    // Samar State University coordinates: 11.7711° N, 124.8866° E
    const ssuCenter = LatLng(11.771098490339574, 124.8865787518895);

    // Get trashcans from provider
    final trashcansAsync = ref.watch(trashcansProvider);

    return trashcansAsync.when(
      data: (trashcans) {
        print('📍 Displaying ${trashcans.length} trashcans on map');

        return FlutterMap(
          options: MapOptions(
            initialCenter: ssuCenter,
            initialZoom: 16.0,
            onTap: (tapPosition, point) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Map tapped at: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'com.example.ecowaste_manager_app',
              errorTileCallback: (tile, error, stackTrace) {
                print('Tile loading error: $error');
              },
              maxZoom: 18,
              minZoom: 1,
            ),
            // Trashcan Markers
            MarkerLayer(
              markers: trashcans
                  .map((trashcan) => Marker(
                        point: trashcan.coordinates,
                        width: 50,
                        height: 80,
                        child: _buildTrashcanMarker(trashcan),
                      ))
                  .toList(),
            ),
          ],
        );
      },
      loading: () {
        // Show map with loading indicator while fetching trashcans
        return Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: ssuCenter,
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.ecowaste_manager_app',
                  maxZoom: 18,
                  minZoom: 1,
                ),
              ],
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkGray.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryGreen),
                    SizedBox(height: 12),
                    Text(
                      'Loading trashcans...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stack) {
        // Show map with error message
        return Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: ssuCenter,
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.example.ecowaste_manager_app',
                  maxZoom: 18,
                  minZoom: 1,
                ),
              ],
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Error loading trashcans',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => ref.invalidate(trashcansProvider),
                      child: const Text('Tap to retry', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrashcanMarker(TrashcanModel trashcan) {
    Color getTrashcanColor(TrashcanStatus status) {
      switch (status) {
        case TrashcanStatus.empty:
          return AppTheme.successGreen;
        case TrashcanStatus.half:
          return AppTheme.warningOrange;
        case TrashcanStatus.full:
          return AppTheme.dangerRed;
        case TrashcanStatus.maintenance:
          return AppTheme.secondaryBlue;
        case TrashcanStatus.offline:
          return AppTheme.neutralGray;
        case TrashcanStatus.alive:
          return AppTheme.successGreen;
      }
                  }

    final markerColor = getTrashcanColor(trashcan.status);

    return GestureDetector(
      onTap: () => _showTrashcanStatusDetails(trashcan),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated marker with pulse effect
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.8, end: 1.0),
            curve: Curves.easeInOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: markerColor,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: markerColor.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Fill level indicator
                      ClipOval(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              // Fill level animation
                              TweenAnimationBuilder<double>(
                                duration: const Duration(milliseconds: 1000),
                                tween: Tween(begin: 0.0, end: trashcan.fillLevel),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Container(
                                    height: 50 * value,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Trash icon
                      Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 24,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          // Status label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: markerColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${(trashcan.fillLevel * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMapStatCard(String title, String value, IconData icon) {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? EcoGradients.glassGradient
            : EcoGradients.lightGlassGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    switch (_selectedIndex) {
      case 1:
        return _buildMapContent();
      case 2:
        return const AnalyticsPage();
      case 3:
        return const SettingsPage();
      default:
        return Center(
          child: Text(
            'Coming Soon...',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.bold,
                ),
          ),
        );
    }
  }

  Widget _buildBottomNavigation() {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard, 'Dashboard', 0),
          _buildNavItem(Icons.map, 'Map', 1),
          _buildNavItem(Icons.analytics, 'Analytics', 2),
          _buildNavItem(Icons.settings, 'Settings', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isDark = ref.watch(isDarkModeProvider);
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.neonPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? EcoShadows.neon : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary),
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppTheme.textSecondary
                        : AppTheme.lightTextSecondary),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for grid background
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryGreen.withOpacity(0.03)
      ..strokeWidth = 1.0;

    const spacing = 50.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


