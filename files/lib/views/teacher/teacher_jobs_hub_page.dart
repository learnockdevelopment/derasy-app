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
import '../../widgets/loading_page.dart';

class TeacherJobsHubPage extends StatefulWidget {
  const TeacherJobsHubPage({Key? key}) : super(key: key);

  @override
  State<TeacherJobsHubPage> createState() => _TeacherJobsHubPageState();
}

class _TeacherJobsHubPageState extends State<TeacherJobsHubPage> {
  late Future<List<TeacherJob>> _jobsFuture;

  @override
  void initState() {
    super.initState();
    _refreshJobs();
  }

  void _refreshJobs() {
    setState(() {
      _jobsFuture = TeacherService.getJobs();
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
                padding: Responsive.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [Colors.white, const Color(0xFFF1F5F9)],
                  ),
                  borderRadius: BorderRadius.circular(Responsive.r(28)),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: Responsive.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.salesAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(Responsive.r(16)),
                          ),
                          child: Icon(IconlyBold.work, color: AppColors.salesAccent, size: Responsive.sp(22)),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'jobs_portal'.tr,
                                style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                              ),
                              SizedBox(height: Responsive.h(2)),
                              Text(
                                'manage_jobs_cv'.tr,
                                style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(20)),
                    
                    // Side-by-side action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: IconlyLight.document,
                            title: 'cv_profile_builder'.tr,
                            color: AppColors.salesAccent,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            onTap: () => Get.toNamed(AppRoutes.teacherCvProfile)?.then((_) => _refreshJobs()),
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: _buildActionCard(
                            icon: IconlyLight.plus,
                            title: 'add_job_opening'.tr,
                            color: Colors.teal,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            onTap: () => Get.toNamed(AppRoutes.teacherAddJob)?.then((_) => _refreshJobs()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: Responsive.h(28)),

              // 2. Feed Section Title
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
                    'active_jobs'.tr,
                    style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(16)),

              // 3. Dynamic FutureBuilder Feed List
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

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jobs.length,
                    separatorBuilder: (context, index) => SizedBox(height: Responsive.h(16)),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return _buildJobFeedCard(job, cardBg, borderColor, shadowColor, textColor);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: Responsive.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          children: [
            Container(
              padding: Responsive.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: Responsive.sp(18)),
            ),
            SizedBox(height: Responsive.h(8)),
            Text(
              title,
              style: AppFonts.AlmaraiBold10.copyWith(color: color),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
    return Container(
      width: double.infinity,
      padding: Responsive.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(Responsive.r(24)),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Title and salary badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: AppFonts.AlmaraiBold14.copyWith(color: textColor),
                    ),
                    SizedBox(height: Responsive.h(4)),
                    Text(
                      job.department,
                      style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: Responsive.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: Text(
                  '${job.salary.toStringAsFixed(0)} $currencyText',
                  style: AppFonts.AlmaraiBold10.copyWith(color: Colors.amber.shade800),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.h(12)),

          // Row 2: Tag labels
          Row(
            children: [
              Container(
                padding: Responsive.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.salesAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.r(6)),
                ),
                child: Text(
                  job.employmentType == 'full_time' ? 'full_time'.tr : 'part_time'.tr,
                  style: AppFonts.AlmaraiBold10.copyWith(color: AppColors.salesAccent),
                ),
              ),
              const Spacer(),
              Text(
                '${'created_at'.tr}: ${job.datePosted}',
                style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary.withOpacity(0.8)),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.black12, height: 1),
          ),

          // Paragraph: Description
          Text(
            job.description,
            style: AppFonts.AlmaraiRegular12.copyWith(color: textColor.withOpacity(0.85), height: 1.4),
          ),
          
