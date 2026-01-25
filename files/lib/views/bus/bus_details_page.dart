import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';
import '../../models/bus_models.dart';
import '../../services/bus_service.dart';
import '../../widgets/shimmer_loading.dart';

class BusDetailsPage extends StatefulWidget {
  const BusDetailsPage({super.key, required this.schoolId, required this.busId, this.initialBus});

  final String schoolId;
  final String busId;
  final Bus? initialBus;

  @override
  State<BusDetailsPage> createState() => _BusDetailsPageState(); 
}

class _BusDetailsPageState extends State<BusDetailsPage> {
  Bus? _bus;
  bool _loading = true;
  List<dynamic> _routes = [];
  bool _routesLoading = false;
  List<dynamic> _lines = [];
  bool _linesLoading = false;
  String? _linesDateFilter;

  @override
  void initState() {
    super.initState();
    _bus = widget.initialBus;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await BusService.getBusDetails(widget.schoolId, widget.busId);
      setState(() => _bus = res);
      _loadRoutes();
      _loadLines();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_bus?.busNumber ?? 'bus'.tr, style: AppFonts.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.2,
        actions: const [],
      ),
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: _loading
            ? const _BusDetailsShimmer()
            : _bus == null
                ? Center(child: Text('no_data'.tr))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: EdgeInsets.all(16.w),
                      children: [
                        _headerCard(),
                        SizedBox(height: 12.h),
                        _infoSection(),
                        SizedBox(height: 12.h),
                        _peopleSection(),
                        SizedBox(height: 12.h),
                        _assignedStudentsSection(),
                        SizedBox(height: 12.h),
                        _routesSection(),
                        SizedBox(height: 12.h),
                        _linesSection(),
                        if ((_bus?.gps.trackingUrl ?? '').isNotEmpty) ...[
                          SizedBox(height: 12.h),
                          _gpsSection(),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  Future<void> _onEditBus() async {
    if (_bus == null) return;
    final res = await Get.toNamed(
      AppRoutes.busForm, 
      arguments: {
        'schoolId': widget.schoolId,
        'bus': _bus,
      },
    );
    if (res == true) {
      _load();
    }
  }

  Widget _headerCard() {
    final bus = _bus!;
    final occupancy = bus.capacity == null || bus.capacity == 0
        ? '${bus.currentOccupancy ?? 0}'
        : '${bus.currentOccupancy ?? 0}/${bus.capacity}';
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(IconlyBold.discovery, color: Colors.white, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.busNumber, style: AppFonts.h3.copyWith(color: Colors.white)),
                    if (bus.plateNumber?.isNotEmpty == true)
                      Text(bus.plateNumber!, style: AppFonts.bodySmall.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _statusChip(bus.status ?? 'active'),
                  SizedBox(width: 6.w),
                  _actionIcon(Icons.edit_rounded, Colors.white, () => _onEditBus()),
                  _actionIcon(Icons.delete_outline_rounded, Colors.white, () => _onDeleteBus()),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _pill(Icons.event_seat_rounded, occupancy, light: true),
              _pill(Icons.route, _localizedBusType(bus.busType), light: true),
              _pill(Icons.calendar_today_rounded, bus.year?.toString() ?? '—', light: true),
              if (bus.color?.isNotEmpty == true) _pill(Icons.palette_rounded, bus.color!, light: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoSection() {
    final bus = _bus!;
    return _sectionCard(
      title: 'details'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _enhancedInfoRow(Icons.precision_manufacturing_rounded, 'manufacturer'.tr, bus.manufacturer ?? '—'),
          SizedBox(height: 12.h),
          _enhancedInfoRow(Icons.directions_car_rounded, 'model'.tr, bus.model ?? '—'),
          SizedBox(height: 12.h),
          _enhancedInfoRow(Icons.palette_rounded, 'color'.tr, bus.color ?? '—'),
          SizedBox(height: 12.h),
          _enhancedInfoRow(Icons.settings_rounded, 'motor_number'.tr, bus.motorNumber ?? '—'),
          SizedBox(height: 12.h),
          _enhancedInfoRow(Icons.build_rounded, 'chassis_number'.tr, bus.chassisNumber ?? '—'),
          if (bus.notes?.isNotEmpty == true) ...[
            SizedBox(height: 12.h),
            _enhancedInfoRow(Icons.note_rounded, 'notes'.tr, bus.notes!),
          ],
        ],
      ),
    );
  }

  Widget _peopleSection() {
    final bus = _bus!;
    return _sectionCard(
      title: 'team'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _enhancedPersonCard(
            icon: Icons.person_outline_rounded,
            title: 'driver'.tr,
            person: bus.driver,
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          SizedBox(height: 12.h),
          _enhancedPersonCard(
            icon: Icons.support_agent_rounded,
            title: 'assistant'.tr,
            person: bus.assistant,
            gradient: const LinearGradient(
              colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignedStudentsSection() {
    final students = _bus?.assignedStudents ?? [];
    return _sectionCard(
      title: 'students'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.blue1.withOpacity(0.1),
                  AppColors.blue1.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.blue1.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.people_rounded, color: AppColors.blue1, size: 18.sp),
                ),
                SizedBox(width: 10.w),
                Text(
                  '${students.length} ${'students'.tr}',
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.blue1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (students.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Column(
                  children: [
                    Icon(Icons.school_outlined, size: 48.sp, color: AppColors.textSecondary.withOpacity(0.5)),
                    SizedBox(height: 12.h),
                    Text(
                      'no_students_assigned'.tr,
                      style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...students.map((s) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _enhancedStudentCard(
                    name: s.student?.fullName ?? '—',
                    route: s.route ?? s.status ?? '',
                  ),
                )),
        ],
      ),
    );
  }
 
  Widget _gpsSection() {
    final url = _bus?.gps.trackingUrl ?? '';
    return _sectionCard(
      title: 'gps'.tr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF11998E).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: url.isNotEmpty ? () => Get.toNamed(url) : null,
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.my_location_rounded, color: Colors.white, size: 24.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'track_location'.tr,
                              style: AppFonts.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              url.isNotEmpty ? url : 'no_gps_url'.tr,
                              style: AppFonts.bodySmall.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'maintenance':
        color = Colors.orange;
        break;
      case 'inactive':
        color = Colors.grey;
        break;
      default:
        color = AppColors.blue1;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        status.tr,
        style: AppFonts.labelSmall.copyWith(color: color),
      ),
    );
  }

  Widget _routesSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'routes'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          // Buttons
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              _modernButton(
                icon: Icons.refresh_rounded,
                label: 'refresh'.tr,
                onTap: _loadRoutes,
                color: const Color(0xFF3B82F6),
              ),
              _modernButton(
                icon: Icons.add_rounded,
                label: 'add_route'.tr,
                onTap: () => _openRouteDialog(),
                color: AppColors.blue1,
              ),
            ],
          ),
          SizedBox(height: 20.h),
          // Routes List
          _routesLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _routes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: Column(
                          children: [
                            Icon(
                              Icons.route_outlined,
                              size: 64.sp,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'no_routes'.tr,
                              style: AppFonts.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: _routes.map((r) => _routeTile(r)).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _routeTile(dynamic route) {
    final map = route as Map<String, dynamic>? ?? {};
    final name = map['name']?.toString() ?? '—';
    final desc = map['description']?.toString() ?? '';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRouteDetails(map),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.alt_route_rounded, color: Colors.white, size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppFonts.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          desc,
                          style: AppFonts.bodyMedium.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _linesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section in card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'bus_lines'.tr,
                      style: AppFonts.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: _modernButton(
                      icon: Icons.date_range_rounded,
                      label: _linesDateFilter ?? 'date'.tr,
                      onTap: _pickLinesDate,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _modernButton(
                      icon: Icons.add_rounded,
                      label: 'add_line'.tr,
                      onTap: () => _openLineDialog(),
                      color: AppColors.blue1,
                    ),
                  ),
                  if (_linesDateFilter != null) ...[
                    SizedBox(width: 10.w),
                    _modernButton(
                      icon: Icons.close_rounded,
                      label: 'clear_filters'.tr,
                      onTap: _clearLinesDate,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Lines List - outside cards
        _linesLoading
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(40.h),
                  child: const CircularProgressIndicator(),
                ),
              )
            : _lines.isEmpty
                ? Container(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.route_outlined,
                            size: 64.sp,
                            color: AppColors.textSecondary.withOpacity(0.5),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'no_lines'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: _lines.asMap().entries.map((entry) => _lineExpandedSection(entry.value, entry.key)).toList(),
                  ),
      ],
    );
  }

  Widget _lineExpandedSection(dynamic line, int index) {  
    final map = line as Map<String, dynamic>? ?? {};
    final date = _formatDisplayDate(map['date']?.toString());
    final status = map['status']?.toString() ?? ''; 
    final id = map['_id']?.toString() ?? '';
    final stations = map['stations'] as List<dynamic>? ?? [];
    final driver = map['driver'] as Map<String, dynamic>?;
    final assistant = map['assistant'] as Map<String, dynamic>?;
    final notes = map['notes']?.toString() ?? '';
    
    // Determine status color
    Color statusColor = AppColors.blue1;
    if (status.toLowerCase() == 'completed') {
      statusColor = const Color(0xFF10B981);
    } else if (status.toLowerCase() == 'active' || status.toLowerCase() == 'in_progress') {
      statusColor = const Color(0xFF3B82F6);
    } else if (status.toLowerCase() == 'cancelled') {
      statusColor = const Color(0xFFEF4444);
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
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
          // Line Header Row
          Row(
            children: [
              // Date, Stations, Status
              Expanded(
                child: Wrap(
                  spacing: 12.w,
                  runSpacing: 8.h,
                  children: [
                    if (date.isNotEmpty)
                      _lineDataChip(Icons.calendar_today_rounded, date, AppColors.blue1),
                    _lineDataChip(Icons.location_on_rounded, '${stations.length} ${'stations'.tr}', const Color(0xFF10B981)),
                    if (status.isNotEmpty)
                      _lineDataChip(Icons.circle, status.tr, statusColor),
                  ],
                ),
              ),
              // Edit & Delete Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _lineActionBtn(
                    icon: Icons.edit_rounded,
                    onTap: () => _editLine(map),
                    color: AppColors.blue1,
                  ),
                  SizedBox(width: 8.w),
                  _lineActionBtn(
                    icon: Icons.delete_rounded,
                    onTap: id.isNotEmpty ? () => _deleteLineById(id) : null,
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
          
          // Driver & Assistant
          if (driver != null || assistant != null) ...[
            SizedBox(height: 12.h),
            if (driver != null)
              _linePersonRow(Icons.person_rounded, 'driver'.tr, driver),
            if (assistant != null) ...[
              SizedBox(height: 8.h),
              _linePersonRow(Icons.support_agent_rounded, 'assistant'.tr, assistant),
            ],
          ],
          
          // Stations Progress
          if (stations.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Divider(color: AppColors.borderLight),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.timeline_rounded, size: 18.sp, color: statusColor),
                SizedBox(width: 8.w),
                Text(
                  'stations_progress'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
                  ...stations.asMap().entries.map((entry) {
                    final station = entry.value as Map<String, dynamic>? ?? {};
                    final stationName = station['name']?.toString() ?? 'Station ${entry.key + 1}';
                    final address = station['address']?.toString() ?? '';
                    final order = int.tryParse(station['order']?.toString() ?? '${entry.key + 1}') ?? (entry.key + 1);
                    final arrivalTime = station['arrivalTime']?.toString() ?? '';
                    final departureTime = station['departureTime']?.toString() ?? '';
                    final stationStatus = station['status']?.toString() ?? '';
                    final students = station['students'] as List<dynamic>? ?? [];
                    final stationOrder = order;
                    final isLast = entry.key == stations.length - 1;
                    final isCompleted = stationStatus.toLowerCase() == 'completed' || stationStatus.toLowerCase() == 'departed';
                    final isInProgress = stationStatus.toLowerCase() == 'in_progress' || stationStatus.toLowerCase() == 'arrived';
                    
                    // Calculate attendance counts (from API, not static)
                    final statusCounts = <String, int>{};
                    for (final s in students) {
                      final sMap = s as Map<String, dynamic>? ?? {};
                      final att = (sMap['attendanceStatus'] ?? sMap['attendance'])?.toString().trim().toLowerCase() ?? '';
                      if (att.isEmpty) continue;
                      statusCounts[att] = (statusCounts[att] ?? 0) + 1;
                    }
                    
                    Color stationColor = isCompleted 
                        ? const Color(0xFF10B981) 
                        : isInProgress 
                            ? const Color(0xFF3B82F6) 
                            : AppColors.textSecondary.withOpacity(0.4);
                    
                    return _buildStationProgress(
                      order: order,
                      name: stationName,
                      address: address,
                      arrivalTime: arrivalTime,
                      departureTime: departureTime,
                      status: stationStatus,
                      studentsCount: students.length,
                      color: stationColor,
                      isLast: isLast,
                      isCompleted: isCompleted,
                      isInProgress: isInProgress,
                      lineId: id,
                      stationId: stationOrder.toString(),
                      statusCounts: statusCounts,
                      students: students,
                    );
                  }).toList(),
                ],
                
          // Notes
          if (notes.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note_rounded, size: 16.sp, color: AppColors.textSecondary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    notes,
                    style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _lineDataChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppFonts.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineActionBtn({required IconData icon, VoidCallback? onTap, required Color color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
      ),
    );
  }

  Widget _linePersonRow(IconData icon, String label, Map<String, dynamic> person) {
    final personName = person['name']?.toString() ?? '—';
    final phone = person['phone']?.toString() ?? '';
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.blue1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: AppColors.blue1),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                personName,
                style: AppFonts.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (phone.isNotEmpty)
          Text(
            phone,
            style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }

  Widget _buildStationProgress({
    required int order,
    required String name,
    required String address,
    required String arrivalTime,
    required String departureTime,
    required String status,
    required int studentsCount,
    required Color color,
    required bool isLast,
    required bool isCompleted,
    required bool isInProgress,
    required String lineId,
    required String stationId,
    Map<String, int> statusCounts = const {},
    List<dynamic> students = const [],
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Column
        Column(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$order',
                  style: AppFonts.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: isCompleted ? color : color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1.r),
                ),
              ),
          ],
        ),
        SizedBox(width: 12.w),
        // Station Info
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: AppFonts.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (status.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          status.tr,
                          style: AppFonts.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            
                          ),
                        ),
                      ),
                  ],
                ),
                if (address.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    address,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      
                    ),
                  ),
                ],
                SizedBox(height: 6.h),
                Wrap(
                  spacing: 12.w,
                  runSpacing: 4.h,
                  children: [
                    if (arrivalTime.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time_rounded, size: 12.sp, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            arrivalTime,
                            style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    if (departureTime.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 12.sp, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            departureTime,
                            style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    if (studentsCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_rounded, size: 12.sp, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            '$studentsCount',
                            style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                  ],
                ),
                // Attendance Summary
                if (studentsCount > 0) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'attendance'.tr,
                              style: AppFonts.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => _openAttendanceDialog(lineId, stationId, name, students),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: AppColors.blue1.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded, size: 12.sp, color: AppColors.blue1),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'edit_att'.tr,
                                      style: AppFonts.labelSmall.copyWith(
                                        color: AppColors.blue1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _buildAttendanceBadgesFromApi(statusCounts),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAttendanceBadgesFromApi(Map<String, int> statusCounts) {
    if (statusCounts.isEmpty) {
      // If API didn't return statuses, show 0 for known ones (but still derived/expected by API)
      return [
        _attendanceBadge('arrived'.tr, 0, const Color(0xFF10B981)),
        _attendanceBadge('not_arrived'.tr, 0, const Color(0xFFEF4444)),
        _attendanceBadge('late'.tr, 0, const Color(0xFFF59E0B)),
        _attendanceBadge('suspend'.tr, 0, const Color(0xFF6B7280)),
      ];
    }

    final entries = statusCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) {
      final color = _attendanceStatusColor(e.key);
      return _attendanceBadge(_attendanceStatusLabel(e.key), e.value, color);
    }).toList();
  }

  Color _attendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'arrived':
        return const Color(0xFF10B981);
      case 'not_arrived':
      case 'not arrived':
      case 'no_show':
      case 'no-show':
        return const Color(0xFFEF4444);
      case 'late':
        return const Color(0xFFF59E0B);
      case 'suspend':
      case 'suspended':
        return const Color(0xFF6B7280);
      default:
        return AppColors.blue1;
    }
  }

