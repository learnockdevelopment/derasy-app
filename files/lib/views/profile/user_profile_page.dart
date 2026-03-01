import 'package:flutter/material.dart';
import '../../core/controllers/app_config_controller.dart';
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
import 'package:local_auth/local_auth.dart';
import '../../services/auth_service.dart';
import '../../models/auth_models.dart';
import 'package:flutter/services.dart';


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

  // Biometrics
  bool _biometricEnabled = false;
  final LocalAuthentication auth = LocalAuthentication();
  bool _isSupportingBiometrics = false;

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
    _checkBiometricSupport();
    _loadBiometricStatus();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final isSupported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _isSupportingBiometrics = isSupported && canCheck;
        });
      }
    } catch (e) {
      print('Biometric support check failed: $e');
    }
  }

  void _loadBiometricStatus() {
    if (mounted) {
      setState(() {
        _biometricEnabled = UserStorageService.isBiometricEnabled();
      });
    }
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

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      if (!_isSupportingBiometrics) {
         Get.snackbar('error'.tr, 'biometric_not_supported'.tr,
             snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
         return;
      }
      
      final password = await _showPasswordConfirmationDialog();
      if (password != null && password.isNotEmpty) {
        try {
           final user = await UserStorageService.getUserData();
           final email = user?['email']; 
           if (email == null) {
              Get.snackbar('error'.tr, 'User email not found',
                  snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
              return;
           }

            Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
            
            try {
               await AuthService.login(LoginRequest(email: email, password: password));
               Get.back(); // close loading

                final bool didAuthenticate = await auth.authenticate(
                    localizedReason: 'scan_fingerprint'.tr,
                    options: const AuthenticationOptions(stickyAuth: true),
                );
                
                if (didAuthenticate) {
                    await UserStorageService.saveBiometricCredentials(email, password);
                    if (mounted) {
                        setState(() {
                            _biometricEnabled = true;
                        });
                    }
                     Get.snackbar('success'.tr, 'biometric_enabled_success'.tr,
                         snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
                } else {
                     Get.snackbar('error'.tr, 'biometric_error'.tr,
                         snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
                }

            } catch (e) {
               Get.back(); // close loading
               Get.snackbar('error'.tr, 'invalid_credentials'.tr,
                   snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
            }
        } catch (e) {
             if (Get.isDialogOpen ?? false) Get.back();
             Get.snackbar('error'.tr, 'Unexpected error: $e',
                 snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
        }
      }
    } else {
      await UserStorageService.setBiometricEnabled(false);
      if (mounted) {
        setState(() {
            _biometricEnabled = false;
        });
      }
      Get.snackbar('success'.tr, 'biometric_disabled_success'.tr,
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  Future<String?> _showPasswordConfirmationDialog() {
    final controller = TextEditingController();
    return Get.dialog<String>(
      AlertDialog(
        backgroundColor: AppConfigController.to.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        title: Text('secure_your_account'.tr, style: AppFonts.h4.copyWith(color: AppConfigController.to.isDarkMode ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('confirm_password_for_biometric'.tr, style: AppFonts.bodySmall.copyWith(color: AppConfigController.to.isDarkMode ? Colors.grey : Colors.black87)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              obscureText: true,
              style: AppFonts.bodyMedium.copyWith(color: AppConfigController.to.isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'password'.tr,
                hintStyle: TextStyle(color: AppConfigController.to.isDarkMode ? Colors.grey : Colors.grey.shade600),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppConfigController.to.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade300)
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.blue1)
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr, style: TextStyle(color: AppConfigController.to.isDarkMode ? Colors.grey : Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue1),
            child: Text('confirm'.tr, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    
    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;
      final bgColor = isDark ? const Color(0xFF0F172A) : AppColors.grey200;
      final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      final textColor = isDark ? Colors.white : AppColors.textPrimary;
      final textSecondaryColor = isDark ? Colors.grey.shade400 : AppColors.textSecondary;
      final borderColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB);
      
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: bgColor,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: AppColors.blue1,
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
                  _buildProfileCard(cardColor, textColor, textSecondaryColor),
                  SizedBox(height: Responsive.h(16)),

                  // User Information Section
                  _buildUserInfoSection(cardColor, textColor, textSecondaryColor, borderColor, isDark),
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
        ),
      );
    });
  }


  Widget _buildProfileCard(Color cardColor, Color textColor, Color textSecondaryColor) {
    final userName = _userData?['name'] ??
        _userData?['fullName'] ??
        'user'.tr;
    final userEmail = _userData?['email'] ?? 'N/A';
    final avatarUrl = _userData?['avatar']?.toString() ??
        _userData?['profileImage']?.toString();

    return Container(
      padding: Responsive.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: Responsive.w(70),
            height: Responsive.w(70),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.blue1.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue1.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? SafeNetworkImage(
                imageUrl: avatarUrl,
                width: Responsive.w(70),
                height: Responsive.w(70),
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: AppColors.blue1,
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: Responsive.sp(35),
                  ),
                ),
              )
                  : Container(
                color: AppColors.blue1,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: Responsive.sp(35),
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.h(10)),
          // User Name
          Text(
            userName,
            style: AppFonts.h3.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.sp(16),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: Responsive.h(6)),
          // User Email
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_rounded,
                size: Responsive.sp(14),
                color: AppColors.textSecondary,
              ),
              SizedBox(width: Responsive.w(4)),
              Flexible(
                child: Text(
                  userEmail,
                  style: AppFonts.bodyMedium.copyWith(
                    color: textSecondaryColor,
                    fontSize: Responsive.sp(12),
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

  Widget _buildUserInfoSection(Color cardColor, Color textColor, Color textSecondaryColor, Color borderColor, bool isDark) {
    return Container(
      padding: Responsive.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
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
                padding: Responsive.all(6),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.blue1,
                  size: Responsive.sp(16),
                ),
              ),
              SizedBox(width: Responsive.w(10)),
              Text(
                'personal_information'.tr,
                style: AppFonts.h4.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(14),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(14)),

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
              SizedBox(height: Responsive.h(12)),
              // Language Change Button
              InkWell(
                onTap: () {
                  // Toggle language between Arabic and English
                  final currentLocale = Get.locale?.languageCode ?? 'en';
                  final newLocale = currentLocale == 'ar' ? const Locale('en', 'US') : const Locale('ar', 'SA');
                  Get.updateLocale(newLocale);
                  Get.snackbar(
                    'success'.tr,
                    'language_changed'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.blue1,
                    colorText: Colors.white,
                    duration: const Duration(seconds: 2),
                  );
                },
                borderRadius: BorderRadius.circular(Responsive.r(10)),
                child: Container(
                  padding: Responsive.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(Responsive.r(10)),
                    border: Border.all(
                      color: AppColors.blue1.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: AppColors.blue1,
                        size: Responsive.sp(18),
                      ),
                      SizedBox(width: Responsive.w(12)), 
                      Text(
                        'change_language'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: AppColors.blue1,
                          fontWeight: FontWeight.w600,
                          fontSize: Responsive.sp(13),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Get.locale?.languageCode == 'ar' ? 'EN' : 'عربي',
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.sp(12),
                        ),
                      ),
                      SizedBox(width: Responsive.w(8)),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.blue1,
                        size: Responsive.sp(14),
                      ),
                    ],
                  ), 
                ),
              ),
              SizedBox(height: Responsive.h(12)),
              // Dark Mode Toggle
              Container(
                padding: Responsive.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(Responsive.r(10)),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('dark_mode'.tr, style: AppFonts.bodyMedium.copyWith(color: textColor)),
                  value: isDark,
                  onChanged: (val) => AppConfigController.to.toggleTheme(),
                  activeColor: AppColors.blue1,
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: AppColors.blue1),
                ),
              ),
              if (_isSupportingBiometrics) ...[
                SizedBox(height: Responsive.h(12)),
                // Biometrics Toggle
                Container(
                  padding: Responsive.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(Responsive.r(10)),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('biometric_login'.tr, style: AppFonts.bodyMedium.copyWith(color: textColor)),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    activeColor: AppColors.blue1,
                    secondary: Icon(Icons.fingerprint, color: AppColors.blue1),
                  ),
                ),
              ],
            ],
        ],
      ),
    );
  }




  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: Responsive.h(48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFEF4444),
            Color(0xFFDC2626),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Responsive.r(12)),
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
          borderRadius: BorderRadius.circular(Responsive.r(12)),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: Responsive.sp(18),
                ),
                SizedBox(width: Responsive.w(6)),
                Text(
                  'logout'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.sp(14),
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
    if (value.isEmpty || value == 'N/A' || value == 'null') {
      return const SizedBox.shrink();
    }
    final isDark = AppConfigController.to.isDarkMode;
    return Container(
      margin: Responsive.only(bottom: 16),
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(Responsive.r(12)),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
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
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontSize: AppFonts.size12,
                  ),
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  value,
                  style: AppFonts.bodyMedium.copyWith(
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
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
    final isDark = AppConfigController.to.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
              size: AppFonts.size18,
            ),
            SizedBox(width: Responsive.w(8)),
            Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
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
            color: isDark ? Colors.white : const Color(0xFF1F2937),
            fontSize: AppFonts.size16,
          ),
          decoration: InputDecoration(
            hintText: 'enter_label'.tr.replaceAll('{label}', label),
            hintStyle: AppFonts.bodyMedium.copyWith(
              color: isDark ? Colors.grey.shade600 : const Color(0xFF9CA3AF),
              fontSize: AppFonts.size16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB)),
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
    final isDark = AppConfigController.to.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.image_rounded,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
              size: AppFonts.size18,
            ),
            SizedBox(width: Responsive.w(8)),
            Text(
              'profile_picture'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
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
                color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB),
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(Responsive.r(12)),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
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

