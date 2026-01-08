import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'sidebar_navigation.dart';

class ResponsiveLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  ConsumerState<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends ConsumerState<ResponsiveLayout> {
  bool _isMobile = false;
  bool _showSidebar = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isMobile = MediaQuery.of(context).size.width < 768;
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return _buildMobileLayout();
    } else {
      return SidebarNavigation(
        currentRoute: widget.currentRoute,
        child: widget.child,
      );
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            widget.child,
            if (_showSidebar)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: SidebarNavigation(
                        currentRoute: widget.currentRoute,
                        child: const SizedBox.shrink(),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showSidebar = false;
                          });
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('EcoWaste Manager'),
        backgroundColor: const Color(0xFF1a237e),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              _showSidebar = !_showSidebar;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pushNamed('/notifications');
              } else {
                try {
                  GoRouter.of(context).go('/notifications');
                } catch (_) {
                  Navigator.of(context).pushNamed('/notifications');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

