import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive_utils.dart';
import '../../services/sales_service.dart';
import '../../widgets/loading_page.dart';

class SalesOnboardingPage extends StatefulWidget {
  const SalesOnboardingPage({Key? key}) : super(key: key); 

  @override
  State<SalesOnboardingPage> createState() => _SalesOnboardingPageState(); 
}

class _SalesOnboardingPageState extends State<SalesOnboardingPage> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  bool _isLoading = false;
  late AnimationController _animationController;

  // Form Controllers
  final _schoolNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerEmailController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _ownerPasswordController = TextEditingController();

  // Selected Data
  String? _selectedType = 'Private';
  String? _selectedGovernorate = 'Cairo';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
    
    // Add listeners to update UI on text change for validation
    _schoolNameController.addListener(_updateState);
    _ownerNameController.addListener(_updateState);
    _ownerEmailController.addListener(_updateState);
    _ownerPhoneController.addListener(_updateState);
    _ownerPasswordController.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _schoolNameController.removeListener(_updateState);
    _ownerNameController.removeListener(_updateState);
    _ownerEmailController.removeListener(_updateState);
    _ownerPhoneController.removeListener(_updateState);
    _ownerPasswordController.removeListener(_updateState);
    
    _schoolNameController.dispose();
    _ownerNameController.dispose();
    _ownerEmailController.dispose();
    _ownerPhoneController.dispose();
    _ownerPasswordController.dispose();
    super.dispose();
  }
  
  bool _isStepValid() {
    switch (_currentStep) {
      case 0:
        return _schoolNameController.text.trim().isNotEmpty &&
               _selectedType != null &&
               _selectedGovernorate != null;
      case 1:
        return _ownerNameController.text.trim().isNotEmpty &&
               _ownerEmailController.text.trim().isNotEmpty &&
               _ownerPhoneController.text.trim().isNotEmpty &&
               _ownerPasswordController.text.trim().isNotEmpty;
      case 2:
        return true; 
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildAppBar(),
          body: Column(
            children: [
              _buildModernStepIndicator(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: SingleChildScrollView(
                    key: ValueKey<int>(_currentStep),
                    padding: Responsive.all(24),
                    child: _buildCurrentStepView(),
                  ),
                ),
              ),
              _buildEnhancedBottomNav(),
            ],
          ),
        ),
        if (_isLoading) const LoadingPage(),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('onboard_new_school'.tr, style: AppFonts.AlmaraiBold18),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 16),
        ),
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildModernStepIndicator() {
    final steps = [
      {'label': 'school'.tr, 'icon': IconlyBold.home},
      {'label': 'owner'.tr, 'icon': IconlyBold.profile},
      {'label': 'review'.tr, 'icon': IconlyBold.document},
    ];

    return Container(
      padding: Responsive.symmetric(vertical: 24, horizontal: 32),
      color: Colors.white,
      child: Row(
        children: steps.asMap().entries.map((entry) {
          int index = entry.key;
          var step = entry.value;
          bool isActive = _currentStep == index;
          bool isCompleted = _currentStep > index;
          bool isLast = index == steps.length - 1;

          return Expanded(
            flex: isLast ? 0 : 1,
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: Responsive.w(40),
                      height: Responsive.w(40),
                      decoration: BoxDecoration(
                        color: isActive || isCompleted ? AppColors.blue1 : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive || isCompleted ? AppColors.blue1 : AppColors.grey300,
                          width: 2,
                        ),
                        boxShadow: isActive
                            ? [BoxShadow(color: AppColors.blue1.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : (step['icon'] as IconData),
                        color: isActive || isCompleted ? Colors.white : AppColors.grey400,
                        size: Responsive.sp(18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step['label'] as String,
                      style: AppFonts.AlmaraiBold12.copyWith(
                        color: isActive ? AppColors.blue1 : AppColors.grey400,
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.blue1 : AppColors.grey200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildSchoolDataStep();
      case 1:
        return _buildOwnerDataStep();
      case 2:
        return _buildReviewStep();
      default:
        return Container();
    }
  }

  Widget _buildStepWrapper({required String title, required String subtitle, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppFonts.AlmaraiBold20.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppFonts.AlmaraiRegular14.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Container(
          padding: Responsive.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolDataStep() {
    return _buildStepWrapper(
      title: 'school_information'.tr,
      subtitle: 'onboard_new_school_desc'.tr,
      children: [
        _buildModernTextField('school_name'.tr, _schoolNameController, IconlyLight.home),
        const SizedBox(height: 20),
        _buildModernDropdown('school_type'.tr, ['Private', 'International', 'Governmental'], _selectedType, (val) => setState(() => _selectedType = val)),
        const SizedBox(height: 20),
        _buildModernDropdown('governorate'.tr, ['Cairo', 'Giza', 'Alexandria'], _selectedGovernorate, (val) => setState(() => _selectedGovernorate = val)),
      ],
    );
  }

  Widget _buildOwnerDataStep() {
    return _buildStepWrapper(
      title: 'owner_information'.tr,
      subtitle: 'owner_information_desc'.tr,
      children: [
        _buildModernTextField('owner_full_name'.tr, _ownerNameController, IconlyLight.profile),
        const SizedBox(height: 20),
        _buildModernTextField('owner_email'.tr, _ownerEmailController, IconlyLight.message, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 20),
        _buildModernTextField('owner_phone'.tr, _ownerPhoneController, IconlyLight.call, keyboardType: TextInputType.phone),
        const SizedBox(height: 20),
        _buildModernTextField('owner_password'.tr, _ownerPasswordController, IconlyLight.lock, isPassword: true),
      ],
    );
  }

  Widget _buildReviewStep() {
    return _buildStepWrapper(
      title: 'review_and_submit'.tr,
      subtitle: 'review_your_entries'.tr,
      children: [
        _buildReviewCard('school_information'.tr, [
          _buildReviewRow('school_name'.tr, _schoolNameController.text),
          _buildReviewRow('school_type'.tr, _selectedType ?? ''),
          _buildReviewRow('governorate'.tr, _selectedGovernorate ?? ''),
        ]),
        const SizedBox(height: 16),
        _buildReviewCard('owner_information'.tr, [
          _buildReviewRow('owner_name'.tr, _ownerNameController.text),
          _buildReviewRow('owner_email'.tr, _ownerEmailController.text),
          _buildReviewRow('owner_phone'.tr, _ownerPhoneController.text),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: Responsive.all(16),
          decoration: BoxDecoration(
            color: AppColors.blue1.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.blue1.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(IconlyLight.info_square, color: AppColors.blue1, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'onboarding_final_notice'.tr,
                      style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.blue1),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.blue1)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary)),
          Text(value.isNotEmpty ? value : '-', style: AppFonts.AlmaraiBold12),
        ],
      ),
    );
  }

  Widget _buildModernTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: AppFonts.AlmaraiMedium14,
          decoration: InputDecoration(
            hintText: 'enter_field'.trParams({'field': label}),
            hintStyle: AppFonts.AlmaraiRegular14.copyWith(color: AppColors.grey400),
            prefixIcon: Icon(icon, size: 20, color: AppColors.blue1),
            filled: true,
            fillColor: AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.blue1, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          style: AppFonts.AlmaraiMedium14.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.grey50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.grey200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.blue1, width: 2),
            ),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildEnhancedBottomNav() {
    bool isValid = _isStepValid();

    return Container(
      padding: Responsive.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: TextButton.styleFrom(
                    padding: Responsive.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('previous'.tr, style: AppFonts.AlmaraiBold16.copyWith(color: AppColors.grey400)),
                ),
              ),
            if (_currentStep > 0) SizedBox(width: Responsive.w(16)),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (isValid && !_isLoading) ? _handleNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid ? AppColors.blue1 : AppColors.grey300,
                  foregroundColor: isValid ? Colors.white : AppColors.grey500,
                  padding: Responsive.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: isValid ? 8 : 0,
                  shadowColor: isValid ? AppColors.blue1.withOpacity(0.4) : Colors.transparent,
                ),
                child: _isLoading 
                ? const SizedBox(
                    width: 24, 
                    height: 24, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == 2 ? 'submit'.tr : 'next'.tr,
                      style: AppFonts.AlmaraiBold16.copyWith(
                        color: isValid ? Colors.white : AppColors.grey500
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded, 
                      color: isValid ? Colors.white : AppColors.grey500, 
                      size: 20
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNext() async {
    if (_currentStep < 2) {
      if (_isStepValid()) {
        setState(() => _currentStep++);
      }
    } else {
      _submitOnboarding();
    }
  }

  void _submitOnboarding() async {
    setState(() => _isLoading = true);
    try {
      final onboardingData = {
        "schoolData": {
          "name": _schoolNameController.text,
          "type": _selectedType,
          "location": {"governorate": _selectedGovernorate},
        },
        "ownerData": {
          "name": _ownerNameController.text,
          "email": _ownerEmailController.text,
          "phone": _ownerPhoneController.text,
          "password": _ownerPasswordController.text,
        },
        "moderatorData": {
          "name": "${_ownerNameController.text} Moderator",
          "email": "mod_${_ownerEmailController.text}",
          "phone": _ownerPhoneController.text,
          "password": _ownerPasswordController.text, 
        },
        "configData": {"approved": true}
      };

      print('🚀 [SALES] Creating new school...');
      print('📝 Onboarding Data: ${jsonEncode(onboardingData)}');

      await SalesService.onboardSchool(onboardingData);
      
      print('✅ [SALES] School created successfully via service');
      
      Get.snackbar(
        'success'.tr, 
        'school_created_successfully'.tr, 
        backgroundColor: Colors.green.withOpacity(0.8), 
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
      Get.offAllNamed(AppRoutes.salesHome);
    } catch (e) {
      print('❌ [SALES] Error creating school: $e');
      Get.snackbar(
        'error'.tr, 
        e.toString(), 
        backgroundColor: Colors.red.withOpacity(0.8), 
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
}
