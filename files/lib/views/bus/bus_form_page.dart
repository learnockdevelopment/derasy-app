import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/bus_models.dart';
import '../../services/bus_service.dart';

class BusFormPage extends StatefulWidget {
  const BusFormPage({super.key, required this.schoolId, this.bus});

  final String schoolId;
  final Bus? bus;

  @override
  State<BusFormPage> createState() => _BusFormPageState();
}

class _BusFormPageState extends State<BusFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late final TextEditingController _busNumberCtrl;
  late final TextEditingController _plateNumberCtrl;
  late final TextEditingController _motorNumberCtrl;
  late final TextEditingController _chassisNumberCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _manufacturerCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _notesCtrl;

  String? _status;
  String? _busType;

  static const List<String> _statusItems = ['active', 'inactive', 'maintenance'];
  static const List<String> _busTypeItems = ['standard', 'mini', 'luxury', 'large'];

  bool get _isEdit => widget.bus != null;

  @override
  void initState() {
    super.initState();
    final bus = widget.bus;
    _busNumberCtrl = TextEditingController(text: bus?.busNumber ?? '');
    _plateNumberCtrl = TextEditingController(text: bus?.plateNumber ?? '');
    _motorNumberCtrl = TextEditingController(text: bus?.motorNumber ?? '');
    _chassisNumberCtrl = TextEditingController(text: bus?.chassisNumber ?? '');
    _capacityCtrl = TextEditingController(text: bus?.capacity?.toString() ?? '');
    _manufacturerCtrl = TextEditingController(text: bus?.manufacturer ?? '');
    _modelCtrl = TextEditingController(text: bus?.model ?? '');
    _yearCtrl = TextEditingController(text: bus?.year?.toString() ?? '');
    _colorCtrl = TextEditingController(text: bus?.color ?? '');
    _notesCtrl = TextEditingController(text: bus?.notes ?? '');
    
    // Ensure status is valid (null => show hint on create)
    final rawStatus = bus?.status?.toLowerCase();
    _status = (rawStatus != null && _statusItems.contains(rawStatus)) ? rawStatus : (bus == null ? null : 'active');

    // Ensure busType is valid (null => show hint on create)
    final rawType = bus?.busType?.toLowerCase();
    _busType = (rawType != null && _busTypeItems.contains(rawType)) ? rawType : (bus == null ? null : 'standard');
  }

  @override
  void dispose() {
    _busNumberCtrl.dispose();
    _plateNumberCtrl.dispose();
    _motorNumberCtrl.dispose();
    _chassisNumberCtrl.dispose();
    _capacityCtrl.dispose();
    _manufacturerCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _colorCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {
        'busNumber': _busNumberCtrl.text.trim(),
        'plateNumber': _plateNumberCtrl.text.trim(),
        'motorNumber': _motorNumberCtrl.text.trim(),
        'chassisNumber': _chassisNumberCtrl.text.trim(),
        'capacity': int.tryParse(_capacityCtrl.text.trim()) ?? 0,
        'manufacturer': _manufacturerCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'year': int.tryParse(_yearCtrl.text.trim()),
        'color': _colorCtrl.text.trim(),
        'status': _status ?? 'active',
        'busType': _busType ?? 'standard',
        'notes': _notesCtrl.text.trim(),
      };

      if (_isEdit) {
        await BusService.updateBus(widget.schoolId, widget.bus!.id, data);
        Get.snackbar('success'.tr, 'bus_updated'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white);
      } else {
        await BusService.createBus(widget.schoolId, data);
        Get.snackbar('success'.tr, 'bus_created'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.success,
            colorText: Colors.white);
      }
      Get.back(result: true);
    } catch (e) {
      Get.snackbar('error'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'edit_bus'.tr : 'add_bus'.tr, style: AppFonts.h3),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.2,
      ),
      body: Container(
        color: const Color(0xFFF6F7FB),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              _sectionTitle('basic_info'.tr),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _busNumberCtrl,
                label: 'bus_number'.tr,
                icon: Icons.directions_bus_rounded,
                required: true,
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _plateNumberCtrl,
                label: 'plate_number'.tr,
                icon: Icons.confirmation_number_rounded,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      label: 'status'.tr,
                      value: _status,
                      items: _statusItems,
                      onChanged: (v) => setState(() => _status = v),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildDropdown(
                      label: 'bus_type'.tr,
                      value: _busType,
                      items: _busTypeItems,
                      onChanged: (v) => setState(() => _busType = v),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              _sectionTitle('vehicle_details'.tr),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _motorNumberCtrl,
                      label: 'motor_number'.tr,
                      icon: Icons.engineering_rounded,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField(
                      controller: _chassisNumberCtrl,
                      label: 'chassis_number'.tr,
                      icon: Icons.build_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _manufacturerCtrl,
                      label: 'manufacturer'.tr,
                      icon: Icons.factory_rounded,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField(
                      controller: _modelCtrl,
                      label: 'model'.tr,
                      icon: Icons.model_training_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _yearCtrl,
                      label: 'year'.tr,
                      icon: Icons.calendar_today_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField(
                      controller: _colorCtrl,
                      label: 'color'.tr,
                      icon: Icons.color_lens_rounded,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _capacityCtrl,
                label: 'capacity'.tr,
                icon: Icons.people_rounded,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 24.h),
              _sectionTitle('additional_info'.tr),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _notesCtrl,
                label: 'notes'.tr,
                icon: Icons.note_rounded,
                maxLines: 3,
              ),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                        height: 20.h,
                        width: 20.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEdit ? 'update'.tr : 'create'.tr,
                        style: AppFonts.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppFonts.h4.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppFonts.bodySmall,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
        hintText: hint ?? '${'enter'.tr} $label',
        hintStyle: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: AppColors.blue1, size: 20.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.blue1, width: 2),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'required'.tr : null
          : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.blue1),
      style: AppFonts.bodySmall.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary),
        hintText: '${'enter'.tr} $label',
        hintStyle: AppFonts.bodySmall.copyWith(color: AppColors.textSecondary.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.blue1, width: 2),
        ),
      ),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(_translateDropdownItem(e), style: AppFonts.bodySmall),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  String _translateDropdownItem(String item) {
    switch (item) {
      case 'active': return 'active'.tr;
      case 'inactive': return 'inactive'.tr;
      case 'maintenance': return 'maintenance'.tr;
      case 'standard': return 'standard'.tr;
      case 'mini': return 'mini'.tr;
      case 'luxury': return 'luxury'.tr;
      case 'large': return 'large'.tr;
      default: return item.tr;
    }
  }
}

