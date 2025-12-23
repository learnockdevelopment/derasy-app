import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_fonts.dart';
import 'location_picker.dart';
import 'simple_location_picker.dart';

class EnhancedAddressField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Function(String address, double latitude, double longitude)?
      onLocationSelected;

  const EnhancedAddressField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.onLocationSelected,
  }) : super(key: key);

  @override
  State<EnhancedAddressField> createState() => _EnhancedAddressFieldState();
}

class _EnhancedAddressFieldState extends State<EnhancedAddressField> {
  double? _latitude;
  double? _longitude;

  void _openLocationPicker() async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPicker(
            initialAddress: widget.controller.text,
            onLocationSelected: (address, latitude, longitude) {
              setState(() {
                _latitude = latitude;
                _longitude = longitude;
              });
              widget.controller.text = address;
              widget.onLocationSelected?.call(address, latitude, longitude);
            },
          ),
        ),
      );
    } catch (e) {
      // Fallback to simple location picker if Google Maps fails
      print('Google Maps not available, using simple picker: $e');
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleLocationPicker(
            initialAddress: widget.controller.text,
            onLocationSelected: (address, latitude, longitude) {
              setState(() {
                _latitude = latitude;
                _longitude = longitude;
              });
              widget.controller.text = address;
              widget.onLocationSelected?.call(address, latitude, longitude);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Text Field
              TextFormField(
                controller: widget.controller,
                readOnly: true,
                style: AppFonts.bodyMedium.copyWith(
                  color: const Color(0xFF1F2937),
                  
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: AppFonts.bodySmall.copyWith(
                    color: const Color(0xFF9CA3AF),
                    
                  ),
                  prefixIcon: Container(
                    margin: EdgeInsets.all(8.w),
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: const Color(0xFF3B82F6),
                      size: 20.sp,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                ),
                onTap: _openLocationPicker,
              ),

              // Location Picker Buttons
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.05),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: _openLocationPicker,
                      child: Row(
                        children: [
                          Icon(
                            Icons.map_rounded,
                            color: const Color(0xFF3B82F6),
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'select_location_on_map'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                              
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF3B82F6),
                            size: 16.sp,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8.h),
                    InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SimpleLocationPicker(
                              initialAddress: widget.controller.text,
                              onLocationSelected:
                                  (address, latitude, longitude) {
                                setState(() {
                                  _latitude = latitude;
                                  _longitude = longitude;
                                });
                                widget.controller.text = address;
                                widget.onLocationSelected
                                    ?.call(address, latitude, longitude);
                              },
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_location_rounded,
                            color: const Color(0xFF6B7280),
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'enter_location_manually'.tr,
                            style: AppFonts.bodyMedium.copyWith(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                              
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: const Color(0xFF6B7280),
                            size: 16.sp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Location Info (if coordinates are available)
              if (_latitude != null && _longitude != null)
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.05),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${'location'.tr}: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                        style: AppFonts.bodySmall.copyWith(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
