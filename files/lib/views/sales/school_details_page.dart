import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/school_models.dart';
import '../../services/schools_service.dart';
import '../../services/sales_service.dart';
import '../../services/user_storage_service.dart';
import '../../core/controllers/app_config_controller.dart';
import '../../widgets/loading_page.dart';

class SchoolDetailsPage extends StatefulWidget {
  final String schoolId;
  const SchoolDetailsPage({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<SchoolDetailsPage> createState() => _SchoolDetailsPageState();
}

class _SchoolDetailsPageState extends State<SchoolDetailsPage> {
  School? _school;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSchoolDetails();
  }

  Future<void> _fetchSchoolDetails() async {
    try {
      School? school;
      
      if (UserStorageService.isSales()) {
        print('🏫 [SCHOOL DETAILS] Sales role detected - fetching detail from dashboard API');
        try {
          final schoolData = await SalesService.getSchoolById(widget.schoolId);
          if (schoolData.isNotEmpty) {
            // Handle wrapper if exists (e.g. { "success": true, "school": { ... } })
            final data = schoolData.containsKey('school') ? schoolData['school'] : schoolData;
            school = School.fromJson(data);
          }
        } catch (e) {
          print('🏫 [SCHOOL DETAILS] Dashboard API fetch failed: $e. Falling back to SchoolsService.');
        }
      }

      // Fallback or Parent Role
      if (school == null) {
        school = await SchoolsService.getSchoolById(widget.schoolId);
      }

      if (mounted) {
        setState(() {
          _school = school;
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

  IconData _getIconData(String iconName) {
    iconName = iconName.toLowerCase();
    
    // Common mappings from strings/api keys to Icons
    final Map<String, IconData> iconMap = {
      'pool': Icons.pool,
      'swimming': Icons.pool,
      'library': Icons.library_books,
      'books': Icons.library_books,
      'lab': Icons.science,
      'science': Icons.science,
      'gym': Icons.sports_basketball,
      'sports': Icons.sports_basketball,
      'basketball': Icons.sports_basketball,
      'football': Icons.sports_soccer,
      'soccer': Icons.sports_soccer,
      'theater': Icons.theater_comedy,
      'cinema': Icons.theater_comedy,
      'clinic': Icons.medical_services,
      'medical': Icons.medical_services,
      'playground': Icons.child_care,
      'kids': Icons.child_care,
      'cafeteria': Icons.restaurant,
      'food': Icons.restaurant,
      'computer': Icons.computer,
      'it': Icons.computer,
      'mosque': Icons.mosque,
      'prayer': Icons.mosque,
      'security': Icons.security,
      'bus': Icons.directions_bus,
      'transport': Icons.directions_bus,
      'music': Icons.music_note,
      'art': Icons.palette,
      'garden': Icons.park,
      'park': Icons.park,
      'wifi': Icons.wifi,
      'internet': Icons.wifi,
      'ac': Icons.ac_unit,
      'cooling': Icons.ac_unit,
      'camera': Icons.videocam,
      'cctv': Icons.videocam,
    };

    for (var key in iconMap.keys) {
      if (iconName.contains(key)) return iconMap[key]!;
    }

    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = AppConfigController.to.isDarkMode;
      final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
      final surfaceColor = Theme.of(context).colorScheme.surface;
      final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

      if (_isLoading) return Scaffold(backgroundColor: scaffoldColor, body: const Center(child: LoadingPage()));
      
      if (_error != null) {
        return Scaffold(
          backgroundColor: scaffoldColor,
          appBar: AppBar(
            title: Text('school_details'.tr, style: AppFonts.AlmaraiBold18.copyWith(color: onSurfaceColor)),
            elevation: 0,
            backgroundColor: surfaceColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: onSurfaceColor, size: 20),
              onPressed: () => Get.back(),
            ),
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.red50.withOpacity(isDark ? 0.1 : 1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(IconlyBold.danger, size: 64, color: AppColors.error),
                  ),
                  SizedBox(height: 24.h),
                  Text('Something went wrong', style: AppFonts.AlmaraiBold20.copyWith(color: onSurfaceColor)),
                  SizedBox(height: 12.h),
                  Text(_error!, style: AppFonts.AlmaraiRegular14.copyWith(color: onSurfaceColor.withOpacity(0.6)), textAlign: TextAlign.center),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: _fetchSchoolDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.salesAccent,
                      padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Retry', style: AppFonts.AlmaraiBold16.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: scaffoldColor,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, isDark, surfaceColor, onSurfaceColor),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStats(isDark, surfaceColor, onSurfaceColor),
                    SizedBox(height: 32.h),
                    
                    _buildSectionHeader('info'.tr, IconlyLight.info_square, isDark),
                    _buildAboutSection(isDark, surfaceColor, onSurfaceColor),
                    SizedBox(height: 32.h),
                    
                    if (_school?.ownership.owner != null || (_school?.ownership.moderators.isNotEmpty == true)) ...[
                      _buildSectionHeader('management'.tr, IconlyLight.user_1, isDark),
                      _buildStaffSection(isDark, surfaceColor, onSurfaceColor),
                      SizedBox(height: 32.h),
                    ],
                    
                    if (_school?.facilities != null && _school!.facilities!.isNotEmpty) ...[
                      _buildSectionHeader('facilities'.tr, IconlyLight.category, isDark),
                      _buildFacilitiesGrid(isDark, surfaceColor, onSurfaceColor),
                      SizedBox(height: 32.h),
                    ],

                    if (_school?.workingHours != null && _school!.workingHours!.isNotEmpty) ...[
                      _buildSectionHeader('working_hours'.tr, IconlyLight.time_circle, isDark),
                      _buildWorkingHoursSection(isDark, surfaceColor, onSurfaceColor),
                      SizedBox(height: 32.h),
                    ],

                    _buildSectionHeader('admission_info'.tr, IconlyLight.wallet, isDark),
                    _buildAdmissionSection(isDark, surfaceColor, onSurfaceColor),
                    SizedBox(height: 32.h),

                    _buildSectionHeader('location'.tr, IconlyLight.location, isDark),
                    _buildLocationSection(isDark, surfaceColor, onSurfaceColor),
                    SizedBox(height: 60.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.salesAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.salesAccent, size: 20.w),
          ),
          SizedBox(width: 12.w),
          Text(title, style: AppFonts.AlmaraiBold18.copyWith(color: AppColors.salesAccent)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark, Color surfaceColor, Color onSurfaceColor) {
    final bannerUrl = _school?.media?.schoolImages?.isNotEmpty == true 
        ? _school!.media!.schoolImages!.first.url 
        : _school?.bannerImage;

    return SliverAppBar(
      expandedHeight: 320.h,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.salesAccent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18.w),
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
            child: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round_rounded, color: Colors.white, size: 20.w),
          ),
          onPressed: () => AppConfigController.to.toggleTheme(),
        ),
        SizedBox(width: 8.w),
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
            child: Icon(IconlyLight.send, color: Colors.white, size: 20.w),
          ),
          onPressed: () {},
        ),
        SizedBox(width: 12.w),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            bannerUrl != null
                ? Image.network(bannerUrl, fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.salesAccent, AppColors.salesAccent.withOpacity(0.7)],
                      ),
                    ),
                    child: Center(
                      child: Icon(IconlyBold.home, color: Colors.white.withOpacity(0.3), size: 100.w),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
            Positioned(
              bottom: 24.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.salesAccent,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Text(
                          _school?.type?.toUpperCase() ?? 'SCHOOL',
                          style: AppFonts.AlmaraiBold10.copyWith(color: Colors.white, letterSpacing: 1),
                        ),
                      ),
                      if (_school?.approved == true) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(Icons.check_circle, color: Colors.blue, size: 16.w),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    _school?.name ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.bold),
                  ),
                  if (_school?.location?.city != null) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(IconlyLight.location, color: Colors.white.withOpacity(0.9), size: 16.sp),
                        SizedBox(width: 6.w),
                        Text(
                          '${_school!.location!.district ?? ""}, ${_school!.location!.city}',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.sp),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isDark, Color surfaceColor, Color onSurfaceColor) {
    return Row(
      children: [
        _buildStatCard('status'.tr, _school?.approved == true ? 'active'.tr : 'pending'.tr, _school?.approved == true ? Colors.green : Colors.orange, surfaceColor, onSurfaceColor),
        SizedBox(width: 12.w),
        _buildStatCard('system'.tr, _school?.educationSystem ?? 'general'.tr, AppColors.salesAccent, surfaceColor, onSurfaceColor),
        SizedBox(width: 12.w),
        _buildStatCard('gender'.tr, _school?.gender ?? 'co_ed'.tr, Colors.deepPurpleAccent, surfaceColor, onSurfaceColor),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, Color surfaceColor, Color onSurfaceColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppFonts.AlmaraiRegular12.copyWith(color: onSurfaceColor.withOpacity(0.5))),
            SizedBox(height: 6.h),
            Text(
              value,
              style: AppFonts.AlmaraiBold14.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(bool isDark, Color surfaceColor, Color onSurfaceColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoRow(IconlyLight.user_1, 'principal'.tr, _school?.principal?.name ?? 'N/A', onSurfaceColor),
          _divider(isDark),
          _buildInfoRow(IconlyLight.calling, 'phone'.tr, _school?.location?.mainPhone ?? 'N/A', onSurfaceColor),
          _divider(isDark),
          _buildInfoRow(IconlyLight.message, 'email'.tr, _school?.location?.officialEmail ?? 'N/A', onSurfaceColor),
          _divider(isDark),
          _buildInfoRow(IconlyLight.discovery, 'languages'.tr, _school?.languages.isNotEmpty == true ? _school!.languages.join(', ') : 'N/A', onSurfaceColor),
        ],
      ),
    );
  }

  Widget _buildFacilitiesGrid(bool isDark, Color surfaceColor, Color onSurfaceColor) {
    final facilities = _school!.facilities!;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20.h,
          crossAxisSpacing: 15.w,
          childAspectRatio: 1.1,
        ),
        itemCount: facilities.length,
        itemBuilder: (context, index) {
          final facility = facilities[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.salesAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_getIconData(facility.icon), color: AppColors.salesAccent, size: 24.w),
              ),
              SizedBox(height: 8.h),
              Text(
                facility.name,
                style: AppFonts.AlmaraiBold12.copyWith(color: onSurfaceColor),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkingHoursSection(bool isDark, Color surfaceColor, Color onSurfaceColor) {
    final hours = _school!.workingHours!;
    final days = hours.keys.toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: days.map((day) {
          final dayInfo = hours[day];
          final isLast = days.last == day;
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(day, style: AppFonts.AlmaraiBold14.copyWith(color: onSurfaceColor)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : AppColors.grey50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${dayInfo['from']} - ${dayInfo['to']}',
                        style: AppFonts.AlmaraiRegular14.copyWith(color: AppColors.blue1, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) _divider(isDark),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdmissionSection(bool isDark, Color surfaceColor, Color onSurfaceColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoRow(IconlyLight.wallet, 'admission_fee'.tr, '${_school?.admissionFee?.amount ?? 0} ${_school?.admissionFee?.currency ?? "EGP"}', onSurfaceColor),
          _divider(isDark),
          _buildInfoRow(IconlyLight.ticket_star, 'fees_range'.tr, '${_school?.feesRange?.min.toInt() ?? 0} - ${_school?.feesRange?.max.toInt() ?? 0} EGP', onSurfaceColor),
          _divider(isDark),
          _buildInfoRow(IconlyLight.info_square, 'admission_open'.tr, _school?.admissionOpen == true ? 'yes'.tr : 'no'.tr, onSurfaceColor),
          _divider(isDark),
          _buildInfoRow(IconlyLight.document, 'special_needs_policy_label'.tr, _school?.supportsSpecialNeeds == true ? 'supported'.tr : 'no'.tr, onSurfaceColor),
        ],
      ),
    );
  }

  Widget _buildLocationSection(bool isDark, Color surfaceColor, Color onSurfaceColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(IconlyLight.location, color: AppColors.salesAccent, size: 20),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  '${_school?.location?.governorate ?? ""}, ${_school?.location?.city ?? ""}',
                  style: AppFonts.AlmaraiBold16.copyWith(color: onSurfaceColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(left: 32.w),
            child: Text(
              _school?.location?.address ?? 'Address not provided',
              style: AppFonts.AlmaraiRegular14.copyWith(color: onSurfaceColor.withOpacity(0.6)),
            ),
          ),
          SizedBox(height: 20.h),
          Material(
            color: isDark ? Colors.white10 : AppColors.grey50,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: _launchMaps,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(IconlyLight.discovery, color: AppColors.salesAccent, size: 20),
                    SizedBox(width: 8.w),
                    Text('view_on_maps'.tr, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.salesAccent)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSection(bool isDark, Color surfaceColor, Color onSurfaceColor) {
    final ownership = _school!.ownership;
    final List<Widget> children = [];

    // Owner section
    if (ownership.owner != null) {
      children.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Text('admin'.tr.toUpperCase(), style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.salesAccent, letterSpacing: 1)),
            ),
            _buildInfoRow(IconlyLight.user_1, 'name'.tr, ownership.owner!.name, onSurfaceColor),
            _divider(isDark),
            _buildInfoRow(IconlyLight.message, 'email'.tr, ownership.owner!.email, onSurfaceColor),
            if (ownership.owner!.phone != null) ...[
              _divider(isDark),
              _buildInfoRow(IconlyLight.calling, 'phone'.tr, ownership.owner!.phone!, onSurfaceColor),
            ],
          ],
        ),
      );
    }

    // Moderators section
    if (ownership.moderators.isNotEmpty) {
      if (children.isNotEmpty) children.add(SizedBox(height: 24.h));
      
      for (int i = 0; i < ownership.moderators.length; i++) {
        final mod = ownership.moderators[i];
        children.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Text('${'moderator'.tr} ${i + 1}'.toUpperCase(), style: AppFonts.AlmaraiBold12.copyWith(color: Colors.orange, letterSpacing: 1)),
              ),
              _buildInfoRow(IconlyLight.user_1, 'name'.tr, mod.name, onSurfaceColor),
              _divider(isDark),
              _buildInfoRow(IconlyLight.message, 'email'.tr, mod.email, onSurfaceColor),
              if (mod.phone != null) ...[
                _divider(isDark),
                _buildInfoRow(IconlyLight.calling, 'phone'.tr, mod.phone!, onSurfaceColor),
              ],
              if (i < ownership.moderators.length - 1) SizedBox(height: 16.h),
            ],
          ),
        );
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.w),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color onSurfaceColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
      child: Row(
        children: [
          Icon(icon, size: 20.w, color: AppColors.salesAccent),
          SizedBox(width: 12.w),
          Text(label, style: AppFonts.AlmaraiRegular14.copyWith(color: onSurfaceColor.withOpacity(0.5))),
          const Spacer(),
          Text(value, style: AppFonts.AlmaraiBold14.copyWith(color: onSurfaceColor)),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(height: 1, color: isDark ? Colors.white10 : AppColors.grey100);

  Future<void> _launchMaps() async {
    if (_school?.location == null) return;
    
    final loc = _school!.location!;
    Uri url;
    
    if (loc.latitude != null && loc.longitude != null) {
      // Use coordinates if available
      final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}";
      url = Uri.parse(googleMapsUrl);
    } else {
      // Fallback to address search
      final String query = Uri.encodeComponent("${_school?.name}, ${loc.governorate}, ${loc.city}");
      url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('error'.tr, 'could_not_launch_maps'.tr);
    }
  }
}
