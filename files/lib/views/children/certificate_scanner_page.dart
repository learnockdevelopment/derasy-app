import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

class CertificateScannerPage extends StatefulWidget {
  final String documentType; // 'certificate', 'parent_id', or 'child_id'
  
  const CertificateScannerPage({
    Key? key,
    this.documentType = 'certificate',
  }) : super(key: key);

  @override
  State<CertificateScannerPage> createState() => _CertificateScannerPageState();
}

class _CertificateScannerPageState extends State<CertificateScannerPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      }
    } catch (e) {
      print('📷 [SCANNER] Camera initialization error: $e');
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          'camera_initialization_failed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() {
        _isProcessing = true;
      });

      final XFile image = await _controller!.takePicture();
      
      setState(() {
        _isProcessing = false;
      });

      // Return the captured image
      if (mounted) {
        Navigator.pop(context, File(image.path));
      }
    } catch (e) {
      print('📷 [SCANNER] Capture error: $e');
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          'failed_to_capture_image'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: CameraPreview(_controller!),
              )
            else
              Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlue,
                ),
              ),

            // Scanning Frame Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: ScannerOverlayPainter(
                  documentType: widget.documentType,
                ),
              ),
            ),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 28.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.documentType == 'parent_id'
                            ? 'scan_parent_national_id'.tr
                            : widget.documentType == 'child_id'
                                ? 'scan_child_national_id'.tr
                                : 'scan_certificate'.tr,
                        style: AppFonts.h3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48.w), // Balance the close button
                  ],
                ),
              ),
            ),

            // Instructions
            Positioned(
              top: 100.h,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                margin: EdgeInsets.symmetric(horizontal: 24.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.documentType == 'parent_id' || widget.documentType == 'child_id'
                          ? Icons.badge
                          : Icons.document_scanner,
                      color: Colors.white,
                      size: 32.sp,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      widget.documentType == 'parent_id' || widget.documentType == 'child_id'
                          ? 'position_national_id_in_frame'.tr
                          : 'position_certificate_in_frame'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      widget.documentType == 'parent_id' || widget.documentType == 'child_id'
                          ? 'ensure_national_id_edges_visible'.tr
                          : 'ensure_all_edges_are_visible'.tr,
                      style: AppFonts.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Capture Button
                    GestureDetector(
                      onTap: _isProcessing ? null : _captureImage,
                      child: Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isProcessing
                              ? Colors.grey
                              : AppColors.primaryBlue,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: _isProcessing
                            ? Padding(
                                padding: EdgeInsets.all(20.w),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 32.sp,
                              ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'tap_to_capture'.tr,
                      style: AppFonts.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Scanner Overlay
class ScannerOverlayPainter extends CustomPainter {
  final String documentType;
  
  ScannerOverlayPainter({this.documentType = 'certificate'});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // National ID is smaller than certificate
    final scanAreaWidth = (documentType == 'parent_id' || documentType == 'child_id')
        ? size.width * 0.9 
        : size.width * 0.85;
    final scanAreaHeight = (documentType == 'parent_id' || documentType == 'child_id')
        ? size.height * 0.35
        : size.height * 0.5;
    final scanAreaLeft = (size.width - scanAreaWidth) / 2;
    // Child ID is at the top of the image, parent ID and certificate are centered
    final scanAreaTop = documentType == 'child_id'
        ? size.height * 0.15  // Position at top for child ID
        : (size.height - scanAreaHeight) / 2;  // Center for parent ID and certificate

    // Draw dark overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    
    final scanPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(scanAreaLeft, scanAreaTop, scanAreaWidth, scanAreaHeight),
          Radius.circular(16),
        ),
      );
    
    final cutPath = Path.combine(
      PathOperation.difference,
      path,
      scanPath,
    );

    canvas.drawPath(cutPath, paint);

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.w;

    // Top-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth - cornerLength, scanAreaTop),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft, scanAreaTop + scanAreaHeight - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + scanAreaWidth - cornerLength, scanAreaTop + scanAreaHeight),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight),
      Offset(scanAreaLeft + scanAreaWidth, scanAreaTop + scanAreaHeight - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

