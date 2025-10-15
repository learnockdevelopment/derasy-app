// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:get/get.dart';
// import '../../core/constants/app_colors.dart';
// import '../../core/constants/app_fonts.dart';
// import '../../core/constants/assets.dart';
// import '../../core/routes/app_routes.dart';
// import '../../models/user_model.dart';
// import '../../services/user_storage_service.dart';

// class AccountSwitchingPage extends StatefulWidget {
//   const AccountSwitchingPage({Key? key}) : super(key: key);

//   @override
//   State<AccountSwitchingPage> createState() => _AccountSwitchingPageState();
// }

// class _AccountSwitchingPageState extends State<AccountSwitchingPage> {
//   List<UserModel> _savedUsers = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadSavedUsers();
//   }

//   void _loadSavedUsers() {
//     setState(() {
//       _savedUsers = UserStorageService.getSavedUsers();
//       _isLoading = false;
//     });
//   }

//   Future<void> _switchToAccount(UserModel user) async {
//     Get.toNamed(AppRoutes.loginPin, arguments: {
//       'identifier': user.email,
//       'isAccountSwitch': true,
//       'user': user,
//     });
//   }

//   Future<void> _addNewAccount() async {
//     Get.offNamed(AppRoutes.login);
//   }

//   Future<void> _removeAccount(UserModel user) async {
//     await UserStorageService.removeSavedUser(user.email);
//     _loadSavedUsers();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.all(24.w),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               SizedBox(height: 20.h),

//               // Header
//               Row(
//                 children: [
//                   Image.asset(
//                     AssetsManager.logo,
//                     width: 40.w,
//                     height: 40.h,
//                   ),
//                   SizedBox(width: 12.w),
//                   Text(
//                     'arkan_shares'.tr,
//                     style: AppFonts.robotoBold18.copyWith(
//                       color: AppColors.textPrimary,
//                     ),
//                   ),
//                 ],
//               ),

//               SizedBox(height: 40.h),

//               // Title
//               Text(
//                 'account_switching'.tr,
//                 style: AppFonts.robotoBold24.copyWith(
//                   color: AppColors.textPrimary,
//                 ),
//               ),

//               SizedBox(height: 8.h),

//               Text(
//                 'select_account'.tr,
//                 style: AppFonts.robotoRegular14.copyWith(
//                   color: AppColors.textSecondary,
//                 ),
//               ),

//               SizedBox(height: 4.h),

//               // Click instruction label
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
//                 decoration: BoxDecoration(
//                   color: AppColors.primary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(20.r),
//                   border: Border.all(
//                     color: AppColors.primary.withOpacity(0.3),
//                     width: 1,
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       Icons.touch_app,
//                       size: 16.w,
//                       color: AppColors.primary,
//                     ),
//                     SizedBox(width: 6.w),
//                     Text(
//                       'click_account_to_login'.tr,
//                       style: AppFonts.robotoMedium12.copyWith(
//                         color: AppColors.primary,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               SizedBox(height: 32.h),

//               // Saved Accounts List
//               Expanded(
//                 child: _isLoading
//                     ? Center(
//                         child: CircularProgressIndicator(
//                           color: AppColors.primary,
//                         ),
//                       )
//                     : _savedUsers.isEmpty
//                         ? _buildNoAccounts()
//                         : _buildAccountsList(),
//               ),

//               // Add New Account Button
//               Container(
//                 width: double.infinity,
//                 height: 56.h,
//                 decoration: BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       AppColors.primary,
//                       AppColors.primary.withOpacity(0.8)
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(28.r),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.primary.withOpacity(0.3),
//                       blurRadius: 12,
//                       offset: Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Material(
//                   color: Colors.transparent,
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(28.r),
//                     onTap: _addNewAccount,
//                     child: Center(
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.add_circle_outline,
//                             color: Colors.white,
//                             size: 20.w,
//                           ),
//                           SizedBox(width: 8.w),
//                           Text(
//                             'add_new_account'.tr,
//                             style: AppFonts.robotoBold16.copyWith(
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildNoAccounts() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 120.w,
//             height: 120.h,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(60.r),
//             ),
//             child: Icon(
//               Icons.person_outline,
//               size: 60.w,
//               color: AppColors.primary,
//             ),
//           ),
//           SizedBox(height: 32.h),
//           Text(
//             'no_saved_accounts'.tr,
//             style: AppFonts.robotoBold18.copyWith(
//               color: AppColors.textPrimary,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           SizedBox(height: 8.h),
//           Text(
//             'click_account_to_login'.tr,
//             style: AppFonts.robotoRegular14.copyWith(
//               color: AppColors.textSecondary,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAccountsList() {
//     return ListView.builder(
//       itemCount: _savedUsers.length,
//       itemBuilder: (context, index) {
//         final user = _savedUsers[index];
//         return Container(
//           margin: EdgeInsets.only(bottom: 16.h),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16.r),
//             border: Border.all(
//               color: AppColors.grey200,
//               width: 1,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 10,
//                 offset: Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               borderRadius: BorderRadius.circular(16.r),
//               onTap: () => _switchToAccount(user),
//               child: Container(
//                 padding: EdgeInsets.all(10.w),
//                 child: Row(
//                   children: [
//                     // Avatar
//                     Container(
//                       width: 50.w,
//                       height: 50.h,
//                       decoration: BoxDecoration(
//                         color: AppColors.primary,
//                         borderRadius: BorderRadius.circular(25.r),
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.primary.withOpacity(0.3),
//                             blurRadius: 8,
//                             offset: Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: Center(
//                         child: Text(
//                           user.firstName.isNotEmpty
//                               ? user.firstName[0].toUpperCase()
//                               : 'U',
//                           style: AppFonts.robotoBold18.copyWith(
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),

//                     SizedBox(width: 10.w),

//                     // User Info
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             user.fullName,
//                             style: AppFonts.robotoBold16.copyWith(
//                               color: AppColors.textPrimary,
//                             ),
//                           ),
//                           SizedBox(height: 4.h),
//                           Text(
//                             user.email,
//                             style: AppFonts.robotoRegular14.copyWith(
//                               color: AppColors.textSecondary,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     // Action Buttons
//                     Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Login Arrow
//                         Container(
//                           padding: EdgeInsets.all(8.w),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(8.r),
//                           ),
//                           child: Icon(
//                             Icons.arrow_forward_ios,
//                             color: AppColors.primary,
//                             size: 16.w,
//                           ),
//                         ),

//                         SizedBox(width: 8.w),

//                         // Delete Button
//                         GestureDetector(
//                           onTap: () => _removeAccount(user),
//                           child: Container(
//                             padding: EdgeInsets.all(8.w),
//                             decoration: BoxDecoration(
//                               color: AppColors.error.withOpacity(0.1),
//                               borderRadius: BorderRadius.circular(8.r),
//                             ),
//                             child: Icon(
//                               Icons.delete_outline,
//                               color: AppColors.error,
//                               size: 18.w,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
