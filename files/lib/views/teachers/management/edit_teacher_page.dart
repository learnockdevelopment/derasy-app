import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../services/teachers_service.dart';
import '../../../services/grades_service.dart';

class EditTeacherPage extends StatefulWidget {
  final Teacher teacher;
  final String schoolId;

  const EditTeacherPage({
    Key? key,
    required this.teacher,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<EditTeacherPage> createState() => _EditTeacherPageState();
}

class _EditTeacherPageState extends State<EditTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _salaryController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _qualificationController = TextEditingController();

  List<Grade> _grades = [];
  List<String> _selectedSubjects = [];
  List<String> _selectedGradeLevels = [];
  String? _selectedEmploymentType;
  DateTime? _selectedHireDate;
  List<String> _qualifications = [];
  bool _isLoading = false;
  bool _isActive = true;

  final List<String> _employmentTypes = ['full_time', 'part_time', 'contract'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadGrades();
  }

  void _initializeForm() {
    _nameController.text = widget.teacher.name;
    _emailController.text = widget.teacher.email ?? '';
    _phoneController.text = widget.teacher.phone ?? '';
    _employeeIdController.text = widget.teacher.teacher?.employeeId ?? '';
    _salaryController.text = widget.teacher.teacher?.salary?.toString() ?? '';
    _experienceYearsController.text = widget.teacher.teacher?.experienceYears?.toString() ?? '';
    _selectedEmploymentType = widget.teacher.teacher?.employmentType;
    _qualifications = List<String>.from(widget.teacher.teacher?.qualifications ?? []);
    _isActive = widget.teacher.isActive ?? true;
    
    if (widget.teacher.teacher?.hireDate != null) {
      try {
        _selectedHireDate = DateTime.parse(widget.teacher.teacher!.hireDate!);
      } catch (e) {
        print('Error parsing hire date: $e');
      }
    }
    
    _selectedGradeLevels = widget.teacher.teacher?.gradeLevels.map((g) => g.id).toList() ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _salaryController.dispose();
    _experienceYearsController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    try {
      final response = await GradesService.getAllGrades(widget.schoolId);
      if (response.success) {
        setState(() {
          _grades = response.grades;
        });
      }
    } catch (e) {
      print('Error loading grades: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final teacherData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'subjects': _selectedSubjects,
        'gradeLevels': _selectedGradeLevels,
        'hireDate': _selectedHireDate?.toIso8601String().split('T')[0],
        'salary': _salaryController.text.isNotEmpty ? int.tryParse(_salaryController.text) : null,
        'employmentType': _selectedEmploymentType,
        'qualifications': _qualifications,
        'experienceYears': _experienceYearsController.text.isNotEmpty ? int.tryParse(_experienceYearsController.text) : null,
        'isActive': _isActive,
      };

      await TeachersService.updateTeacher(widget.schoolId, widget.teacher.id, teacherData);
      
      Get.snackbar(
        'success'.tr,
        'teacher_updated_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primaryBlue,
        colorText: Colors.white,
      );
      
      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'edit_teacher'.tr,
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: AppFonts.size20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionTitle('basic_information'.tr),
              SizedBox(height: 12.h),
              _buildTextField(_nameController, 'name'.tr, Icons.person_rounded, required: true),
              SizedBox(height: 16.h),
              _buildTextField(_emailController, 'email'.tr, Icons.email_rounded, keyboardType: TextInputType.emailAddress, required: true),
              SizedBox(height: 16.h),
              _buildTextField(_phoneController, 'phone'.tr, Icons.phone_rounded, keyboardType: TextInputType.phone),
              
              SizedBox(height: 24.h),
              // Employment Information
              _buildSectionTitle('employment_information'.tr),
              SizedBox(height: 12.h),
              _buildTextField(_employeeIdController, 'employee_id'.tr, Icons.badge_rounded),
              SizedBox(height: 16.h),
              _buildDropdown(
                'employment_type'.tr,
                _selectedEmploymentType,
                _employmentTypes,
                (value) => setState(() => _selectedEmploymentType = value),
                Icons.work_rounded,
              ),
              SizedBox(height: 16.h),
              _buildDatePicker('hire_date'.tr, _selectedHireDate, (date) => setState(() => _selectedHireDate = date)),
              SizedBox(height: 16.h),
              _buildTextField(_salaryController, 'salary'.tr, Icons.attach_money_rounded, keyboardType: TextInputType.number),
              SizedBox(height: 16.h),
              _buildTextField(_experienceYearsController, 'experience_years'.tr, Icons.trending_up_rounded, keyboardType: TextInputType.number),
              
              SizedBox(height: 24.h),
              // Qualifications
              _buildSectionTitle('qualifications'.tr),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_qualificationController, 'add_qualification'.tr, Icons.school_rounded),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_qualificationController.text.trim().isNotEmpty) {
                          setState(() {
                            _qualifications.add(_qualificationController.text.trim());
                            _qualificationController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                      label: Text(
                        'add'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      ),
                    ),
                  ),
                ],
              ),
              if (_qualifications.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _qualifications.map((q) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Chip(
                        label: Text(
                          q,
                          style: AppFonts.bodySmall.copyWith(
                            color: AppColors.primaryBlue,
                            fontSize: AppFonts.size12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onDeleted: () {
                          setState(() {
                            _qualifications.remove(q);
                          });
                        },
                        deleteIcon: Icon(
                          Icons.close_rounded,
                          size: 18.sp,
                          color: AppColors.primaryBlue,
                        ),
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              SizedBox(height: 24.h),
              // Grade Levels
              _buildSectionTitle('grade_levels'.tr),
              SizedBox(height: 12.h),
              _buildMultiSelectChips(
                _grades.map((g) => g.name).toList(),
                _grades.where((g) => _selectedGradeLevels.contains(g.id)).map((g) => g.name).toList(),
                (selected) => setState(() {
                  _selectedGradeLevels = _grades.where((g) => selected.contains(g.name)).map((g) => g.id).toList();
                }),
              ),
              
              SizedBox(height: 24.h),
              // Status
              _buildSectionTitle('status'.tr),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SwitchListTile(
                  title: Text(
                    'active'.tr,
                    style: AppFonts.bodyMedium.copyWith(
                      color: const Color(0xFF1F2937),
                      fontSize: AppFonts.size14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeColor: AppColors.primaryBlue,
                ),
              ),
              
              SizedBox(height: 32.h),
              // Submit Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              'update_teacher'.tr,
                              style: AppFonts.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: AppFonts.size16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: AppFonts.h3.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: AppFonts.size18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscureText = false,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppFonts.bodyMedium.copyWith(
          color: const Color(0xFF1F2937),
          fontSize: AppFonts.size14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppFonts.bodySmall.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: AppFonts.size12,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'required_field'.tr;
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        style: AppFonts.bodyMedium.copyWith(
          color: const Color(0xFF1F2937),
          fontSize: AppFonts.size14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppFonts.bodySmall.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: AppFonts.size12,
          ),
          prefixIcon: Container(
            margin: EdgeInsets.all(12.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
        items: items.map((item) {
          final displayText = item == 'full_time' 
              ? 'full_time'.tr 
              : item == 'part_time' 
                  ? 'part_time'.tr 
                  : item == 'contract' 
                      ? 'contract'.tr 
                      : item.replaceAll('_', ' ').toUpperCase();
          return DropdownMenuItem(
            value: item,
            child: Text(displayText),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? selectedDate, Function(DateTime) onDateSelected) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            onDateSelected(date);
          }
        },
        borderRadius: BorderRadius.circular(16.r),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: AppFonts.size12,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(12.w),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.calendar_today_rounded, color: AppColors.primaryBlue, size: 20.sp),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          ),
          child: Text(
            selectedDate != null
                ? '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'
                : 'select_date'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: selectedDate != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
              fontSize: AppFonts.size14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips(List<String> options, List<String> selected, Function(List<String>) onChanged) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(option),
          selected: isSelected,
           onSelected: (isSelected) {
            final newList = List<String>.from(selected);
            if (isSelected) {
              newList.add(option);
            } else {
              newList.remove(option);
            }
            onChanged(newList);
          },
        );
      }).toList(),
    );
  }
}

