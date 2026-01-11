import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    Key? key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFFE5E7EB),
      highlightColor: highlightColor ?? const Color(0xFFF3F4F6),
      child: child,
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;
  final EdgeInsets? margin;

  const ShimmerCard({
    Key? key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? Responsive.h(100),
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius ?? Responsive.r(12)),
      ),
      child: ShimmerLoading(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(borderRadius ?? Responsive.r(12)),
          ),
        ),
      ),
    );
  }
}

class ShimmerListTile extends StatelessWidget {
  final bool hasAvatar;
  final bool hasSubtitle;
  final EdgeInsets? padding;

  const ShimmerListTile({
    Key? key,
    this.hasAvatar = true,
    this.hasSubtitle = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? Responsive.all(16),
      child: Row(
        children: [
          if (hasAvatar) ...[
            ShimmerLoading(
              child: Container(
                width: Responsive.w(50),
                height: Responsive.h(50),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Responsive.r(25)),
                ),
              ),
            ),
            SizedBox(width: Responsive.w(12)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading(
                  child: Container(
                    height: Responsive.h(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(Responsive.r(8)),
                    ),
                  ),
                ),
                if (hasSubtitle) ...[
                  SizedBox(height: Responsive.h(8)),
                  ShimmerLoading(
                    child: Container(
                      height: Responsive.h(12),
                      width: Responsive.w(200),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(Responsive.r(6)),
                      ),
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
}

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const ShimmerGrid({
    Key? key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio ?? 1.2,
        crossAxisSpacing: crossAxisSpacing ?? Responsive.w(12),
        mainAxisSpacing: mainAxisSpacing ?? Responsive.h(12),
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerCard(
          borderRadius: Responsive.r(16),
        );
      },
    );
  }
}

class ShimmerActionGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerActionGrid({
    Key? key,
    this.itemCount = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: Responsive.w(12),
        mainAxisSpacing: Responsive.h(12),
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoading(
          child: Container(
            padding: Responsive.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Responsive.r(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: Responsive.w(48),
                  height: Responsive.h(48),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                  ),
                ),
                SizedBox(height: Responsive.h(12)),
                Container(
                  height: Responsive.h(14),
                  width: Responsive.w(80),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(Responsive.r(7)),
                  ),
                ),
                SizedBox(height: Responsive.h(4)),
                Container(
                  height: Responsive.h(11),
                  width: Responsive.w(60),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(Responsive.r(5)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
