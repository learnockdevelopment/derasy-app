import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/admission_models.dart';
import '../../services/admission_service.dart';
import '../../widgets/shimmer_loading.dart';

class ApplicationDetailsPage extends StatefulWidget {
  const ApplicationDetailsPage({Key? key}) : super(key: key);

  @override
  State<ApplicationDetailsPage> createState() => _ApplicationDetailsPageState();
}

class _ApplicationDetailsPageState extends State<ApplicationDetailsPage> {
  Application? _application;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    final args = Get.arguments as Map<String, dynamic>?;
    if (args == null || args['applicationId'] == null) {
      Get.back();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final applicationId = args['applicationId'] as String;
      final application = await AdmissionService.getApplicationById(applicationId);
      if (mounted) {
        setState(() {
          _application = application;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      String errorMessage = 'Failed to load application. Please try again.';
      if (e is AdmissionException) {
        errorMessage = e.message;
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );

      Get.back();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'under_review':
        return AppColors.primaryBlue;
      case 'accepted':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'draft':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under Review';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Application Details',
            style: AppFonts.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.sp,
            ),
          ),
        ),
        body: ListView.builder(
          padding: EdgeInsets.all(12.w),
          itemCount: 6,
          itemBuilder: (context, index) {
            return ShimmerCard(
              height: 70.h,
              margin: EdgeInsets.only(bottom: 12.h),
            );
          },
        ),
      );
    }

    if (_application == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Text(
            'Application not found',
            style: AppFonts.h4.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
            ),
          ),
        ),
      );
    }

    final app = _application!;
    final statusColor = _getStatusColor(app.status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: statusColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Application Details',
          style: AppFonts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            // Compact Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      _getStatusIcon(app.status),
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
                          _getStatusLabel(app.status),
                          style: AppFonts.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'ID: ${app.id.substring(0, 8).toUpperCase()}',
                          style: AppFonts.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // School Information
            _buildInfoCard(
              icon: Icons.school_rounded,
              iconColor: const Color(0xFF6366F1),
              title: 'School Information',
              children: [
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'School Name',
                  value: app.school.name,
                  isHighlight: true,
                ),
                if (app.school.address != null) ...[
                  SizedBox(height: 8.h),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Address',
                    value: app.school.address!,
                  ),
                ],
              ],
            ),
            SizedBox(height: 10.h),

            // Child Information
            _buildInfoCard(
              icon: Icons.child_care_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Child Information',
              children: [
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Name',
                  value: app.child.fullName,
                  isHighlight: true,
                ),
                if (app.child.birthDate != null) ...[
                  SizedBox(height: 8.h),
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: 'Birth Date',
                    value: '${app.child.birthDate!.day}/${app.child.birthDate!.month}/${app.child.birthDate!.year}',
                  ),
                ],
                if (app.child.gender != null) ...[
                  SizedBox(height: 8.h),
                  _buildInfoRow(
                    icon: Icons.wc,
                    label: 'Gender',
                    value: app.child.gender!.toUpperCase(),
                  ),
                ],
              ],
            ),
            SizedBox(height: 10.h),

            // Payment Information
            if (app.payment != null)
              _buildInfoCard(
                icon: Icons.payments_rounded,
                iconColor: app.payment!.isPaid
                    ? AppColors.success
                    : AppColors.warning,
                title: 'Payment Information',
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: (app.payment!.isPaid
                              ? AppColors.success
                              : AppColors.warning)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: (app.payment!.isPaid
                                ? AppColors.success
                                : AppColors.warning)
                            .withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: app.payment!.isPaid
                                ? AppColors.success
                                : AppColors.warning,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            app.payment!.isPaid
                                ? Icons.check_circle
                                : Icons.pending,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.payment!.isPaid ? 'Paid' : 'Unpaid',
                                style: AppFonts.h4.copyWith(
                                  color: app.payment!.isPaid
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${app.payment!.amount} EGP',
                                style: AppFonts.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (app.payment != null) SizedBox(height: 10.h),

            // Application Details
            _buildInfoCard(
              icon: Icons.info_outline_rounded,
              iconColor: AppColors.primaryBlue,
              title: 'Application Details',
              children: [
                _buildInfoRow(
                  icon: Icons.fingerprint,
                  label: 'Application ID',
                  value: app.id,
                  copyable: true,
                ),
                SizedBox(height: 8.h),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'Submitted',
                  value: '${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year}',
                ),
                SizedBox(height: 8.h),
                _buildInfoRow(
                  icon: Icons.update,
                  label: 'Last Updated',
                  value: '${app.updatedAt.day}/${app.updatedAt.month}/${app.updatedAt.year}',
                ),
                if (app.notes != null && app.notes!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.note,
                          size: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notes',
                                style: AppFonts.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                app.notes!,
                                style: AppFonts.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Interview Slots
            if (app.preferredInterviewSlots.isNotEmpty) ...[
              SizedBox(height: 10.h),
              _buildInfoCard(
                icon: Icons.event_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Preferred Interview Slots',
                children: app.preferredInterviewSlots
                    .map((slot) => _buildInterviewSlot(slot))
                    .toList(),
              ),
            ],

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: iconColor, size: 16.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool copyable = false,
    bool isHighlight = false,
  }) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.grey100 : AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: isHighlight
            ? Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1.5,
              )
            : Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(icon, size: 14.sp, color: AppColors.primaryBlue),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: AppFonts.bodyMedium.copyWith(
                          color: valueColor ?? AppColors.textPrimary,
                          fontWeight: isHighlight
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: isHighlight ? 13.sp : 12.sp,
                        ),
                      ),
                    ),
                    if (copyable)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: value));
                            Get.snackbar(
                              'Copied',
                              'Application ID copied to clipboard',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.success,
                              colorText: Colors.white,
                              snackStyle: SnackStyle.FLOATING,
                            );
                          },
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(
                              Icons.copy,
                              size: 12.sp,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewSlot(InterviewSlot slot) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.calendar_today,
              size: 14.sp,
              color: const Color(0xFFF59E0B),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.date.day}/${slot.date.month}/${slot.date.year}',
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      '${slot.timeRange.from} - ${slot.timeRange.to}',
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'under_review':
        return Icons.visibility_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'draft':
        return Icons.edit_note_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}
