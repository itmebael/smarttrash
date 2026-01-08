import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/smart_bin_provider.dart';
import '../../../../core/providers/staff_tasks_provider.dart';
import '../../../../core/providers/trashcan_provider.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/notification_data_service.dart';
import '../../../../core/widgets/theme_toggle.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../tasks/presentation/pages/tasks_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/notification_popup_dialog.dart';

class StaffDashboardPage extends ConsumerStatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  ConsumerState<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends ConsumerState<StaffDashboardPage>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

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
    _initializeNotifications();
  }

  void _initializeNotifications() {
    final userId = ref.read(authProvider).value?.id;
    if (userId != null) {
      print('🔔 Staff Dashboard: Initializing notifications for user: $userId');
      
      // Load existing notifications
      NotificationDataService.getAllNotifications(userId: userId).then((_) {
        print('✅ Staff Dashboard: Loaded existing notifications');
      });
      
      // Start listening for new notifications with callback
      NotificationDataService.startListening(
        userId: userId,
        onNewNotification: (notification) {
          print('🔔 Staff Dashboard: New notification received, showing popup...');
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showNotificationPopup(notification);
              }
            });
          }
        },
      );
      
      print('✅ Staff Dashboard: Notification listening started');
    } else {
      print('⚠️ Staff Dashboard: No user ID available for notifications');
    }
  }

  void _showNotificationPopup(NotificationModel notification) {
    if (!mounted) {
      print('⚠️ Staff Dashboard: Cannot show popup - widget not mounted');
      return;
    }
    
    print('📢 Staff Dashboard: Showing notification popup for: ${notification.title}');
    
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => NotificationPopupDialog(
        notification: notification,
        onDismiss: () {
          print('👆 Staff Dashboard: Notification popup dismissed');
          Navigator.of(context).pop();
        },
        onViewDetails: () {
          print('👆 Staff Dashboard: View details clicked, navigating to notifications');
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
        // Animated floating orbs with staff colors (blue theme)
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
                        AppTheme.secondaryBlue.withOpacity(0.1),
                        AppTheme.secondaryBlue.withOpacity(0.05),
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
                        AppTheme.lightBlue.withOpacity(0.08),
                        AppTheme.lightBlue.withOpacity(0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Additional floating elements with staff accent
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              top: 300 + (40 * _animationController.value),
              left: 50 + (100 * _animationController.value),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentGreen.withOpacity(0.06),
                      AppTheme.accentGreen.withOpacity(0.02),
                      Colors.transparent,
            ],
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
    final currentUserAsync = ref.watch(authProvider);
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
                    // Staff Profile Section with logo
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isDark
                            ? EcoShadows.light
                            : [
                                BoxShadow(
                                  color: AppTheme.secondaryBlue.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
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
                            'Welcome back, Staff!',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.textSecondary
                                      : AppTheme.lightTextSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                          const SizedBox(height: 2),
                          currentUserAsync.when(
                            data: (user) => Text(
                              user?.name ?? 'Staff Member',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: isDark
                                        ? AppTheme.textGray
                                        : AppTheme.lightTextPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                            ),
                            loading: () => const Text('Loading...'),
                            error: (_, __) => const Text('Staff Member'),
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
                        icon: Icons.notifications_outlined,
                        onTap: () => context.go('/notifications'),
                        badge: true,
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
                // Staff Profile Section with logo
                Container(
                  width: isMobile ? 50 : 60,
                  height: isMobile ? 50 : 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: isDark
                        ? EcoShadows.light
                        : [
                            BoxShadow(
                              color: AppTheme.secondaryBlue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                        'Welcome back, Staff!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.lightTextSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                      const SizedBox(height: 4),
                      currentUserAsync.when(
                        data: (user) => Text(
                          user?.name ?? 'Staff Member',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isDark
                                    ? AppTheme.textGray
                                    : AppTheme.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 18 : 22,
                              ),
                        ),
                        loading: () => const Text('Loading...'),
                        error: (_, __) => const Text('Staff Member'),
                      ),
                    ],
                  ),
                ),
                // Action Buttons
                Row(
                  children: [
                    const AnimatedThemeToggle(),
                    SizedBox(width: isMobile ? 8 : 12),
                    _buildHeaderButton(
                      icon: Icons.notifications_outlined,
                      onTap: () => context.go('/notifications'),
                      badge: true,
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
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
                          color: AppTheme.warningOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.warningOrange.withOpacity(0.6),
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
    
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Staff Task Overview
            _buildStaffOverview(),

            const SizedBox(height: 32),

            // My Tasks
            _buildMyTasks(),

            const SizedBox(height: 32),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffOverview() {
    final isDark = ref.watch(isDarkModeProvider);
    final currentUserAsync = ref.watch(authProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null || user.id.isEmpty) {
          return _buildStaffOverviewError();
        }
        
        // Get task stats from database
        final taskStatsAsync = ref.watch(staffTaskStatsProvider(user.id));

        return taskStatsAsync.when(
          data: (stats) {
            final pendingTasks = stats['pending'] ?? 0;
            final completedToday = stats['completedToday'] ?? 0;
            final inProgress = stats['inProgress'] ?? 0;
            final totalTasks = stats['total'] ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Work Overview',
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
                          _buildStaffStatCard(
                            title: 'Tasks Pending',
                            value: pendingTasks.toString(),
                            icon: Icons.assignment,
                            color: AppTheme.warningOrange,
                          ),
                          SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
                          _buildStaffStatCard(
                            title: 'Completed Today',
                            value: completedToday.toString(),
                            icon: Icons.check_circle,
                            color: AppTheme.successGreen,
                          ),
                          SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
                          _buildStaffStatCard(
                            title: 'In Progress',
                            value: inProgress.toString(),
                            icon: Icons.hourglass_empty,
                            color: AppTheme.secondaryBlue,
                          ),
                          SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
                          _buildStaffStatCard(
                            title: 'Total Assigned',
                            value: totalTasks.toString(),
                            icon: Icons.list_alt,
                            color: AppTheme.lightBlue,
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStaffStatCard(
                                  title: 'Tasks Pending',
                                  value: pendingTasks.toString(),
                                  icon: Icons.assignment,
                                  color: AppTheme.warningOrange,
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.getCardSpacing(context)),
                              Expanded(
                                child: _buildStaffStatCard(
                                  title: 'Completed Today',
                                  value: completedToday.toString(),
                                  icon: Icons.check_circle,
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveHelper.getCardSpacing(context)),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStaffStatCard(
                                  title: 'In Progress',
                                  value: inProgress.toString(),
                                  icon: Icons.hourglass_empty,
                                  color: AppTheme.secondaryBlue,
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.getCardSpacing(context)),
                              Expanded(
                                child: _buildStaffStatCard(
                                  title: 'Total Assigned',
                                  value: totalTasks.toString(),
                                  icon: Icons.list_alt,
                                  color: AppTheme.lightBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Work Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, stack) => _buildStaffOverviewError(),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading staff data...'),
          ],
        ),
      ),
      error: (_, __) => _buildStaffOverviewError(),
    );
  }

  Widget _buildStaffOverviewError() {
    final isDark = ref.watch(isDarkModeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Work Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Error loading task data',
            style: TextStyle(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffStatCard({
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

  Widget _buildMyTasks() {
    final isDark = ref.watch(isDarkModeProvider);
    final currentUserAsync = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Tasks',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          currentUserAsync.when(
            data: (user) {
              if (user == null || user.id.isEmpty) {
                return Center(
                  child: Text(
                    'Unable to load tasks',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                );
              }

              // Refresh tasks when user changes
              final tasksAsync = ref.watch(staffTasksProvider(user.id));

              return tasksAsync.when(
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        'No tasks assigned',
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: tasks.take(3).map((task) {
                      final title = task['title'] as String? ?? 'Untitled Task';
                      final status = task['status'] as String? ?? 'pending';
                      final trashcan = task['trashcans'] as Map<String, dynamic>?;
                      final trashcanName = trashcan?['name'] as String? ?? 'Unknown Bin';

                      Color statusColor = AppTheme.warningOrange;
                      if (status == 'completed') statusColor = AppTheme.successGreen;
                      if (status == 'in_progress') statusColor = AppTheme.secondaryBlue;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      trashcanName,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading tasks',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                'Error loading user',
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

  Widget _buildRecentActivity() {
    final isDark = ref.watch(isDarkModeProvider);
    final currentUserAsync = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          currentUserAsync.when(
            data: (user) {
              if (user == null || user.id.isEmpty) {
                return Center(
                  child: Text(
                    'Unable to load activity',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                );
              }

              final activityAsync = ref.watch(staffRecentActivityProvider(user.id));

              return activityAsync.when(
                data: (activities) {
                  if (activities.isEmpty) {
                    return Center(
                      child: Text(
                        'No recent activity',
                        style: TextStyle(
                          color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: activities.map((activity) {
                      final title = activity['title'] as String? ?? 'Activity';
                      final status = activity['status'] as String? ?? 'pending';
                      final updatedAt = activity['updated_at'] as String?;
                      final trashcan = activity['trashcans'] as Map<String, dynamic>?;
                      final trashcanName = trashcan?['name'] as String? ?? 'Unknown Bin';

                      // Format time
                      String timeAgo = 'Just now';
                      if (updatedAt != null) {
                        final date = DateTime.parse(updatedAt);
                        final now = DateTime.now();
                        final diff = now.difference(date);
                        if (diff.inMinutes < 60) {
                          timeAgo = '${diff.inMinutes}m ago';
                        } else if (diff.inHours < 24) {
                          timeAgo = '${diff.inHours}h ago';
                        } else {
                          timeAgo = '${diff.inDays}d ago';
                        }
                      }

                      Color statusColor = AppTheme.warningOrange;
                      if (status == 'completed') statusColor = AppTheme.successGreen;
                      if (status == 'in_progress') statusColor = AppTheme.secondaryBlue;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                status == 'completed'
                                    ? Icons.check_circle
                                    : status == 'in_progress'
                                        ? Icons.hourglass_empty
                                        : Icons.assignment,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    trashcanName,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeAgo,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Error loading activity',
                    style: TextStyle(
                      color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(
                'Error loading user',
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

  Widget _buildPlaceholderContent() {
    switch (_selectedIndex) {
      case 1:
        return const TasksPage();
      case 2:
        return _buildMapContent();
      case 3:
        return const ProfilePage();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildMapContent() {
    final isDark = ref.watch(isDarkModeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryGreen,
                            AppTheme.secondaryBlue
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isDark ? EcoShadows.neon : EcoShadows.light,
                      ),
                      child: const Icon(
                        Icons.map,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Samar State University Map',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.textGray
                                      : AppTheme.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View SSU campus locations and trash collection points',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? AppTheme.textSecondary
                                      : AppTheme.lightTextSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Map Container
          Container(
            height: 800,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildMapView(),
            ),
          ),

          const SizedBox(height: 24),

          // Map Controls
          Container(
            padding: const EdgeInsets.all(20),
            decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Map Controls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMapControlButton(
                        'Campus View',
                        Icons.school,
                        () => _showMapInfo('Campus View',
                            'View all campus buildings and facilities'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMapControlButton(
                        'Trash Points',
                        Icons.delete_outline,
                        () => _showMapInfo('Trash Collection Points',
                            'View all trash collection locations'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMapControlButton(
                        'Parking Areas',
                        Icons.local_parking,
                        () => _showMapInfo(
                            'Parking Areas', 'View available parking spaces'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMapControlButton(
                        'Emergency',
                        Icons.emergency,
                        () => _showMapInfo('Emergency Points',
                            'View emergency exits and stations'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SSU Campus Statistics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Buildings', '0', Icons.business),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                          'Trash Points', '0', Icons.delete_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:
                          _buildStatCard('Parking', '0', Icons.local_parking),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    final isDark = ref.watch(isDarkModeProvider);

    return Stack(
      children: [
        // Actual Map
        SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: _buildActualMap(),
        ),

        // Map Overlay Info
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkGray : Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'SSU Campus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),

        // Map Controls Overlay
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapControlOverlay(
                icon: Icons.my_location,
                onTap: () => _centerMapOnSSU(),
              ),
              const SizedBox(height: 8),
              _buildMapControlOverlay(
                icon: Icons.zoom_in,
                onTap: () => _zoomInMap(),
              ),
              const SizedBox(height: 8),
              _buildMapControlOverlay(
                icon: Icons.zoom_out,
                onTap: () => _zoomOutMap(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActualMap() {
    // Samar State University coordinates: 11.7711° N, 124.8866° E
    const ssuCenter = LatLng(11.771098490339574, 124.8865787518895);

    // Get current user
    final currentUserAsync = ref.watch(authProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null || user.id.isEmpty) {
          return _buildMapError('Unable to load user data');
        }

        // Get staff tasks to find assigned bins
        final tasksAsync = ref.watch(staffTasksProvider(user.id));

        return tasksAsync.when(
          data: (tasks) {
            // Collect assigned trashcans from tasks (only those with coordinates)
            final assignedTrashcans = <Map<String, dynamic>>[];
            for (final task in tasks) {
              final trashcan = task['trashcans'] as Map<String, dynamic>?;
              if (trashcan == null) continue;
              final lat = trashcan['latitude'];
              final lng = trashcan['longitude'];
              if (lat == null || lng == null) continue;
              assignedTrashcans.add(trashcan);
            }

            print('📍 [Staff] Showing ${assignedTrashcans.length} assigned trashcans on map');

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
                // Assigned trashcan markers
                MarkerLayer(
                  markers: assignedTrashcans.map((trashcan) {
                    final lat = double.tryParse(trashcan['latitude'].toString());
                    final lng = double.tryParse(trashcan['longitude'].toString());
                    if (lat == null || lng == null) return null;
                    final name = (trashcan['name'] ?? 'Bin').toString();
                    final status = (trashcan['status'] ?? 'unknown').toString();

                    Color color = AppTheme.warningOrange;
                    if (status == 'empty') color = AppTheme.successGreen;
                    if (status == 'full') color = AppTheme.dangerRed;
                    if (status == 'maintenance') color = AppTheme.secondaryBlue;

                    return Marker(
                      point: LatLng(lat, lng),
                      width: 50,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name • $status'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.delete,
                          color: color,
                          size: 36,
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ),
              ],
            );
          },
          loading: () => _buildMapLoading(),
          error: (error, stack) => _buildMapError('Error loading tasks'),
        );
      },
      loading: () => _buildMapLoading(),
      error: (_, __) => _buildMapError('Error loading user'),
    );
  }

  Widget _buildMapLoading() {
    const ssuCenter = LatLng(11.771098490339574, 124.8865787518895);
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
                CircularProgressIndicator(color: AppTheme.secondaryBlue),
                SizedBox(height: 12),
                Text(
                  'Loading assigned bins...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapError(String message) {
    const ssuCenter = LatLng(11.771098490339574, 124.8865787518895);
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
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    ref.invalidate(smartBinsProvider);
                    ref.invalidate(trashcansProvider);
                  },
                  child: const Text(
                    'Tap to retry',
                    style: TextStyle(
                      inherit: false,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlOverlay({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = ref.watch(isDarkModeProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkGray : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryGreen,
          size: 20,
        ),
      ),
    );
  }

  void _centerMapOnSSU() {
    // Center map on Samar State University coordinates
    // SSU coordinates: 11.7711° N, 124.8866° E
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Centering map on SSU Campus...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _zoomInMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zooming in...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _zoomOutMap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zooming out...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildMapControlButton(
      String title, IconData icon, VoidCallback onTap) {
    final isDark = ref.watch(isDarkModeProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkGray : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkGray : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryGreen,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                ),
          ),
        ],
      ),
    );
  }

  void _showMapInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(inherit: false),
            ),
          ),
        ],
      ),
    );
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
          _buildNavItem(Icons.assignment, 'Tasks', 1),
          _buildNavItem(Icons.map, 'Map', 2),
          _buildNavItem(Icons.person, 'Profile', 3),
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
                  colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.secondaryBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
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
      ..color = AppTheme.secondaryBlue.withOpacity(0.03)
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