  String _attendanceStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'arrived':
        return 'arrived'.tr;
      case 'not_arrived':
      case 'not arrived':
      case 'no_show':
      case 'no-show':
        return 'not_arrived'.tr;
      case 'late':
        return 'late'.tr;
      case 'suspend':
      case 'suspended':
        return 'suspend'.tr;
      default:
        // fallback to server text
        return status;
    }
  }

  Widget _attendanceBadge(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            '$count',
            style: AppFonts.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAttendanceDialog(String lineId, String stationOrderStr, String stationName, List<dynamic> students) async {
    final stationOrder = int.tryParse(stationOrderStr);
    if (stationOrder == null) {
      Get.snackbar(
        'error'.tr,
        'station_id_missing'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    await Get.to(
      () => _StationAttendancePage(
        schoolId: widget.schoolId,
        busId: widget.busId,
        lineId: lineId,
        stationOrder: stationOrder,
        stationName: stationName,
        initialStudents: students,
      ),
    );
    _loadLines();
  }

  Future<void> _editLine(Map<String, dynamic> line) async {
    final result = await Get.to(() => _LineEditPage(
      schoolId: widget.schoolId,
      busId: widget.busId,
      line: line,
    ));
    if (result == true) {
      _loadLines();
    }
  }

  Future<void> _deleteLineById(String lineId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text('delete_line'.tr, style: AppFonts.h4),
            ),
          ],
        ),
        content: Text('confirm_delete_line'.tr, style: AppFonts.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await BusService.deleteLine(widget.schoolId, widget.busId, lineId);
        _loadLines();
        Get.snackbar('success'.tr, 'line_deleted'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.blue1,
            colorText: Colors.white);
      } catch (e) {
        Get.snackbar('error'.tr, e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white);
      }
    }
  }


  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12, 
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  Future<void> _loadRoutes() async {
    setState(() => _routesLoading = true);
    try {
      final res = await BusService.getRoutes(widget.schoolId, widget.busId);
      setState(() => _routes = res);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _routesLoading = false);
    }
  }

  Future<void> _loadLines() async {
    setState(() => _linesLoading = true);
    try {
      final res = await BusService.getLines(
        widget.schoolId,
        widget.busId,
        date: _linesDateFilter,
      );
      setState(() => _lines = res);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _linesLoading = false);
    }
  }

  Future<void> _openRouteDialog({Map<String, dynamic>? route}) async {
    final nameCtrl = TextEditingController(text: route?['name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: route?['description']?.toString() ?? '');
    final isEdit = route != null;
    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.blue1.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.blue1.withOpacity(0.15),
                          AppColors.blue1.withOpacity(0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.alt_route_rounded, color: AppColors.blue1, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      isEdit ? 'edit_route'.tr : 'add_route'.tr,
                      style: AppFonts.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(result: false),
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.blue1.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: nameCtrl,
                  style: AppFonts.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'route_name'.tr,
                    labelStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.label_rounded, color: AppColors.blue1),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.blue1.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: AppFonts.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'description'.tr,
                    labelStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.description_rounded, color: AppColors.blue1),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(result: false),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                        ),
                      ),
                      child: Text('cancel'.tr, style: AppFonts.bodyLarge.copyWith(color: AppColors.textSecondary)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                      child: Text('save'.tr, style: AppFonts.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true) {
      try {
        final payload = {
          'name': nameCtrl.text.trim(),
          'description': descCtrl.text.trim(),
        };
        if (isEdit) {
          await BusService.updateRoute(widget.schoolId, widget.busId, payload..addAll({'routeId': route['_id']}));
        } else {
          await BusService.addRoute(widget.schoolId, widget.busId, payload);
        }
        _loadRoutes();
        Get.snackbar('success'.tr, isEdit ? 'route_updated'.tr : 'route_added'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.blue1,
            colorText: Colors.white);
      } catch (e) {
        Get.snackbar('error'.tr, e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white);
      }
    }
  }

  Future<void> _openLineDialog({Map<String, dynamic>? line}) async {
    final isEdit = line != null;
    final routeCtrl = TextEditingController(text: line?['routeName']?.toString() ?? '');
    final tripTypeCtrl = TextEditingController(text: line?['tripType']?.toString() ?? '');
    final dateCtrl = TextEditingController(text: _formatDisplayDate(line?['date']?.toString()));
    final statusCtrl = TextEditingController(text: line?['status']?.toString() ?? '');
    final notesCtrl = TextEditingController(text: line?['notes']?.toString() ?? '');
    
    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                AppColors.blue1.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.blue1.withOpacity(0.15),
                            AppColors.blue1.withOpacity(0.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.route_rounded, color: AppColors.blue1, size: 24.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        isEdit ? 'edit_line'.tr : 'add_line'.tr,
                        style: AppFonts.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.back(result: false),
                      icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                // API: date + tripType required, and either routeName OR stations[]
                _buildModalTextField(routeCtrl, 'route_name'.tr, Icons.label_rounded, required: !isEdit),
                SizedBox(height: 16.h),
                _buildModalTextField(tripTypeCtrl, 'trip_type'.tr, Icons.swap_horiz_rounded),
                SizedBox(height: 16.h),
                _buildModalTextField(
                  dateCtrl,
                  'date'.tr,
                  Icons.calendar_today_rounded,
                  readOnly: true,
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = dateCtrl.text.isNotEmpty ? DateTime.tryParse(dateCtrl.text) ?? now : now;
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(now.year - 2),
                      lastDate: DateTime(now.year + 2),
                    );
                    if (picked != null) {
                      dateCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                SizedBox(height: 16.h),
                if (isEdit) ...[
                  _buildModalTextField(statusCtrl, 'status'.tr, Icons.info_rounded),
                  SizedBox(height: 16.h),
                ],
                _buildModalTextField(notesCtrl, 'notes'.tr, Icons.note_rounded),
                SizedBox(height: 24.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                          ),
                        ),
                        child: Text('cancel'.tr, style: AppFonts.bodyLarge.copyWith(color: AppColors.textSecondary)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text('save'.tr, style: AppFonts.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result == true) {
      final payload = <String, dynamic>{};
      final routeName = routeCtrl.text.trim();
      final tripType = tripTypeCtrl.text.trim();
      final date = dateCtrl.text.trim();
      final status = statusCtrl.text.trim();
      final notes = notesCtrl.text.trim();

      if (!isEdit) {
        // Create API requires date + tripType + (routeName OR stations)
        payload['date'] = date;
        payload['tripType'] = tripType;
        if (routeName.isNotEmpty) payload['routeName'] = routeName;
        if (notes.isNotEmpty) payload['notes'] = notes;
      } else {
        // Update API: all optional
        if (tripType.isNotEmpty) payload['tripType'] = tripType;
        if (routeName.isNotEmpty) payload['routeName'] = routeName;
        if (date.isNotEmpty) payload['date'] = date;
        if (status.isNotEmpty) payload['status'] = status;
        if (notes.isNotEmpty) payload['notes'] = notes;
      }
      try {
        if (isEdit) {
          await BusService.updateLine(widget.schoolId, widget.busId, line['_id']?.toString() ?? '', payload);
        } else {
          await BusService.createLine(widget.schoolId, widget.busId, payload);
        }
        _loadLines();
        Get.snackbar('success'.tr, isEdit ? 'line_updated'.tr : 'line_added'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.blue1,
            colorText: Colors.white);
      } catch (e) { 
        Get.snackbar('error'.tr, e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white);
      }
    }
  }

  Widget _buildModalTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.blue1.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: AppFonts.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.blue1),
          suffixIcon: readOnly ? Icon(Icons.arrow_drop_down_rounded, color: AppColors.blue1) : null,
        ),
      ),
    );
  }
  
  Future<void> _onDeleteBus() async {  
    if (_bus == null) return;
    final confirm = await _confirmDialog(
      title: 'delete'.tr,
      message: 'confirm_delete_bus'.trParams({'bus': _bus!.busNumber}),
      confirmLabel: 'delete'.tr,
    );
    if (confirm == true) {
      try {
        await BusService.deleteBus(widget.schoolId, widget.busId);
        Get.back(result: true);
        Get.snackbar('success'.tr, 'bus_deleted'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.blue1,
            colorText: Colors.white);
      } catch (e) {
        Get.snackbar('error'.tr, e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white);
      }
    }
  }

  Widget _pill(IconData icon, String text, {bool light = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: light ? Colors.white.withOpacity(0.18) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: light ? Colors.white : AppColors.textSecondary),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppFonts.bodySmall.copyWith(color: light ? Colors.white : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, Widget? trailing, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration(),
      child: Column( 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: AppFonts.h4.copyWith(color: AppColors.textPrimary)),
              ),
              if (trailing != null)
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback? onTap) {
    return Padding(
      padding: EdgeInsets.only(left: 6.w),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, size: 18.sp, color: color),
        ),
      ),
    );
  }

  Widget _enhancedInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.blue1.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.blue1.withOpacity(0.1),
                  AppColors.blue1.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.blue1, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedPersonCard({
    required IconData icon,
    required String title,
    required BusPerson? person,
    required Gradient gradient,
  }) {
    final hasPerson = person != null && person.name.isNotEmpty;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: hasPerson
            ? gradient
            : LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.1),
                  Colors.grey.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasPerson
              ? Colors.white.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasPerson
                ? const Color(0xFF667EEA).withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: hasPerson
                  ? Colors.white.withOpacity(0.25)
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: hasPerson ? Colors.white : Colors.grey,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.bodySmall.copyWith(
                    color: hasPerson
                        ? Colors.white.withOpacity(0.9)
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  hasPerson ? person.name : '—',
                  style: AppFonts.bodyLarge.copyWith(
                    color: hasPerson ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasPerson && (person.phone?.isNotEmpty ?? false)) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(
                        Icons.phone_rounded,
                        size: 14.sp,
                        color: hasPerson
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textSecondary,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        person.phone!,
                        style: AppFonts.bodySmall.copyWith(
                          color: hasPerson
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedStudentCard({required String name, required String route}) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppColors.blue1.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.blue1.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.blue1.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.blue1.withOpacity(0.15),
                  AppColors.blue1.withOpacity(0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.blue1,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (route.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    route,
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: AppFonts.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openRouteDetails(Map<String, dynamic> route) {
    Get.to(() => RouteDetailsPage(
      schoolId: widget.schoolId,
      busId: widget.busId,
      route: route,
      onUpdated: _loadRoutes,
    ));
  }

  Future<bool> _confirmDialog({required String title, required String message, required String confirmLabel}) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: AppFonts.h4.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr, style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
            ),
            child: Text(confirmLabel, style: AppFonts.bodyMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _pickLinesDate() async {
    final now = DateTime.now();
    final initial = _linesDateFilter != null ? DateTime.tryParse(_linesDateFilter!) ?? now : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _linesDateFilter = _fmtDate(picked));
      _loadLines();
    }
  }

  void _clearLinesDate() {
    setState(() => _linesDateFilter = null);
    _loadLines();
  }

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return _fmtDate(parsed);
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
}

class _BusDetailsShimmer extends StatelessWidget {
  const _BusDetailsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: 3,
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: ShimmerLoading(
          child: Container(
            height: 120.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
        ),
      ),
    );
  }
}

