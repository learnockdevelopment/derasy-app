import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../models/bus_models.dart';
import '../../models/school_models.dart';
import '../../services/bus_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../widgets/top_app_bar_widget.dart';
import '../../services/user_storage_service.dart';
import '../../services/students_service.dart';
import '../../models/student_models.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key, this.schoolId, this.school});

  final String? schoolId;
  final School? school;

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  List<Bus> _buses = [];
  bool _loading = true;
  String _statusFilter = 'all';
  String _typeFilter = 'all';
  final TextEditingController _searchCtrl = TextEditingController();
  Map<String, dynamic>? _userData;
  Set<String> _childrenSchoolIds = {};

  String get _schoolId => widget.schoolId ?? widget.school?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (_schoolId.isEmpty) {
      _loadChildrenSchools().then((_) => _load());
    } else {
      _load();
    }
  }
  
  Future<void> _loadChildrenSchools() async {
    try {
      final response = await StudentsService.getRelatedChildren();
      if (response.success) {
        // Get current user ID to filter only parent's children
        final currentUser = UserStorageService.getCurrentUser();
        if (currentUser == null) return;

        final currentUserId = currentUser.id;
        final userJson = currentUser.toJson();
        final currentUserIdAlt = userJson['_id']?.toString() ?? currentUserId;

        // Filter children to show only those where current user is the parent
        final filteredChildren = response.students.where((child) {
          final parentId = child.parent.id;
          return parentId == currentUserId || parentId == currentUserIdAlt;
        }).toList();

        // Get unique school IDs from children
        final schoolIds = filteredChildren
            .where((child) => child.schoolId.id.isNotEmpty)
            .map((child) => child.schoolId.id)
            .toSet();

        setState(() {
          _childrenSchoolIds = schoolIds;
        });
      }
    } catch (e) {
      print('🚌 [BUSES] Error loading children schools: $e');
    }
  }

  Future<void> _loadUserData() async {
    final userData = await UserStorageService.getUserData();
    if (mounted) {
      setState(() {
        _userData = userData;
      });
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    
    try {
      List<Bus> allBuses = [];
      
      if (_schoolId.isNotEmpty) {
        // Load buses for specific school
        final res = await BusService.getBuses(
          _schoolId,
          status: _statusFilter,
          busType: _typeFilter,
        );
        allBuses = res.buses;
      } else if (_childrenSchoolIds.isNotEmpty) {
        // Load buses for all schools that children are linked with
        for (final schoolId in _childrenSchoolIds) {
          try {
            final res = await BusService.getBuses(
              schoolId,
              status: _statusFilter,
              busType: _typeFilter,
            );
            allBuses.addAll(res.buses);
          } catch (e) {
            print('🚌 [BUSES] Error loading buses for school $schoolId: $e');
            // Continue loading other schools
          }
        }
      } else {
        // No school ID and no children schools
        setState(() => _loading = false);
        Future.microtask(() {
          Get.snackbar('error'.tr, 'no_schools_found'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: AppColors.error,
              colorText: Colors.white);
        });
        return;
      }
      
      setState(() => _buses = allBuses);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // Top App Bar Widget
          TopAppBarWidget(
            userData: _userData,
            showLoading: _userData == null,
          ),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          // Hero Header
          SliverToBoxAdapter(child: _buildHeroHeader()),
          // Search Bar
          SliverToBoxAdapter(child: _buildSearchBar()),
          // Filters
          SliverToBoxAdapter(child: _buildFilters()),
          SliverToBoxAdapter(child: SizedBox(height: 16.h)),
          // Buses List
          if (_loading)
            SliverToBoxAdapter(child: _buildShimmerList())
          else if (_buses.isEmpty)
            SliverToBoxAdapter(child: _buildEmpty())
          else
            SliverPadding(
              padding: EdgeInsets.all(16.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _busCard(_buses[index]),
                  childCount: _buses.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('buses'.tr, style: AppFonts.h3.copyWith(color: Colors.white)),
                SizedBox(height: 4.h),
                Text(
                  _loading ? '...' : '${_buses.length} ${'buses'.tr}',
                  style: AppFonts.bodyMedium.copyWith(color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _onAddBus,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('add_bus'.tr, style: AppFonts.bodyMedium.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.18),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              elevation: 0,
            ),
          )
        ],
      ),
    );
  }

  Future<void> _onAddBus() async {
    final res = await Get.toNamed(
      AppRoutes.busForm,
      arguments: {
        'schoolId': _schoolId,
        'bus': null,
      },
    );
    if (res == true) {
      _load();
    }
  }


  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 10.h),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildDropdownFilter(
                  label: 'status'.tr,
                  value: _statusFilter,
                  items: const ['all', 'active', 'inactive', 'maintenance'],
                  onChanged: (v) {
                    setState(() => _statusFilter = v ?? 'all');
                    _load();
                  },
                )),
                SizedBox(width: 12.w),
                Expanded(child: _buildDropdownFilter(
                  label: 'bus_type'.tr,
                  value: _typeFilter,
                  items: const ['all', 'standard', 'mini', 'large'],
                  onChanged: (v) {
                    setState(() => _typeFilter = v ?? 'all');
                    _load();
                  },
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e == 'all' ? 'all'.tr : e.tr,
                      style: AppFonts.bodyMedium,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        child: TextField(
          controller: _searchCtrl,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            hintText: 'search_buses'.tr,
            hintStyle: AppFonts.bodySmall.copyWith(
              color: const Color(0xFF9CA3AF),
              
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      _load();
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildShimmerList() {
    return Column(
      children: List.generate(
        6,
        (index) => Padding(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
          child: ShimmerLoading(
            child: Container(
              height: 110.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(IconlyLight.info_circle, size: 48.sp, color: AppColors.textSecondary),
            SizedBox(height: 12.h),
            Text('no_data'.tr, style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _busCard(Bus bus) {
    final occupancy = bus.capacity == null || bus.capacity == 0
        ? '${bus.currentOccupancy ?? 0}'
        : '${bus.currentOccupancy ?? 0}/${bus.capacity}';

    Color statusColor = AppColors.primaryBlue;
    switch (bus.status) {
      case 'maintenance':
        statusColor = Colors.orange;
        break;
      case 'inactive':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = AppColors.primaryBlue;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: () {
          Get.toNamed(
            AppRoutes.busDetails,
            arguments: {
              'busId': bus.id,
              'schoolId': _schoolId,
              'bus': bus,
            },
          );
        },
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(IconlyBold.discovery, color: AppColors.primaryBlue, size: 22.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bus.busNumber,
                          style: AppFonts.h4.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (bus.plateNumber != null && bus.plateNumber!.isNotEmpty)
                          Text(
                            bus.plateNumber!,
                            style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      (bus.status ?? 'active').tr,
                      style: AppFonts.labelSmall.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _infoChip(Icons.event_seat_rounded, occupancy),
                  SizedBox(width: 8.w),
                  _infoChip(Icons.route, _localizedBusType(bus.busType)),
                  SizedBox(width: 8.w),
                  _infoChip(Icons.person, bus.driver?.name ?? '—'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedBusType(String? type) {
    switch ((type ?? 'standard').toLowerCase()) {
      case 'mini':
        return 'bus_type_mini'.tr;
      case 'large':
        return 'bus_type_large'.tr;
      default:
        return 'bus_type_standard'.tr;
    }
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.textSecondary),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

