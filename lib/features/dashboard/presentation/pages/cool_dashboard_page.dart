import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/models/trashcan_model.dart';
import '../../../../core/widgets/theme_toggle.dart';

class CoolDashboardPage extends ConsumerStatefulWidget {
  const CoolDashboardPage({super.key});

  @override
  ConsumerState<CoolDashboardPage> createState() => _CoolDashboardPageState();
}

class _CoolDashboardPageState extends ConsumerState<CoolDashboardPage>
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _cardAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

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
        // Animated floating orbs
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              top: 100 + (20 * _animationController.value),
              right: -50 + (30 * _animationController.value),
              child: Transform.rotate(
                angle: _animationController.value * 0.1,
                child: Container(
                  width: 200,
                  height: 200,
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
              bottom: 200 - (15 * _animationController.value),
              left: -100 + (20 * _animationController.value),
              child: Transform.rotate(
                angle: -_animationController.value * 0.15,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.secondaryBlue.withOpacity(0.08),
                        AppTheme.secondaryBlue.withOpacity(0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Additional floating elements
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              top: 300 + (40 * _animationController.value),
              left: 50 + (60 * _animationController.value),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.neonPurple.withOpacity(0.06),
                      AppTheme.neonPurple.withOpacity(0.02),
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

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Row(
        children: [
          // Profile Section with neon glow
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: EcoGradients.primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? EcoShadows.neon : EcoShadows.light,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 20),

          // Welcome Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin User',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              const AnimatedThemeToggle(),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.notifications_outlined,
                onTap: () => context.go('/notifications'),
                badge: true,
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.logout,
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
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
        child: Stack(
          children: [
            Icon(
              icon,
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
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
    return SlideTransition(
      position: _slideAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Stats Cards
            _buildQuickStats(),

            const SizedBox(height: 32),

            // Detailed Stats
            _buildDetailedStats(),

            const SizedBox(height: 32),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    // TODO: Replace with real data from API/database
    final mockTrashcans = <TrashcanModel>[];
    final totalTrashcans = mockTrashcans.length;
    final fullTrashcans =
        mockTrashcans.where((t) => t.status == TrashcanStatus.full).length;
    final emptyTrashcans =
        mockTrashcans.where((t) => t.status == TrashcanStatus.empty).length;
    final halfTrashcans =
        mockTrashcans.where((t) => t.status == TrashcanStatus.half).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total',
                value: totalTrashcans.toString(),
                icon: Icons.delete_outline,
                color: AppTheme.primaryGreen,
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Full',
                value: fullTrashcans.toString(),
                icon: Icons.warning,
                color: AppTheme.dangerRed,
                gradient: const LinearGradient(
                  colors: [AppTheme.dangerRed, Colors.redAccent],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Empty',
                value: emptyTrashcans.toString(),
                icon: Icons.check_circle,
                color: AppTheme.successGreen,
                gradient: const LinearGradient(
                  colors: [AppTheme.successGreen, Colors.greenAccent],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Half Full',
                value: halfTrashcans.toString(),
                icon: Icons.schedule,
                color: AppTheme.warningOrange,
                gradient: const LinearGradient(
                  colors: [AppTheme.warningOrange, Colors.orangeAccent],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
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
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
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
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
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

  Widget _buildDetailedStats() {
    // TODO: Replace with real data from API/database
    const activeStaff =
        0; // MockDataService.getMockUsers().where((u) => u.role == UserRole.staff).length;
    final mockTasks = <dynamic>[]; // MockDataService.getMockTasks();
    final tasksToday = mockTasks.length;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: GlassEffects.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Status',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textGray, // Black for better visibility
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Active Staff',
                  activeStaff.toString(),
                  Icons.people,
                  AppTheme.lightBlue,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Tasks Today',
                  tasksToday.toString(),
                  Icons.assignment_turned_in,
                  AppTheme.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'System Health',
                  '98%',
                  Icons.health_and_safety,
                  AppTheme.successGreen,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Uptime',
                  '99.9%',
                  Icons.timer,
                  AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
      String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textGray, // Black for better visibility
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme
                          .textSecondary, // Dark gray for secondary text
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: GlassEffects.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textGray, // Black for better visibility
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              GestureDetector(
                onTap: () => context.go('/tasks'),
                child: Text(
                  'View All',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Trashcan #001 emptied',
            '2 minutes ago',
            Icons.delete_sweep,
            AppTheme.successGreen,
          ),
          _buildActivityItem(
            'New task assigned',
            '15 minutes ago',
            Icons.assignment,
            AppTheme.secondaryBlue,
          ),
          _buildActivityItem(
            'Trashcan #003 full',
            '1 hour ago',
            Icons.warning,
            AppTheme.dangerRed,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGray, // Black for better visibility
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme
                            .textSecondary, // Dark gray for secondary text
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getPlaceholderIcon(),
            size: 64,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            _getPlaceholderTitle(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _getPlaceholderSubtitle(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
          ),
        ],
      ),
    );
  }

  IconData _getPlaceholderIcon() {
    switch (_selectedIndex) {
      case 1:
        return Icons.map;
      case 2:
        return Icons.assignment;
      case 3:
        return Icons.analytics;
      case 4:
        return Icons.person;
      default:
        return Icons.dashboard;
    }
  }

  String _getPlaceholderTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Map View';
      case 2:
        return 'Tasks';
      case 3:
        return 'Reports';
      case 4:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  String _getPlaceholderSubtitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Explore trashcan locations';
      case 2:
        return 'Manage and assign tasks';
      case 3:
        return 'View insights and analytics';
      case 4:
        return 'Manage your profile and settings';
      default:
        return 'Overview of your system';
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: GlassEffects.card,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard, 'Dashboard', 0),
          _buildNavItem(Icons.map, 'Map', 1),
          _buildNavItem(Icons.assignment, 'Tasks', 2),
          _buildNavItem(Icons.analytics, 'Reports', 3),
          _buildNavItem(Icons.person, 'Profile', 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          setState(() => _selectedIndex = index);
        } else {
          switch (index) {
            case 1:
              context.go('/map');
              break;
            case 2:
              context.go('/tasks');
              break;
            case 3:
              context.go('/reports');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? EcoGradients.primaryGradient : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? EcoShadows.neon : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