          if (job.requirements.isNotEmpty) ...[
            SizedBox(height: Responsive.h(12)),
            // Bullet points for requirements
            Text(
              'job_requirements'.tr,
              style: AppFonts.AlmaraiBold10.copyWith(color: textColor),
            ),
            SizedBox(height: Responsive.h(6)),
            Column(
              children: job.requirements.map((req) {
                return Padding(
                  padding: EdgeInsets.only(bottom: Responsive.h(4)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: Responsive.h(5), left: Responsive.w(4), right: Responsive.w(6)),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.teal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          req,
                          style: AppFonts.AlmaraiRegular10.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          SizedBox(height: Responsive.h(16)),
          SizedBox(
            width: double.infinity,
            height: Responsive.h(38),
            child: ElevatedButton.icon(
              onPressed: () => _showApplyBottomSheet(job),
              icon: Icon(IconlyLight.send, color: Colors.white, size: Responsive.sp(16)),
              label: Text(
                'apply_now'.tr.isEmpty ? 'قدم الآن' : 'apply_now'.tr,
                style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salesAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
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
      text: 'خطاب تعريفي للمدرسة يوضح دوافع التقديم',
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
                              'job_application'.tr.isEmpty ? 'تقديم طلب وظيفة' : 'job_application'.tr,
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
                    'cover_letter'.tr.isEmpty ? 'الخطاب التعريفي' : 'cover_letter'.tr,
                    style: AppFonts.AlmaraiBold12.copyWith(color: textColor),
                  ),
                  SizedBox(height: Responsive.h(8)),
                  TextField(
                    controller: _coverLetterController,
                    maxLines: 4,
                    style: AppFonts.AlmaraiRegular12.copyWith(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'اكتب هنا دوافع التقديم للمدرسة...',
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
                                  'error'.tr.isEmpty ? 'خطأ' : 'error'.tr,
                                  'please_enter_cover_letter'.tr.isEmpty
                                      ? 'يرجى كتابة الخطاب التعريفي أولاً'
                                      : 'please_enter_cover_letter'.tr,
                                  backgroundColor: Colors.red.withOpacity(0.9),
                                  colorText: Colors.white,
                                );
                                return;
                              }

                              setModalState(() {
                                isSubmitting = true;
                              });

                              final success = await TeacherService.applyToJob(
                                job.id ?? 'job_123_english',
                                text,
                              );

                              setModalState(() {
                                isSubmitting = false;
                              });

                              if (success) {
                                Get.back(); // close bottom sheet
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
                                            'applied_successfully'.tr.isEmpty
                                                ? 'تم التقديم بنجاح'
                                                : 'applied_successfully'.tr,
                                            style: AppFonts.AlmaraiBold16.copyWith(color: textColor),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: Responsive.h(8)),
                                          Text(
                                            'application_sent_sub'.tr.isEmpty
                                                ? 'تم إرسال طلبك والخطاب التعريفي إلى المدرسة بنجاح وجاري مراجعة ملفك الشخصي.'
                                                : 'application_sent_sub'.tr,
                                            style: AppFonts.AlmaraiRegular12.copyWith(color: secondaryTextColor),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: Responsive.h(24)),
                                          SizedBox(
                                            width: double.infinity,
                                            height: Responsive.h(40),
                                            child: ElevatedButton(
                                              onPressed: () => Get.back(),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.salesAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(Responsive.r(12)),
                                                ),
                                              ),
                                              child: Text(
                                                'ok'.tr.isEmpty ? 'حسناً' : 'ok'.tr,
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
                                Get.snackbar(
                                  'error'.tr.isEmpty ? 'خطأ' : 'error'.tr,
                                  'failed_to_apply'.tr.isEmpty
                                      ? 'فشل تقديم الطلب، يرجى المحاولة لاحقاً'
                                      : 'failed_to_apply'.tr,
                                  backgroundColor: Colors.red.withOpacity(0.9),
                                  colorText: Colors.white,
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
                              'submit_application'.tr.isEmpty ? 'إرسال الطلب' : 'submit_application'.tr,
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
}
