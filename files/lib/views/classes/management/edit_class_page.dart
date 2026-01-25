import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../services/classes_service.dart';
import '../../../services/grades_service.dart';

class EditClassPage extends StatefulWidget {
  final SchoolClass schoolClass;
  final String schoolId;

  const EditClassPage({
    Key? key,
    required this.schoolClass,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  ClassesResponse? _classesResponse;
  String? _selectedStage;
  String? _selectedYear;
  String? _selectedSection;
  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadClassesData();
  }

  void _initializeForm() {
    _nameController.text = widget.schoolClass.name;
    _selectedStage = widget.schoolClass.stage?.id;
    _selectedYear = widget.schoolClass.grade?.id;
    _selectedSection = widget.schoolClass.section?.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadClassesData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final response = await ClassesService.getAllClasses(widget.schoolId);
      setState(() {
        _classesResponse = response;
      });
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_data'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStage == null || _selectedYear == null || _selectedSection == null) {
      Get.snackbar('error'.tr, 'please_select_all_fields'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final classData = {
        'name': _nameController.text.trim(),
        'grade': _selectedStage,
        'year': _selectedYear,
        'section': _selectedSection,
      };

      await ClassesService.updateClass(widget.schoolId, widget.schoolClass.id, classData);
      
      Get.snackbar(
        'success'.tr,
        'class_updated_successfully'.tr,
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
          'edit_class'.tr,
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(_nameController, 'class_name'.tr, Icons.class_rounded, required: true),
                    SizedBox(height: 24.h),
                    if (_classesResponse != null) ...[
                      _buildDropdown(
                        'stage'.tr,
                        _selectedStage,
                        _classesResponse!.gradesOffered.map((s) => s.id).toList(),
                        _classesResponse!.gradesOffered.map((s) => s.name).toList(),
                        (value) => setState(() {
                          _selectedStage = value;
                          _selectedYear = null; // Reset year when stage changes
                        }),
                        Icons.school_rounded,
                      ),
                      SizedBox(height: 16.h),
                      _buildDropdown(
                        'year'.tr,
                        _selectedYear,
                        _classesResponse!.years.map((y) => y.id).toList(),
                        _classesResponse!.years.map((y) => y.name).toList(),
                        (value) => setState(() => _selectedYear = value),
                        Icons.calendar_today_rounded,
                      ),
                      SizedBox(height: 16.h),
                      _buildDropdown(
                        'section'.tr,
                        _selectedSection,
                        _classesResponse!.divisions.map((d) => d.id).toList(),
                        _classesResponse!.divisions.map((d) => d.name).toList(),
                        (value) => setState(() => _selectedSection = value),
                        Icons.group_rounded,
                      ),
                    ],
                    SizedBox(height: 32.h),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
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
                                    'update_class'.tr,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
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
              color: AppColors.blue1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.blue1, size: 20.sp),
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
            borderSide: BorderSide(color: AppColors.blue1, width: 2),
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
    List<String> ids,
    List<String> names,
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
              color: AppColors.blue1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.blue1, size: 20.sp),
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
            borderSide: BorderSide(color: AppColors.blue1, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
        items: ids.asMap().entries.map((entry) {
          return DropdownMenuItem(
            value: entry.value,
            child: Text(names[entry.key]),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'required_field'.tr;
          }
          return null;
        },
      ),
    );
  }
}


