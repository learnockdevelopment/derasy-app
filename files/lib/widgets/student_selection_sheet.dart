import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../models/student_models.dart';
import '../services/students_service.dart';
import 'shimmer_loading.dart';

class StudentSelectionSheet extends StatefulWidget {
  const StudentSelectionSheet({Key? key}) : super(key: key);

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
          _children = response.success ? response.students : [];
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
                  color: AppColors.primaryBlue,
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
          
          // Content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
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
    return Padding(
      padding: Responsive.all(40),
      child: Column(
        children: [
          Icon(
            IconlyBroken.profile,
            size: Responsive.sp(64),
            color: AppColors.grey400,
          ),
          SizedBox(height: Responsive.h(16)),
          Text(
            'no_children_found'.tr,
            style: AppFonts.h4.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: Responsive.h(8)),
          Text(
            'add_child_first_description'.tr,
            style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
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
            // Avatar (now pill-shaped with full name)
            Container(
              padding: Responsive.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Responsive.r(20)), // Pill shape
              ),
              child: Text(
                displayName.isNotEmpty ? displayName : 'Student',
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.sp(12),
                ),
              ),
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
                    ),
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
              IconlyBroken.arrow_left_2,
              color: AppColors.grey400,
              size: Responsive.sp(20),
            ),
          ],
        ),
      ),
    );
  }
}
