import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fullName;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({
    Key? key,
    this.imageUrl,
    required this.fullName,
    this.size = 50,
    this.onTap,
  }) : super(key: key);

  String get _initials {
    if (fullName.isEmpty) return 'U';

    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    } else {
      return '${names[0].substring(0, 1)}${names[1].substring(0, 1)}'
          .toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size.w,
        height: size.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryBlue,
          border: Border.all(
            color: AppColors.grey300,
            width: 1,
          ),
        ),
        child: imageUrl != null &&
                imageUrl!.isNotEmpty &&
                imageUrl!.trim().isNotEmpty
            ? ClipOval(
                child: Image.network(
                  imageUrl!,
                  width: size.w,
                  height: size.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildInitials(),
                ),
              )
            : _buildInitials(),
      ),
    );
  }

  Widget _buildInitials() {
    return Center(
      child: Text(
        _initials,
        style: AppFonts.AlmaraiBold16.copyWith(
          color: Colors.white,
          fontSize: (size * 0.4).sp,
        ),
      ),
    );
  }
}
