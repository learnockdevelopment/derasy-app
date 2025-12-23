import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../models/student_models.dart';
import '../../../../services/pickup_permissions_service.dart';

class PickupPermissionsPage extends StatefulWidget {
  final Student student;
  final String schoolId;

  const PickupPermissionsPage({
    Key? key,
    required this.student,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<PickupPermissionsPage> createState() => _PickupPermissionsPageState();
}

class _PickupPermissionsPageState extends State<PickupPermissionsPage> {
  bool _isLoading = false;
  List<PickupPermission> _permissions = [];
  final _formKey = GlobalKey<FormState>();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _relationController = TextEditingController();
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  @override
  void dispose() {
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _loadPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await PickupPermissionsService.getPickupPermissions(
        widget.schoolId,
        widget.student.id,
      );
      if (response.success) {
        setState(() {
          _permissions = response.permissions;
        });
      }
    } catch (e) {
      // Check if it's a 405 Method Not Allowed error
      if (e.toString().contains('405') ||
          e.toString().contains('Method Not Allowed')) {
        Get.snackbar(
          'feature_not_available'.tr,
          'pickup_retrieval_not_available'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
        // Set empty permissions list to show add form
        setState(() {
          _permissions = [];
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_load_pickup_permissions'.tr + ': ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addPermission() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiresAt == null) {
      Get.snackbar(
        'error'.tr,
        'please_select_expiration_date'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final permission = PickupPermission(
        id: '', // Will be assigned by the server
        guardianName: _guardianNameController.text.trim(),
        guardianPhone: _guardianPhoneController.text.trim(),
        relation: _relationController.text.trim(),
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        expiresAt: _expiresAt!.toIso8601String(),
      );

      final response = await PickupPermissionsService.addPickupPermission(
        widget.schoolId,
        widget.student.id,
        permission.toJson(),
      );

      if (response.success) {
        setState(() {
          _permissions.add(permission);
        });

        // Clear form
        _guardianNameController.clear();
        _guardianPhoneController.clear();
        _relationController.clear();
        _expiresAt = null;

        Get.snackbar(
          'success'.tr,
          'pickup_permission_added'.tr,
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
        'failed_to_add_pickup_permission'.tr + ': ${e.toString()}',
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

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 3650)),
    );
    if (picked != null && picked != _expiresAt) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          '${'pickup_permissions'.tr} - ${widget.student.fullName}',
          style: AppFonts.h4.copyWith(
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add Permission Form
          _buildAddPermissionForm(),

          // Permissions List
          Expanded(
            child: _buildPermissionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPermissionForm() {
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
                  Icons.car_rental,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'add_pickup_permission'.tr,
                  style: AppFonts.h5.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Guardian Name Field
            _buildTextField(
              controller: _guardianNameController,
              label: 'guardian_name'.tr,
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_guardian_name'.tr;
                }
                return null;
              },
            ),

            SizedBox(height: 12.h),

            // Guardian Phone Field
            _buildTextField(
              controller: _guardianPhoneController,
              label: 'guardian_phone'.tr,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'please_enter_phone'.tr;
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

            // Expiration Date Field
            _buildDateField(),

            SizedBox(height: 16.h),

            // Add Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
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
                        'add_permission'.tr,
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
          borderSide: BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        hintStyle: AppFonts.bodySmall.copyWith(
          color: AppColors.textSecondary,
          
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectExpirationDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey300),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20.sp, color: AppColors.grey500),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                _expiresAt == null
                    ? 'select_expiration_date'.tr
                    : '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}',
                style: AppFonts.bodyMedium.copyWith(
                  color: _expiresAt == null
                      ? AppColors.grey500
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.car_rental_outlined,
              size: 64.sp,
              color: AppColors.grey100,
            ),
            SizedBox(height: 16.h),
            Text(
              'no_pickup_permissions'.tr,
              style: AppFonts.h4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'add_pickup_permissions_above'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              margin: EdgeInsets.symmetric(horizontal: 32.w),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'note_some_schools_pickup'.tr,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _permissions.length,
      itemBuilder: (context, index) {
        final permission = _permissions[index];
        return _buildPermissionCard(permission);
      },
    );
  }

  Widget _buildPermissionCard(PickupPermission permission) {
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
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.car_rental,
                  color: AppColors.warning,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.guardianName,
                      style: AppFonts.h5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      permission.relation,
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: permission.isActive
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.grey100.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  permission.isActive ? 'active'.tr : 'inactive'.tr,
                  style: AppFonts.labelSmall.copyWith(
                    color: permission.isActive
                        ? AppColors.success
                        : AppColors.grey500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(Icons.phone, permission.guardianPhone),
          _buildInfoRow(Icons.schedule,
              '${'expires'.tr}: ${_formatDate(permission.expiresAt)}'),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
