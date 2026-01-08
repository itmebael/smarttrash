import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      imageAsset: 'assets/images/logo.jpg',
      title: 'Track Waste Bins',
      description:
          'Monitor all waste bins across campus in real-time. Know exactly when bins need attention.',
      color: AppTheme.primaryGreen,
    ),
    OnboardingSlide(
      icon: Icons.sensors_rounded,
      title: 'Real-time Monitoring',
      description:
          'Get instant updates on bin fill levels and status. Smart sensors keep you informed 24/7.',
      color: AppTheme.warningOrange,
    ),
    OnboardingSlide(
      icon: Icons.rocket_launch_rounded,
      title: 'Get Started',
      description:
          'Join the smart waste management revolution. Sign in to manage your eco-friendly campus.',
      color: AppTheme.primaryGreen,
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _skipToLogin() {
    _navigateToLogin();
  }

  void _navigateToLogin() {
    context.pushReplacement('/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppTheme.backgroundGreen,
                    AppTheme.darkGray,
                    AppTheme.backgroundGreen,
                  ]
                : [
                    AppTheme.lightBackground,
                    AppTheme.lightGreen,
                    AppTheme.lightBackground,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topRight,
                  child: _currentPage < _slides.length - 1
                      ? TextButton(
                          onPressed: _skipToLogin,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.lightTextSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : const SizedBox(height: 48),
                ),
              ),

              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index], isDark);
                  },
                ),
              ),

              // Page Indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => _buildPageIndicator(index, isDark),
                  ),
                ),
              ),

              // Next/Get Started Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage < _slides.length - 1
                              ? 'Next'
                              : 'Get Started',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _currentPage < _slides.length - 1
                              ? Icons.arrow_forward_rounded
                              : Icons.login_rounded,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon or Image
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.color.withOpacity(0.1),
              border: Border.all(
                color: slide.color.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: slide.imageAsset != null
                ? ClipOval(
                    child: Image.asset(
                      slide.imageAsset!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    slide.icon,
                    size: 80,
                    color: slide.color,
                  ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            ),
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: isDark
                  ? AppTheme.textSecondary
                  : AppTheme.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index, bool isDark) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 32 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryGreen
            : isDark
                ? AppTheme.textSecondary.withOpacity(0.3)
                : AppTheme.lightTextSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingSlide {
  final IconData? icon;
  final String? imageAsset;
  final String title;
  final String description;
  final Color color;

  OnboardingSlide({
    this.icon,
    this.imageAsset,
    required this.title,
    required this.description,
    required this.color,
  });
}

