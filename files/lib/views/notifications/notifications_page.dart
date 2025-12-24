import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/routes/app_routes.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = false;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Replace with actual API call when notification service is available
    // Simulated delay
    await Future.delayed(Duration(milliseconds: 500));

    // Mock notifications data
    setState(() {
      _notifications = [
        NotificationItem(
          id: '1',
          title: 'New Message',
          message: 'You have a new message from the school',
          type: NotificationType.message,
          isRead: false,
          createdAt: DateTime.now().subtract(Duration(minutes: 5)),
        ),
        NotificationItem(
          id: '2',
          title: 'Attendance Update',
          message: 'Your child\'s attendance has been updated',
          type: NotificationType.attendance,
          isRead: false,
          createdAt: DateTime.now().subtract(Duration(hours: 2)),
        ),
        NotificationItem(
          id: '3',
          title: 'Homework Reminder',
          message: 'New homework assignment is due tomorrow',
          type: NotificationType.homework,
          isRead: true,
          createdAt: DateTime.now().subtract(Duration(days: 1)),
        ),
        NotificationItem(
          id: '4',
          title: 'Event Announcement',
          message: 'School event scheduled for next week',
          type: NotificationType.event,
          isRead: true,
          createdAt: DateTime.now().subtract(Duration(days: 2)),
        ),
        NotificationItem(
          id: '5',
          title: 'Grade Update',
          message: 'New grades have been posted',
          type: NotificationType.grade,
          isRead: true,
          createdAt: DateTime.now().subtract(Duration(days: 3)),
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });

    // TODO: Call API to mark notification as read
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });

    // TODO: Call API to mark all notifications as read
  }

  Future<void> _deleteNotification(String notificationId) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });

    // TODO: Call API to delete notification
    Get.snackbar(
      'success'.tr,
      'notification_deleted'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just_now'.tr;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return IconlyBroken.message;
      case NotificationType.attendance:
        return IconlyBroken.calendar;
      case NotificationType.homework:
        return IconlyBroken.document;
      case NotificationType.event:
        return IconlyBroken.notification;
      case NotificationType.grade:
        return IconlyBroken.star;
      default:
        return IconlyBroken.notification;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return AppColors.primaryBlue;
      case NotificationType.attendance:
        return AppColors.primaryGreen;
      case NotificationType.homework:
        return AppColors.primaryYellow;
      case NotificationType.event:
        return AppColors.primaryPurple;
      case NotificationType.grade:
        return AppColors.primaryRed;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'notifications'.tr,
          style: AppFonts.h3.copyWith(
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: Text(
                'mark_all_read'.tr,
                style: AppFonts.AlmaraiBlack18.copyWith(
                  color: AppColors.white,
                  fontSize: 14.sp,
                ),
              ),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
              ),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppColors.primaryBlue,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            IconlyBroken.notification,
            size: 80.sp,
            color: AppColors.grey400,
          ),
          SizedBox(height: 24.h),
          Text(
            'no_new_notifications'.tr,
            style: AppFonts.h3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'no_notifications_description'.tr,
            style: AppFonts.AlmaraiBlack18.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    final iconColor = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          IconlyBroken.delete,
          color: AppColors.white,
          size: 24.sp,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _markAsRead(notification.id);
          }
          // TODO: Navigate to notification details if needed
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: notification.isRead ? AppColors.white : AppColors.blue50,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.borderLight
                  : AppColors.primaryBlue.withOpacity(0.3),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppFonts.h4.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notification.message,
                      style: AppFonts.AlmaraiBlack18.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _formatDateTime(notification.createdAt),
                      style: AppFonts.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum NotificationType {
  message,
  attendance,
  homework,
  event,
  grade,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

