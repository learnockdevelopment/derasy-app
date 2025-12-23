import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_fonts.dart';
import '../../../../models/student_models.dart';
import '../../../../services/clinic_records_service.dart';

class ClinicRecordsPage extends StatefulWidget {
  final Student student;
  final String schoolId;

  const ClinicRecordsPage({
    Key? key,
    required this.student,
    required this.schoolId,
  }) : super(key: key);

  @override
  State<ClinicRecordsPage> createState() => _ClinicRecordsPageState();
}

class _ClinicRecordsPageState extends State<ClinicRecordsPage> {
  bool _isLoading = false;
  StudentClinicInfo? _clinicInfo;
  List<ClinicRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadClinicRecords();
  }

  Future<void> _loadClinicRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ClinicRecordsService.getStudentClinicRecords(
        widget.schoolId,
        widget.student.id,
      );
      if (response.success) {
        setState(() {
          _clinicInfo = response.student;
          _records = response.clinicRecords;
        });
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_clinic_records'.tr + ': ${e.toString()}',
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
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          '${'clinic_records'.tr} - ${widget.student.fullName}',
          style: AppFonts.h4.copyWith(
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Medical Info
          if (_clinicInfo != null) _buildStudentInfo(),

          SizedBox(height: 16.h),

          // Clinic Records
          _buildRecordsSection(),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Container(
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
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.local_hospital,
                  color: AppColors.success,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'student_medical_information'.tr,
                      style: AppFonts.h5.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _clinicInfo!.fullName,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_clinicInfo!.medicalNotes?.isNotEmpty == true) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 16.sp,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'medical_notes'.tr,
                        style: AppFonts.labelMedium.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _clinicInfo!.medicalNotes!,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordsSection() {
    return Container(
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
                Icons.assignment,
                color: AppColors.primaryBlue,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'clinic_records'.tr,
                style: AppFonts.h5.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_records.isEmpty)
            _buildEmptyRecords()
          else
            ..._records.map((record) => _buildRecordCard(record)).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyRecords() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64.sp,
            color: AppColors.grey100,
          ),
          SizedBox(height: 16.h),
          Text(
            'no_clinic_records'.tr,
            style: AppFonts.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'no_clinic_records_found'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(ClinicRecord record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date and Status
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16.sp,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 8.w),
              Text(
                _formatDate(record.date),
                style: AppFonts.labelMedium.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'clinic_visit'.tr,
                  style: AppFonts.labelSmall.copyWith(
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Symptoms
          if (record.symptoms?.isNotEmpty == true)
            _buildInfoSection('symptoms'.tr, record.symptoms!, Icons.warning),

          // Diagnosis
          if (record.diagnosis?.isNotEmpty == true)
            _buildInfoSection(
                'diagnosis'.tr, record.diagnosis!, Icons.medical_services),

          // Treatment
          if (record.treatment?.isNotEmpty == true)
            _buildInfoSection('treatment'.tr, record.treatment!, Icons.healing),

          // Medication
          if (record.medication?.isNotEmpty == true)
            _buildInfoSection(
                'medication'.tr, record.medication!, Icons.medication),

          // Follow-up
          if (record.followUp?.isNotEmpty == true)
            _buildInfoSection('follow_up'.tr, record.followUp!, Icons.schedule),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: AppColors.textSecondary),
              SizedBox(width: 8.w),
              Text(
                title,
                style: AppFonts.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Padding(
            padding: EdgeInsets.only(left: 24.w),
            child: Text(
              content,
              style: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
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
