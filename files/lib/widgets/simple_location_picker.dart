import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/constants/app_fonts.dart';

class SimpleLocationPicker extends StatefulWidget {
  final String? initialAddress;
  final Function(String address, double latitude, double longitude)
      onLocationSelected;

  const SimpleLocationPicker({
    Key? key,
    this.initialAddress,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<SimpleLocationPicker> createState() => _SimpleLocationPickerState();
}

class _SimpleLocationPickerState extends State<SimpleLocationPicker> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialAddress ?? '';
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _confirmLocation() {
    final address = _addressController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim()) ?? 0.0;
    final longitude = double.tryParse(_longitudeController.text.trim()) ?? 0.0;

    if (address.isNotEmpty) {
      widget.onLocationSelected(address, latitude, longitude);
      Navigator.pop(context);
    } else {
      _showErrorDialog('Please enter an address');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'enter_location'.tr,
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
      body: SingleChildScrollView(
        padding: Responsive.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withOpacity(0.08),
                    const Color(0xFF1E40AF).withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(Responsive.r(16)),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: Responsive.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(Responsive.r(12)),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      color: const Color(0xFF3B82F6),
                      size: Responsive.sp(24),
                    ),
                  ),
                  SizedBox(width: Responsive.w(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'enter_location_details'.tr,
                          style: AppFonts.h3.copyWith(
                            color: const Color(0xFF1F2937),
                            fontWeight: FontWeight.bold,
                            
                          ),
                        ),
                        SizedBox(height: Responsive.h(4)),
                        Text(
                          'enter_address_manually'.tr,
                          style: AppFonts.bodySmall.copyWith(
                            color: const Color(0xFF6B7280),
                            
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: Responsive.h(24)),

            // Address Field
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              hint: 'enter_full_address'.tr,
              icon: Icons.location_on_rounded,
              maxLines: 3,
            ),

            SizedBox(height: Responsive.h(20)),

            // Coordinates Section
            Text(
              'Coordinates (Optional)',
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
                
              ),
            ),
            SizedBox(height: Responsive.h(12)),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _latitudeController,
                    label: 'Latitude',
                    hint: 'e.g., 30.0444',
                    icon: Icons.my_location_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: Responsive.w(16)),
                Expanded(
                  child: _buildTextField(
                    controller: _longitudeController,
                    label: 'Longitude',
                    hint: 'e.g., 31.2357',
                    icon: Icons.my_location_rounded,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            SizedBox(height: Responsive.h(24)),

            // Instructions
            Container(
              padding: Responsive.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(Responsive.r(12)),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFF3B82F6),
                    size: Responsive.sp(20),
                  ),
                  SizedBox(width: Responsive.w(12)),
                  Expanded(
                    child: Text(
                      'You can find coordinates using online maps or leave them empty for address-only location.',
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.bodyMedium.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            
          ),
        ),
        SizedBox(height: Responsive.h(8)),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(Responsive.r(12)),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF1F2937),
              
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF9CA3AF),
                
              ),
              prefixIcon: Container(
                margin: Responsive.all(8),
                padding: Responsive.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Responsive.r(8)),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3B82F6),
                  size: Responsive.sp(20),
                ),
              ),
              border: InputBorder.none,
              contentPadding: Responsive.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