class RouteDetailsPage extends StatefulWidget {
  final String schoolId;
  final String busId;
  final Map<String, dynamic> route;
  final VoidCallback onUpdated;

  const RouteDetailsPage({
    Key? key,
    required this.schoolId,
    required this.busId,
    required this.route,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Print route details
    debugPrint('=== ROUTE DETAILS ===');
    debugPrint('Route ID: ${widget.route['_id']}');
    debugPrint('Route Name: ${widget.route['name']}');
    debugPrint('Description: ${widget.route['description']}');
    debugPrint('Full Route Data: ${widget.route}');
    debugPrint('====================');
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.route['name']?.toString() ?? '—';
    final desc = widget.route['description']?.toString() ?? '';
    final id = widget.route['_id']?.toString() ?? '';
    final stations = widget.route['stations'] as List<dynamic>? ?? [];
    final createdAt = widget.route['createdAt']?.toString();
    final updatedAt = widget.route['updatedAt']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('route_details'.tr, style: AppFonts.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.2,
      ),
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.alt_route_rounded, color: Colors.white, size: 32.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    name,
                    style: AppFonts.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text(
                      desc,
                      style: AppFonts.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 20.h),
            // Route Data Box
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
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
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667EEA).withOpacity(0.15),
                              const Color(0xFF764BA2).withOpacity(0.25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.info_rounded, color: const Color(0xFF667EEA), size: 22.sp),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'route_information'.tr,
                        style: AppFonts.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _routeDataRow(Icons.label_rounded, 'route_name'.tr, name),
                  if (desc.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _routeDataRow(Icons.description_rounded, 'description'.tr, desc),
                  ],
                  if (id.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _routeDataRow(Icons.fingerprint_rounded, 'route_id'.tr, id),
                  ],
                  if (stations.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _routeDataRow(Icons.location_on_rounded, 'stations_count'.tr, '${stations.length}'),
                  ],
                  if (createdAt != null) ...[
                    SizedBox(height: 16.h),
                    _routeDataRow(Icons.calendar_today_rounded, 'created_at'.tr, _formatDate(createdAt)),
                  ],
                  if (updatedAt != null) ...[
                    SizedBox(height: 16.h),
                    _routeDataRow(Icons.update_rounded, 'updated_at'.tr, _formatDate(updatedAt)),
                  ],
                ],
              ),
            ),
            // Stations List if available
            if (stations.isNotEmpty) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
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
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667EEA).withOpacity(0.15),
                                const Color(0xFF764BA2).withOpacity(0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.location_on_rounded, color: const Color(0xFF667EEA), size: 22.sp),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'stations'.tr,
                          style: AppFonts.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    ...stations.asMap().entries.map((entry) {
                      final station = entry.value as Map<String, dynamic>? ?? {};
                      final stationName = station['name']?.toString() ?? 'Station ${entry.key + 1}';
                      final address = station['address']?.toString() ?? '';
                      final order = station['order']?.toString() ?? '${entry.key + 1}';
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Container(
                          padding: EdgeInsets.all(14.w),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.blue1.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: AppColors.blue1.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  order,
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: AppColors.blue1,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stationName,
                                      style: AppFonts.bodyLarge.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (address.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        address,
                                        style: AppFonts.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.edit_rounded,
                    label: 'edit'.tr,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _editRoute(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _actionButton(
                    icon: Icons.delete_rounded,
                    label: 'delete'.tr,
                    color: const Color(0xFFEF4444),
                    onTap: id.isNotEmpty ? () => _deleteRoute(id) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeDataRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.blue1.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.blue1, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppFonts.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: AppFonts.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editRoute() async {
    final result = await Get.to(() => _RouteEditPage(
      schoolId: widget.schoolId,
      busId: widget.busId,
      route: widget.route,
    ));
    if (result == true) {
      widget.onUpdated();
      Get.back();
    }
  }

  Future<void> _deleteRoute(String routeId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text('delete_route'.tr, style: AppFonts.h4),
            ),
          ],
        ),
        content: Text('confirm_delete_route'.tr, style: AppFonts.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await BusService.deleteRoute(widget.schoolId, widget.busId, routeId);
        widget.onUpdated();
        Get.back();
        Get.snackbar('success'.tr, 'route_deleted'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.blue1,
            colorText: Colors.white);
      } catch (e) {
        Get.snackbar('error'.tr, e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white);
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }
}

class LineDetailsPage extends StatefulWidget {
  final String schoolId;
  final String busId;
  final Map<String, dynamic> line;
  final VoidCallback onUpdated;

  const LineDetailsPage({
    Key? key,
    required this.schoolId,
    required this.busId,
    required this.line,
    required this.onUpdated,
  }) : super(key: key);

  @override
  State<LineDetailsPage> createState() => _LineDetailsPageState();
}

class _LineDetailsPageState extends State<LineDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Print line details
    debugPrint('=== LINE DETAILS ===');
    debugPrint('Line ID: ${widget.line['_id']}');
    debugPrint('Line Name: ${widget.line['name']}');
    debugPrint('Route Name: ${widget.line['routeName']}');
    debugPrint('Date: ${widget.line['date']}');
    debugPrint('Trip Type: ${widget.line['tripType']}');
    debugPrint('Status: ${widget.line['status']}');
    debugPrint('Stations: ${widget.line['stations']}');
    debugPrint('Driver: ${widget.line['driver']}');
    debugPrint('Assistant: ${widget.line['assistant']}');
    debugPrint('Notes: ${widget.line['notes']}');
    debugPrint('Full Line Data: ${widget.line}');
    debugPrint('===================');
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.line['name']?.toString() ?? '—';
    final routeName = widget.line['routeName']?.toString() ?? '';
    final tripType = widget.line['tripType']?.toString() ?? '';
    final date = _formatDisplayDate(widget.line['date']?.toString());
    final status = widget.line['status']?.toString() ?? '';
    final id = widget.line['_id']?.toString() ?? '';
    final stations = widget.line['stations'] as List<dynamic>? ?? [];
    final driver = widget.line['driver'] as Map<String, dynamic>?;
    final assistant = widget.line['assistant'] as Map<String, dynamic>?;
    final notes = widget.line['notes']?.toString() ?? '';
    final startedAt = widget.line['startedAt']?.toString();
    final completedAt = widget.line['completedAt']?.toString();
    final createdAt = widget.line['createdAt']?.toString();

    // Determine gradient colors
    List<Color> gradientColors;
    if (status.toLowerCase() == 'completed') {
      gradientColors = [const Color(0xFF10B981), const Color(0xFF059669)];
    } else if (status.toLowerCase() == 'active' || status.toLowerCase() == 'in_progress') {
      gradientColors = [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    } else if (status.toLowerCase() == 'cancelled') {
      gradientColors = [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    } else {
      gradientColors = [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('line_details'.tr, style: AppFonts.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.2,
      ),
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.route_rounded, color: Colors.white, size: 32.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    name,
                    style: AppFonts.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (routeName.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      routeName,
                      style: AppFonts.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: [
                      if (date.isNotEmpty)
                        _whiteInfoChip(Icons.calendar_today_rounded, date),
                      if (tripType.isNotEmpty)
                        _whiteInfoChip(Icons.swap_horiz_rounded, tripType),
                      if (status.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            status.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            // Line Data Box
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
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
                          gradient: LinearGradient(
                            colors: [
                              gradientColors[0].withOpacity(0.15),
                              gradientColors[1].withOpacity(0.25),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.info_rounded, color: gradientColors[0], size: 22.sp),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'line_information'.tr,
                        style: AppFonts.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  _dataRow(Icons.title_rounded, 'line_name'.tr, name),
                  if (routeName.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.label_rounded, 'route_name'.tr, routeName),
                  ],
                  if (date.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.calendar_today_rounded, 'date'.tr, date),
                  ],
                  if (tripType.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.swap_horiz_rounded, 'trip_type'.tr, tripType),
                  ],
                  if (status.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.info_rounded, 'status'.tr, status.tr),
                  ],
                  if (id.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.fingerprint_rounded, 'line_id'.tr, id),
                  ],
                  if (notes.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.note_rounded, 'notes'.tr, notes),
                  ],
                  if (startedAt != null) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.play_circle_rounded, 'started_at'.tr, _formatDateTime(startedAt)),
                  ],
                  if (completedAt != null) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.check_circle_rounded, 'completed_at'.tr, _formatDateTime(completedAt)),
                  ],
                  if (createdAt != null) ...[
                    SizedBox(height: 16.h),
                    _dataRow(Icons.calendar_today_rounded, 'created_at'.tr, _formatDateTime(createdAt)),
                  ],
                ],
              ),
            ),
            // Driver & Assistant Section
            if (driver != null || assistant != null) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
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
                            gradient: LinearGradient(
                              colors: [
                                gradientColors[0].withOpacity(0.15),
                                gradientColors[1].withOpacity(0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.people_rounded, color: gradientColors[0], size: 22.sp),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'team'.tr,
                          style: AppFonts.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    if (driver != null) ...[
                      _personDataRow(Icons.person_outline_rounded, 'driver'.tr, driver),
                      SizedBox(height: 16.h),
                    ],
                    if (assistant != null)
                      _personDataRow(Icons.support_agent_rounded, 'assistant'.tr, assistant),
                  ],
                ),
              ),
            ],
            // Stations Progress Section
            if (stations.isNotEmpty) ...[
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
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
                            gradient: LinearGradient(
                              colors: [
                                gradientColors[0].withOpacity(0.15),
                                gradientColors[1].withOpacity(0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.timeline_rounded, color: gradientColors[0], size: 22.sp),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'stations_progress'.tr,
                          style: AppFonts.h3.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    ...stations.asMap().entries.map((entry) {
                      final station = entry.value as Map<String, dynamic>? ?? {};
                      final stationName = station['name']?.toString() ?? 'Station ${entry.key + 1}';
                      final address = station['address']?.toString() ?? '';
                      final order = int.tryParse(station['order']?.toString() ?? '${entry.key + 1}') ?? (entry.key + 1);
                      final arrivalTime = station['arrivalTime']?.toString() ?? '';
                      final departureTime = station['departureTime']?.toString() ?? '';
                      final stationStatus = station['status']?.toString() ?? '';
                      final students = station['students'] as List<dynamic>? ?? [];
                      final isLast = entry.key == stations.length - 1;
                      final isCompleted = stationStatus.toLowerCase() == 'completed' || stationStatus.toLowerCase() == 'departed';
                      final isInProgress = stationStatus.toLowerCase() == 'in_progress' || stationStatus.toLowerCase() == 'arrived';
                      
                      Color stationColor = isCompleted 
                          ? const Color(0xFF10B981) 
                          : isInProgress 
                              ? const Color(0xFF3B82F6) 
                              : AppColors.textSecondary.withOpacity(0.3);
                      
                      return _buildStationProgressItem(
                        order: order,
                        name: stationName,
                        address: address,
                        arrivalTime: arrivalTime,
                        departureTime: departureTime,
                        status: stationStatus,
                        studentsCount: students.length,
                        color: stationColor,
                        isLast: isLast,
                        isCompleted: isCompleted,
                        isInProgress: isInProgress,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
            SizedBox(height: 20.h),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.edit_rounded,
                    label: 'edit'.tr,
                    color: const Color(0xFF3B82F6),
                    onTap: () => _editLine(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _actionButton(
                    icon: Icons.delete_rounded,
                    label: 'delete'.tr,
                    color: const Color(0xFFEF4444),
                    onTap: id.isNotEmpty ? () => _deleteLine(id) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.blue1.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.blue1.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.blue1, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppFonts.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            text,
            style: AppFonts.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                label,
                style: AppFonts.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDisplayDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final parsed = DateTime.tryParse(dateStr);
    if (parsed == null) return dateStr;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStationProgressItem({
    required int order,
    required String name,
    required String address,
    required String arrivalTime,
    required String departureTime,
    required String status,
    required int studentsCount,
    required Color color,
    required bool isLast,
    required bool isCompleted,
    required bool isInProgress,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Column
        Column(
          children: [
            // Station Circle
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$order',
                  style: AppFonts.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Connecting Line
            if (!isLast)
              Container(
                width: 2.w,
                height: 80.h,
                decoration: BoxDecoration(
                  color: isCompleted ? color : color.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1.r),
                ),
              ),
          ],
        ),
        SizedBox(width: 16.w),
        // Station Info
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppFonts.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              address,
                              style: AppFonts.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (status.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          status.tr,
                          style: AppFonts.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                Wrap(
                  spacing: 16.w,
                  runSpacing: 8.h,
                  children: [
                    if (arrivalTime.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16.sp,
                            color: isCompleted || isInProgress ? color : AppColors.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'arrival'.tr,
                            style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            arrivalTime,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (departureTime.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16.sp,
                            color: isCompleted ? color : AppColors.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'departure'.tr,
                            style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            departureTime,
                            style: AppFonts.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    if (studentsCount > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_rounded, size: 16.sp, color: AppColors.textSecondary),
                          SizedBox(width: 6.w),
                          Text(
                            '$studentsCount ${'students'.tr}',
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _personDataRow(IconData icon, String label, Map<String, dynamic> person) {
    final personName = person['name']?.toString() ?? '—';
    final email = person['email']?.toString() ?? '';
    final phone = person['phone']?.toString() ?? '';
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.blue1.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: AppColors.blue1, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(left: 42.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personName,
                  style: AppFonts.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.email_rounded, size: 14.sp, color: AppColors.textSecondary),
                      SizedBox(width: 6.w),
                      Text(
                        email,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 14.sp, color: AppColors.textSecondary),
                      SizedBox(width: 6.w),
                      Text(
                        phone,
                        style: AppFonts.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editLine() async {
    final result = await Get.to(() => _LineEditPage(
      schoolId: widget.schoolId,
      busId: widget.busId,
      line: widget.line,
    ));
    if (result == true) {
      widget.onUpdated();
      Get.back();
    }
  }

  Future<void> _deleteLine(String lineId) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text('delete_line'.tr, style: AppFonts.h4),
            ),
          ],
        ),
        content: Text('confirm_delete_line'.tr, style: AppFonts.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await BusService.deleteLine(widget.schoolId, widget.busId, lineId);
        widget.onUpdated();
        Get.back();
        Get.snackbar('success'.tr, 'line_deleted'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.blue1,
            colorText: Colors.white);
      } catch (e) {
        Get.snackbar('error'.tr, e.toString(),
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.error,
            colorText: Colors.white);
      }
    }
  }
}

class _RouteEditPage extends StatefulWidget {
  final String schoolId;
  final String busId;
  final Map<String, dynamic> route;

  const _RouteEditPage({
    Key? key,
    required this.schoolId,
    required this.busId,
    required this.route,
  }) : super(key: key);

  @override
  State<_RouteEditPage> createState() => _RouteEditPageState();
}

class _RouteEditPageState extends State<_RouteEditPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.route['name']?.toString() ?? '';
    _descCtrl.text = widget.route['description']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_route'.tr, style: AppFonts.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.2,
      ),
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _buildTextField(_nameCtrl, 'route_name'.tr, required: true),
            SizedBox(height: 16.h),
            _buildTextField(_descCtrl, 'description'.tr, maxLines: 3),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('save'.tr, style: AppFonts.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, int maxLines = 1}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        style: AppFonts.bodyLarge,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'required_field'.tr : null : null,
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'route_name_required'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'routeId': widget.route['_id'],
      };
      await BusService.updateRoute(widget.schoolId, widget.busId, payload);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _LineEditPage extends StatefulWidget {
  final String schoolId;
  final String busId;
  final Map<String, dynamic> line;

  const _LineEditPage({
    Key? key,
    required this.schoolId,
    required this.busId,
    required this.line,
  }) : super(key: key);

  @override
  State<_LineEditPage> createState() => _LineEditPageState();
}

class _LineEditPageState extends State<_LineEditPage> {
  final _nameCtrl = TextEditingController();
  final _routeCtrl = TextEditingController();
  final _tripTypeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.line['name']?.toString() ?? '';
    _routeCtrl.text = widget.line['routeName']?.toString() ?? '';
    _tripTypeCtrl.text = widget.line['tripType']?.toString() ?? '';
    _dateCtrl.text = _formatDateForEdit(widget.line['date']?.toString());
    _statusCtrl.text = widget.line['status']?.toString() ?? '';
  }

  String _formatDateForEdit(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _routeCtrl.dispose();
    _tripTypeCtrl.dispose();
    _dateCtrl.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit_line'.tr, style: AppFonts.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.2,
      ),
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _buildTextField(_nameCtrl, 'line_name'.tr, required: true),
            SizedBox(height: 16.h),
            _buildTextField(_routeCtrl, 'route_name'.tr),
            SizedBox(height: 16.h),
            _buildTextField(_tripTypeCtrl, 'trip_type'.tr),
            SizedBox(height: 16.h),
            _buildTextField(_dateCtrl, 'date'.tr, onTap: () => _pickDate()),
            SizedBox(height: 16.h),
            _buildTextField(_statusCtrl, 'status'.tr),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('save'.tr, style: AppFonts.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false, VoidCallback? onTap}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: onTap != null,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary),
          suffixIcon: onTap != null ? Icon(Icons.calendar_today_rounded, color: AppColors.blue1) : null,
        ),
        style: AppFonts.bodyLarge,
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'required_field'.tr : null : null,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dateCtrl.text.isNotEmpty ? DateTime.tryParse(_dateCtrl.text) ?? now : now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      _dateCtrl.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar('error'.tr, 'line_name_required'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'routeName': _routeCtrl.text.trim(),
        'tripType': _tripTypeCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'status': _statusCtrl.text.trim(),
      };
      await BusService.updateLine(widget.schoolId, widget.busId, widget.line['_id']?.toString() ?? '', payload);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _StationAttendancePage extends StatefulWidget {
  final String schoolId;
  final String busId;
  final String lineId;
  final int stationOrder;
  final String stationName;
  final List<dynamic> initialStudents;

  const _StationAttendancePage({
    Key? key,
    required this.schoolId,
    required this.busId,
    required this.lineId,
    required this.stationOrder,
    required this.stationName,
    required this.initialStudents,
  }) : super(key: key);

  @override
  State<_StationAttendancePage> createState() => _StationAttendancePageState();
}

class _StationAttendancePageState extends State<_StationAttendancePage> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    try {
      // Use line details data (stations[].students) as source of truth.
      _students = widget.initialStudents.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _saving = true);
    try {
      final attendanceRecords = _students.map((s) {
        final studentData = s['student'] as Map<String, dynamic>? ?? s;
        final studentId = (studentData['_id'] ?? studentData['id'] ?? s['studentId'])?.toString() ?? '';
        final status = (s['attendanceStatus'] ?? s['attendance'] ?? 'present').toString().toLowerCase();
        return <String, dynamic>{
          'studentId': studentId,
          'attendanceStatus': status,
        };
      }).where((r) => (r['studentId'] as String).isNotEmpty).toList();

      await BusService.bulkUpdateAttendanceAtStation(
        schoolId: widget.schoolId,
        busId: widget.busId,
        lineId: widget.lineId,
        stationOrder: widget.stationOrder,
        attendanceRecords: attendanceRecords,
      );
      
      Get.snackbar('success'.tr, 'attendance_saved'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white);
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _setAttendance(int index, String status) {
    setState(() {
      _students[index]['attendanceStatus'] = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stationName, style: AppFonts.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.2,
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveAttendance,
            child: _saving
                ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2))
                : Text('save'.tr, style: AppFonts.bodyMedium.copyWith(color: AppColors.blue1, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64.sp, color: AppColors.textSecondary.withOpacity(0.5)),
                        SizedBox(height: 16.h),
                        Text('no_students'.tr, style: AppFonts.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      // Handle nested student object
                      final studentData = student['student'] as Map<String, dynamic>? ?? student;
                      final name = studentData['name']?.toString() ?? 
                                   studentData['fullName']?.toString() ?? 
                                   studentData['firstName']?.toString() ?? 
                                   '${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}'.trim();
                      final displayName = name.isNotEmpty ? name : 'student'.tr + ' ${index + 1}';
                      final code = studentData['studentCode']?.toString() ?? studentData['code']?.toString() ?? '';
                      final phone = studentData['phone']?.toString() ?? studentData['guardianPhone']?.toString() ?? studentData['parentPhone']?.toString() ?? '';
                      final className = studentData['className']?.toString() ?? studentData['class']?.toString() ?? studentData['grade']?.toString() ?? '';
                      final avatar = studentData['avatar']?.toString() ?? studentData['photo']?.toString() ?? studentData['image']?.toString() ?? '';
                      final currentAtt = (student['attendanceStatus'] ?? student['attendance'] ?? studentData['attendanceStatus'] ?? studentData['attendance'])
                              ?.toString()
                              .toLowerCase() ??
                          '';
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                avatar.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 24.r,
                                        backgroundImage: NetworkImage(avatar),
                                      )
                                    : Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                        decoration: BoxDecoration(
                                          color: AppColors.blue1.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20.r),
                                        ),
                                        child: Text(
                                          displayName.isNotEmpty ? displayName : '?',
                                          style: AppFonts.bodyMedium.copyWith(
                                            color: AppColors.blue1,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: AppFonts.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Wrap(
                                        spacing: 8.w,
                                        runSpacing: 4.h,
                                        children: [
                                          if (code.isNotEmpty)
                                            _studentInfoTag(Icons.badge_outlined, code),
                                          if (className.isNotEmpty)
                                            _studentInfoTag(Icons.school_outlined, className),
                                          if (phone.isNotEmpty)
                                            _studentInfoTag(Icons.phone_outlined, phone),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Wrap(
                              spacing: 8.w,
                              runSpacing: 8.h,
                              children: _buildAttendanceStatusButtons(
                                currentStatus: currentAtt,
                                onSelect: (s) => _setAttendance(index, s),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _attendanceButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: color, width: isSelected ? 2 : 1),
          ),
          child: Center(
            child: Text(
              label,
              style: AppFonts.labelSmall.copyWith(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAttendanceStatusButtons({
    required String currentStatus,
    required ValueChanged<String> onSelect,
  }) {
    final statuses = _deriveAttendanceStatusesFromApi();
    return statuses.map((s) {
      final color = _attendanceStatusColor(s);
      return SizedBox(
        width: (Get.width - 16.w * 2 - 8.w * 3) / 2, // 2 buttons per row approx
        child: _attendanceButton(
          label: _attendanceStatusLabel(s),
          isSelected: currentStatus == s.toLowerCase(),
          color: color,
          onTap: () => onSelect(s),
        ),
      );
    }).toList();
  }

  List<String> _deriveAttendanceStatusesFromApi() {
    final set = <String>{};
    for (final s in _students) {
      final status = (s['attendanceStatus'] ?? s['attendance'])?.toString().trim().toLowerCase();
      if (status != null && status.isNotEmpty) set.add(status);
    }
    // If API already provides statuses, use them; else use the required 4.
    if (set.isNotEmpty) return set.toList();
    return const ['suspend', 'late', 'not_arrived', 'arrived'];
  }

  Color _attendanceStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'arrived':
        return const Color(0xFF10B981);
      case 'not_arrived':
      case 'not arrived':
      case 'no_show':
      case 'no-show':
        return const Color(0xFFEF4444);
      case 'late':
        return const Color(0xFFF59E0B);
      case 'suspend':
      case 'suspended':
        return const Color(0xFF6B7280);
      default:
        return AppColors.blue1;
    }
  }

  String _attendanceStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'arrived':
        return 'arrived'.tr;
      case 'not_arrived':
      case 'not arrived':
      case 'no_show':
      case 'no-show':
        return 'not_arrived'.tr;
      case 'late':
        return 'late'.tr;
      case 'suspend':
      case 'suspended':
        return 'suspend'.tr;
      default:
        return status;
    }
  }

  Widget _studentInfoTag(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: AppColors.textSecondary),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppFonts.labelSmall.copyWith(
              color: AppColors.textSecondary,
              
            ),
          ),
        ],
      ),
    );
  }
}


