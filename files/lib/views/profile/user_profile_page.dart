import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_storage_service.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/safe_network_image.dart';
import '../../widgets/global_chatbot_widget.dart';

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
      if (mounted) {
        _loadUserData();
      }
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
      print('👤 [USER PROFILE] FULL API RESPONSE RECEIVED');
      print('👤 [USER PROFILE] ===========================================');
      apiResponse.forEach((key, value) {
        print('👤 [USER PROFILE] $key: $value');
      });
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

        if (mounted) {
          setState(() {
            _userData = userData;
          });
        }

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

        if (mounted) {
          setState(() {
            _userData = localData;
          });
        }
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

        if (mounted) {
          setState(() {
            _userData = localData;
          });
        }
      } catch (localError) {
        print(
            '👤 [USER PROFILE] Error loading from local storage: $localError');
        Get.snackbar(
          'error'.tr,
          'failed_to_load_user_data'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text
        .trim()
        .isEmpty ||
        _phoneController.text
            .trim()
            .isEmpty) {
      Get.snackbar(
        'error'.tr,
        'name_and_phone_required'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      String? avatarUrl = _userData?['avatar'];
      if (_selectedImage != null) {
        print(
            '👤 [USER PROFILE] Image selected but not uploaded yet: ${_selectedImage!
                .path}');
      }

      final response = await UserProfileService.updateUserProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatar: avatarUrl,
      );

      print('👤 [USER PROFILE] Update response: $response');

      if (response.containsKey('user')) {
        final updatedUser = response['user'] as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _userData = updatedUser;
            _isEditing = false;
          });
        }

        Get.snackbar(
          'success'.tr,
          'profile_updated_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('👤 [USER PROFILE] Error updating profile: $e');
      Get.snackbar(
        'error'.tr,
        'failed_to_update_profile'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        if (mounted) {
          setState(() {
            _selectedImage = File(image.path);
          });
        }
        print('👤 [USER PROFILE] Image selected: ${image.path}');
      }
    } catch (e) {
      print('👤 [USER PROFILE] Error picking image: $e');
      Get.snackbar(
        'error'.tr,
        'failed_to_pick_image'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _toggleEdit() {
    if (mounted) {
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
  }

  Future<void> _logout() async {
    try {
      await UserStorageService.clearUserData();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_logout'.tr,
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
      backgroundColor: AppColors.grey200,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: Responsive.sp(24)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'profile'.tr,
          style: AppFonts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.sp(18),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: Responsive.all(16),
          child: Column(
            children: [
              // User Profile Card with Image, Name, Email
              _buildProfileCard(),
              SizedBox(height: Responsive.h(16)),

              // User Information Section
              _buildUserInfoSection(),
              SizedBox(height: Responsive.h(16)),

              // Wallet Section
              _buildWalletSection(),
              SizedBox(height: Responsive.h(16)),

              // Logout Button
              _buildLogoutButton(),
              SizedBox(height: Responsive.h(32)),
            ],
          ),
        ),
      ),
      floatingActionButton: DraggableChatbotWidget(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }


  Widget _buildProfileCard() {
    final userName = _userData?['name'] ??
        _userData?['fullName'] ??
        'user'.tr;
    final userEmail = _userData?['email'] ?? 'N/A';
    final avatarUrl = _userData?['avatar']?.toString() ??
        _userData?['profileImage']?.toString();

    return Container(
      padding: Responsive.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: Responsive.w(100),
            height: Responsive.w(100),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? SafeNetworkImage(
                imageUrl: avatarUrl,
                width: Responsive.w(100),
                height: Responsive.w(100),
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: AppColors.primaryBlue,
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: Responsive.sp(50),
                  ),
                ),
              )
                  : Container(
                color: AppColors.primaryBlue,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: Responsive.sp(50),
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.h(16)),
          // User Name
          Text(
            userName,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.sp(20),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: Responsive.h(8)),
          // User Email
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_rounded,
                size: Responsive.sp(16),
                color: AppColors.textSecondary,
              ),
              SizedBox(width: Responsive.w(6)),
              Flexible(
                child: Text(
                  userEmail,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: Responsive.sp(14),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Container(
      padding: Responsive.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: Responsive.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.r(10)),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryBlue,
                  size: Responsive.sp(20),
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Text(
                'personal_information'.tr,
                style: AppFonts.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(16),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(20)),

          // Editable fields when in edit mode
          if (_isEditing) ...[
            _buildEditableField(
                'full_name'.tr, _nameController, Icons.person_rounded),
            SizedBox(height: Responsive.h(16)),
            _buildEditableField(
                'phone'.tr, _phoneController, Icons.phone_rounded),
            SizedBox(height: Responsive.h(16)),
            _buildAvatarField(),
            SizedBox(height: Responsive.h(20)),
            _buildSaveCancelButtons(),
          ] else
            ...[
              // Display mode - show phone, role, and user ID only (name and email are in profile card)
              _buildInfoRow(
                  'phone'.tr, _userData?['phone'] ?? 'N/A',
                  Icons.phone_rounded),
              SizedBox(height: Responsive.h(12)),
              _buildInfoRow('role'.tr, _userData?['role'] ?? 'N/A',
                  Icons.admin_panel_settings_rounded),
              SizedBox(height: Responsive.h(12)),
              _buildInfoRow(
                  'user_id'.tr, _userData?['id'] ?? 'N/A', Icons.badge_rounded),
            ],
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Container(
      padding: Responsive.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: Responsive.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.r(10)),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              SizedBox(width: Responsive.w(12)),
              Text(
                'wallet_title'.tr,
                style: AppFonts.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(16),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.wallet),
                child: Text('view_all'.tr),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.wallet),
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              child: Container(
                padding: Responsive.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'current_balance'.tr,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_userData?['walletBalance']?.toString() ?? '0.00'} EGP',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: Responsive.h(56),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEF4444),
            Color(0xFFDC2626),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.r(16)),
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
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: AppFonts.size20,
                ),
                SizedBox(width: Responsive.w(8)),
                Text(
                  'logout'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: AppFonts.size16,
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
      margin: Responsive.only(bottom: 16),
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(Responsive.r(12)),
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
            size: Responsive.sp(20),
          ),
          SizedBox(width: Responsive.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.labelSmall.copyWith(
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontSize: AppFonts.size12,
                  ),
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  value,
                  style: AppFonts.bodyMedium.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                    fontSize: AppFonts.size14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEditableField(String label, TextEditingController controller,
      IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: AppFonts.size18,
            ),
            SizedBox(width: Responsive.w(8)),
            Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: AppFonts.size14,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.h(8)),
        TextFormField(
          controller: controller,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF1F2937),
            fontSize: AppFonts.size16,
          ),
          decoration: InputDecoration(
            hintText: 'enter_label'.tr.replaceAll('{label}', label),
            hintStyle: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF9CA3AF),
              fontSize: AppFonts.size16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding:
            Responsive.symmetric(horizontal: 16, vertical: 12),
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
              padding: Responsive.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.r(12)),
              ),
            ),
            child: Text(
              'cancel'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: AppFonts.size16,
              ),
            ),
          ),
        ),
        SizedBox(width: Responsive.w(12)),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: Responsive.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.r(12)),
              ),
            ),
            child: _isLoading
                ? SizedBox(
              width: Responsive.w(20),
              height: Responsive.h(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              'save'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: AppFonts.size16,
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
              size: AppFonts.size18,
            ),
            SizedBox(width: Responsive.w(8)),
            Text(
              'profile_picture'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
                fontSize: AppFonts.size14,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.h(12)),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: Responsive.h(120),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              color: const Color(0xFFF9FAFB),
            ),
            child: _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.r(10)),
              child: Image.file(
                _selectedImage!,
                width: double.infinity,
                height: Responsive.h(120),
                fit: BoxFit.cover,
              ),
            )
            : SafeNetworkImage(
              imageUrl: _userData?['avatar']?.toString(),
              width: double.infinity,
              height: Responsive.h(120),
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(Responsive.r(10)),
              errorWidget: _buildAvatarPlaceholder(),
              placeholder: _buildAvatarPlaceholder(),
            ),
          ),
        ),
        SizedBox(height: Responsive.h(8)),
        Center(
          child: Text(
            'tap_to_select_image_from_gallery'.tr,
            style: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF9CA3AF),
              fontSize: AppFonts.size12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      width: double.infinity,
      height: Responsive.h(120),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.r(10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: AppFonts.size32,
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'select_image'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: Colors.white,
              fontSize: AppFonts.size14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

}
