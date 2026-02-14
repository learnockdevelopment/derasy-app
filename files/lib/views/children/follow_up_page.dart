import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/bus_line_models.dart';
import '../../models/student_models.dart';
import '../../models/chat_models.dart';
import '../../core/controllers/follow_up_controller.dart';
import '../../widgets/horizontal_swipe_detector.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/routes/app_routes.dart'; 


class FollowUpPage extends StatefulWidget {
  final Student child;

  const FollowUpPage({Key? key, required this.child}) : super(key: key);

  @override
  State<FollowUpPage> createState() => _FollowUpPageState();
}

class _FollowUpPageState extends State<FollowUpPage> with SingleTickerProviderStateMixin {
  late FollowUpController controller;
  late TabController _tabController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  
  // Map Controller
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};


  @override
  void initState() {
    super.initState();
    controller = Get.put(FollowUpController(child: widget.child), tag: widget.child.id);
    _tabController = TabController(length: 3, vsync: this);
    
    // Lazy load data when tab is opened
    _tabController.addListener(() {
      if (_tabController.index == 1) { // 1 is Bus tab
        controller.loadBusDataIfNeeded();
      } else if (_tabController.index == 2) { // 2 is Chat tab (was 3)
        if (controller.classTeachers.isEmpty && !controller.isLoadingTeachers.value) {
          controller.loadClassTeachers();
        }
        if (controller.activeConversation.value == null && !controller.isLoadingChat.value) {
          controller.loadChat();
        }
      }
    });
  }

  @override
  void dispose() {
    Get.delete<FollowUpController>(tag: widget.child.id);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: HorizontalSwipeDetector(
        onSwipeLeft: () {
          if (Responsive.isRTL) {
            Get.offNamed(AppRoutes.myStudents);
          } else {
            Get.offNamed(AppRoutes.applications);
          }
        },
        onSwipeRight: () {
          if (Responsive.isRTL) {
            Get.offNamed(AppRoutes.applications);
          } else {
            Get.offNamed(AppRoutes.myStudents);
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: Responsive.h(70),
              floating: false,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.blue1,
              elevation: 4,
              shadowColor: AppColors.blue1.withOpacity(0.2),
              centerTitle: false,
              title: Row(
                children: [
                   _buildSmallAvatar(),
                   SizedBox(width: Responsive.w(8)),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         'follow_up'.tr,
                         style: AppFonts.h4.copyWith(
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                           fontSize: Responsive.sp(14),
                         ),
                       ),
                       Text(
                         widget.child.arabicFullName ?? widget.child.fullName,
                         style: AppFonts.bodySmall.copyWith(
                           color: Colors.white.withOpacity(0.8),
                           fontSize: Responsive.sp(10),
                         ),
                       ),
                     ],
                   ),
                ],
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.blue1, Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.adaptive.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => Get.back(),
              ),
            ),
            SliverPadding(
              padding: Responsive.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverToBoxAdapter(
                child: _buildTabsHeader(),
              ),
            ),
            SliverFillRemaining(
              child: Padding(
                padding: Responsive.symmetric(horizontal: 16),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAttendanceTab(),
                    _buildBusTab(),
                    _buildChatTab(), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallAvatar() {
    final displayName = widget.child.arabicFullName ?? widget.child.fullName;
    return Container(
      width: Responsive.w(32),
      height: Responsive.w(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(
          displayName[0].toUpperCase(),
          style: AppFonts.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTabsHeader() {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.grey600,
        indicator: BoxDecoration(
          color: AppColors.blue1,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: AppColors.blue1.withOpacity(0.3), blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: [
          _buildCompactTab('attendance'.tr, IconlyBroken.calendar),
          _buildCompactTab('bus'.tr, Icons.directions_bus_outlined),
          _buildCompactTab('chat'.tr, IconlyBroken.chat),
        ],
      ),
    );
  }

  Widget _buildCompactTab(String label, IconData icon) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(label, style: AppFonts.labelSmall.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAttendanceTab() {
    return Obx(() {
      if (controller.isLoadingAttendance.value) {
        return _buildLoadingState();
      }
      if (controller.attendanceRecords.isEmpty) {
        return _buildEmptyState('no_attendance_records'.tr);
      }
      return ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 8),
        itemCount: controller.attendanceRecords.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.grey100),
        itemBuilder: (context, index) {
          final record = controller.attendanceRecords[index];
          return Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.blue1.withOpacity(0.05), shape: BoxShape.circle),
                  child: Icon(IconlyBroken.calendar, size: 18, color: AppColors.blue1),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.date,
                    style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                _buildStatusChip(record.status),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildBusTab() {
    return Obx(() {
      if (controller.isLoadingBus.value) {
        return _buildLoadingState();
      }
      final bus = controller.bus.value;
      if (bus == null) {
        return _buildEmptyState('no_bus_assigned'.tr);
      }
      
      final activeLine = controller.activeLine.value;
      final recentLines = controller.recentLines;
      final routes = controller.routes;

      // Initialize map if active line exists and markers not set
      if (activeLine != null && _markers.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _initMap(activeLine));
      }

      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          _buildDetailCard(IconlyBroken.info_circle, 'bus_number'.tr, bus.busNumber),
          _buildDetailCard(IconlyBroken.profile, 'driver'.tr, bus.driver?.name ?? 'n/a'.tr),
          _buildDetailCard(IconlyBroken.location, 'plate_number'.tr, bus.plateNumber ?? 'n/a'.tr),
          if (bus.gps.enabled)
             _buildDetailCard(IconlyBroken.discovery, 'gps_tracking'.tr, 'active'.tr, color: AppColors.success),
          
          if (activeLine != null) ...[
            SizedBox(height: 24),
            _buildSectionHeader('live_tracking'.tr), // Ensure translation exists or use fallback
            SizedBox(height: 12),
            _buildMapSection(),
            
            SizedBox(height: 24),
            _buildSectionHeader('bus_progress'.tr),
            SizedBox(height: 16),
            _buildModernLineProgress(activeLine),
          ],

          if (recentLines.isNotEmpty) ...[
            SizedBox(height: 24),
            _buildSectionHeader('bus_attendance_history'.tr),
            SizedBox(height: 12),
            ...recentLines.map((line) => _buildBusAttendanceItem(line)).toList(),
          ],

          if (routes.isNotEmpty) ...[
            SizedBox(height: 24),
            _buildSectionHeader('bus_routes'.tr),
            SizedBox(height: 12),
            ...routes.map((route) => _buildModernRouteItem(route)).toList(),
          ],
        ],
      );
    });
  }

  Widget _buildBusAttendanceItem(BusLine line) {
    // Find student status in this line
    String status = 'pending';
    String? time;
    
    // Check all stations for the student
    for (var station in line.stations) {
      for (var s in station.students) {
        if (s.student.id == widget.child.id) {
          status = s.attendanceStatus;
          if (s.attendanceTime != null) {
            time = _formatTime(s.attendanceTime!);
          }
        }
      }
    }

    // Default to line status if student status is pending/unknown but line is completed
    if (status == 'pending' && line.status == 'completed') {
       // status = 'completed'; // Or keep pending?
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.grey100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 6,
                color: status == 'present' ? AppColors.success : (status == 'absent' ? AppColors.error : AppColors.grey300),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              line.date.day.toString(),
                              style: AppFonts.h3.copyWith(color: AppColors.blue1, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _getMonthName(line.date.month),
                              style: AppFonts.labelSmall.copyWith(color: AppColors.blue1, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              line.routeName ?? 'trip'.tr,
                              style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            if (time != null)
                              Row(
                                children: [
                                  Icon(IconlyLight.time_circle, size: 14, color: AppColors.grey500),
                                  SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: AppFonts.bodySmall.copyWith(color: AppColors.grey500),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernRouteItem(dynamic route) {
    final map = route as Map<String, dynamic>;
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.alt_route_rounded, size: 20, color: AppColors.blue1),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  map['name'] ?? 'route'.tr,
                  style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey400),
            ],
          ),
          if (map['description'] != null) ...[
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                map['description'],
                style: AppFonts.bodySmall.copyWith(color: AppColors.grey600, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.blue1,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: AppFonts.h4.copyWith(
            fontSize: Responsive.sp(12),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildModernLineProgress(BusLine line) {
    final stations = line.stations.isNotEmpty ? line.stations : <BusStation>[];
    if (stations.isEmpty) return _buildEmptyState('no_stations_found'.tr);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(stations.length, (index) {
          final station = stations[index];
          final isLast = index == stations.length - 1;
          final status = station.status;
          final isCompleted = status == 'completed' || status == 'departed';
          final isArrived = status == 'arrived';
          final isCurrent = status == 'in_progress';
          final isNext = !isCompleted && !isArrived && !isCurrent;
          
          Color dotColor = AppColors.grey300;
          if (isCompleted) dotColor = AppColors.success;
          else if (isArrived) dotColor = AppColors.blue1;
          else if (isCurrent) dotColor = AppColors.blue1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.success : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: dotColor,
                          width: isCompleted ? 0 : 2,
                        ),
                        boxShadow: isCurrent ? [
                          BoxShadow(color: AppColors.blue1.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                        ] : null,
                      ),
                      child: isCompleted 
                        ? Icon(Icons.check, size: 12, color: Colors.white)
                        : (isCurrent || isArrived) 
                            ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.blue1, shape: BoxShape.circle)))
                            : null,
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted ? AppColors.success.withOpacity(0.5) : AppColors.grey200,
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: AppFonts.bodyMedium.copyWith(
                            fontWeight: (isCurrent || isArrived || isCompleted) ? FontWeight.bold : FontWeight.w500,
                            color: (isCurrent || isArrived) ? AppColors.blue1 : (isNext ? AppColors.grey500 : AppColors.textPrimary),
                          ),
                        ),
                        if (station.arrivalTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 12, color: AppColors.grey500),
                                SizedBox(width: 4),
                                Text(
                                  station.arrivalTime!,
                                  style: AppFonts.bodySmall.copyWith(color: AppColors.grey500),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isCurrent || isArrived)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.blue1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isArrived ? 'arrived'.tr : 'current'.tr,
                      style: AppFonts.bodySmall.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // --- Map & Location ---
  
  void _initMap(BusLine line) {
    if (line.stations.isEmpty) return;
    
    final markers = <Marker>{};
    final points = <LatLng>[];

    for (var station in line.stations) {
      if (station.coordinates != null) {
        final lat = station.coordinates!.lat;
        final lng = station.coordinates!.lng;
        if (lat != 0 && lng != 0) {
          final pos = LatLng(lat, lng);
          points.add(pos);
          
          // Map dynamic station to object manually if needed or just use properties
          final name = station.name;
          
          markers.add(Marker(
            markerId: MarkerId('s_${station.order}'),
            position: pos,
            infoWindow: InfoWindow(title: name),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              station.status == 'completed' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueBlue
            ),
          ));
        }
      }
    }

    if (points.isNotEmpty) {
      setState(() {
        _markers = markers;
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: points,
            color: AppColors.blue1,
            width: 4,
          )
        };
      });

      // Fit bounds
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if (_mapController != null) {
           _fitBounds(points);
         }
       });
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
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

  Widget _buildMapSection() {
    if (_markers.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_rounded, color: Colors.grey[400], size: 32),
              SizedBox(height: 8),
              Text('no_location_data'.tr, style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _markers.first.position,
            zoom: 14,
          ),
          markers: _markers,
          polylines: _polylines,
          onMapCreated: (mapController) {
            _mapController = mapController;
            // Delay fit bounds to ensure map is ready
            Future.delayed(Duration(milliseconds: 500), () {
               if (controller.activeLine.value != null && _markers.isNotEmpty) {
                 // Re-calculate bounds from markers
                 final points = _markers.map((m) => m.position).toList();
                 _fitBounds(points);
               }
            });
          },
          zoomControlsEnabled: true,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }




  Widget _buildChatTab() {
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Column(
      children: [
        _buildTeachersList(),
        Expanded(
          child: Obx(() {
            if (controller.isLoadingChat.value) {
              return _buildLoadingState();
            }
            if (controller.chatMessages.isEmpty && !controller.isLoadingChat.value) {
              return _buildEmptyState('no_messages'.tr);
            }
            return ListView.builder(
              controller: _chatScrollController,
              padding: EdgeInsets.symmetric(vertical: 16),
              itemCount: controller.chatMessages.length,
              itemBuilder: (context, index) {
                final message = controller.chatMessages[index];
                return _buildMessageBubble(message);
              },
            );
          }),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildTeachersList() {
    return Obx(() {
      if (controller.isLoadingTeachers.value && controller.classTeachers.isEmpty) {
        return SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
      }

      return Container(
        height: 100,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          border: Border(bottom: BorderSide(color: AppColors.grey200)),
        ),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          children: [
            // School Admin
            _buildTeacherAvatar(
              id: widget.child.schoolId.id,
              name: 'school_admin'.tr,
              role: 'school'.tr,
              isSelected: controller.selectedParticipantId.value == null || controller.selectedParticipantId.value == widget.child.schoolId.id,
            ),
            ...controller.classTeachers.map((teacher) => _buildTeacherAvatar(
              id: teacher.id,
              name: teacher.name,
              role: teacher.role.tr,
              avatar: teacher.avatar,
              isSelected: controller.selectedParticipantId.value == teacher.id,
            )).toList(),
          ],
        ),
      );
    });
  }

  Widget _buildTeacherAvatar({
    required String id,
    required String name,
    required String role,
    String? avatar,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => controller.selectParticipant(id),
      child: Container(
        width: 70,
        margin: EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isSelected ? AppColors.blue1 : AppColors.grey300,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null ? Icon(IconlyBold.user_2, color: Colors.white, size: 24) : null,
                ),
                if (isSelected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              name,
              style: AppFonts.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.blue1 : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == controller.currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: isMe ? 40 : 0, right: isMe ? 0 : 40),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.blue1 : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppFonts.bodyMedium.copyWith(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: AppFonts.bodySmall.copyWith(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour}:${time.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildChatInput() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'type_message'.tr,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.grey50,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          SizedBox(width: 8),
          Obx(() => IconButton(
            onPressed: controller.isSendingMessage.value ? null : () {
              if (_chatController.text.trim().isNotEmpty) {
                 controller.sendMessage(_chatController.text);
                 _chatController.clear();
                 // Optionally scroll to bottom
              }
            },
            icon: controller.isSendingMessage.value 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                : Icon(IconlyBold.send, color: AppColors.blue1),
          )),
        ],
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value, {Color? color}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey100),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? AppColors.blue1),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10)),
              Text(value, style: AppFonts.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String statusLabel = status.tr;
    switch (status.toLowerCase()) {
      case 'present': color = AppColors.success; break;
      case 'absent': color = AppColors.error; break;
      case 'late': color = AppColors.warning; break;
      default: color = AppColors.grey400;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        statusLabel,
        style: AppFonts.bodySmall.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1));
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.grey50, shape: BoxShape.circle),
            child: Icon(IconlyLight.document, size: 40, color: AppColors.grey300),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: AppFonts.bodySmall.copyWith(color: AppColors.grey400),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
