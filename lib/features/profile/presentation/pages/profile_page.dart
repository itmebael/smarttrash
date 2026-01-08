import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/models/user_model.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;
  File? _newProfileImage;
  bool _isUploadingImage = false;

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
                          _buildProfileCard(),
                          const SizedBox(height: 32),
                          _buildPersonalInfo(),
                          const SizedBox(height: 32),
                          _buildWorkStats(),
                          const SizedBox(height: 32),
                          _buildAccountActions(),
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
                colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isDark ? EcoShadows.light : EcoShadows.light,
            ),
            child: const Icon(
              Icons.person,
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
                  'My Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isDark
                            ? AppTheme.textGray
                            : AppTheme.lightTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                ),
                Text(
                  'Manage your account and preferences',
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

  Widget _buildProfileCard() {
    final isDark = ref.watch(isDarkModeProvider);
    final userAsync = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                'User not loaded',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            );
          }

          return Column(
            children: [
              // Profile Avatar
              GestureDetector(
                onTap: _pickProfileImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.secondaryBlue, AppTheme.lightBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.secondaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _newProfileImage != null
                            ? Image.file(
                                _newProfileImage!,
                                fit: BoxFit.cover,
                              )
                            : (user.profileImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: user.profileImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 50,
                                  )),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              Text(
                user.role.name.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : AppTheme.dangerRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: user.isActive ? AppTheme.successGreen : AppTheme.dangerRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading profile...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Error loading profile',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    final isDark = ref.watch(isDarkModeProvider);
    final userAsync = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Information',
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
                  _buildInfoItem('Email', user.email, Icons.email),
                  _buildInfoItem('Phone', user.phoneNumber.isNotEmpty ? user.phoneNumber : 'N/A', Icons.phone),
                  _buildInfoItem('Department', user.department?.isNotEmpty == true ? user.department! : 'N/A', Icons.business),
                  _buildInfoItem('Position', user.position?.isNotEmpty == true ? user.position! : 'N/A', Icons.work),
                  _buildInfoItem('Address', user.address?.isNotEmpty == true ? user.address! : 'N/A', Icons.location_on),
                  _buildInfoItem('City', user.city?.isNotEmpty == true ? user.city! : 'N/A', Icons.location_city),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: ValueKey('edit_profile_button'),
                      onPressed: () => _editProfile(),
                      icon: const Icon(Icons.edit),
                      label: Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          inherit: false,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(
                          color: Colors.white,
                          inherit: false,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(
              'Error loading data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkStats() {
    final isDark = ref.watch(isDarkModeProvider);
    final userAsync = ref.watch(authProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Work Statistics',
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
                return const Center(child: CircularProgressIndicator());
              }
              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchWorkStats(user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Text(
                      'Error loading statistics',
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
                      ),
                    );
                  }
                  
                  final stats = snapshot.data ?? {};
                  final tasksCompleted = stats['tasks_completed'] ?? 0;
                  final hoursWorked = stats['hours_worked'] ?? 0.0;
                  final efficiencyRate = stats['efficiency_rate'] ?? 0.0;
                  final rating = stats['rating'] ?? 0.0;
                  
                  return Column(
                    children: [
                      Row(
                        key: ValueKey('stats_row_1_${user.id}'),
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Tasks Completed',
                              tasksCompleted.toString(),
                              Icons.check_circle,
                              AppTheme.successGreen,
                              key: ValueKey('tasks_completed_${user.id}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Hours Worked',
                              hoursWorked.toStringAsFixed(1),
                              Icons.schedule,
                              AppTheme.secondaryBlue,
                              key: ValueKey('hours_worked_${user.id}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        key: ValueKey('stats_row_2_${user.id}'),
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Efficiency Rate',
                              '${efficiencyRate.toStringAsFixed(1)}%',
                              Icons.trending_up,
                              AppTheme.primaryGreen,
                              key: ValueKey('efficiency_rate_${user.id}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              key: ValueKey('rating_card_${user.id}'),
                              onTap: () {
                                // Only admins can rate staff
                                final currentUser = ref.read(authProvider).value;
                                if (currentUser?.isAdmin == true && user.role == UserRole.staff) {
                                  _showRatingDialog(user.id, user.name, rating);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: _buildStatCard(
                                'Rating',
                                '${rating.toStringAsFixed(1)}/5',
                                Icons.star,
                                AppTheme.warningOrange,
                                key: ValueKey('rating_stat_${user.id}'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Text(
              'Error loading statistics',
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    Key? key,
  }) {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? EcoGradients.glassGradient
            : EcoGradients.lightGlassGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondary
                      : AppTheme.lightTextSecondary,
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildAccountActions() {
    final isDark = ref.watch(isDarkModeProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: isDark ? GlassEffects.card : GlassEffects.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Actions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 20),
          _buildActionItem(
            'Edit Profile',
            'Update your personal info',
            Icons.edit,
            _editProfile,
          ),
          _buildActionItem(
            'Help & Support',
            'Get help or contact support',
            Icons.help,
            () => _showHelp(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    final isDark = ref.watch(isDarkModeProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.secondaryBlue,
              size: 16,
            ),
          ),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color:
                        isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }


  Widget _buildActionItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    final isDark = ref.watch(isDarkModeProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isDark
                ? EcoGradients.glassGradient
                : EcoGradients.lightGlassGradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.borderColor : AppTheme.lightBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.secondaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
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
                        fontSize: 14,
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
              Icon(
        Icons.arrow_forward_ios,
        size: 16,
                color: isDark
                    ? AppTheme.textSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
      );
      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(String userId) async {
    if (_newProfileImage == null) return null;

    try {
      setState(() => _isUploadingImage = true);
      final bytes = await _newProfileImage!.readAsBytes();
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to upload image: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _editProfile() {
    final user = ref.read(authProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load user'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final deptController = TextEditingController(text: user.department ?? '');
    final positionController = TextEditingController(text: user.position ?? '');
    final addressController = TextEditingController(text: user.address ?? '');
    final cityController = TextEditingController(text: user.city ?? '');
    final stateController = TextEditingController(text: user.state ?? '');
    final zipController = TextEditingController(text: user.zipCode ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = ref.watch(isDarkModeProvider);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkGray : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Profile',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark
                              ? AppTheme.textGray
                              : AppTheme.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        ClipOval(
                          child: SizedBox(
                            width: 110,
                            height: 110,
                            child: _newProfileImage != null
                                ? Image.file(
                                    _newProfileImage!,
                                    fit: BoxFit.cover,
                                  )
                                : (user.profileImageUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: user.profileImageUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) =>
                                            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        errorWidget: (_, __, ___) => Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.person, size: 48),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.person,
                                          size: 48,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _isUploadingImage ? null : _pickProfileImage,
                          icon: const Icon(Icons.photo_camera),
                          label: Text(
                            _isUploadingImage ? 'Uploading...' : 'Change photo',
                            style: TextStyle(inherit: false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('Full Name', nameController),
                  _buildTextField('Phone Number', phoneController,
                      keyboardType: TextInputType.phone),
                  _buildTextField('Department', deptController),
                  _buildTextField('Position', positionController),
                  _buildTextField('Address', addressController),
                  _buildTextField('City', cityController),
                  _buildTextField('State', stateController),
                  _buildTextField('ZIP Code', zipController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saving profile...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        String? uploadedUrl;
                        if (_newProfileImage != null) {
                          uploadedUrl = await _uploadProfileImage(user.id);
                        }
                        await ref.read(authProvider.notifier).updateProfile(
                              name: nameController.text.trim(),
                              phoneNumber: phoneController.text.trim(),
                              profileImageUrl: uploadedUrl,
                              department: deptController.text.trim().isEmpty
                                  ? null
                                  : deptController.text.trim(),
                              position: positionController.text.trim().isEmpty
                                  ? null
                                  : positionController.text.trim(),
                              address: addressController.text.trim().isEmpty
                                  ? null
                                  : addressController.text.trim(),
                              city: cityController.text.trim().isEmpty
                                  ? null
                                  : cityController.text.trim(),
                              province: stateController.text.trim().isEmpty
                                  ? null
                                  : stateController.text.trim(),
                              zipCode: zipController.text.trim().isEmpty
                                  ? null
                                  : zipController.text.trim(),
                            );
                        if (uploadedUrl != null) {
                          setState(() {
                            _newProfileImage = null;
                          });
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated'),
                            backgroundColor: AppTheme.successGreen,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          inherit: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    final isDark = ref.watch(isDarkModeProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor:
              isDark ? AppTheme.backgroundGreen.withOpacity(0.1) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }


  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('Contact support for assistance'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(inherit: false),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchWorkStats(String userId) async {
    try {
      // Use Supabase RPC function to get work statistics
      final response = await _supabase.rpc(
        'get_work_statistics',
        params: {'p_user_id': userId},
      );
      
      if (response == null) {
        throw Exception('No data returned from function');
      }
      
      // Parse the JSON response
      final stats = response as Map<String, dynamic>;
      
      return {
        'tasks_completed': (stats['tasks_completed'] as num?)?.toInt() ?? 0,
        'hours_worked': (stats['hours_worked'] as num?)?.toDouble() ?? 0.0,
        'efficiency_rate': (stats['efficiency_rate'] as num?)?.toDouble() ?? 0.0,
        'rating': (stats['rating'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      print('Error fetching work stats: $e');
      // Fallback to default values if function doesn't exist yet
      return {
        'tasks_completed': 0,
        'hours_worked': 0.0,
        'efficiency_rate': 0.0,
        'rating': 0.0,
      };
    }
  }

  void _showRatingDialog(String staffId, String staffName, double currentRating) {
    double selectedRating = currentRating;
    
    showDialog(
      context: context,
      builder: (context) {
        final isDark = ref.watch(isDarkModeProvider);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Rate Staff Member'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rate $staffName',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final rating = index + 1.0;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedRating = rating;
                        });
                      },
                      child: Icon(
                        rating <= selectedRating ? Icons.star : Icons.star_border,
                        color: AppTheme.warningOrange,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  '${selectedRating.toStringAsFixed(1)} / 5.0',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textGray : AppTheme.lightTextPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(inherit: false),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateStaffRating(staffId, selectedRating);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rating updated to ${selectedRating.toStringAsFixed(1)}/5'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                    // Refresh the page
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Save Rating',
                  style: TextStyle(
                    color: Colors.white,
                    inherit: false,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateStaffRating(String staffId, double rating) async {
    try {
      // Try using the SQL function first (if it exists)
      try {
        await _supabase.rpc(
          'update_staff_rating',
          params: {
            'p_staff_id': staffId,
            'p_rating': rating,
          },
        );
      } catch (rpcError) {
        // Fallback to direct update if function doesn't exist
        print('RPC function not available, using direct update: $rpcError');
        await _supabase
            .from('users')
            .update({'rating': rating})
            .eq('id', staffId);
      }
    } catch (e) {
      print('Error updating rating: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating rating: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }
}

