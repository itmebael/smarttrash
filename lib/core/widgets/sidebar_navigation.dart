import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class SidebarNavigation extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const SidebarNavigation({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends ConsumerState<SidebarNavigation> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.when(
      data: (user) => user,
      loading: () => null,
      error: (_, __) => null,
    );
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 280,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.darkBlue, Color(0xFF1a237e)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildHeader(user, isAdmin),
                    Expanded(child: _buildNavigationItems(isAdmin)),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color(0xFFf8f9fa),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(user, bool isAdmin) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80, maxHeight: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          bottom:
              BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.eco, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('EcoWaste',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis),
                    Text('Manager',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          if (user != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        color: Colors.white,
                        size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis),
                        const Text('Administrator',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationItems(bool isAdmin) {
    final navigationItems = _getNavigationItems(isAdmin);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: navigationItems.length,
      itemBuilder: (context, index) {
        final item = navigationItems[index];
        final isSelected = widget.currentRoute == item.route;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToRoute(item.route),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40, maxHeight: 48),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isSelected
                      ? Border.all(color: Colors.white.withOpacity(0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(item.icon,
                        color: isSelected ? Colors.white : Colors.white70,
                        size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppTheme.dangerRed,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFooterItem(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () => context.go('/settings')),
          const SizedBox(height: 4),
          _buildFooterItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => _showLogoutDialog(),
              isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32, maxHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(icon,
                  color: isDestructive ? AppTheme.dangerRed : Colors.white70,
                  size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDestructive ? AppTheme.dangerRed : Colors.white70,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<NavigationItem> _getNavigationItems(bool isAdmin) {
    final items = <NavigationItem>[
      NavigationItem(
          icon: Icons.dashboard,
          title: 'Dashboard',
          route: isAdmin ? '/dashboard' : '/staff-dashboard'),
      const NavigationItem(icon: Icons.map, title: 'Map View', route: '/map'),
      const NavigationItem(
          icon: Icons.assignment, title: 'Tasks', route: '/tasks', badge: '3'),
      const NavigationItem(
          icon: Icons.notifications,
          title: 'Notifications',
          route: '/notifications',
          badge: '5'),
      const NavigationItem(
          icon: Icons.analytics, title: 'Reports', route: '/reports'),
    ];

    if (isAdmin) {
      items.insert(
          2,
          const NavigationItem(
              icon: Icons.people,
              title: 'Staff Management',
              route: '/staff-management'));
    }

    items.add(const NavigationItem(
        icon: Icons.person, title: 'Profile', route: '/profile'));
    return items;
  }

  void _navigateToRoute(String route) {
    if (route != widget.currentRoute) {
      context.go(route);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerRed,
                foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String title;
  final String route;
  final String? badge;

  const NavigationItem({
    required this.icon,
    required this.title,
    required this.route,
    this.badge,
  });
}

