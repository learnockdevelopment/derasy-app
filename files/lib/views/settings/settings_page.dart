import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../services/user_storage_service.dart';
import '../../services/auth_service.dart';
import '../../models/auth_models.dart';
import '../../core/utils/responsive_utils.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricEnabled = false;
  final LocalAuthentication auth = LocalAuthentication();
  bool _isSupportingBiometrics = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enabling
      if (!_isSupportingBiometrics) {
         Get.snackbar('error'.tr, 'biometric_not_supported'.tr,
             snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
         return;
      }
      
      // confirm password
      final password = await _showPasswordConfirmationDialog();
      if (password != null && password.isNotEmpty) {
        // verify
        try {
           final user = await UserStorageService.getUserData();
           final email = user?['email']; 
           if (email == null) {
              Get.snackbar('error'.tr, 'User email not found',
                  snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
              return;
           }

            // Show loading
            Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
            
            try {
               await AuthService.login(LoginRequest(email: email, password: password));
               Get.back(); // close loading

               // Check biometric ownership
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
      // Disabling
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
        title: Text('secure_your_account'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('confirm_password_for_biometric'.tr),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'password'.tr,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: controller.text),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey200,
      appBar: AppBar(
        title: Text(
            'settings'.tr,
             style: AppFonts.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: Responsive.sp(18),
              ),
        ),
        backgroundColor: AppColors.blue1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: Responsive.sp(24)),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: Responsive.all(16),
        children: [
            if (_isSupportingBiometrics)
              Container(
                 decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SwitchListTile(
                    title: Text('biometric_login'.tr, style: AppFonts.bodyLarge),
                    subtitle: Text('enable_biometric_login'.tr, style: AppFonts.bodySmall),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    activeColor: AppColors.blue1,
                    secondary: Icon(Icons.fingerprint, color: AppColors.blue1),
                  ),
              ),
            if (!_isSupportingBiometrics)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('biometric_not_supported'.tr,
                      style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                ),
        ],
      ),
    );
  }
}
