import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../services/user_storage_service.dart';
import '../../core/utils/responsive_utils.dart';
import '../../services/sales_service.dart'; // Added import for SalesService

class SalesHomePage extends StatefulWidget {
  const SalesHomePage({Key? key}) : super(key: key);

  @override
  State<SalesHomePage> createState() => _SalesHomePageState();
}

class _SalesHomePageState extends State<SalesHomePage> {
  int _totalSchools = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final schools = await SalesService.getSalesSchools();
      if (mounted) {
        setState(() {
          _totalSchools = schools.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Failed to load sales stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserStorageService.getCurrentUser();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(user),
          SliverPadding(
            padding: Responsive.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('overview'.tr),
                const SizedBox(height: 16),
                _buildStatsGrid(),
                const SizedBox(height: 32),
                _buildSectionHeader('quick_actions'.tr),
                const SizedBox(height: 16),
                _buildActionCard(
                  'onboard_new_school'.tr,
                  'onboard_new_school_desc'.tr,
                  IconlyBold.plus,
                  AppColors.blue1,
                  () => Get.toNamed(AppRoutes.salesOnboarding),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  'my_schools'.tr,
                  'my_schools_desc'.tr,
                  IconlyBold.category,
                  Colors.purple,
                  () => Get.toNamed(AppRoutes.mySchools),
                ),
                const SizedBox(height: 100), // Extra space for scrolling
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(user) {
    return SliverAppBar(
      expandedHeight: Responsive.h(160),
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.blue1,
      centerTitle: false,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Immersive Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.blue1,
                    Color(0xFF1E40AF),
                    Color(0xFF1E3A8A),
                  ],
                ),
              ),
            ),
            // Content
            Padding(
              padding: Responsive.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: Responsive.r(24),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            (user?.name ?? 'S')[0].toUpperCase(),
                            style: AppFonts.AlmaraiBold18.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${'welcome'.tr},',
                            style: AppFonts.AlmaraiRegular14.copyWith(color: Colors.white.withOpacity(0.8)),
                          ),
                          Text(
                            user?.name ?? 'Sales Associate',
                            style: AppFonts.AlmaraiBold20.copyWith(color: Colors.white, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: InkWell(
              onTap: () async {
                await UserStorageService.logout();
                Get.offAllNamed(AppRoutes.login);
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: const Icon(IconlyLight.logout, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppFonts.AlmaraiBold18.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            'total_schools'.tr,
            _isLoading ? '...' : '$_totalSchools',
            IconlyBold.home,
            AppColors.blue1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernStatCard(
            'active_onboarding'.tr,
            '03', // Placeholder until backend provides this specific stat
            IconlyBold.time_circle,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: Responsive.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          Text(
            value,
            style: AppFonts.AlmaraiBold24.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String desc, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: Responsive.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.grey200, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.AlmaraiBold18.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.blue1, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
