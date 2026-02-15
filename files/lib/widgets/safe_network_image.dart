import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/constants/assets.dart';

class SafeNetworkImage extends StatefulWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final String? fallbackAsset;
  final Map<String, String>? headers;

  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.headers,
    this.fallbackAsset,
  }) : super(key: key);

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Reset error state when imageUrl changes
    _hasError = false;
  }

  @override
  void didUpdateWidget(SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state if imageUrl changed
    if (oldWidget.imageUrl != widget.imageUrl) {
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If error occurred, show error widget
    if (_hasError) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    // If no URL provided or empty, show error widget immediately
    if (widget.imageUrl == null || widget.imageUrl!.trim().isEmpty) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    final trimmedUrl = widget.imageUrl!.trim();

    // Check for invalid URL strings
    final lowerUrl = trimmedUrl.toLowerCase();
    if (lowerUrl == 'null' || lowerUrl == 'undefined' || lowerUrl == 'none' || lowerUrl == 'n/a') {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    // If URL is invalid (not http/https), show error widget
    if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    // Check if it's an SVG
    final isSvg = trimmedUrl.toLowerCase().split('?').first.endsWith('.svg');
    if (isSvg) {
      return SvgPicture.network(
        trimmedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholderBuilder: (context) => widget.placeholder ?? _buildPlaceholder(),
        errorBuilder: (context, error, stackTrace) => widget.errorWidget ?? _buildErrorWidget(),
      );
    }

    // Use browser User-Agent to avoid blocks
    final Map<String, String> mergedHeaders = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      if (widget.headers != null) ...widget.headers!,
    };

    // Wrap Image.network in error boundary to catch all exceptions
    Widget imageWidget;
    try {
      imageWidget = Image.network(
        trimmedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        headers: mergedHeaders,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            // Image finished loading successfully
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = false; // Clear any previous error state
                });
              }
            });
            return child;
          }
          // Still loading - show placeholder
          return widget.placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          // Only mark as error if we actually get an error callback
          // This handles 404, network errors, invalid image data, etc.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasError) {
              setState(() {
                _hasError = true;
              });
            }
          });
          // Return error widget immediately to prevent invalid image data errors
          return widget.errorWidget ?? _buildErrorWidget();
        },
      );
    } catch (e) {
      // Only catch synchronous exceptions during widget creation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasError) {
          setState(() {
            _hasError = true;
          });
        }
      });
      return widget.errorWidget ?? _buildErrorWidget();
    }

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.fallbackAsset != null) {
      return Container(
        width: widget.width,
        height: widget.height,
        child: Image.asset(
          widget.fallbackAsset!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (context, error, stackTrace) => _buildDefaultErrorWidget(),
        ),
      );
    }
    return _buildDefaultErrorWidget();
  }

  Widget _buildDefaultErrorWidget() {
    // Calculate icon size safely - ensure it's finite and valid
    double iconSize = 24.0; // Default size
    if (widget.width != null && 
        widget.height != null && 
        widget.width! > 0 && 
        widget.height! > 0 &&
        widget.width!.isFinite && 
        widget.height!.isFinite) {
      final smallerDimension = widget.width! < widget.height! ? widget.width! : widget.height!;
      iconSize = (smallerDimension * 0.4).clamp(16.0, 48.0); // Clamp between 16 and 48
      if (!iconSize.isFinite || iconSize <= 0) {
        iconSize = 24.0;
      }
    }
    
    // Ensure container has valid dimensions - use defaults if needed
    final containerWidth = (widget.width != null && widget.width! > 0 && widget.width!.isFinite) 
        ? widget.width 
        : 48.0;
    final containerHeight = (widget.height != null && widget.height! > 0 && widget.height!.isFinite) 
        ? widget.height 
        : 48.0;
    
    return Container(
      width: containerWidth,
      height: containerHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Blue color
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Circular avatar image widget
class SafeAvatarImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  const SafeAvatarImage({
    Key? key,
    required this.imageUrl,
    required this.size,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey[300],
      ),
      child: ClipOval(
        child: SafeNetworkImage(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: Container(
            color: const Color(0xFF3B82F6), // Blue color
            child: Icon(
              Icons.person_rounded,
              size: (size * 0.6).clamp(16.0, 48.0).isFinite 
                  ? (size * 0.6).clamp(16.0, 48.0) 
                  : 24.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// School logo image widget
class SafeSchoolImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final String? fallbackAsset;

  const SafeSchoolImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.fallbackAsset = AssetsManager.login,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {

    return SafeNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(8.r),
      placeholder: placeholder,
      fallbackAsset: fallbackAsset,

    );
  }
}

