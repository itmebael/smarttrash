import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/user_model.dart';

class CoolLoginPage extends ConsumerStatefulWidget {
  const CoolLoginPage({super.key});

  @override
  ConsumerState<CoolLoginPage> createState() => _CoolLoginPageState();
}

class _CoolLoginPageState extends ConsumerState<CoolLoginPage> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'CoolLoginForm');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('=== LOGIN PAGE START ===');
      print('Email: ${_emailController.text.trim()}');
      print('Password: ${_passwordController.text}');

      final success = await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);

      print('Login result from provider: $success');

      // Check current auth state
      final currentAuthState = ref.read(authProvider);
      print('Current auth state after login: $currentAuthState');

      if (!success && mounted) {
        print('Login failed - auth state listener will handle error display');
      } else {
        print('Login succeeded - auth state listener should handle navigation');
      }
      // Auth state listener will handle successful login navigation
    } catch (e) {
      print('Login exception: $e');
      if (mounted) {
        _showErrorSnackBar('Login error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('=== LOGIN PAGE END ===');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    // Listen to auth state changes
    ref.listen<AsyncValue<UserModel?>>(authProvider, (previous, next) {
      print('=== AUTH STATE LISTENER ===');
      print('Previous state: $previous');
      print('Next state: $next');

      next.when(
        data: (user) {
          print('Auth state data: user = $user');
          if (user != null && mounted) {
            print('✅ User logged in: ${user.name} (${user.role})');
            
            // Use post frame callback to ensure navigation happens after build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                print('🚀 Navigating to dashboard...');
                final route = user.isAdmin ? '/dashboard' : '/staff-dashboard';
                print('📍 Target route: $route');
                context.pushReplacement(route);
              }
            });
          } else {
            print('⚠️ User is null or widget not mounted');
          }
        },
        loading: () {
          print('⏳ Auth state loading...');
        },
        error: (error, stackTrace) {
          print('❌ Auth state error: $error');
          if (mounted) {
            _showErrorSnackBar('Login failed: ${error.toString()}');
          }
        },
      );
      print('=== AUTH STATE LISTENER END ===');
    });

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundGreen : AppTheme.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'EcoWaste Manager',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: isDark
                                    ? AppTheme.textGray
                                    : AppTheme.lightTextPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'SSU Smart Trash Management',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.lightTextSecondary,
                          ),
                    ),

                    const SizedBox(height: 48),

                    // Login Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkGray : Colors.white,
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
                        border: isDark
                            ? Border.all(
                                color: AppTheme.borderColor,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'Enter your email',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  key: const ValueKey(
                                      'password_visibility_toggle'),
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Login Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Login'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

