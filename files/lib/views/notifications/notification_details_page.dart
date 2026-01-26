import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/utils/responsive_utils.dart';
import '../../models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationDetailsPage extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailsPage({Key? key, required this.notification}) : super(key: key);

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return AppColors.blue1;
      case NotificationType.attendance:
        return AppColors.blue1;
      case NotificationType.homework:
        return AppColors.blue2;
      case NotificationType.event:
        return AppColors.blue2;
      case NotificationType.grade:
        return AppColors.blue1;
      default:
        return AppColors.blue1;
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getNotificationColor(notification.type);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'notification_details'.tr, // Make sure to add this key or use a fallback
          style: AppFonts.h3.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: Responsive.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.r(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: Responsive.w(64),
                    height: Responsive.w(64),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: primaryColor,
                      size: Responsive.sp(32),
                    ),
                  ),
                  SizedBox(height: Responsive.h(16)),
                  Text(
                    notification.title,
                    style: AppFonts.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: Responsive.h(8)),
                  Text(
                     DateFormat('MMMM d, y • h:mm a').format(notification.createdAt),
                    style: AppFonts.bodySmall.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: Responsive.h(24)),
            
            // Content Card
            Container(
              width: double.infinity,
              padding: Responsive.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Responsive.r(16)),
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
                  Text(
                    'details'.tr,
                    style: AppFonts.h4.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.h(16)),
                  Text(
                    notification.message,
                    style: AppFonts.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                      fontSize: Responsive.sp(16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
