import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../models/student_models.dart';
import '../services/students_service.dart';
import 'shimmer_loading.dart';
import '../core/routes/app_routes.dart';

class StudentSelectionSheet extends StatefulWidget {
  final bool onlySchoolStudents;

  const StudentSelectionSheet({
    Key? key,
    this.onlySchoolStudents = false,
  }) : super(key: key);

  @override
  State<StudentSelectionSheet> createState() => _StudentSelectionSheetState();
}

class _StudentSelectionSheetState extends State<StudentSelectionSheet> {
  List<Student> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    try {
      final response = await StudentsService.getRelatedChildren();
      if (mounted) {
        setState(() {
          List<Student> students = response.success ? response.students : <Student>[];
          if (widget.onlySchoolStudents) {
            students = students.where((s) => s.schoolId.id.isNotEmpty).toList();
          }
          _children = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _children = [];
          _isLoading = false;
        });
      }
      print('Failed to load children: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.r(30))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar
          Container(
            margin: Responsive.symmetric(vertical: 12),
            width: Responsive.w(40),
            height: Responsive.h(4),
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(Responsive.r(2)),
            ),
          ),
          
          // Title
          Padding(
            padding: Responsive.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  IconlyBold.profile,
                  color: AppColors.blue1,
                  size: Responsive.sp(24),
                ),
                SizedBox(width: Responsive.w(12)),
                Text(
                  'select_child'.tr,
                  style: AppFonts.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          
          Divider(),
          
          // Content - Flexible instead of Expanded
          Flexible(
            child: _isLoading
                ? _buildLoadingState()
                : _children.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: Responsive.all(24),
                        shrinkWrap: true,
                        itemCount: _children.length,
                        separatorBuilder: (context, index) => SizedBox(height: Responsive.h(16)),
                        itemBuilder: (context, index) {
                          return _buildStudentItem(_children[index]);
                        },
                      ),
          ),
          
          // Add Student/Application Button (Always Visible)
          Padding(
            padding: Responsive.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back(); // Close sheet
                  Get.toNamed(AppRoutes.addChildSteps);
                },
                icon: Icon(
                  _children.isEmpty ? IconlyBold.document : IconlyBold.profile, 
                  size: Responsive.sp(20),
                ),
                label: Text(
                  _children.isEmpty ? 'add_new_student'.tr : 'add_student'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  padding: Responsive.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Responsive.r(16)),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: Responsive.all(24),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: Responsive.only(bottom: 16),
            child: ShimmerCard(height: Responsive.h(80), borderRadius: Responsive.r(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: Responsive.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Container(
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                color: AppColors.blue1.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconlyBroken.document,
                size: Responsive.sp(48),
                color: AppColors.blue1,
              ),
            ),
            SizedBox(height: Responsive.h(24)),
            
            // Main Title
            Text(
              'create_smart_profile_title'.tr,
              textAlign: TextAlign.center,
              style: AppFonts.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            
            SizedBox(height: Responsive.h(16)),
            
            // Description (Features list)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: Responsive.w(300)),
              child: Text(
                'smart_profile_desc'.tr.replaceAll('•', '\n• '), // Format with bullets on new lines for better readability if needed, or keep inline
                textAlign: TextAlign.center,
                style: AppFonts.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: Responsive.sp(13),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentItem(Student child) {
    final hasArabicName = child.arabicFullName != null && child.arabicFullName!.isNotEmpty;
    final displayName = hasArabicName ? child.arabicFullName! : child.fullName;
    final schoolName = child.schoolId.name.isNotEmpty ? child.schoolId.name : 'no_school'.tr;

    return InkWell(
      onTap: () => Get.back(result: child),
      borderRadius: BorderRadius.circular(Responsive.r(16)),
      child: Container(
        padding: Responsive.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey100.withOpacity(0.5),
          borderRadius: BorderRadius.circular(Responsive.r(16)),
          border: Border.all(color: AppColors.grey200),
          ),
        child: Row(
          children: [
            // Student Avatar
            Container(
              width: Responsive.w(48),
              height: Responsive.w(48),
              decoration: BoxDecoration(
                color: AppColors.blue1.withOpacity(0.1),
                shape: BoxShape.circle,
                image: (child.profileImage != null || child.avatar != null)
                    ? DecorationImage(
                        image: NetworkImage(child.profileImage ?? child.avatar!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (child.profileImage == null && child.avatar == null)
                  ? Center(
                      child: Text(
                        _getInitials(displayName),
                        style: AppFonts.h4.copyWith(
                          color: AppColors.blue1,
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.sp(16),
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: Responsive.w(16)),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppFonts.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: Responsive.sp(14),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Responsive.h(4)),
                  Row(
                    children: [
                      Icon(
                        IconlyBroken.location,
                        size: Responsive.sp(14),
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: Responsive.w(4)),
                      Expanded(
                        child: Text(
                          schoolName,
                          style: AppFonts.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: Responsive.sp(12),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Get.locale?.languageCode == 'ar' 
                  ? IconlyBroken.arrow_left_2 
                  : IconlyBroken.arrow_right_2,
              color: AppColors.grey400,
              size: Responsive.sp(20),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}

