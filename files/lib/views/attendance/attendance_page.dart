import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../services/attendance_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool _isLoading = false;
  List<School> _schools = [];
  School? _selectedSchool;
  List<AttendanceRecord> _attendanceRecords = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SchoolsService.getAllSchools();
      if (response.success) {
        setState(() {
          _schools = response.schools;
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_schools'.tr + ': ${e.toString()}',
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

  Future<void> _loadAttendance() async {
    if (_selectedSchool == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await AttendanceService.getAllAttendance(_selectedSchool!.id);
      if (response.success) {
        setState(() {
          _attendanceRecords = response.attendances ?? [];
        });
      }
    } catch (e) {
      // Check if it's an authorization error
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('403')) {
        Get.snackbar(
          'access_denied'.tr,
          'no_permission_view_attendance'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.warning,
          colorText: Colors.white,
          duration: Duration(seconds: 4),
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_to_load_attendance'.tr + ': ${e.toString()}',
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendance();
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
          'attendance'.tr,
          style: AppFonts.h3.copyWith(
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // School Selection
          _buildSchoolSelection(),

          // Date Selection
          if (_selectedSchool != null) _buildDateSelection(),

          // Attendance Content
          Expanded(
            child: _selectedSchool == null
                ? _buildSchoolSelectionPrompt()
                : _buildAttendanceContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolSelection() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: AppColors.blue1,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'select_school'.tr,
                style: AppFonts.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          DropdownButtonFormField<School>(
            value: _selectedSchool,
            decoration: InputDecoration(
              hintText: 'choose_a_school'.tr,
              hintStyle: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
                
              ),
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
            items: _schools.map((school) {
              return DropdownMenuItem<School>(
                value: school,
                child: Text(
                  school.name,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }).toList(),
            onChanged: (School? school) {
              setState(() {
                _selectedSchool = school;
                _attendanceRecords = [];
              });
              if (school != null) {
                _loadAttendance();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
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
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: AppColors.blue1,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            '${'date'.tr}: ',
            style: AppFonts.h5.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey300),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolSelectionPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 64.sp,
            color: AppColors.grey100,
          ),
          SizedBox(height: 16.h),
          Text(
            'select_a_school'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'choose_school_view_attendance'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attendanceRecords.isEmpty) {
      return _buildEmptyAttendance();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildEmptyAttendance() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64.sp,
            color: AppColors.grey100,
          ),
          SizedBox(height: 16.h),
          Text(
            'no_attendance_records'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'no_attendance_for_date'.tr,
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
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'contact_admin_attendance'.tr,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.warning,
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

  Widget _buildAttendanceCard(AttendanceRecord record) {
    Color statusColor;
    IconData statusIcon;

    switch (record.status.toLowerCase()) {
      case 'present':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'absent':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      case 'late':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = AppColors.grey100;
        statusIcon = Icons.help;
    }

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
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.childName ?? 'unknown_student'.tr,
                  style: AppFonts.h5.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${'date'.tr}: ${record.date}',
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (record.checkInTime != null)
                  Text(
                    '${'check_in'.tr}: ${record.checkInTime}',
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
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              record.status.toUpperCase(),
              style: AppFonts.labelMedium.copyWith(
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

