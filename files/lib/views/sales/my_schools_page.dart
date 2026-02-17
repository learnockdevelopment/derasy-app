import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/utils/responsive_utils.dart';
import '../../services/sales_service.dart';
import '../../widgets/loading_page.dart';
import '../../widgets/school_card_widget.dart';
import 'school_details_page.dart';

class MySchoolsPage extends StatefulWidget {
  const MySchoolsPage({Key? key}) : super(key: key);

  @override
  State<MySchoolsPage> createState() => _MySchoolsPageState();
}

class _MySchoolsPageState extends State<MySchoolsPage> {
  List<dynamic> _schools = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSchools();
  }

  Future<void> _fetchSchools() async {
    try {
      final allSchools = await SalesService.getSalesSchools();
      if (mounted) {
        setState(() {
          _schools = allSchools;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('my_schools'.tr, style: AppFonts.AlmaraiBold18),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 16),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingPage())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(IconlyBold.danger, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: AppFonts.AlmaraiBold16.copyWith(color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchSchools,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Retry', style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _schools.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(IconlyBold.home, size: 64, color: AppColors.grey300),
                          const SizedBox(height: 16),
                          Text(
                            'no_schools_found'.tr,
                            style: AppFonts.AlmaraiBold16.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: Responsive.all(24),
                      itemCount: _schools.length,
                      itemBuilder: (context, index) {
                        final school = _schools[index];
                        return _buildSchoolCard(school);
                      },
                    ),
    );
  }

  Widget _buildSchoolCard(Map<String, dynamic> school) {
    bool isApproved = school['approved'] == true;
    final schoolId = school['id']?.toString() ?? school['_id']?.toString() ?? '';
    
    return SchoolCardWidget(
      name: school['name'] ?? 'Unknown School',
      coverUrl: school['coverUrl'],
      logoUrl: school['logoUrl'],
      type: school['type'] ?? 'School',
      onTap: schoolId.isNotEmpty ? () => Get.toNamed(AppRoutes.schoolDetails, arguments: schoolId) : null,
      statusBadge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isApproved ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isApproved ? 'active'.tr : 'not_active'.tr,
              style: AppFonts.AlmaraiBold12.copyWith(
                color: isApproved ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
      dataItems: [
        SchoolCardData(
          'System',
          school['educationSystem'] != null
              ? (school['educationSystem'] is Map
                  ? school['educationSystem']['name'] ?? 'General'
                  : 'General')
              : 'General',
          IconlyLight.work,
        ),
        SchoolCardData(
          'Location',
          school['city'] ?? 'N/A',
          IconlyLight.location,
        ),
        SchoolCardData(
          'Date',
          '2024',
          IconlyLight.calendar,
        ),
      ],
    );
  }
}
