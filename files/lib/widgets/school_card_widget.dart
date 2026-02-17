import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';

class SchoolCardData {
  final String label;
  final String value;
  final IconData icon;

  const SchoolCardData(this.label, this.value, this.icon);
}

class SchoolCardWidget extends StatelessWidget {
  final String name;
  final String? coverUrl;
  final String? logoUrl;
  final String type;
  final VoidCallback? onTap;

  // Status/Badges
  final Widget? statusBadge;
  final bool isSelected;
  final bool isAISuggested;

  // Data Grid
  final List<SchoolCardData> dataItems;

  const SchoolCardWidget({
    Key? key,
    required this.name,
    this.coverUrl,
    this.logoUrl,
    required this.type,
    this.onTap,
    this.statusBadge,
    this.isSelected = false,
    this.isAISuggested = false,
    this.dataItems = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: AppColors.blue1, width: 2)
              : isAISuggested
                  ? Border.all(color: AppColors.blue1.withOpacity(0.5), width: 1.5)
                  : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.blue1.withOpacity(0.15)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Header Section
            _buildHeader(),

            // 2. Info Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppFonts.AlmaraiBold20.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(IconlyLight.category,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        type,
                        style: AppFonts.AlmaraiMedium14.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  
                  if (dataItems.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    // 3. Data Grid
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.grey50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.grey100),
                      ),
                      child: Row(
                        children: _buildDataGrid(),
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
  }

  Widget _buildHeader() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        color: AppColors.blue1.withOpacity(0.05),
        image: coverUrl != null
            ? DecorationImage(
                image: NetworkImage(coverUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Logic: If no cover, show pattern/gradient
          if (coverUrl == null)
            Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.blue1.withOpacity(0.1),
                    AppColors.purple100.withOpacity(0.3),
                  ],
                ),
              ),
            ),

          // Logo Overlay
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: logoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(logoUrl!),
                        fit: BoxFit.contain,
                      )
                    : null,
              ),
              child: logoUrl == null
                  ? Icon(IconlyBold.image, color: AppColors.grey300, size: 30)
                  : null,
            ),
          ),

          // Status Badge / Custom Badge (Top Right)
          if (statusBadge != null)
            Positioned(
              top: 20,
              right: 20,
              child: statusBadge!,
            ),
            
          // AI Suggested Badge
          if (isAISuggested && statusBadge == null)
             Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.blue1,
                        AppColors.blue1.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'AI Recommended',
                        style: AppFonts.AlmaraiBold12.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
             ),

          // Selection Checkmark
          if (isSelected)
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blue1,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 4),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildDataGrid() {
    List<Widget> widgets = [];
    for (int i = 0; i < dataItems.length; i++) {
      widgets.add(Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(dataItems[i].icon, size: 12, color: AppColors.grey400),
                const SizedBox(width: 4),
                Text(
                  dataItems[i].label,
                  style: AppFonts.AlmaraiRegular10.copyWith(
                      color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dataItems[i].value,
              style: AppFonts.AlmaraiBold14.copyWith(
                  color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ));
      
      // Add divider if not last item
      if (i < dataItems.length - 1) {
        widgets.add(Container(
          width: 1,
          height: 24,
          color: AppColors.grey200,
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ));
      }
    }
    return widgets;
  }
}
