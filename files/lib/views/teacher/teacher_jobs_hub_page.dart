import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/teacher_models.dart';
import '../../services/teacher_service.dart';
import '../../services/user_storage_service.dart';
import '../../widgets/loading_page.dart';

class TeacherJobsHubPage extends StatefulWidget {
  const TeacherJobsHubPage({Key? key}) : super(key: key);

  @override
  State<TeacherJobsHubPage> createState() => _TeacherJobsHubPageState();
}

class _TeacherJobsHubPageState extends State<TeacherJobsHubPage> {
  late Future<List<TeacherJob>> _jobsFuture;
  TeacherModel? _profile;
  bool _loadingProfile = true;
  List<TeacherJobApplication> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _refreshJobs();
  }

  void _loadProfile() {
    final user = UserStorageService.getCurrentUser();
    TeacherService.getTeacherProfile(user?.id ?? 'teacher_123').then((profile) {
      if (mounted) {
        setState(() {
          _profile = profile;
          _loadingProfile = false;
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    });
  }

  void _refreshJobs() {
    setState(() {
      _jobsFuture = TeacherService.getJobs();
    });
    TeacherService.getMyApplications().then((apps) {
      if (mounted) {
        setState(() {
          _applications = apps;
        });
      }
    }).catchError((e) {
      print('Error fetching applications: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppConfigController.to.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.04);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Responsive.isRTL ? IconlyLight.arrow_right_2 : IconlyLight.arrow_left_2,
            color: textColor,
          ),
        ),
        title: Text(
          'jobs'.tr,
          style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadProfile();
          _refreshJobs();
        },
        color: AppColors.salesAccent,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: Responsive.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Premium Glassmorphic Portal Header
              Container(
                width: double.infinity,
                padding: Responsive.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [AppColors.salesAccent.withOpacity(0.2), const Color(0xFF1E293B)]
                        : [AppColors.salesAccent.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(Responsive.r(32)),
                  border: Border.all(color: AppColors.salesAccent.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppColors.salesAccent.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: Responsive.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.salesAccent,
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                            boxShadow: [
                              BoxShadow(color: AppColors.salesAccent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Icon(IconlyBold.work, color: Colors.white, size: Responsive.sp(24)),
                        ),
                        SizedBox(width: Responsive.w(16)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'jobs_portal'.tr,
                                style: AppFonts.AlmaraiBold20.copyWith(color: textColor),
                              ),
                              SizedBox(height: Responsive.h(4)),
                              Text(
                                'manage_jobs_cv'.tr,
                                style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(24)),
                    
                    // Action button
                    ElevatedButton.icon(
                      onPressed: () => Get.toNamed(AppRoutes.teacherCvProfile)?.then((_) {
                        _refreshJobs();
                        _loadProfile();
                      }),
                      icon: Icon(
                        _profile?.hasCv == true ? IconlyLight.document : IconlyLight.plus,
                        color: Colors.white,
                        size: Responsive.sp(18),
                      ),
                      label: Text(
                        _profile?.hasCv == true 
                            ? 'edit_cv'.tr 
                            : 'add_your_cv_to_apply'.tr,
                        style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.salesAccent,
                        padding: Responsive.symmetric(vertical: 14, horizontal: 20),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.r(16))),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: Responsive.h(28)),
              
              _buildSubmittedApplicationsSection(isDark),

              // 2. Dynamic FutureBuilder Feed List
              FutureBuilder<List<TeacherJob>>(
                future: _jobsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: ModernLoadingWidget(size: 60),
                      ),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'error'.tr,
                          style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.error),
                        ),
                      ),
                    );
                  }

                  final jobs = snapshot.data ?? [];
                  if (jobs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: Responsive.all(32),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IconlyLight.document, size: Responsive.sp(48), color: AppColors.textSecondary.withOpacity(0.4)),
                          SizedBox(height: Responsive.h(16)),
                          Text(
                            'no_jobs_found'.tr,
                            style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final recentJobs = jobs.take(2).toList();
                  final otherJobs = jobs.skip(2).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recentJobs.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: Responsive.w(4),
                              height: Responsive.h(16),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: Responsive.w(8)),
                            Text(
                              'recent_jobs'.tr,
                              style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(16)),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentJobs.length,
                          separatorBuilder: (context, index) => SizedBox(height: Responsive.h(16)),
                          itemBuilder: (context, index) {
                            final job = recentJobs[index];
                            return _buildJobFeedCard(job, cardBg, borderColor, shadowColor, textColor);
                          },
                        ),
                        if (otherJobs.isNotEmpty) SizedBox(height: Responsive.h(28)),
                      ],
                      if (otherJobs.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: Responsive.w(4),
                              height: Responsive.h(16),
                              decoration: BoxDecoration(
                                color: AppColors.salesAccent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: Responsive.w(8)),
                            Text(
                              'other_jobs'.tr,
                              style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(16)),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: otherJobs.length,
                          separatorBuilder: (context, index) => SizedBox(height: Responsive.h(16)),
                          itemBuilder: (context, index) {
                            final job = otherJobs[index];
                            return _buildJobFeedCard(job, cardBg, borderColor, shadowColor, textColor);
                          },
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildJobFeedCard(
    TeacherJob job,
    Color cardBg,
    Color borderColor,
    Color shadowColor,
    Color textColor,
  ) {
    final currencyText = 'salary_currency'.tr;
    final isDark = AppConfigController.to.isDarkMode;
    
    return Container(
      width: double.infinity,
      padding: Responsive.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(28)),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Icon, Title and Department
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: Responsive.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : AppColors.grey50,
                  borderRadius: BorderRadius.circular(Responsive.r(16)),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(IconlyLight.work, color: AppColors.salesAccent, size: Responsive.sp(24)),
              ),
              SizedBox(width: Responsive.w(14)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: AppFonts.AlmaraiBold16.copyWith(color: textColor, letterSpacing: -0.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      job.department,
                      style: AppFonts.AlmaraiMedium12.copyWith(color: AppColors.salesAccent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(16)),

          // Row 2: Premium Tag labels
          Wrap(
            spacing: Responsive.w(8),
            runSpacing: Responsive.h(8),
            children: [
              Container(
                padding: Responsive.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyBold.wallet, color: Colors.amber.shade700, size: Responsive.sp(14)),
                    SizedBox(width: Responsive.w(6)),
                    Text(
                      '${job.salary.toStringAsFixed(0)} $currencyText',
                      style: AppFonts.AlmaraiBold10.copyWith(color: Colors.amber.shade800),
                    ),
                  ],
                ),
              ),
              Container(
                padding: Responsive.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.salesAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.r(20)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(IconlyLight.time_circle, color: AppColors.salesAccent, size: Responsive.sp(14)),
                    SizedBox(width: Responsive.w(6)),
                    Text(
                      job.employmentType == 'full_time' ? 'full_time'.tr : 'part_time'.tr,
                      style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.salesAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: Responsive.h(16)),
            child: Divider(color: isDark ? Colors.white12 : AppColors.grey200, height: 1),
          ),

          // Paragraph: Description
          Text(
            job.description,
            style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
          
          if (job.requirements.isNotEmpty) ...[
            SizedBox(height: Responsive.h(16)),
            Text(
              'job_requirements'.tr,
              style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
            ),
            SizedBox(height: Responsive.h(10)),
            Column(
              children: job.requirements.map((req) {
                return Padding(
                  padding: EdgeInsets.only(bottom: Responsive.h(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(IconlyLight.tick_square, color: Colors.teal, size: Responsive.sp(16)),
                      SizedBox(width: Responsive.w(8)),
                      Expanded(
                        child: Text(
                          req,
                          style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: Responsive.h(20)),
          (() {
            final app = _applications.firstWhereOrNull((a) => a.jobId == job.id);
            final hasApplied = app != null;
            
            Color buttonBg = AppColors.salesAccent;
            String labelText = 'apply_now'.tr;
            IconData iconData = IconlyBold.send;
            
            if (hasApplied) {
              final status = app.status.toLowerCase();
              if (status.contains('reject')) {
                buttonBg = Colors.red;
                labelText = 'rejected'.tr;
                iconData = IconlyBold.close_square;
              } else {
                buttonBg = Colors.grey.shade600;
                labelText = 'applied'.tr;
                iconData = IconlyBold.tick_square;
              }
            }

            return SizedBox(
              width: double.infinity,
              height: Responsive.h(44),
              child: ElevatedButton.icon(
                onPressed: hasApplied ? null : () => _handleApplyPressed(job),
                icon: Icon(iconData, color: Colors.white, size: Responsive.sp(18)),
                label: Text(
                  labelText,
                  style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonBg,
                  disabledBackgroundColor: buttonBg.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(Responsive.r(16)),
                  ),
                  elevation: hasApplied ? 0 : 4,
                  shadowColor: buttonBg.withOpacity(0.5),
                ),
              ),
            );
          }()),
        ],
      ),
    );
  }

  void _handleApplyPressed(TeacherJob job) {
    if (_profile == null || !_profile!.hasCv) {
      final isDark = AppConfigController.to.isDarkMode;
      final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
      final textColor = isDark ? Colors.white : AppColors.textPrimary;
      final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
      final borderColor = isDark ? Colors.white12 : AppColors.grey300;

      Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: Responsive.all(24),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(Responsive.r(24)),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: Responsive.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    IconlyBold.document,
                    color: Colors.amber,
                    size: 48,
                  ),
                ),
                SizedBox(height: Responsive.h(20)),
                Text(
                  'add_your_cv_to_apply'.tr,
                  style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.h(8)),
                Text(
                  'please_add_cv_first'.tr,
                  style: AppFonts.AlmaraiRegular12.copyWith(color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: Responsive.h(24)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                          ),
                          padding: Responsive.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'cancel'.tr,
                          style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                        ),
                      ),
                    ),
                    SizedBox(width: Responsive.w(12)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          Get.toNamed(AppRoutes.teacherCvProfile)?.then((_) {
                            _refreshJobs();
                            _loadProfile();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.salesAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Responsive.r(12)),
                          ),
                          padding: Responsive.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          'add_cv'.tr,
                          style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      _showApplyBottomSheet(job);
    }
  }

  void _showApplyBottomSheet(TeacherJob job) {
    final isDark = AppConfigController.to.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryTextColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;
    bool isSubmitting = false;
    
    final TextEditingController _coverLetterController = TextEditingController(
      text: 'cover_letter_default'.tr,
    );

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: Responsive.all(24),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(30))),
              border: Border.all(color: borderColor),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: Responsive.w(40),
                      height: Responsive.h(4),
                      decoration: BoxDecoration(
                        color: AppColors.grey300.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.h(20)),
                  Row(
                    children: [
                      Container(
                        padding: Responsive.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.salesAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(IconlyBold.work, color: AppColors.salesAccent, size: Responsive.sp(20)),
                      ),
                      SizedBox(width: Responsive.w(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'job_application'.tr,
                              style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                            ),
                            SizedBox(height: Responsive.h(2)),
                            Text(
                              job.title,
                              style: AppFonts.AlmaraiRegular12.copyWith(color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.h(24)),
                  Text(
                    'cover_letter'.tr,
                    style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  TextField(
                    controller: _coverLetterController,
                    maxLines: 4,
                    style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'write_cover_letter_hint'.tr,
                      hintStyle: AppFonts.AlmaraiRegular12.copyWith(color: secondaryTextColor.withOpacity(0.5)),
                      fillColor: inputBg,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.r(16)),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.r(16)),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Responsive.r(16)),
                        borderSide: const BorderSide(color: AppColors.salesAccent, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.h(28)),
                  SizedBox(
                    width: double.infinity,
                    height: Responsive.h(48),
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = _coverLetterController.text.trim();
                              if (text.isEmpty) {
                                Get.snackbar(
                                  'error'.tr,
                                  'please_enter_cover_letter'.tr,
                                  backgroundColor: Colors.red.withOpacity(0.9),
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                              });

                              final errorMsg = await TeacherService.applyToJob(
                                job.id ?? 'job_123_english',
                                text,
                              );

                              if (!context.mounted) return;

                              setModalState(() {
                                isSubmitting = false;
                              });

                              if (errorMsg == null) {
                                Get.back(); // close bottom sheet
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      padding: Responsive.all(24),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: Responsive.all(16),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withOpacity(0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF10B981),
                                              size: 48,
                                            ),
                                          ),
                                          SizedBox(height: Responsive.h(20)),
                                          Text(
                                            'applied_successfully'.tr,
                                            style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: Responsive.h(8)),
                                          Text(
                                            'application_sent_sub'.tr,
                                            style: AppFonts.AlmaraiRegular12.copyWith(color: secondaryTextColor),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: Responsive.h(24)),
                                          SizedBox(
                                            width: double.infinity,
                                            height: Responsive.h(40),
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.of(dialogContext).pop(),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.salesAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                                ),
                                              ),
                                              child: Text(
                                                'ok'.tr,
                                                style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                Get.back(); // close bottom sheet
                                if (!context.mounted) return;
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => Dialog(
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      padding: Responsive.all(24),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(Responsive.r(24)),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: Responsive.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.12),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.error_outline_rounded,
                                              color: AppColors.error,
                                              size: 48,
                                            ),
                                          ),
                                          SizedBox(height: Responsive.h(20)),
                                          Text(
                                            'error'.tr,
                                            style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: Responsive.h(8)),
                                          Text(
                                            errorMsg,
                                            style: AppFonts.AlmaraiRegular12.copyWith(color: secondaryTextColor),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: Responsive.h(24)),
                                          SizedBox(
                                            width: double.infinity,
                                            height: Responsive.h(40),
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.of(dialogContext).pop(),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.error,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                                ),
                                              ),
                                              child: Text(
                                                'ok'.tr,
                                                style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.salesAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Responsive.r(14)),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'submit_application'.tr,
                              style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSubmittedApplicationsSection(bool isDark) {
    final appliedApps = _applications.where((app) => !app.status.toLowerCase().contains('reject')).toList();
    final rejectedApps = _applications.where((app) => app.status.toLowerCase().contains('reject')).toList();

    if (appliedApps.isEmpty && rejectedApps.isEmpty) {
      return const SizedBox.shrink();
    }

    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : AppColors.grey300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appliedApps.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: Responsive.w(4),
                height: Responsive.h(16),
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: Responsive.w(8)),
              Text(
                'applied_applications'.tr,
                style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: appliedApps.length,
            separatorBuilder: (context, index) => SizedBox(height: Responsive.h(12)),
            itemBuilder: (context, index) {
              final app = appliedApps[index];
              return _buildApplicationCard(app, cardBg, borderColor, Colors.teal, isDark);
            },
          ),
          SizedBox(height: Responsive.h(24)),
        ],
        if (rejectedApps.isNotEmpty) ...[
          Row(
            children: [
              Container(
                width: Responsive.w(4),
                height: Responsive.h(16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: Responsive.w(8)),
              Text(
                'rejected_applications'.tr,
                style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rejectedApps.length,
            separatorBuilder: (context, index) => SizedBox(height: Responsive.h(12)),
            itemBuilder: (context, index) {
              final app = rejectedApps[index];
              return _buildApplicationCard(app, cardBg, borderColor, Colors.red, isDark);
            },
          ),
          SizedBox(height: Responsive.h(24)),
        ],
      ],
    );
  }

  Widget _buildApplicationCard(TeacherJobApplication app, Color cardBg, Color borderColor, Color themeColor, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    return Container(
      padding: Responsive.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(20)),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  app.jobTitle,
                  style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: Responsive.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(10)),
                ),
                child: Text(
                  app.status.tr,
                  style: AppFonts.AlmaraiBold10.copyWith(color: themeColor),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(4)),
          Text(
            app.schoolName,
            style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: Responsive.h(8)),
          Row(
            children: [
              Icon(IconlyLight.calendar, size: 12, color: AppColors.textSecondary),
              SizedBox(width: Responsive.w(4)),
              Text(
                '${'applied_on'.tr} ${app.appliedDate}',
                style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
