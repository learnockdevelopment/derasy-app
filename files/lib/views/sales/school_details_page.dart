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
        print('🏫 [SCHOOL DETAILS] Sales role detected - searching in sales schools');
        final salesSchools = await SalesService.getSalesSchools();
        final schoolData = salesSchools.firstWhere(
          (s) => (s['id']?.toString() ?? s['_id']?.toString() ?? '') == widget.schoolId,
          orElse: () => null,
        );
        
        if (schoolData != null) {
          school = School.fromJson(schoolData);
        }
      }

      // If not sales or not found in sales list, try direct fetch
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
    if (_isLoading) return const Scaffold(body: Center(child: LoadingPage()));
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('school_details'.tr, style: AppFonts.AlmaraiBold18),
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
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
                    color: AppColors.red50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(IconlyBold.danger, size: 64, color: AppColors.error),
                ),
                SizedBox(height: 24.h),
                Text('Something went wrong', style: AppFonts.AlmaraiBold20),
                SizedBox(height: 12.h),
                Text(_error!, style: AppFonts.AlmaraiRegular14.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: _fetchSchoolDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(),
                  SizedBox(height: 32.h),
                  
                   SizedBox(height: 32.h),
 
                   if (_school?.ownership.owner != null || (_school?.ownership.moderators.isNotEmpty == true)) ...[
                     _buildSectionHeader('management'.tr, IconlyLight.user_1),
                     _buildStaffSection(),
                     SizedBox(height: 32.h),
                   ],
                  
                  if (_school?.facilities != null && _school!.facilities!.isNotEmpty) ...[
                    _buildSectionHeader('facilities'.tr, IconlyLight.category),
                    _buildFacilitiesGrid(),
                    SizedBox(height: 32.h),
                  ],

                  if (_school?.workingHours != null && _school!.workingHours!.isNotEmpty) ...[
                    _buildSectionHeader('working_hours'.tr, IconlyLight.time_circle),
                    _buildWorkingHoursSection(),
                    SizedBox(height: 32.h),
                  ],

                  _buildSectionHeader('admission_info'.tr, IconlyLight.wallet),
                  _buildAdmissionSection(),
                  SizedBox(height: 32.h),

                  _buildSectionHeader('location'.tr, IconlyLight.location),
                  _buildLocationSection(),
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.blue1, size: 20.w),
          ),
          SizedBox(width: 12.w),
          Text(title, style: AppFonts.AlmaraiBold18.copyWith(color: AppColors.blue1)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final bannerUrl = _school?.media?.schoolImages?.isNotEmpty == true 
        ? _school!.media!.schoolImages!.first.url 
        : _school?.bannerImage;

    return SliverAppBar(
      expandedHeight: 320.h,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.blue1,
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
            child: Icon(IconlyLight.heart, color: Colors.white, size: 20.w),
          ),
          onPressed: () {},
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
                        colors: [AppColors.blue1, AppColors.blue2],
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
                          color: AppColors.blue1,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Text(
                          _school?.type?.toUpperCase() ?? 'SCHOOL',
                          style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1),
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

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildStatCard('status'.tr, _school?.approved == true ? 'active'.tr : 'pending'.tr, _school?.approved == true ? Colors.green : Colors.orange),
        SizedBox(width: 12.w),
        _buildStatCard('system'.tr, _school?.educationSystem ?? 'general'.tr, AppColors.blue1),
        SizedBox(width: 12.w),
        _buildStatCard('gender'.tr, _school?.gender ?? 'co_ed'.tr, Colors.deepPurpleAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppFonts.AlmaraiRegular12.copyWith(color: AppColors.textSecondary)),
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

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoRow(IconlyLight.user_1, 'principal'.tr, _school?.principal?.name ?? 'N/A'),
          _divider(),
          _buildInfoRow(IconlyLight.calling, 'phone'.tr, _school?.location?.mainPhone ?? 'N/A'),
          _divider(),
          _buildInfoRow(IconlyLight.message, 'email'.tr, _school?.location?.officialEmail ?? 'N/A'),
          _divider(),
          _buildInfoRow(IconlyLight.discovery, 'languages'.tr, _school?.languages.isNotEmpty == true ? _school!.languages.join(', ') : 'N/A'),
        ],
      ),
    );
  }

  Widget _buildFacilitiesGrid() {
    final facilities = _school!.facilities!;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: AppColors.blue1.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(_getIconData(facility.icon), color: AppColors.blue1, size: 24.w),
              ),
              SizedBox(height: 8.h),
              Text(
                facility.name,
                style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.textPrimary),
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

  Widget _buildWorkingHoursSection() {
    final hours = _school!.workingHours!;
    final days = hours.keys.toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
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
                    Text(day, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.textPrimary)),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
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
              if (!isLast) _divider(),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdmissionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildInfoRow(IconlyLight.wallet, 'admission_fee'.tr, '${_school?.admissionFee?.amount ?? 0} ${_school?.admissionFee?.currency ?? "EGP"}'),
          _divider(),
          _buildInfoRow(IconlyLight.ticket_star, 'fees_range'.tr, '${_school?.feesRange?.min.toInt() ?? 0} - ${_school?.feesRange?.max.toInt() ?? 0} EGP'),
          _divider(),
          _buildInfoRow(IconlyLight.info_square, 'admission_open'.tr, _school?.admissionOpen == true ? 'yes'.tr : 'no'.tr),
          _divider(),
          _buildInfoRow(IconlyLight.document, 'special_needs_policy_label'.tr, _school?.supportsSpecialNeeds == true ? 'supported'.tr : 'no'.tr),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(IconlyLight.location, color: AppColors.blue1, size: 20.w),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  '${_school?.location?.governorate ?? ""}, ${_school?.location?.city ?? ""}',
                  style: AppFonts.AlmaraiBold16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.only(left: 32.w),
            child: Text(
              _school?.location?.address ?? 'Address not provided',
              style: AppFonts.AlmaraiRegular14.copyWith(color: AppColors.textSecondary),
            ),
          ),
          SizedBox(height: 20.h),
          Material(
            color: AppColors.grey50,
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
                    Icon(IconlyLight.discovery, color: AppColors.blue1, size: 20.w),
                    SizedBox(width: 8.w),
                    Text('view_on_maps'.tr, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.blue1)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffSection() {
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
              child: Text('admin'.tr.toUpperCase(), style: AppFonts.AlmaraiBold12.copyWith(color: AppColors.blue1, letterSpacing: 1)),
            ),
            _buildInfoRow(IconlyLight.user_1, 'name'.tr, ownership.owner!.name),
            _divider(),
            _buildInfoRow(IconlyLight.message, 'email'.tr, ownership.owner!.email),
            if (ownership.owner!.phone != null) ...[
              _divider(),
              _buildInfoRow(IconlyLight.calling, 'phone'.tr, ownership.owner!.phone!),
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
              _buildInfoRow(IconlyLight.user_1, 'name'.tr, mod.name),
              _divider(),
              _buildInfoRow(IconlyLight.message, 'email'.tr, mod.email),
              if (mod.phone != null) ...[
                _divider(),
                _buildInfoRow(IconlyLight.calling, 'phone'.tr, mod.phone!),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.w, color: AppColors.blue1),
          SizedBox(width: 12.w),
          Text(label, style: AppFonts.AlmaraiRegular14.copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: AppFonts.AlmaraiBold14.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.grey100);

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
