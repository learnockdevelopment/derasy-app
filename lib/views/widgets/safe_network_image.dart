import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if URL is valid and not a placeholder
    if (imageUrl == null || 
        imageUrl!.trim().isEmpty || 
        imageUrl!.contains('example.com') ||
        imageUrl!.contains('placeholder')) {
      return _buildFallback();
    }

    // If this is a local asset path, render as asset image
    if (imageUrl!.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.asset(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Asset image load error for path: $imageUrl - ${error.toString()}');
            return _buildFallback();
          },
        ),
      );
    }

    // Only load http/https URLs; otherwise fallback
    final lower = imageUrl!.toLowerCase();
    final isHttp = lower.startsWith('http://') || lower.startsWith('https://');
    if (!isHttp) {
      return _buildFallback();
    }

    // Avoid attempting to decode unsupported formats (e.g., svg)
    if (lower.endsWith('.svg')) {
      return _buildFallback();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        filterQuality: FilterQuality.low,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image load error for URL: $imageUrl - ${error.toString()}');
          return _buildFallback();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        headers: const {
          'Cache-Control': 'max-age=3600',
        },
      ),
    );
  }

  Widget _buildFallback() {
    if (errorWidget != null) return errorWidget!;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFE5E7EB),
        borderRadius: borderRadius,
      ),
      child: const Icon(
        Icons.image_not_supported_rounded,
        color: Color(0xFF9CA3AF),
        size: 24,
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFF3F4F6),
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
          ),
        ),
      ),
    );
  }
}

// Specialized widgets for common use cases
class SafeAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  const SafeAvatarImage({
    Key? key,
    required this.imageUrl,
    this.size = 50,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeNetworkImage(
      imageUrl: imageUrl,
      width: size.w,
      height: size.h,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size.w / 2),
      backgroundColor: backgroundColor,
      errorWidget: Container(
        width: size.w,
        height: size.h,
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xFF1E3A8A),
          borderRadius: BorderRadius.circular(size.w / 2),
        ),
        child: Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: (size * 0.5).sp,
        ),
      ),
    );
  }
}

class SafeSchoolImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SafeSchoolImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.fill,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorWidget: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(
          Icons.school_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}
