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
  final _headlineController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillController = TextEditingController();

  late Future<TeacherModel> _profileFuture;
  TeacherModel? _profile;
  bool _isLoading = false;
  bool _isEditing = false;

  double _experienceYears = 0;
  List<String> _qualifications = [];
  List<TimetableItem> _timetable = [];
  List<TeacherSkill> _skills = [];

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
          _experienceYears = profile.experienceYears.toDouble();
          _qualifications = List.from(profile.qualifications);
          _timetable = List.from(profile.timetable);
          _headlineController.text = profile.headline;
          _bioController.text = profile.bio;
          _skills = List.from(profile.skills);
          _isEditing = profile.hasCv != true;
        });
      }
    });
  }

  @override
  void dispose() {
    _salaryController.dispose();
    _qualificationController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _skillController.dispose();
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

  void _addSkill() {
    final text = _skillController.text.trim();
    if (text.isNotEmpty) {
      if (!_skills.any((s) => s.name.toLowerCase() == text.toLowerCase())) {
        setState(() {
          _skills.add(TeacherSkill(
            id: 'skill_${DateTime.now().millisecondsSinceEpoch}',
            name: text,
            category: 'professional',
          ));
          _skillController.clear();
        });
      }
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
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
      'experienceYears': _experienceYears.toInt(),
      'qualifications': _qualifications,
      'headline': _headlineController.text.trim(),
      'bio': _bioController.text.trim(),
      'skills': _skills.map((s) => { 'name': s.name, 'category': s.category }).toList(),
      'teacher': {
        'salary': double.tryParse(_salaryController.text) ?? 0.0,
        'experienceYears': _experienceYears.toInt(),
        'qualifications': _qualifications,
      }
    };

    final profileSuccess = await TeacherService.updateTeacherProfile(teacherId, updateData);
    final timetableSuccess = await TeacherService.updateTimetable(teacherId, _timetable);

    setState(() {
      _isLoading = false;
    });

    if (profileSuccess && timetableSuccess) {
      Get.snackbar(
        'success'.tr,
        'profile_updated_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
      _loadProfile();
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
          _profile?.hasCv == true ? 'edit_cv'.tr : 'add_cv'.tr,
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

          if (!_isEditing) {
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: Responsive.all(24),
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
                          SizedBox(height: Responsive.h(4)),
                          Text(
                            _profile?.email ?? '',
                            style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
                          ),
                          if (_profile != null && _profile!.headline.isNotEmpty) ...[
                            SizedBox(height: Responsive.h(12)),
                            Container(
                              padding: Responsive.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(Responsive.r(8)),
                              ),
                              child: Text(
                                _profile!.headline,
                                style: AppFonts.AlmaraiBold12.copyWith(color: accentColor),
                              ),
                            ),
                          ],
                          if (_profile != null && _profile!.bio.isNotEmpty) ...[
                            SizedBox(height: Responsive.h(12)),
                            Divider(color: accentColor.withOpacity(0.15)),
                            SizedBox(height: Responsive.h(8)),
                            Text(
                              'bio'.tr,
                              style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                            ),
                            SizedBox(height: Responsive.h(4)),
                            Text(
                              _profile!.bio,
                              style: AppFonts.AlmaraiRegular12.copyWith(color: textColor.withOpacity(0.85)),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(28)),

                    // Employment Details Title
                    _buildSectionTitle(
                      icon: IconlyBold.work,
                      title: 'employment_and_experience'.tr,
                      textColor: textColor,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Experience Years Card
                    _buildViewDetailCard(
                      title: 'experience_years'.tr,
                      value: _experienceYears == 0
                          ? 'none'.tr
                          : '${_experienceYears.toInt()} ${'years'.tr}',
                      icon: IconlyBold.star,
                      accentColor: accentColor,
                      textColor: textColor,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),

                    SizedBox(height: Responsive.h(16)),

                    // Expected Salary Card
                    _buildViewDetailCard(
                      title: 'expected_salary'.tr,
                      value: (double.tryParse(_salaryController.text) ?? 0.0) == 0.0
                          ? 'none'.tr
                          : '${_salaryController.text} EGP',
                      icon: IconlyBold.wallet,
                      accentColor: accentColor,
                      textColor: textColor,
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),

                    SizedBox(height: Responsive.h(28)),

                    // Qualifications Section
                    _buildSectionTitle(
                      icon: IconlyBold.document,
                      title: 'credentials_and_qualifications'.tr,
                      textColor: textColor,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Qualifications Card
                    Container(
                      width: double.infinity,
                      padding: Responsive.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_qualifications.isEmpty)
                            Center(
                              child: Text(
                                'none'.tr,
                                style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          else
                            Wrap(
                              spacing: Responsive.w(8),
                              runSpacing: Responsive.h(8),
                              children: List.generate(_qualifications.length, (index) {
                                return Container(
                                  padding: Responsive.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                    border: Border.all(color: accentColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    _qualifications[index],
                                    style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(28)),

                    // Skills Section
                    _buildSectionTitle(
                      icon: IconlyBold.category,
                      title: 'skills'.tr,
                      textColor: textColor,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Skills Card
                    Container(
                      width: double.infinity,
                      padding: Responsive.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_skills.isEmpty)
                            Center(
                              child: Text(
                                'none'.tr,
                                style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          else
                            Wrap(
                              spacing: Responsive.w(8),
                              runSpacing: Responsive.h(8),
                              children: List.generate(_skills.length, (index) {
                                return Container(
                                  padding: Responsive.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                                    border: Border.all(color: accentColor.withOpacity(0.2)),
                                  ),
                                  child: Text(
                                    _skills[index].name,
                                    style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: Responsive.h(40)),

                    // Edit CV Button
                    SizedBox(
                      width: double.infinity,
                      height: Responsive.h(50),
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(IconlyLight.edit, color: Colors.white, size: 18),
                        label: Text(
                          'edit_cv'.tr,
                          style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
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

                    SizedBox(height: Responsive.h(20)),

                    // Headline Input
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
                            'headline'.tr,
                            style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                          ),
                          SizedBox(height: Responsive.h(8)),
                          TextFormField(
                            controller: _headlineController,
                            style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'headline_hint'.tr,
                              hintStyle: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
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

                    SizedBox(height: Responsive.h(16)),

                    // Bio Input
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
                            'bio'.tr,
                            style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                          ),
                          SizedBox(height: Responsive.h(8)),
                          TextFormField(
                            controller: _bioController,
                            maxLines: 3,
                            style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'bio_hint'.tr,
                              hintStyle: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
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

                    // Employment & Experience Section Title
                    _buildSectionTitle(
                      icon: IconlyBold.work,
                      title: 'employment_and_experience'.tr,
                      textColor: textColor,
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

                    SizedBox(height: Responsive.h(28)),

                    // Skills Section Title
                    _buildSectionTitle(
                      icon: IconlyBold.category,
                      title: 'skills'.tr,
                      textColor: textColor,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Skills tag editor
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
                                  controller: _skillController,
                                  style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                                  decoration: InputDecoration(
                                    hintText: 'add_skill'.tr,
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
                                onPressed: _addSkill,
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
                          if (_skills.isEmpty)
                            Center(
                              child: Text(
                                'no_skills_added'.tr,
                                style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          else
                            Wrap(
                              spacing: Responsive.w(8),
                              runSpacing: Responsive.h(8),
                              children: List.generate(_skills.length, (index) {
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
                                        _skills[index].name,
                                        style: AppFonts.AlmaraiBold10.copyWith(color: textColor),
                                      ),
                                      SizedBox(width: Responsive.w(6)),
                                      GestureDetector(
                                        onTap: () => _removeSkill(index),
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

                    // Save & Cancel Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Responsive.r(16)),
                              ),
                              padding: Responsive.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'cancel'.tr,
                              style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                              elevation: 0,
                              padding: Responsive.symmetric(vertical: 14),
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

  Widget _buildViewDetailCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color textColor,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: Responsive.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          SizedBox(width: Responsive.w(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: Responsive.h(4)),
                Text(
                  value,
                  style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
