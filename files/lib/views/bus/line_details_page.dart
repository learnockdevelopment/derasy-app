import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/bus_line_models.dart';
import '../../services/bus_service.dart';
import '../../widgets/shimmer_loading.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'bus_details_page.dart'; // To access StationAttendancePage

class LineDetailsPage extends StatefulWidget {
  final String schoolId;
  final String busId;
  final String lineId;
  final BusLine? initialLine;

  const LineDetailsPage({
    super.key,
    required this.schoolId,
    required this.busId,
    required this.lineId,
    this.initialLine,
  });

  @override
  State<LineDetailsPage> createState() => _LineDetailsPageState();
}

class _LineDetailsPageState extends State<LineDetailsPage> {
  BusLine? _line;
  bool _loading = true;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _line = widget.initialLine;
    if (_line != null) {
      _initMap();
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await BusService.getLine(
        widget.schoolId,
        widget.busId,
        widget.lineId,
      );
      setState(() {
        _line = res;
        _initMap();
      });
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _initMap() {
    if (_line == null) return;
    
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    final List<LatLng> points = [];

    for (var station in _line!.stations) {
      if (station.coordinates != null && (station.coordinates!.lat != 0 || station.coordinates!.lng != 0)) {
        final pos = LatLng(station.coordinates!.lat, station.coordinates!.lng);
        points.add(pos);

        markers.add(Marker(
          markerId: MarkerId('station_${station.order}'),
          position: pos,
          infoWindow: InfoWindow(title: station.name, snippet: station.address),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            station.status == 'active' ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed, 
          ),
        ));
      }
    }

    if (points.isNotEmpty) {
      polylines.add(Polyline(
        polylineId: const PolylineId('route_line'),
        points: points,
        color: AppColors.blue1,
        width: 4,
      ));
      
      // Optionally move camera to fit bounds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mapController != null && points.isNotEmpty) {
          double minLat = points.first.latitude;
          double maxLat = points.first.latitude;
          double minLng = points.first.longitude;
          double maxLng = points.first.longitude;
          for (var p in points) {
            if (p.latitude < minLat) minLat = p.latitude;
            if (p.latitude > maxLat) maxLat = p.latitude;
            if (p.longitude < minLng) minLng = p.longitude;
            if (p.longitude > maxLng) maxLng = p.longitude;
          }
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            50,
          ));
        }
      });
    }
    
    _markers = markers;
    _polylines = polylines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(_line?.routeName ?? 'line_details'.tr, style: AppFonts.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading && _line == null
          ? const _LineShimmer()
          : _line == null
              ? Center(child: Text('no_data'.tr))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.all(20.w),
                    children: [
                      _buildHeader(),
                      if (_markers.isNotEmpty) ...[
                        SizedBox(height: 24.h),
                        Container(
                          height: 300.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20.r),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _markers.first.position,
                                zoom: 12,
                              ),
                              markers: _markers,
                              polylines: _polylines,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                _initMap(); // trigger bounds update
                              },
                              myLocationEnabled: true,
                              zoomControlsEnabled: true,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 24.h),
                      _buildTeamSection(),
                      SizedBox(height: 24.h),
                      Text(
                        'stations_progress'.tr,
                        style: AppFonts.h4.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16.h),
                      ..._line!.stations.asMap().entries.map((entry) {
                        return _buildStationItem(entry.value, entry.key == _line!.stations.length - 1);
                      }).toList(),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    final line = _line!;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
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
                child: Icon(Icons.route_rounded, color: Colors.white, size: 28.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.routeName ?? 'line_details'.tr,
                      style: AppFonts.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${line.tripType.tr} • ${line.date}',
                      style: AppFonts.bodySmall.copyWith(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(line.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.white;
    switch (status.toLowerCase()) {
      case 'active':
      case 'in_progress':
      case 'arrived':
        color = const Color(0xFF3B82F6);
        break;
      case 'completed':
      case 'departed':
        color = const Color(0xFF10B981);
        break;
      case 'cancelled':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF6B7280);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Text(
        status.tr,
        style: AppFonts.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTeamSection() {
    return Row(
      children: [
        if (_line!.driver != null)
          Expanded(child: _buildPersonChip(Icons.person_rounded, 'driver'.tr, _line!.driver!.name)),
        if (_line!.assistant != null) ...[
          SizedBox(width: 12.w),
          Expanded(child: _buildPersonChip(Icons.support_agent_rounded, 'assistant'.tr, _line!.assistant!.name)),
        ],
      ],
    );
  }

  Widget _buildPersonChip(IconData icon, String label, String name) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.blue1),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary)),
                Text(
                  name,
                  style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 13.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationItem(BusStation station, bool isLast) {
    final status = station.status.toLowerCase();
    final isArrived = status == 'arrived' || status == 'departed' || status == 'completed';
    final isDeparted = status == 'departed' || status == 'completed';
    
    Color stationColor = isDeparted 
        ? const Color(0xFF10B981) 
        : isArrived 
            ? const Color(0xFF3B82F6) 
            : const Color(0xFFD1D5DB);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: stationColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: stationColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${station.order}',
                    style: AppFonts.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    decoration: BoxDecoration(
                      color: stationColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1.r),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
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
                        Expanded(
                          child: Text(
                            station.name,
                            style: AppFonts.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildStationStatusBadge(station.status, stationColor),
                      ],
                    ),
                    if (station.address?.isNotEmpty == true) ...[
                      SizedBox(height: 4.h),
                      Text(
                        station.address!,
                        style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        _infoIconText(Icons.access_time_rounded, station.arrivalTime ?? '--:--'),
                        SizedBox(width: 16.w),
                        _infoIconText(Icons.schedule_rounded, station.departureTime ?? '--:--'),
                        SizedBox(width: 16.w),
                        _infoIconText(Icons.people_rounded, '${station.students.length}'),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        if (!isArrived)
                          Expanded(
                            child: _actionBtn(
                              label: 'arrive'.tr,
                              color: const Color(0xFF3B82F6),
                              onTap: () => _markArrived(station.order),
                            ),
                          ),
                        if (isArrived && !isDeparted)
                          Expanded(
                            child: _actionBtn(
                              label: 'depart'.tr,
                              color: const Color(0xFF10B981),
                              onTap: () => _markDeparted(station.order),
                            ),
                          ),
                        if (isArrived && !isDeparted) SizedBox(width: 10.w),
                        if (isArrived && !isDeparted)
                          Expanded(
                            child: _actionBtn(
                              label: 'attendance'.tr,
                              color: AppColors.blue1,
                              outline: true,
                              onTap: () => _openAttendance(station),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationStatusBadge(String status, Color color) {
    if (status.isEmpty) return const SizedBox();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status.tr,
        style: AppFonts.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: AppColors.textSecondary),
        SizedBox(width: 4.w),
        Text(text, style: AppFonts.labelSmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool outline = false,
  }) {
    return Material(
      color: outline ? Colors.transparent : color,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: outline ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppFonts.labelSmall.copyWith(
                color: outline ? color : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markArrived(int order) async {
    try {
      final updatedLine = await BusService.markStationArrived(
        schoolId: widget.schoolId,
        busId: widget.busId,
        lineId: widget.lineId,
        stationOrder: order,
      );
      setState(() => _line = updatedLine);
      Get.snackbar('success'.tr, 'marked_arrived'.tr,
          backgroundColor: const Color(0xFF10B981), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  Future<void> _markDeparted(int order) async {
    try {
      final updatedLine = await BusService.markStationDeparted(
        schoolId: widget.schoolId,
        busId: widget.busId,
        lineId: widget.lineId,
        stationOrder: order,
      );
      setState(() => _line = updatedLine);
      Get.snackbar('success'.tr, 'marked_departed'.tr,
          backgroundColor: const Color(0xFF10B981), colorText: Colors.white);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          backgroundColor: AppColors.error, colorText: Colors.white);
    }
  }

  void _openAttendance(BusStation station) async {
    final res = await Get.to(
      () => StationAttendancePage(
        schoolId: widget.schoolId,
        busId: widget.busId,
        lineId: widget.lineId,
        stationOrder: station.order,
        stationName: station.name,
        initialStudents: station.students,
      ),
    );
    if (res == true) {
      _load();
    }
  }
}

class _LineShimmer extends StatelessWidget {
  const _LineShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      children: [
        ShimmerLoading(
          child: Container(
            height: 120.h,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
          ),
        ),
        SizedBox(height: 24.h),
        Row(
          children: [
            Expanded(
              child: ShimmerLoading(
                child: Container(
                  height: 60.h,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: ShimmerLoading(
                child: Container(
                  height: 60.h,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 32.h),
        ...List.generate(3, (index) => Padding(
          padding: EdgeInsets.only(bottom: 24.h),
          child: ShimmerLoading(
            child: Container(
              height: 140.h,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
            ),
          ),
        )),
      ],
    );
  }
}
