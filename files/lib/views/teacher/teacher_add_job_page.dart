import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/teacher_models.dart';
import '../../services/teacher_service.dart';

class TeacherAddJobPage extends StatefulWidget {
  const TeacherAddJobPage({Key? key}) : super(key: key);

  @override
  State<TeacherAddJobPage> createState() => _TeacherAddJobPageState();
}

class _TeacherAddJobPageState extends State<TeacherAddJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _deptController = TextEditingController();
  final _salaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementController = TextEditingController();

  String _employmentType = 'full_time';
  List<String> _requirements = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _deptController.dispose();
    _salaryController.dispose();
    _descriptionController.dispose();
    _requirementController.dispose();
    super.dispose();
  }

  void _addRequirement() {
    final text = _requirementController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _requirements.add(text);
        _requirementController.clear();
      });
    }
  }

  void _removeRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final job = TeacherJob(
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'معلم رياضيات',
      department: _deptController.text.trim().isNotEmpty ? _deptController.text.trim() : 'قسم الرياضيات والعلوم',
      salary: double.tryParse(_salaryController.text) ?? 8000.0,
      employmentType: _employmentType,
      requirements: _requirements.isNotEmpty ? _requirements : ['مؤهل تربوي مناسب', 'خبرة 3 سنوات'],
      description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : 'مطلوب معلم رياضيات ذو خبرة لتدريس المرحلة الثانوية وتطبيق أساليب التعلم الفعالة.',
      datePosted: DateTime.now().toIso8601String().substring(0, 10),
    );

    final success = await TeacherService.addJob(job);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Get.back();
      Get.snackbar(
        'success'.tr,
        'job_posted_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        'failed_to_post_job'.tr,
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
          'add_job_opening'.tr,
          style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: Responsive.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instruction banner
                Container(
                  width: double.infinity,
                  padding: Responsive.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(Responsive.r(20)),
                    border: Border.all(color: Colors.teal.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Icon(IconlyBold.info_square, color: Colors.teal, size: Responsive.sp(18)),
                      SizedBox(width: Responsive.w(10)),
                      Expanded(
                        child: Text(
                          'post_job_instruction'.tr,
                          style: AppFonts.AlmaraiRegular10.copyWith(color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.h(24)),

                // Job Title
                _buildLabel('job_title'.tr, textColor),
                SizedBox(height: Responsive.h(6)),
                _buildTextField(
                  controller: _titleController,
                  hintText: 'math_teacher_high_school'.tr,
                  textColor: textColor,
                  borderColor: borderColor,
                  accentColor: accentColor,
                ),
                SizedBox(height: Responsive.h(16)),

                // Department
                _buildLabel('department'.tr, textColor),
                SizedBox(height: Responsive.h(6)),
                _buildTextField(
                  controller: _deptController,
                  hintText: 'example_science_dept'.tr,
                  textColor: textColor,
                  borderColor: borderColor,
                  accentColor: accentColor,
                ),
                SizedBox(height: Responsive.h(16)),

                // Salary range
                _buildLabel('budget_salary'.tr, textColor),
                SizedBox(height: Responsive.h(6)),
                _buildTextField(
                  controller: _salaryController,
                  hintText: '8000',
                  keyboardType: TextInputType.number,
                  textColor: textColor,
                  borderColor: borderColor,
                  accentColor: accentColor,
                  suffixText: 'EGP',
                ),
                SizedBox(height: Responsive.h(16)),

                // Employment Type select
                _buildLabel('employment_type'.tr, textColor),
                SizedBox(height: Responsive.h(6)),
                Container(
                  padding: Responsive.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(Responsive.r(16)),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _employmentType,
                      isExpanded: true,
                      dropdownColor: cardBg,
                      style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _employmentType = val;
                          });
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'full_time',
                          child: Text('full_time'.tr),
                        ),
                        DropdownMenuItem(
                          value: 'part_time',
                          child: Text('part_time'.tr),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Responsive.h(16)),

                // Job Description
                _buildLabel('job_description'.tr, textColor),
                SizedBox(height: Responsive.h(6)),
                _buildTextField(
                  controller: _descriptionController,
                  hintText: 'job_description_hint'.tr,
                  maxLines: 4,
                  textColor: textColor,
                  borderColor: borderColor,
                  accentColor: accentColor,
                ),
                SizedBox(height: Responsive.h(16)),

                // Job Requirements List Builder
                _buildLabel('job_requirements'.tr, textColor),
                SizedBox(height: Responsive.h(6)),
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
                              controller: _requirementController,
                              style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                              decoration: InputDecoration(
                                hintText: 'add_requirement'.tr,
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
                            onPressed: _addRequirement,
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
                      if (_requirements.isEmpty)
                        Center(
                          child: Text(
                            'no_requirements_added'.tr,
                            style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        Wrap(
                          spacing: Responsive.w(8),
                          runSpacing: Responsive.h(8),
                          children: List.generate(_requirements.length, (index) {
                            return Container(
                              padding: Responsive.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(Responsive.r(12)),
                                border: Border.all(color: Colors.teal.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _requirements[index],
                                    style: AppFonts.AlmaraiBold10.copyWith(color: textColor),
                                  ),
                                  SizedBox(width: Responsive.w(6)),
                                  GestureDetector(
                                    onTap: () => _removeRequirement(index),
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

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: Responsive.h(50),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'publish_job_opening'.tr,
                            style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
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

  Widget _buildLabel(String text, Color textColor) {
    return Text(
      text,
      style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Color textColor,
    required Color borderColor,
    required Color accentColor,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
        suffixText: suffixText,
        suffixStyle: AppFonts.AlmaraiBold12.copyWith(color: accentColor),
        contentPadding: Responsive.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          borderSide: BorderSide(color: accentColor),
        ),
      ),
    );
  }
}
