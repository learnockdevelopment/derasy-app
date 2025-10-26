import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_storage_service.dart';
import '../../services/user_profile_service.dart';
import '../widgets/safe_network_image.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? _userData;
  bool _isEditing = false;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _avatarController = TextEditingController();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print('👤 [USER PROFILE] ===========================================');
    print(
        '👤 [USER PROFILE] Profile page initialized - calling _loadUserData()');
    print('👤 [USER PROFILE] ===========================================');
    // Load data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when page becomes visible
    print('👤 [USER PROFILE] didChangeDependencies called - refreshing data');
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    print('👤 [USER PROFILE] ===========================================');
    print('👤 [USER PROFILE] _loadUserData() method called');
    print('👤 [USER PROFILE] ===========================================');
    try {
      print('👤 [USER PROFILE] ===========================================');
      print('👤 [USER PROFILE] Starting to load user data from API...');

      // First try to get data from API
      final apiResponse = await UserProfileService.getCurrentUserProfile();

      // Print detailed API response
      print('👤 [USER PROFILE] ===========================================');
      print('👤 [USER PROFILE] API Response received:');
      print('👤 [USER PROFILE] Response type: ${apiResponse.runtimeType}');
      print('👤 [USER PROFILE] Response keys: ${apiResponse.keys.toList()}');
      print('👤 [USER PROFILE] Full API response: $apiResponse');
      print('👤 [USER PROFILE] ===========================================');

      if (apiResponse.containsKey('user')) {
        final userData = apiResponse['user'] as Map<String, dynamic>;
        print('👤 [USER PROFILE] User data from API:');
        print('👤 [USER PROFILE] User ID: ${userData['id']}');
        print('👤 [USER PROFILE] Name: ${userData['name']}');
        print('👤 [USER PROFILE] Email: ${userData['email']}');
        print('👤 [USER PROFILE] Phone: ${userData['phone']}');
        print('👤 [USER PROFILE] Role: ${userData['role']}');
        print('👤 [USER PROFILE] Avatar: ${userData['avatar']}');
        print('👤 [USER PROFILE] Email Verified: ${userData['emailVerified']}');
        print('👤 [USER PROFILE] All API keys: ${userData.keys.toList()}');

        setState(() {
          _userData = userData;
        });

        // Populate controllers for editing
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
        _avatarController.text = userData['avatar'] ?? '';
      } else {
        // Fallback to local storage if API doesn't return user data
        print(
            '👤 [USER PROFILE] No user data in API response, trying local storage...');
        final localData = await UserStorageService.getUserData();
        print('👤 [USER PROFILE] Local storage data: $localData');

        setState(() {
          _userData = localData;
        });
      }
    } catch (e) {
      print('👤 [USER PROFILE] ===========================================');
      print('👤 [USER PROFILE] ERROR loading user data from API: $e');
      print('👤 [USER PROFILE] Error type: ${e.runtimeType}');
      print('👤 [USER PROFILE] Stack trace: ${StackTrace.current}');
      print('👤 [USER PROFILE] Falling back to local storage...');
      print('👤 [USER PROFILE] ===========================================');

      try {
        final localData = await UserStorageService.getUserData();
        print('👤 [USER PROFILE] Local storage fallback data: $localData');

        setState(() {
          _userData = localData;
        });
      } catch (localError) {
        print(
            '👤 [USER PROFILE] Error loading from local storage: $localError');
        Get.snackbar(
          'Error',
          'Failed to load user data: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Name and phone are required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll use the existing avatar URL or empty string
      // In a real app, you'd upload the image to a server and get a URL
      String? avatarUrl = _userData?['avatar'];
      if (_selectedImage != null) {
        // TODO: Upload image to server and get URL
        // For now, we'll keep the existing avatar
        print(
            '👤 [USER PROFILE] Image selected but not uploaded yet: ${_selectedImage!.path}');
      }

      final response = await UserProfileService.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatar: avatarUrl,
      );

      print('👤 [USER PROFILE] Update response: $response');

      if (response.containsKey('user')) {
        final updatedUser = response['user'] as Map<String, dynamic>;
        setState(() {
          _userData = updatedUser;
          _isEditing = false;
        });

        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('👤 [USER PROFILE] Error updating profile: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        print('👤 [USER PROFILE] Image selected: ${image.path}');
      }
    } catch (e) {
      print('👤 [USER PROFILE] Error picking image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers to original values
        _nameController.text = _userData?['name'] ?? '';
        _phoneController.text = _userData?['phone'] ?? '';
        _avatarController.text = _userData?['avatar'] ?? '';
        _selectedImage = null; // Reset selected image
      }
    });
  }

  Future<void> _logout() async {
    try {
      await UserStorageService.clearUserData();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('👤 [USER PROFILE] ===========================================');
    print('👤 [USER PROFILE] Profile page build() method called');
    print('👤 [USER PROFILE] _userData is null: ${_userData == null}');
    print('👤 [USER PROFILE] ===========================================');
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            elevation: 0,
            automaticallyImplyLeading: false, // Remove back button
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
                onPressed: _isLoading ? null : _toggleEdit,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            // User Avatar with Image
                            _buildUserAvatar(),
                            SizedBox(width: 16.w),
                            // User Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userData?['name'] ?? 'User',
                                    style: AppFonts.h2.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20.sp,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    _userData?['email'] ?? 'user@example.com',
                                    style: AppFonts.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14.sp,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      _userData?['role']
                                              ?.toString()
                                              .toUpperCase() ??
                                          'USER',
                                      style: AppFonts.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10.sp,
                                      ),
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
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // User Information Section
                  _buildUserInfoSection(),
                  SizedBox(height: 16.h),

                  // Account Settings Section
                  _buildAccountSettingsSection(),
                  SizedBox(height: 16.h),

                  // Logout Button
                  _buildLogoutButton(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: const Color(0xFF3B82F6),
                size: 22.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Personal Information',
                style: AppFonts.h3.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Editable fields when in edit mode
          if (_isEditing) ...[
            _buildEditableField(
                'Full Name', _nameController, Icons.person_rounded),
            SizedBox(height: 16.h),
            _buildEditableField('Phone', _phoneController, Icons.phone_rounded),
            SizedBox(height: 16.h),
            _buildAvatarField(),
            SizedBox(height: 20.h),
            _buildSaveCancelButtons(),
          ] else ...[
            // Display mode
            _buildInfoRow(
                'Full Name', _userData?['name'] ?? 'N/A', Icons.person_rounded),
            SizedBox(height: 12.h),
            _buildInfoRow(
                'Email', _userData?['email'] ?? 'N/A', Icons.email_rounded),
            SizedBox(height: 12.h),
            _buildInfoRow(
                'Phone', _userData?['phone'] ?? 'N/A', Icons.phone_rounded),
            SizedBox(height: 12.h),
            _buildInfoRow('Role', _userData?['role'] ?? 'N/A',
                Icons.admin_panel_settings_rounded),
            SizedBox(height: 12.h),
            _buildInfoRow(
                'User ID', _userData?['id'] ?? 'N/A', Icons.badge_rounded),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountSettingsSection() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: const Color(0xFF10B981),
                size: 22.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Account Settings',
                style: AppFonts.h3.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              Get.snackbar(
                'Info',
                'Notifications settings coming soon',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF3B82F6),
                colorText: Colors.white,
              );
            },
          ),
          SizedBox(height: 12.h),
          _buildSettingsTile(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Manage your privacy and security settings',
            onTap: () {
              Get.snackbar(
                'Info',
                'Privacy settings coming soon',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF3B82F6),
                colorText: Colors.white,
              );
            },
          ),
          SizedBox(height: 12.h),
          _buildSettingsTile(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'Change your preferred language',
            onTap: () {
              Get.snackbar(
                'Info',
                'Language settings coming soon',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF3B82F6),
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEF4444),
            Color(0xFFDC2626),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Logout',
                  style: AppFonts.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6B7280),
            size: 20.sp,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.labelSmall.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: AppFonts.bodyMedium.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3B82F6),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.bodyMedium.copyWith(
                        color: const Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: AppFonts.bodySmall.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: const Color(0xFF9CA3AF),
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    // Get user image from user data
    String? imageUrl = _userData?['avatar'] ??
        _userData?['profileImage'] ??
        _userData?['image'];

    return Container(
      width: 80.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.r),
        child: SafeAvatarImage(
          imageUrl: imageUrl,
          size: 80,
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      ),
    );
  }

  Widget _buildEditableField(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF1F2937),
            fontSize: 16.sp,
          ),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF9CA3AF),
              fontSize: 16.sp,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveCancelButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _toggleEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Cancel',
              style: AppFonts.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Save',
                    style: AppFonts.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_rounded,
              color: const Color(0xFF6B7280),
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              'Profile Picture',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color: const Color(0xFFF9FAFB),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 120.h,
                      fit: BoxFit.cover,
                    ),
                  )
                : SafeNetworkImage(
                    imageUrl: _userData?['avatar']?.toString(),
                    width: double.infinity,
                    height: 120.h,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(10.r),
                    errorWidget: _buildAvatarPlaceholder(),
                    placeholder: _buildAvatarPlaceholder(),
                  ),
          ),
        ),
        SizedBox(height: 8.h),
        Center(
          child: Text(
            'Tap to select image from gallery',
            style: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF9CA3AF),
              fontSize: 12.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120.h,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            'Select Image',
            style: AppFonts.bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
