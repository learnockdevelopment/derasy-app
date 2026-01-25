import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../services/teachers_service.dart';
import '../../../services/grades_service.dart';

class AddTeacherPage extends StatefulWidget {
  const AddTeacherPage({Key? key}) : super(key: key);

  @override
  State<AddTeacherPage> createState() => _AddTeacherPageState();
}

class _AddTeacherPageState extends State<AddTeacherPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _salaryController = TextEditingController();
  final _experienceYearsController = TextEditingController();
  final _qualificationController = TextEditingController();

  String? _schoolId;
  List<Grade> _grades = [];
  List<String> _selectedSubjects = [];
  List<String> _selectedGradeLevels = [];
  List<String> _selectedClasses = [];
  String? _selectedEmploymentType;
  DateTime? _selectedHireDate;
  List<String> _qualifications = [];
  bool _isLoading = false;
  bool _isActive = true;

  final List<String> _employmentTypes = ['full_time', 'part_time', 'contract'];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _schoolId = args?['schoolId'];
    _loadGrades();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _employeeIdController.dispose();
    _salaryController.dispose();
    _experienceYearsController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _loadGrades() async {
    if (_schoolId == null) return;
    try {
      final response = await GradesService.getAllGrades(_schoolId!);
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
    if (_schoolId == null) {
      Get.snackbar('error'.tr, 'school_id_not_available'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final teacherData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'subjects': _selectedSubjects,
        'gradeLevels': _selectedGradeLevels,
        'classList': _selectedClasses,
        'hireDate': _selectedHireDate?.toIso8601String().split('T')[0],
        'salary': _salaryController.text.isNotEmpty ? int.tryParse(_salaryController.text) : null,
        'employmentType': _selectedEmploymentType,
        'qualifications': _qualifications,
        'experienceYears': _experienceYearsController.text.isNotEmpty ? int.tryParse(_experienceYearsController.text) : null,
        'isActive': _isActive,
      };

      await TeachersService.addTeacher(_schoolId!, teacherData);
      
      Get.snackbar(
        'success'.tr,
        'teacher_added_successfully'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.blue1,
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
        backgroundColor: AppColors.blue1,
        elevation: 0,
        title: Text(
          'add_teacher'.tr,
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
          padding: Responsive.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionTitle('basic_information'.tr),
              SizedBox(height: Responsive.h(12)),
              _buildTextField(_nameController, 'name'.tr, Icons.person_rounded, required: true),
              SizedBox(height: Responsive.h(16)),
              _buildTextField(_emailController, 'email'.tr, Icons.email_rounded, keyboardType: TextInputType.emailAddress, required: true),
              SizedBox(height: Responsive.h(16)),
              _buildTextField(_phoneController, 'phone'.tr, Icons.phone_rounded, keyboardType: TextInputType.phone),
              SizedBox(height: Responsive.h(16)),
              _buildTextField(_usernameController, 'username'.tr, Icons.person_outline_rounded, required: true),
              SizedBox(height: Responsive.h(16)),
              _buildTextField(_passwordController, 'password'.tr, Icons.lock_rounded, obscureText: true, required: true),
              
              SizedBox(height: Responsive.h(24)),
              // Employment Information
              _buildSectionTitle('employment_information'.tr),
              SizedBox(height: Responsive.h(12)),
              _buildTextField(_employeeIdController, 'employee_id'.tr, Icons.badge_rounded),
              SizedBox(height: Responsive.h(16)),
              _buildDropdown(
                'employment_type'.tr,
                _selectedEmploymentType,
                _employmentTypes,
                (value) => setState(() => _selectedEmploymentType = value),
                Icons.work_rounded,
              ),
              SizedBox(height: Responsive.h(16)),
              _buildDatePicker('hire_date'.tr, _selectedHireDate, (date) => setState(() => _selectedHireDate = date)),
              SizedBox(height: Responsive.h(16)),
              _buildTextField(_salaryController, 'salary'.tr, Icons.attach_money_rounded, keyboardType: TextInputType.number),
              SizedBox(height: Responsive.h(16)),
              _buildTextField(_experienceYearsController, 'experience_years'.tr, Icons.trending_up_rounded, keyboardType: TextInputType.number),
              
              SizedBox(height: Responsive.h(24)),
              // Qualifications
              _buildSectionTitle('qualifications'.tr),
              SizedBox(height: Responsive.h(12)),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_qualificationController, 'add_qualification'.tr, Icons.school_rounded),
                  ),
                  SizedBox(width: Responsive.w(12)),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.blue1,
                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue1.withOpacity(0.3),
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
                        padding: Responsive.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              if (_qualifications.isNotEmpty) ...[
                SizedBox(height: Responsive.h(12)),
                Wrap(
                  spacing: Responsive.w(8),
                  runSpacing: Responsive.h(8),
                  children: _qualifications.map((q) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Responsive.r(20)),
                        border: Border.all(
                          color: AppColors.blue1.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Chip(
                        label: Text(
                          q,
                          style: AppFonts.bodySmall.copyWith(
                            color: AppColors.blue1,
                            fontSize: Responsive.sp(12),
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
                          size: Responsive.sp(18),
                          color: AppColors.blue1,
                        ),
                        backgroundColor: Colors.transparent,
                        padding: Responsive.symmetric(horizontal: 8),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              SizedBox(height: Responsive.h(24)),
              // Grade Levels
              _buildSectionTitle('grade_levels'.tr),
              SizedBox(height: Responsive.h(12)),
              _buildMultiSelectChips(
                _grades.map((g) => g.name).toList(),
                _selectedGradeLevels,
                (selected) => setState(() {
                  _selectedGradeLevels = _grades.where((g) => selected.contains(g.name)).map((g) => g.id).toList();
                }),
              ),
              
              SizedBox(height: Responsive.h(24)),
              // Status
              _buildSectionTitle('status'.tr),
              SizedBox(height: Responsive.h(12)),
              Container(
                padding: Responsive.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Responsive.r(16)),
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
                      fontSize: Responsive.sp(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  activeColor: AppColors.blue1,
                ),
              ),
              
              SizedBox(height: Responsive.h(32)),
              // Submit Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue1.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    padding: Responsive.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Responsive.r(16)),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: Responsive.h(20),
                          width: Responsive.w(20),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_rounded, color: Colors.white, size: Responsive.sp(20)),
                            SizedBox(width: Responsive.w(8)),
                            Text(
                              'add_teacher'.tr,
                              style: AppFonts.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.sp(16),
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
      padding: Responsive.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: Responsive.w(4),
            height: Responsive.h(24),
            decoration: BoxDecoration(
              color: AppColors.blue1,
              borderRadius: BorderRadius.circular(Responsive.r(2)),
            ),
          ),
          SizedBox(width: Responsive.w(12)),
          Text(
            title,
            style: AppFonts.h3.copyWith(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
              fontSize: Responsive.sp(18),
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
        borderRadius: BorderRadius.circular(Responsive.r(16)),
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
          fontSize: Responsive.sp(14),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppFonts.bodySmall.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: AppFonts.size12,
          ),
          prefixIcon: Container(
            margin: Responsive.all(12),
            padding: Responsive.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Responsive.r(10)),
            ),
            child: Icon(icon, color: AppColors.blue1, size: Responsive.sp(20)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            borderSide: BorderSide(color: AppColors.blue1, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: Responsive.symmetric(horizontal: 16, vertical: 16),
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
        borderRadius: BorderRadius.circular(Responsive.r(16)),
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
          fontSize: Responsive.sp(14),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppFonts.bodySmall.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: AppFonts.size12,
          ),
          prefixIcon: Container(
            margin: Responsive.all(12),
            padding: Responsive.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Responsive.r(10)),
            ),
            child: Icon(icon, color: AppColors.blue1, size: Responsive.sp(20)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Responsive.r(16)),
            borderSide: BorderSide(color: AppColors.blue1, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: Responsive.symmetric(horizontal: 16, vertical: 16),
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
        borderRadius: BorderRadius.circular(Responsive.r(16)),
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
        borderRadius: BorderRadius.circular(Responsive.r(16)),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: Responsive.sp(12),
            ),
            prefixIcon: Container(
              margin: Responsive.all(12),
              padding: Responsive.all(8),
              decoration: BoxDecoration(
                color: AppColors.blue1.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Responsive.r(10)),
              ),
              child: Icon(Icons.calendar_today_rounded, color: AppColors.blue1, size: Responsive.sp(20)),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.r(16)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.r(16)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Responsive.r(16)),
              borderSide: BorderSide(color: AppColors.blue1, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: Responsive.symmetric(horizontal: 16, vertical: 16),
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
      spacing: Responsive.w(8),
      runSpacing: Responsive.h(8),
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


