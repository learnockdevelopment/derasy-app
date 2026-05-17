import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/teacher_models.dart';
import '../../services/teacher_service.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/loading_page.dart';

class TeacherCvProfilePage extends StatefulWidget {
  const TeacherCvProfilePage({Key? key}) : super(key: key);

  @override
  State<TeacherCvProfilePage> createState() => _TeacherCvProfilePageState();
}

class _TeacherCvProfilePageState extends State<TeacherCvProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _salaryController = TextEditingController();
  final _qualificationController = TextEditingController();

  late Future<TeacherModel> _profileFuture;
  TeacherModel? _profile;
  bool _isLoading = false;

  String _employmentType = 'full_time';
  double _experienceYears = 0;
  List<String> _qualifications = [];
  List<TimetableItem> _timetable = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final user = UserStorageService.getCurrentUser();
    _profileFuture = TeacherService.getTeacherProfile(user?.id ?? 'teacher_123');
    _profileFuture.then((profile) {
      if (mounted) {
        setState(() {
          _profile = profile;
          _salaryController.text = profile.salary.toStringAsFixed(0);
          _employmentType = profile.employmentType;
          _experienceYears = profile.experienceYears.toDouble();
          _qualifications = List.from(profile.qualifications);
          _timetable = List.from(profile.timetable);
        });
      }
    });
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  void _addQualification() {
    final text = _qualificationController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _qualifications.add(text);
        _qualificationController.clear();
      });
    }
  }

  void _removeQualification(int index) {
    setState(() {
      _qualifications.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final user = UserStorageService.getCurrentUser();
    final teacherId = user?.id ?? 'teacher_123';

    final updateData = {
      'salary': double.tryParse(_salaryController.text) ?? 0.0,
      'employmentType': _employmentType,
      'experienceYears': _experienceYears.toInt(),
      'qualifications': _qualifications,
    };

    final profileSuccess = await TeacherService.updateTeacherProfile(teacherId, updateData);
    final timetableSuccess = await TeacherService.updateTimetable(teacherId, _timetable);

    setState(() {
      _isLoading = false;
    });

    if (profileSuccess && timetableSuccess) {
      Get.back();
      Get.snackbar(
        'success'.tr,
        'profile_updated_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'failed_to_update'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConfigController.to.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;
    final accentColor = AppColors.salesAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Responsive.isRTL ? IconlyLight.arrow_right_2 : IconlyLight.arrow_left_2,
            color: textColor,
          ),
        ),
        title: Text(
          'cv_profile_builder'.tr,
          style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<TeacherModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _profile == null) {
            return const LoadingPage();
          }

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: Responsive.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Professional Summary Header Card
                    Container(
                      width: double.infinity,
                      padding: Responsive.all(20),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                        border: Border.all(color: accentColor.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(IconlyBold.profile, color: accentColor, size: Responsive.sp(18)),
                              SizedBox(width: Responsive.w(8)),
                              Text(
                                _profile?.name ?? '',
                                style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.h(8)),
                          Text(
                            _profile?.email ?? '',
                            style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(28)),

                    // Employment & Experience Section Title
                    _buildSectionTitle(
                      icon: IconlyBold.work,
                      title: 'employment_and_experience'.tr,
                      textColor: textColor,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Employment Type Selection
                    Container(
                      padding: Responsive.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'employment_type'.tr,
                            style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                          ),
                          SizedBox(height: Responsive.h(12)),
                          Row(
                            children: [
                              Expanded(
                                child: _buildChoiceChip(
                                  label: 'full_time'.tr,
                                  isSelected: _employmentType == 'full_time',
                                  onSelected: () => setState(() => _employmentType = 'full_time'),
                                  accentColor: accentColor,
                                ),
                              ),
                              SizedBox(width: Responsive.w(12)),
                              Expanded(
                                child: _buildChoiceChip(
                                  label: 'part_time'.tr,
                                  isSelected: _employmentType == 'part_time',
                                  onSelected: () => setState(() => _employmentType = 'part_time'),
                                  accentColor: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(16)),

                    // Experience Years Slider
                    Container(
                      padding: Responsive.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'experience_years'.tr,
                                style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                              ),
                              Text(
                                '${_experienceYears.toInt()} ${'years'.tr}',
                                style: AppFonts.AlmaraiBold14.copyWith(color: accentColor),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.h(8)),
                          Slider(
                            value: _experienceYears,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            activeColor: accentColor,
                            inactiveColor: accentColor.withOpacity(0.15),
                            onChanged: (val) {
                              setState(() {
                                _experienceYears = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(16)),

                    // Expected Salary Input
                    Container(
                      padding: Responsive.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'expected_salary'.tr,
                            style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                          ),
                          SizedBox(height: Responsive.h(8)),
                          TextFormField(
                            controller: _salaryController,
                            keyboardType: TextInputType.number,
                            style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: 'EGP',
                              suffixStyle: AppFonts.AlmaraiBold12.copyWith(color: accentColor),
                              contentPadding: Responsive.symmetric(vertical: 12, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                borderSide: BorderSide(color: accentColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(28)),

                    // Qualifications Credentials Section Title
                    _buildSectionTitle(
                      icon: IconlyBold.document,
                      title: 'credentials_and_qualifications'.tr,
                      textColor: textColor,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Qualifications Input with dynamic Tag items
                    Container(
                      padding: Responsive.all(18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _qualificationController,
                                  style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'add_qualification'.tr,
                                    hintStyle: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
                                    contentPadding: Responsive.symmetric(vertical: 10, horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                                      borderSide: BorderSide(color: borderColor),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: Responsive.w(12)),
                              IconButton(
                                onPressed: _addQualification,
                                icon: Container(
                                  padding: Responsive.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Responsive.h(16)),
                          if (_qualifications.isEmpty)
                            Center(
                              child: Text(
                                'no_qualifications_added'.tr,
                                style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          else
                            Wrap(
                              spacing: Responsive.w(8),
                              runSpacing: Responsive.h(8),
                              children: List.generate(_qualifications.length, (index) {
                                return Container(
                                  padding: Responsive.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                    border: Border.all(color: accentColor.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _qualifications[index],
                                        style: AppFonts.AlmaraiBold10.copyWith(color: textColor),
                                      ),
                                      SizedBox(width: Responsive.w(6)),
                                      GestureDetector(
                                        onTap: () => _removeQualification(index),
                                        child: Icon(Icons.close, color: AppColors.error, size: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(32)),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.h(50),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'save_cv_profile'.tr,
                                style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title, required Color textColor}) {
    return Row(
      children: [
        Container(
          padding: Responsive.all(6),
          decoration: BoxDecoration(
            color: AppColors.salesAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(Responsive.r(8)),
          ),
          child: Icon(icon, color: AppColors.salesAccent, size: 16),
        ),
        SizedBox(width: Responsive.w(8)),
        Text(
          title,
          style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: Responsive.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(Responsive.r(12)),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.grey300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppFonts.AlmaraiBold12.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
