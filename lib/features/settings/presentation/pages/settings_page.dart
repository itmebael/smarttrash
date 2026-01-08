import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/navigation_helper.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _notificationsEnabled = true;
  double _alertThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSystemSettings(),
                          const SizedBox(height: 32),
                          _buildNotificationSettings(),
                          const SizedBox(height: 32),
                          _buildAccountSettings(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.neonPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? EcoShadows.neon : EcoShadows.light,
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                ),
                Text(
                  'Configure system preferences and options',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppTheme.textSecondary
                            : AppTheme.lightTextSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemSettings() {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Configuration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 20),
          _buildSettingItem(
            'Dark Mode',
            'Enable dark theme for better visibility',
            Icons.dark_mode,
            Switch(
              value: isDark,
              onChanged: (value) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              activeColor: AppTheme.primaryGreen,
            ),
          ),
          _buildSettingItem(
            'Alert Threshold',
            'Trashcan fill level alert percentage',
            Icons.warning,
            Text('${_alertThreshold.toInt()}%'),
          ),
          _buildSliderSetting(
            'Alert Threshold',
            'Set the fill level percentage for alerts',
            Icons.warning,
            _alertThreshold,
            50.0,
            100.0,
            (value) => setState(() => _alertThreshold = value),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 20),
          _buildSettingItem(
            'Push Notifications',
            'Receive alerts for system events',
            Icons.notifications,
            Switch(
              value: _notificationsEnabled,
              onChanged: (value) =>
                  setState(() => _notificationsEnabled = value),
              activeColor: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    final isDark = ref.watch(isDarkModeProvider);
    final userAsync = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 20),
          userAsync.when(
            data: (user) {
              if (user == null) {
                return Text(
                  'User not loaded',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                  ),
                );
              }

              return Column(
                children: [
                  _buildSettingItem(
                    'Account Type',
                    'User role in system',
                    Icons.admin_panel_settings,
                    Text(
                      user.role.name.toUpperCase(),
                      style: TextStyle(
                        color: user.isAdmin ? AppTheme.primaryGreen : AppTheme.secondaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _buildSettingItem(
                    'Email',
                    'Primary contact email',
                    Icons.email,
                    Text(
                      user.email,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  _buildSettingItem(
                    'Name',
                    'Account name',
                    Icons.person,
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  _buildSettingItem(
                    'Status',
                    'Account status',
                    Icons.check_circle,
                    Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: user.isActive ? AppTheme.successGreen : AppTheme.dangerRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(
              'Error loading account data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    Widget trailing,
  ) {
    final isDark = ref.watch(isDarkModeProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
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
          trailing,
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    final isDark = ref.watch(isDarkModeProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
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
              Text(
                '${value.toInt()}%',
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
            inactiveColor: AppTheme.primaryGreen.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}

