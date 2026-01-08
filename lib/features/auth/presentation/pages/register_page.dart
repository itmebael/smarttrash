import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/eco_button.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.staff;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            role: _selectedRole,
          );

      if (success && mounted) {
        final user = ref.read(currentUserProvider);
        if (user != null) {
          if (user.isAdmin) {
            context.go('/dashboard');
          } else {
            context.go('/staff-dashboard');
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: EcoGradients.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: EcoShadows.medium,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Join EcoWaste Manager',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your account to get started',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.neutralGray,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Registration Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: EcoShadows.medium,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name Field
                        AuthTextField(
                          controller: _nameController,
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icons.person_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            if (value.length < 2) {
                              return 'Name must be at least 2 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Email Field
                        AuthTextField(
                          controller: _emailController,
                          labelText: 'Email Address',
                          hintText: 'Enter your email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Phone Field
                        AuthTextField(
                          controller: _phoneController,
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.length < 10) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Role Selection
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.neutralGray.withOpacity(0.3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<UserRole>(
                              value: _selectedRole,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down),
                              items: UserRole.values.map((UserRole role) {
                                return DropdownMenuItem<UserRole>(
                                  value: role,
                                  child: Text(
                                    role == UserRole.admin ? 'Admin' : 'Staff',
                                    style: const TextStyle(
                                      color: AppTheme.darkGray,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (UserRole? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedRole = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Field
                        AuthTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          obscureText: !_isPasswordVisible,
                          prefixIcon: Icons.lock_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.neutralGray,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
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

                        const SizedBox(height: 16),

                        // Confirm Password Field
                        AuthTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          hintText: 'Confirm your password',
                          obscureText: !_isConfirmPasswordVisible,
                          prefixIcon: Icons.lock_outlined,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.neutralGray,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Register Button
                        EcoButton(
                          onPressed: _isLoading ? null : _handleRegister,
                          text: 'Create Account',
                          isLoading: _isLoading,
                          icon: Icons.person_add,
                        ),

                        const SizedBox(height: 16),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.neutralGray),
                            ),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

