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
        errorMessage.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );

      Get.back();
    }
  }

  Color _getStatusColor(String status, bool isPaid) {
    if (status.toLowerCase() == 'pending' && isPaid) {
      return AppColors.success;
    }
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
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status, bool isPaid) {
    if (status.toLowerCase() == 'pending' && isPaid) {
      return '${'paid'.tr} / ${'pending'.tr}';
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return 'pending'.tr;
      case 'under_review':
        return 'under_review'.tr;
      case 'accepted':
        return 'accepted'.tr;
      case 'rejected':
        return 'rejected'.tr;
      case 'draft':
        return 'draft'.tr;
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
            'application_details_title'.tr,
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
            'application_not_found'.tr,
            style: AppFonts.h4.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14.sp,
            ),
          ),
        ),
      );
    }

    final app = _application!;
    final isPaid = app.payment?.isPaid ?? false;
    final statusColor = _getStatusColor(app.status, isPaid);

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
          'application_details_title'.tr,
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
                      _getStatusIcon(app.status, isPaid),
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
                          _getStatusLabel(app.status, isPaid),
                          style: AppFonts.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${'id'.tr}: ${app.id.substring(0, 8).toUpperCase()}',
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
              title: 'school_information'.tr,
              children: [
                _buildInfoRow(
                  icon: Icons.business,
                  label: 'school_name'.tr,
                  value: app.school.name,
                  isHighlight: true,
                ),
                if (app.school.address != null) ...[
                  SizedBox(height: 8.h),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'address'.tr,
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
              title: 'student_information'.tr,
              children: [
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'full_name'.tr,
                  value: app.child.arabicFullName ?? app.child.fullName,
                  isHighlight: true,
                ),
                if (app.child.birthDate != null) ...[
                  SizedBox(height: 8.h),
                  _buildInfoRow(
                    icon: Icons.cake,
                    label: 'birth_date'.tr,
                    value: _formatDate(app.child.birthDate!),
                  ),
                ],
                if (app.child.gender != null) ...[
                  SizedBox(height: 8.h),
                  _buildInfoRow(
                    icon: Icons.wc,
                    label: 'gender'.tr,
                    value: app.child.gender!.toLowerCase() == 'male' ? 'male'.tr : 'female'.tr,
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
                title: 'payment_information'.tr,
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
                                app.payment!.isPaid ? 'paid'.tr : 'pending'.tr,
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
                                '${app.payment!.amount} ${'egp'.tr}',
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
              title: 'application_details_title'.tr,
              children: [
                _buildInfoRow(
                  icon: Icons.fingerprint,
                  label: 'application_id_label'.tr,
                  value: app.id,
                  copyable: true,
                ),
                SizedBox(height: 8.h),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: 'submitted_date'.tr,
                  value: _formatDate(app.submittedAt ?? app.createdAt),
                ),
                SizedBox(height: 8.h),
                _buildInfoRow(
                  icon: Icons.update,
                  label: 'last_updated'.tr,
                  value: _formatDate(app.updatedAt),
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
                                'notes'.tr,
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
            
            // Confirmed Interview (if exists)
            if (app.interview?.date != null) ...[
              SizedBox(height: 10.h),
              _buildInfoCard(
                icon: Icons.event_available_rounded,
                iconColor: AppColors.success,
                title: 'interview_scheduled'.tr,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14.sp, color: AppColors.success),
                            SizedBox(width: 8.w),
                            Text(
                              _formatDate(app.interview!.date!),
                              style: AppFonts.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                        if (app.interview!.time?.isNotEmpty ?? false) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 14.sp, color: AppColors.success),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  _formatTimeDisplay(app.interview!.time),
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (app.interview!.location != null) ...[
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14.sp, color: AppColors.success),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  app.interview!.location!,
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // Interview Slots
            if (app.preferredInterviewSlots.isNotEmpty) ...[
              SizedBox(height: 10.h),
              _buildInfoCard(
                icon: Icons.event_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'preferred_interview_slots'.tr,
                children: app.preferredInterviewSlots
                    .map((slot) => _buildInterviewSlot(slot))
                    .toList(),
              ),
            ],

            // Events Timeline
            if (app.events.isNotEmpty) ...[
              SizedBox(height: 10.h),
              _buildEventsTimeline(app.events),
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
                              'copied'.tr,
                              'application_id_copied'.tr,
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
                  _formatDate(slot.date),
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
                      '${_getWeekdayKey(slot.date.weekday).tr.toUpperCase()} - ${_formatTimeDisplay("${slot.timeRange.from} - ${slot.timeRange.to}")}',
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

  IconData _getStatusIcon(String status, bool isPaid) {
    if (status.toLowerCase() == 'pending' && isPaid) {
      return Icons.check_circle_outline_rounded;
    }
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'under_review':
        return Icons.search_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'draft':
        return Icons.edit_note_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget _buildEventsTimeline(List<ApplicationEvent> events) {
    return _buildInfoCard(
      icon: Icons.history_rounded,
      iconColor: AppColors.primaryBlue,
      title: 'events_timeline'.tr,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          separatorBuilder: (context, index) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final event = events[events.length - 1 - index]; // Show latest first
            return _buildEventItem(event);
          },
        ),
      ],
    );
  }

  Widget _buildEventItem(ApplicationEvent event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: _getEventColor(event.type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEventIcon(event.type),
                size: 14.sp,
                color: _getEventColor(event.type),
              ),
            ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      event.title.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(event.date),
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
              if (event.description != null && event.description!.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  event.description!.tr,
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
              if (event.createdBy != null) ...[
                SizedBox(height: 4.h),
                Text(
                  '${'created_by'.tr}: ${event.createdBy!.name}',
                  style: AppFonts.bodySmall.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 9.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'status_change':
        return AppColors.primaryBlue;
      case 'note':
        return const Color(0xFF6B7280);
      case 'interview':
        return const Color(0xFFF59E0B);
      case 'document':
        return const Color(0xFF10B981);
      case 'payment':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'status_change':
        return Icons.swap_horiz_rounded;
      case 'note':
        return Icons.note_alt_rounded;
      case 'interview':
        return Icons.event_rounded;
      case 'document':
        return Icons.description_rounded;
      case 'payment':
        return Icons.payments_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getWeekdayKey(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return '';
    }
  }
  String _formatDate(DateTime date) {
    final monthKeys = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    return '${date.day} ${monthKeys[date.month - 1].tr} ${date.year}';
  }

  String _formatTimeDisplay(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    
    // Check if it's a range like "HH:mm - HH:mm" or "HH:mm-HH:mm"
    final rangeMatch = RegExp(r"(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})").firstMatch(timeStr);
    if (rangeMatch != null) {
      final from = rangeMatch.group(1);
      final to = rangeMatch.group(2);
      return "${'from_time'.tr} $from ${'to_time'.tr} $to";
    }
    
    return timeStr;
  }
}
