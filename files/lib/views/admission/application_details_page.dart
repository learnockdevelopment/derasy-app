import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/admission_models.dart';
import '../../services/admission_service.dart';
import '../../../widgets/shimmer_loading.dart';

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
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Application Details',
            style: AppFonts.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
        ),
        body: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: 6,
          itemBuilder: (context, index) {
            return ShimmerCard(
              height: 100.h,
              margin: EdgeInsets.only(bottom: 16.h),
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
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: Text(
            'Application not found',
            style: AppFonts.h4.copyWith(
              color: AppColors.textSecondary,
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
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Application Details',
          style: AppFonts.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(app.status),
                      color: Colors.white,
                      size: 32.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _getStatusLabel(app.status),
                    style: AppFonts.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Application Info
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // School Information
                  _buildInfoCard(
                    icon: Icons.school_rounded,
                    title: 'School Information',
                    children: [
                      _buildInfoRow('School Name', app.school.name),
                      if (app.school.address != null)
                        _buildInfoRow('Address', app.school.address!),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Child Information
                  _buildInfoCard(
                    icon: Icons.child_care_rounded,
                    title: 'Child Information',
                    children: [
                      _buildInfoRow('Name', app.child.fullName),
                      if (app.child.birthDate != null)
                        _buildInfoRow(
                          'Birth Date',
                          '${app.child.birthDate!.day}/${app.child.birthDate!.month}/${app.child.birthDate!.year}',
                        ),
                      if (app.child.gender != null)
                        _buildInfoRow('Gender', app.child.gender!.toUpperCase()),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Payment Information
                  if (app.payment != null)
                    _buildInfoCard(
                      icon: Icons.payments_rounded,
                      title: 'Payment Information',
                      children: [
                        _buildInfoRow(
                          'Status',
                          app.payment!.isPaid ? 'Paid' : 'Unpaid',
                          valueColor: app.payment!.isPaid
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        _buildInfoRow('Amount', '${app.payment!.amount} EGP'),
                      ],
                    ),
                  if (app.payment != null) SizedBox(height: 12.h),

                  // Application Details
                  _buildInfoCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Application Details',
                    children: [
                      _buildInfoRow(
                        'Application ID',
                        app.id,
                        copyable: true,
                      ),
                      _buildInfoRow(
                        'Submitted',
                        '${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year}',
                      ),
                      _buildInfoRow(
                        'Last Updated',
                        '${app.updatedAt.day}/${app.updatedAt.month}/${app.updatedAt.year}',
                      ),
                      if (app.notes != null && app.notes!.isNotEmpty)
                        _buildInfoRow('Notes', app.notes!),
                    ],
                  ),

                  // Interview Slots
                  if (app.preferredInterviewSlots.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    _buildInfoCard(
                      icon: Icons.event_rounded,
                      title: 'Preferred Interview Slots',
                      children: app.preferredInterviewSlots
                          .map((slot) => _buildInterviewSlot(slot))
                          .toList(),
                    ),
                  ],

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Text(
                title,
                style: AppFonts.h4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool copyable = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: AppFonts.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13.sp,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppFonts.bodyMedium.copyWith(
                      color: valueColor ?? AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                if (copyable)
                  IconButton(
                    icon: Icon(Icons.copy, size: 18.sp),
                    onPressed: () {
                      // Copy to clipboard
                      Get.snackbar(
                        'Copied',
                        'Application ID copied to clipboard',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.success,
                        colorText: Colors.white,
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 16.sp, color: AppColors.primaryBlue),
          SizedBox(width: 8.w),
          Text(
            '${slot.date.day}/${slot.date.month}/${slot.date.year}',
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Icon(Icons.access_time, size: 16.sp, color: AppColors.primaryBlue),
          SizedBox(width: 8.w),
          Text(
            '${slot.timeRange.from} - ${slot.timeRange.to}',
            style: AppFonts.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'under_review':
        return Icons.visibility;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'draft':
        return Icons.drafts;
      default:
        return Icons.info;
    }
  }
}

