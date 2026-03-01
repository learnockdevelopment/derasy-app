import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive_utils.dart';
import '../../services/sales_service.dart';
import '../../services/user_storage_service.dart';
import '../../core/controllers/app_config_controller.dart';

class SalesHomePage extends StatefulWidget {
  const SalesHomePage({Key? key}) : super(key: key);

  @override
  State<SalesHomePage> createState() => _SalesHomePageState();
}

class _SalesHomePageState extends State<SalesHomePage> {
  int _totalSchools = 0;
  int _totalUsers = 0;
  List<dynamic> _recentOnboardings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await SalesService.getDashboardStats();
      if (mounted) {
        setState(() {
          _totalSchools = stats['totalSchools'] ?? 0;
          _totalUsers = stats['totalUsers'] ?? 0;
          _recentOnboardings = stats['recentOnboardings'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Failed to load sales stats: $e');
      // Note: 403 is already handled in SalesService -> AuthErrorHandler
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserStorageService.getCurrentUser();
    
    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;
      
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(user, isDark),
            SliverPadding(
              padding: Responsive.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _fadeIn(0, child: _buildSectionHeader('overview'.tr)),
                  const SizedBox(height: 16),
                  _fadeIn(1, child: _buildStatsGrid(isDark)),
                  const SizedBox(height: 32),
                  _fadeIn(2, child: _buildSectionHeader('quick_actions'.tr)),
                  const SizedBox(height: 16),
                  _fadeIn(3, child: _buildActionCard(
                    'onboard_new_school'.tr,
                    'onboard_new_school_desc'.tr,
                    IconlyBold.plus,
                    AppColors.salesAccent,
                    () => Get.toNamed(AppRoutes.salesOnboarding),
                    isDark,
                  )),
                  const SizedBox(height: 16),
                  _fadeIn(4, child: _buildActionCard(
                    'my_schools'.tr,
                    'my_schools_desc'.tr,
                    IconlyBold.category,
                    Colors.purple,
                    () => Get.toNamed(AppRoutes.mySchools),
                    isDark,
                  )),
                  const SizedBox(height: 32),
                  if (_recentOnboardings.isNotEmpty) ...[
                    _fadeIn(5, child: _buildSectionHeader('recent_onboardings'.tr)),
                    const SizedBox(height: 16),
                    ...List.generate(_recentOnboardings.length, (index) {
                      return _fadeIn(6 + index, child: _buildSchoolListCard(_recentOnboardings[index], isDark));
                    }),
                  ],
                  const SizedBox(height: 100), // Extra space for scrolling
                ]),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _fadeIn(int index, {required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildSliverAppBar(user, bool isDark) {
    return SliverAppBar(
      expandedHeight: Responsive.h(160),
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.salesAccent,
      centerTitle: false,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Immersive Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF1E293B), const Color(0xFF030711), const Color(0xFF020617)]
                    : [AppColors.salesAccent, const Color(0xFF1E40AF), const Color(0xFF1E3A8A)],
                ),
              ),
            ),
            // Background Decorative Elements for Premium Feel
            Positioned(
              top: -Responsive.h(50),
              right: -Responsive.w(50),
              child: Container(
                width: Responsive.w(150),
                height: Responsive.w(150),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
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
                            '${'welcome_back'.tr},',
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
        // Theme Toggle Button
        _buildCircleAction(
          onTap: () => AppConfigController.to.toggleTheme(),
          icon: isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round_rounded,
        ),
        const SizedBox(width: 8),
        // Language Toggle Button
        _buildCircleAction(
          onTap: () {
            final currentLocale = Get.locale?.languageCode ?? 'ar';
            final newLocale = currentLocale == 'ar' ? const Locale('en') : const Locale('ar');
            Get.updateLocale(newLocale);
          },
          text: Get.locale?.languageCode == 'ar' ? 'EN' : 'AR',
        ),
        const SizedBox(width: 8),
        _buildCircleAction(
          onTap: () async {
            Get.dialog(
              Dialog(
                backgroundColor: isDark ? AppColors.salesSurfaceDark : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(IconlyBold.logout, color: Colors.red, size: 32),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'logout'.tr,
                        style: AppFonts.AlmaraiBold20.copyWith(color: isDark ? Colors.white : AppColors.salesForegroundLight),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'confirm_logout'.tr,
                        textAlign: TextAlign.center,
                        style: AppFonts.AlmaraiRegular14.copyWith(color: isDark ? Colors.white70 : AppColors.grey600),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Get.back(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.grey50,
                              ),
                              child: Text(
                                'cancel'.tr,
                                style: AppFonts.AlmaraiBold14.copyWith(color: isDark ? Colors.white : AppColors.salesForegroundLight),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                await UserStorageService.logout();
                                Get.offAllNamed(AppRoutes.login);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.red,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                'yes'.tr,
                                style: AppFonts.AlmaraiBold14.copyWith(color: Colors.white),
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
          },
          icon: IconlyLight.logout,
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildCircleAction({required VoidCallback onTap, IconData? icon, String? text}) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: icon != null 
              ? Icon(icon, color: Colors.white, size: 20)
              : Text(
                  text ?? '',
                  style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppFonts.AlmaraiBold18.copyWith(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            'total_schools'.tr,
            _isLoading ? '...' : '$_totalSchools',
            IconlyBold.home,
            AppColors.salesAccent,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: Responsive.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.salesSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
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
            style: AppFonts.AlmaraiBold24.copyWith(color: Theme.of(context).textTheme.displayLarge?.color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppFonts.AlmaraiRegular12.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String desc, IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: Responsive.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.salesSurfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.grey200, width: 1),
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
                    style: AppFonts.AlmaraiBold18.copyWith(color: Theme.of(context).textTheme.titleLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: AppFonts.AlmaraiRegular12.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.grey50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white : AppColors.blue1, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolListCard(Map<String, dynamic> school, bool isDark) {
    final statusColor = school['status'] == 'نشط' ? Colors.green : Colors.orange;
    final hasBanner = school['bannerImage'] != null && school['bannerImage'].toString().isNotEmpty;
    final hasLogo = school['logoUrl'] != null && school['logoUrl'].toString().isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppColors.salesSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.grey200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Image Section
          if (hasBanner)
            Container(
              height: Responsive.h(100),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(school['bannerImage']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          
          // Details Section
          Padding(
            padding: EdgeInsets.fromLTRB(16, hasBanner ? 12 : 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo or Default Icon
                Container(
                  width: Responsive.w(48),
                  height: Responsive.w(48),
                  decoration: BoxDecoration(
                    color: AppColors.salesAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    image: hasLogo 
                      ? DecorationImage(image: NetworkImage(school['logoUrl']), fit: BoxFit.cover)
                      : null,
                    border: hasBanner ? Border.all(color: isDark ? AppColors.salesSurfaceDark : Colors.white, width: 2) : null,
                  ),
                  child: !hasLogo 
                    ? Icon(IconlyBold.home, color: AppColors.salesAccent, size: 24)
                    : null,
                ),
                const SizedBox(width: 16),
                
                // Text Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school['name'] ?? '---',
                        style: AppFonts.AlmaraiBold14.copyWith(color: Theme.of(context).textTheme.titleLarge?.color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'owner'.tr}: ${school['owner'] ?? '---'}',
                        style: AppFonts.AlmaraiRegular10.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Status and Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        school['status'] ?? '---',
                        style: AppFonts.AlmaraiBold10.copyWith(color: statusColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      school['date'] != null ? school['date'].toString().split('T')[0] : '---',
                      style: AppFonts.AlmaraiRegular10.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4)),
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
}
