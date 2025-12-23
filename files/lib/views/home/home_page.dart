import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/student_models.dart';
import '../../services/students_service.dart';
import '../../services/user_storage_service.dart';
import '../chatbot/chatbot_page.dart';
import 'package:iconly/iconly.dart';
import '../profile/user_profile_page.dart';
import '../../widgets/safe_network_image.dart';
import '../../services/user_profile_service.dart';
import '../../widgets/shimmer_loading.dart';
import '../../core/routes/app_routes.dart';
import '../bus/buses_page.dart';
import '../store/products/store_products_page.dart';
import '../../widgets/top_app_bar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Student> _children = [];
  Map<String, List<Student>> _childrenBySchool = {};
  Map<String, dynamic>? _userData;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isChatbotVisible = false;
  Offset? _chatbotOffset;
  Offset? _launcherOffset;
  double? _cachedBottomGuard;

  // Match the embedded chatbot dimensions so we can clamp dragging correctly.
  double get _chatbotPanelWidth => (360.w).clamp(280.0, 420.0).toDouble();
  double get _chatbotPanelHeight => (520.h).clamp(420.0, 640.0).toDouble();

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final size = MediaQuery.of(context).size;
        final guard = _bottomGuard(context);
        _cachedBottomGuard = guard;
        setState(() {
          _chatbotOffset = _defaultChatbotOffset(size, guard);
          _launcherOffset = _defaultLauncherOffset(size, guard);
        });
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user data
      final userData = await UserStorageService.getUserData();
      // Debug prints
      print('🏠 [HOME] ===========================================');
      print('🏠 [HOME] FULL USER DATA FROM STORAGE:');
      print('🏠 [HOME] ${userData?.toString() ?? 'null'}');
      print('🏠 [HOME] ===========================================');

      setState(() {
        _userData = userData;
      });

      // Ensure avatar is available: if missing, try fetching from API once
      await _ensureUserAvatarLoaded();

      // Load children
      await _loadChildren();
    } catch (e) {
      // Only show error if no cached data was returned
      if (e.toString().contains('Server error') || e.toString().contains('500')) {
        Get.snackbar(
          'error'.tr,
          'server_error_try_again'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'error'.tr,
          'network_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChildren() async {
    try {
      final response = await StudentsService.getRelatedChildren();
      if (response.success) {
        // Get current user ID to filter only parent's children
        final currentUser = UserStorageService.getCurrentUser();
        if (currentUser == null) {
          print('🏠 [HOME] No current user found');
          setState(() {
            _children = [];
          });
          return;
        }

        // Get user ID (may be in 'id' or '_id' format)
        final currentUserId = currentUser.id;
        final userJson = currentUser.toJson();
        final currentUserIdAlt = userJson['_id']?.toString() ?? currentUserId;

        if (currentUserId.isEmpty && currentUserIdAlt.isEmpty) {
          print('🏠 [HOME] No current user ID found');
          setState(() {
            _children = [];
          });
          return;
        }

        // Filter children to show only those where current user is the parent (not guardian)
        final filteredChildren = response.students.where((child) {
          final parentId = child.parent.id;
          // Check both id formats to ensure matching
          return parentId == currentUserId || parentId == currentUserIdAlt;
        }).toList();

        print('🏠 [HOME] Total children: ${response.students.length}, Parent children: ${filteredChildren.length}');
        print('🏠 [HOME] Current user ID: $currentUserId / $currentUserIdAlt');
        
        // Group children by school (including those without schools)
        final Map<String, List<Student>> groupedBySchool = {};
        for (var child in filteredChildren) {
          final schoolName = child.schoolId.name.isNotEmpty 
              ? child.schoolId.name 
              : 'No School';
          if (!groupedBySchool.containsKey(schoolName)) {
            groupedBySchool[schoolName] = [];
          }
          groupedBySchool[schoolName]!.add(child);
        }
        
        setState(() {
          _children = filteredChildren;
          _childrenBySchool = groupedBySchool;
        });
      }
    } catch (e) {
      // If error getting children, just show empty list
      print('🏠 [HOME] Error loading children: $e');
      setState(() {
        _children = [];
      });
    }
  }


  Future<void> _refreshData() async {
    // Refresh children data
    await _loadChildren();
    
    // Also refresh user avatar if needed
    await _ensureUserAvatarLoaded();
  }

  void _navigateToAddChild() async {
    final result = await Get.toNamed(AppRoutes.addChild);
    if (result == true) {
      // Refresh children list after adding
      await _loadChildren();
    }
  }

  Future<void> _ensureUserAvatarLoaded() async {
    try {
      final currentAvatar = _userData?['avatar'] ?? _userData?['profileImage'] ?? _userData?['image'];
      final hasValidAvatar = currentAvatar != null && 
          currentAvatar is String && 
          currentAvatar.trim().isNotEmpty &&
          currentAvatar.trim().toLowerCase() != 'null';
      
      if (!hasValidAvatar) {
        final profile = await UserProfileService.getCurrentUserProfile();
        // Handle nested user data structure
        Map<String, dynamic> userDataFromApi = profile;
        if (profile.containsKey('user') && profile['user'] is Map<String, dynamic>) {
          userDataFromApi = profile['user'] as Map<String, dynamic>;
        }
        
        if (mounted) {
          setState(() {
            _userData = {
              ...?_userData,
              'avatar': userDataFromApi['avatar'] ?? _userData?['avatar'],
              'profileImage': userDataFromApi['profileImage'] ?? _userData?['profileImage'],
              'image': userDataFromApi['image'] ?? _userData?['image'],
              'name': userDataFromApi['name'] ?? _userData?['name'],
              'email': userDataFromApi['email'] ?? _userData?['email'],
            };
          });
        }
      }
    } catch (e) {
      // Silent: fall back to placeholder
      debugPrint('🏠 [HOME] Unable to fetch avatar from API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeContent(),
              _buildBusesContent(),
              _buildStoreContent(),
              _buildProfileContent(),
            ],
          ),
          if (_currentIndex == 0 && _isChatbotVisible && _chatbotOffset != null)
            Builder(
              builder: (builderContext) => _buildDraggableChatbot(builderContext),
            ),
          if (_currentIndex == 0 && !_isChatbotVisible && _launcherOffset != null)
            _buildChatbotLauncher(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(), 
    );
  }

  Widget _buildDraggableChatbot(BuildContext context) {
    // Use cached bottom guard if available, otherwise calculate it
    final screenSize = MediaQuery.of(context).size;
    final guard = _cachedBottomGuard ?? _bottomGuard(context);
    final offset = _chatbotOffset ?? _defaultChatbotOffset(screenSize, guard);

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _chatbotOffset = _clampOffset(
              (_chatbotOffset ?? offset) + details.delta,
              screenSize,
              guard,
            );
          });
        },
        child: ChatbotPage(
          embedded: true,
          onClose: () {
            setState(() {
              _isChatbotVisible = false;
            });
          },
        ),
      ),
    );
  }

  Widget _buildChatbotLauncher() {
    return Builder(
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final guard = _cachedBottomGuard ?? _bottomGuard(context);
        final offset = _launcherOffset ?? _defaultLauncherOffset(screenSize, guard);

        return Positioned(
          left: offset.dx,
          top: offset.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _launcherOffset = _clampLauncherOffset(
                  (_launcherOffset ?? offset) + details.delta,
                  screenSize,
                  guard,
                );
              });
            }, 
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isChatbotVisible = true;
                  _chatbotOffset ??= _defaultChatbotOffset( 
                    screenSize,
                    guard,
                  );
                });
              },
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.support_agent_rounded, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Offset _defaultChatbotOffset(Size screenSize, double bottomGuard) {
    final dx = screenSize.width - _chatbotPanelWidth - 16.w;
    final dy = screenSize.height - _chatbotPanelHeight - 120.h;
    return Offset(
      dx.clamp(12.0, screenSize.width - _chatbotPanelWidth - 12.0),
      dy.clamp(12.0, screenSize.height - _chatbotPanelHeight - bottomGuard),
    );
  }

  Offset _defaultLauncherOffset(Size screenSize, double bottomGuard) {
    final dx = screenSize.width - 72.w;
    // keep above navbar/safe-area with a buffer
    final dy = screenSize.height - 110.h - bottomGuard * 0.2;
    return Offset(
      dx.clamp(12.0, screenSize.width - 56.0),
      dy.clamp(12.0, screenSize.height - bottomGuard),
    );
  }

  Offset _clampLauncherOffset(Offset candidate, Size screenSize, double bottomGuard) {
    const buttonSize = 56.0;
    final minX = 8.0;
    final minY = 8.0;
    final maxX = screenSize.width - buttonSize - 8.0;
    final maxY = screenSize.height - buttonSize - bottomGuard;
    return Offset(
      candidate.dx.clamp(minX, maxX),
      candidate.dy.clamp(minY, maxY),
    );
  }

  Offset _clampOffset(Offset candidate, Size screenSize, double bottomGuard) {
    final minX = 12.0;
    final minY = 12.0;
    final maxX = screenSize.width - _chatbotPanelWidth - 12.0;
    final maxY = screenSize.height - _chatbotPanelHeight - bottomGuard;
    return Offset(
      candidate.dx.clamp(minX, maxX),
      candidate.dy.clamp(minY, maxY),
    );
  }

  double _bottomGuard(BuildContext context) {
    final padding = MediaQuery.of(context).padding.bottom;
    // Keep overlay above nav bar + give small gap
    return padding + kBottomNavigationBarHeight + 12.h;
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return _buildShimmerLoading();  
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primaryBlue,
      child: CustomScrollView(
      slivers: [
        // Top App Bar Widget
        TopAppBarWidget(
          userData: _userData,
          showLoading: false,
        ), 
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        // Welcome Section
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: _buildWelcomeSection(),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 12.h)),
        // Children Section - Grouped by School
        if (_children.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildChildrenBySchoolSection(),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: _buildEmptyChildrenState(),
            ),
          ),
        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
      ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
        // Top App Bar Widget with loading state
        TopAppBarWidget(
          userData: null,
          showLoading: true,
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16.h)),
        // Welcome Section Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ShimmerLoading(
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.grey200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16.h,
                            width: 120.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 14.h,
                            width: 100.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 12.h)),
        // Children Section Header Shimmer
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: ShimmerLoading(
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16.h,
                            width: 100.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Container(
                            height: 12.h,
                            width: 80.w,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 60.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 8.h)),
        // Children Cards Shimmer
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ShimmerCard(
                  height: 120.h,
                  borderRadius: 16.r,
                ),
              ),
              childCount: 3, // Show 3 shimmer cards
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 20.h)),
      ],
    );
  }

  Widget _buildBusesContent() {
    return const BusesPage();
  }

  Widget _buildStoreContent() {
    return const StoreProductsPage();
  }

  Widget _buildProfileContent() {
    return const UserProfilePage();
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'good_morning'.tr;
    } else if (hour < 17) {
      greeting = 'good_afternoon'.tr;
    } else {
      greeting = 'good_evening'.tr;
    }

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.primaryGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              hour < 12 
                ? Icons.wb_sunny_rounded 
                : hour < 17 
                  ? Icons.wb_twilight_rounded 
                  : Icons.nightlight_round,
              color: AppColors.primaryBlue,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppFonts.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _userData?['name'] ??  'user'.tr,
                  style: AppFonts.bodyMedium.copyWith( 
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildrenBySchoolSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(0.15),
                    AppColors.primaryBlue.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.family_restroom_rounded,
                color: AppColors.primaryBlue,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'my_children'.tr,
                    style: AppFonts.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${_children.length} ${_children.length == 1 ? 'child'.tr : 'children'.tr}',
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            // Add Child Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _navigateToAddChild(),
                borderRadius: BorderRadius.circular(10.r),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue,
                        AppColors.primaryBlue.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ), 
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'add'.tr,
                        style: AppFonts.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // School Groups
        ..._childrenBySchool.entries.map((entry) {
          final schoolName = entry.key;
          final children = entry.value;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // School Header
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: AppColors.primaryBlue,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        schoolName,
                        style: AppFonts.h4.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                    Text(
                      '${children.length} ${children.length == 1 ? 'child'.tr : 'children'.tr}',
                      style: AppFonts.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              // Children in this school
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: children.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final child = children[index];
                  final imageUrl = child.avatar ?? child.profileImage ?? child.image;
                  final gradientColors = _getChildCardGradient(index);
                  
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Get.toNamed(AppRoutes.childDetails, arguments: {'child': child});
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors[0].withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(14.w),
                          child: Row(
                            children: [
                              // Enhanced Avatar with border
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: SizedBox(
                                    width: 54.w,
                                    height: 54.h,
                                    child: SafeAvatarImage(
                                      imageUrl: imageUrl?.isNotEmpty == true ? imageUrl : null,
                                      size: 54,
                                      backgroundColor: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              // Child Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child.fullName,
                                      style: AppFonts.h4.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.sp,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.1),
                                            offset: const Offset(0, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6.h),
                                    if (child.studentClass.name.isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.25),
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.class_rounded,
                                              color: Colors.white,
                                              size: 12.sp,
                                            ),
                                            SizedBox(width: 4.w),
                                            Text(
                                              child.studentClass.name,
                                              style: AppFonts.bodySmall.copyWith(
                                                color: Colors.white,
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Arrow Icon
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20.h),
            ],
          );
        }).toList(),
      ],
    );
  }


  List<Color> _getChildCardGradient(int index) {
    final gradients = [
      [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.8)],
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
    ];
    return gradients[index % gradients.length];
  }

  Widget _buildEmptyChildrenState() {
    return Container(
      padding: EdgeInsets.all(30.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.grey200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.child_care_outlined,
              color: AppColors.primaryBlue,
              size: 36.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'no_children_found'.tr,
            style: AppFonts.h4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'no_children_found_message'.tr,
            style: AppFonts.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'home'.tr,
                index: 0,
              ),
              _buildNavItem(
                icon: IconlyBold.discovery,
                label: 'buses'.tr,
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.shopping_bag_rounded,
                label: 'store'.tr,
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'profile'.tr,
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryBlue
                  : const Color(0xFF9CA3AF),
              size: AppFonts.size20,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppFonts.labelSmall.copyWith(
                color: isSelected
                    ? AppColors.primaryBlue
                    : const Color(0xFF9CA3AF),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: AppFonts.size12,
              ),
            ),
          ],
        ),
      ),
    );
  }



}
