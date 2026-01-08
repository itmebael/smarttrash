import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/navigation_helper.dart';

class CreateStaffAccountPage extends ConsumerStatefulWidget {
  const CreateStaffAccountPage({super.key});

  @override
  ConsumerState<CreateStaffAccountPage> createState() =>
      _CreateStaffAccountPageState();
}

class _CreateStaffAccountPageState
    extends ConsumerState<CreateStaffAccountPage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkModeProvider);

    return WillPopScope(
      onWillPop: () async {
        // Handle hardware back button - go to dashboard instead of popping
        NavigationHelper.navigateToDashboard(context, ref);
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? EcoGradients.backgroundGradient
                : EcoGradients.lightBackgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: Center(
                    child: _buildCoolPopupCard(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoolPopupCard(bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.darkGray,
                        AppTheme.backgroundGreen.withOpacity(0.8),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppTheme.lightGreen.withOpacity(0.3),
                      ],
                    ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: _buildCreateAccountForm(isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.darkGray.withOpacity(0.5)
                  : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: IconButton(
              onPressed: () => NavigationHelper.navigateToDashboard(context, ref),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Staff Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                ),
                Text(
                  'Add a new team member',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }

  Widget _buildCreateAccountForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfilePictureSection(isDark),
            const SizedBox(height: 24),
            _buildFormCard(
              title: 'Personal Information',
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter staff full name',
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter email address',
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  isDark: isDark,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFormCard(
              title: 'Work Information',
              children: [
                _buildTextField(
                  controller: _departmentController,
                  label: 'Department',
                  hint: 'Enter department',
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter department';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _positionController,
                  label: 'Position',
                  hint: 'Enter position',
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter position';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFormCard(
              title: 'Account Security',
              children: [
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter password',
                  isDark: isDark,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm password',
                  isDark: isDark,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildCreateButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(bool isDark) {
    return Center(
      child: Column(
        children: [
          Text(
            'Profile Picture (Optional)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _profileImage == null
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.accentGreen,
                          AppTheme.lightGreen,
                        ],
                      )
                    : null,
                border: Border.all(
                  color: AppTheme.primaryGreen,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: _profileImage != null
                  ? ClipOval(
                      child: Image.file(
                        _profileImage!,
                        width: 140,
                        height: 140,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_a_photo_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap to Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profileImage == null
                ? 'Upload a profile picture'
                : 'Tap to change picture',
            style: TextStyle(
              color:
                  isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(
            color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color:
                  isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
            fillColor: isDark
                ? AppTheme.backgroundGreen.withOpacity(0.1)
                : AppTheme.lightBackground.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.accentGreen,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _createStaffAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Create Staff Account',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
    }
  }

  Future<void> _createStaffAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
              ),
              SizedBox(height: 16),
              Text(
                'Creating staff account...',
                style: TextStyle(
                  color: AppTheme.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    String? createdUserId;
    bool accountSaved = false;
    
    try {
      final authNotifier = ref.read(authProvider.notifier);

      // Create the auth user (role staff) + insert into public.users
      try {
        final success = await authNotifier.registerStaff(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
        );

        if (success) {
          createdUserId = _supabase.auth.currentUser?.id;
          accountSaved = createdUserId != null;
        }
      } catch (e) {
        // Check if user was actually created despite the error
        print('⚠️ Error during registerStaff, checking if user was created: $e');
        createdUserId = _supabase.auth.currentUser?.id;
        
        // Verify user exists in database
        if (createdUserId != null) {
          try {
            final userCheck = await _supabase
                .from('users')
                .select('id')
                .eq('id', createdUserId)
                .maybeSingle();
            accountSaved = userCheck != null;
            print('✅ User found in database: $accountSaved');
          } catch (_) {
            // If we can't check, assume it might be saved
            accountSaved = true;
          }
        }
      }

      // If account was saved, continue with profile updates
      if (accountSaved && createdUserId != null) {
        try {
          // Upload profile image if provided
          final profileUrl = await _uploadProfileImage(createdUserId);

          // Update extra profile fields in public.users
          await _supabase.from('users').update({
            'department': _departmentController.text.trim(),
            'position': _positionController.text.trim(),
            'phone_number': _phoneController.text.trim(),
            if (profileUrl != null) 'profile_image_url': profileUrl,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', createdUserId);
        } catch (e) {
          print('⚠️ Error updating profile fields (non-critical): $e');
          // Continue anyway - account is saved
        }

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Success message - account was saved
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Staff Account Created Successfully!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Email: ${_emailController.text.trim()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const Text(
                          'Ask the staff to log in with this email & password.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        // Sign out to avoid switching current session to the new staff user
        try {
          await _supabase.auth.signOut(scope: SignOutScope.global);
        } catch (e) {
          print('⚠️ Error signing out (non-critical): $e');
        }
        
        if (mounted) {
          NavigationHelper.navigateToDashboard(context, ref);
        }
        return; // Success - exit early
      }

      // If we get here, account was NOT saved
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog('Failed to create staff account. Please check your connection and try again.');
      
    } catch (e) {
      print('❌ Unexpected error: $e');
      
      // Final check - verify if account was actually saved
      if (createdUserId == null) {
        createdUserId = _supabase.auth.currentUser?.id;
      }
      
      if (createdUserId != null) {
        try {
          final userCheck = await _supabase
              .from('users')
              .select('id')
              .eq('id', createdUserId)
              .maybeSingle();
          
          if (userCheck != null) {
            // Account was saved! Show success instead of error
            if (mounted) Navigator.of(context).pop();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Staff Account Created Successfully!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Email: ${_emailController.text.trim()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.successGreen,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
            try {
              await _supabase.auth.signOut(scope: SignOutScope.global);
            } catch (_) {}
            if (mounted) {
              NavigationHelper.navigateToDashboard(context, ref);
            }
            return; // Success despite error
          }
        } catch (_) {
          // Couldn't verify - show error
        }
      }
      
      // Account was not saved - show error
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Error creating staff account: $e');
      }
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    try {
      if (_profileImage == null) return null;

      final bytes = await _profileImage!.readAsBytes();
      final fileName =
          'users/$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

      await _supabase.storage.from('profile_images').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final publicUrl =
          _supabase.storage.from('profile_images').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      print('⚠️  Profile image upload failed: $e');
      return null;
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to Create Staff Account',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      message.contains('already registered') || message.contains('already exists')
                          ? 'Email already exists'
                          : 'Please check your connection and try again',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.dangerRed,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

}


















