import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../models/student_models.dart';
import '../../../../services/guardians_service.dart';

class GuardiansPage extends StatefulWidget {
  final Student student;
  final String schoolId;

  const GuardiansPage({
    Key? key,
    required this.student,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<GuardiansPage> createState() => _GuardiansPageState();
}

class _GuardiansPageState extends State<GuardiansPage> {
  bool _isLoading = false;
  List<Guardian> _guardians = [];
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _relationController = TextEditingController();
  final _nationalIdController = TextEditingController();
  String _selectedNationality = 'egyptian'.tr;

  @override
  void initState() {
    super.initState();
    _loadGuardians();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _relationController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _loadGuardians() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll just show an empty list
      // TODO: Implement get guardians API when available
      setState(() {
        _guardians = [];
      });
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'Failed to load guardians: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addGuardian() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final guardian = Guardian(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        relation: _relationController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        nationality: _selectedNationality,
      );

      final response = await GuardiansService.updateStudentGuardians(
        widget.schoolId,
        widget.student.id,
        [..._guardians, guardian],
      );

      if (response.success) {
        setState(() {
          _guardians.add(guardian);
        });

        // Clear form
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _relationController.clear();
        _nationalIdController.clear();
        _selectedNationality = 'egyptian'.tr;

        Get.snackbar(
          'success'.tr,
          'guardian_added_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          response.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_add_guardian'.tr + ': ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          '${'guardians'.tr} - ${widget.student.fullName}',
          style: AppFonts.h4.copyWith(
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add Guardian Form
          _buildAddGuardianForm(),

          // Guardians List
          Expanded(
            child: _buildGuardiansList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGuardianForm() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey100.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person_add,
                  color: AppColors.blue1,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'add_guardian'.tr,
                  style: AppFonts.h5.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Name Field
            _buildTextField(
              controller: _nameController,
              label: 'full_name'.tr,
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_guardian_name'.tr;
                }
                return null;
              },
            ),

            SizedBox(height: 12.h),

            // Phone Field
            _buildTextField(
              controller: _phoneController,
              label: 'phone_number_label'.tr,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_phone_number'.tr;
                }
                return null;
              },
            ),

            SizedBox(height: 12.h),

            // Email Field
            _buildTextField(
              controller: _emailController,
              label: 'email_label'.tr,
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_email'.tr;
                }
                if (!GetUtils.isEmail(value)) {
                  return 'please_enter_valid_email'.tr;
                }
                return null;
              },
            ),

            SizedBox(height: 12.h),

            // Relation Field
            _buildTextField(
              controller: _relationController,
              label: 'relation'.tr,
              icon: Icons.family_restroom,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_relation'.tr;
                }
                return null;
              },
            ),

            SizedBox(height: 12.h),

            // National ID Field
            _buildTextField(
              controller: _nationalIdController,
              label: 'national_id'.tr,
              icon: Icons.badge,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_national_id'.tr;
                }
                return null;
              },
            ),

            SizedBox(height: 12.h),

            // Nationality Dropdown
            _buildNationalityDropdown(),

            SizedBox(height: 16.h),

            // Add Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addGuardian,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Add Guardian',
                        style: AppFonts.buttonMedium.copyWith(
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.blue1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
    );
  }

  Widget _buildNationalityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedNationality,
      decoration: InputDecoration(
        labelText: 'nationality'.tr,
        prefixIcon: Icon(Icons.flag, size: 20.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: AppColors.blue1),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      items: ['egyptian'.tr, 'other'.tr].map((nationality) {
        return DropdownMenuItem<String>(
          value: nationality,
          child: Text(nationality),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedNationality = value!;
        });
      },
    );
  }

  Widget _buildGuardiansList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_guardians.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom_outlined,
              size: 64.sp,
              color: AppColors.grey100,
            ),
            SizedBox(height: 16.h),
            Text(
              'no_guardians_found'.tr,
              style: AppFonts.h4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'add_guardians_for_student'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _guardians.length,
      itemBuilder: (context, index) {
        final guardian = _guardians[index];
        return _buildGuardianCard(guardian);
      },
    );
  }

  Widget _buildGuardianCard(Guardian guardian) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey100.withOpacity(0.1),
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
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.blue1,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guardian.name,
                      style: AppFonts.h5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      guardian.relation,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.phone, guardian.phone),
          _buildInfoRow(Icons.email, guardian.email),
          _buildInfoRow(Icons.badge, guardian.nationalId),
          _buildInfoRow(Icons.flag, guardian.nationality),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppColors.textSecondary),
          SizedBox(width: 8.w),
          Text(
            text,
            style: AppFonts.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

