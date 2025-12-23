import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_fonts.dart';

class LocationPicker extends StatefulWidget {
  final String? initialAddress;
  final Function(String address, double latitude, double longitude)
      onLocationSelected;

  const LocationPicker({
    Key? key,
    this.initialAddress,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _currentAddress = '';
  bool _isLoading = true;
  bool _isGettingAddress = false;

  @override
  void initState() {
    super.initState();
    _currentAddress = widget.initialAddress ?? '';
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      PermissionStatus permission;
      try {
        permission = await Permission.location.request();
      } catch (e) {
        print('Permission error: $e');
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
            'Unable to request location permission. Please enable it manually in settings.');
        return;
      }

      if (permission != PermissionStatus.granted) {
        setState(() {
          _isLoading = false;
        });
        _showPermissionDialog();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Get address for current location
      await _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to get current location. Please try again.');
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      setState(() {
        _isGettingAddress = true;
      });

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = _formatAddress(place);
        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _currentAddress = 'Address not found';
      });
    } finally {
      setState(() {
        _isGettingAddress = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    final parts = <String>[];

    if (place.street?.isNotEmpty == true) parts.add(place.street!);
    if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.administrativeArea?.isNotEmpty == true)
      parts.add(place.administrativeArea!);
    if (place.country?.isNotEmpty == true) parts.add(place.country!);

    return parts.join(', ');
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromCoordinates(location.latitude, location.longitude);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Controller is stored for potential future use (e.g., camera movement)
  }

  Widget _buildMapWidget() {
    try {
      return GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _selectedLocation ?? const LatLng(30.0444, 31.2357),
          zoom: 15.0,
        ),
        onTap: _onMapTap,
        markers: _selectedLocation != null
            ? {
                Marker(
                  markerId: const MarkerId('selected_location'),
                  position: _selectedLocation!,
                  infoWindow: InfoWindow(
                    title: 'Selected Location',
                    snippet: _currentAddress,
                  ),
                ),
              }
            : {},
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      );
    } catch (e) {
      print('Google Maps error: $e');
      return _buildFallbackMap();
    }
  }

  Widget _buildFallbackMap() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_rounded,
              size: 48.sp,
              color: const Color(0xFF6B7280),
            ),
            SizedBox(height: 16.h),
            Text(
              'Map Unavailable',
              style: AppFonts.h3.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please use manual location entry',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Use Manual Entry',
                style: AppFonts.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Location Permission Required',
          style: AppFonts.h3.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This app needs location permission to help you select your address. Please enable location permission in settings.',
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: AppFonts.h3.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          message,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF6B7280),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected(
        _currentAddress,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'select_location'.tr,
          style: AppFonts.h3.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _confirmLocation,
            child: Text(
              'Confirm',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Address Display
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: const Color(0xFF3B82F6),
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Selected Address',
                      style: AppFonts.bodyMedium.copyWith(
                        color: const Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                if (_isGettingAddress)
                  Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Getting address...',
                        style: AppFonts.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _currentAddress.isNotEmpty
                        ? _currentAddress
                        : 'Tap on map to select location',
                    style: AppFonts.bodyMedium.copyWith(
                      color: _currentAddress.isNotEmpty
                          ? const Color(0xFF1F2937)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF3B82F6),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Loading map...',
                          style: AppFonts.bodyMedium.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildMapWidget(),
          ),

          // Instructions
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
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
                  Icons.info_outline_rounded,
                  color: const Color(0xFF3B82F6),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Tap anywhere on the map to select your location',
                    style: AppFonts.bodySmall.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
