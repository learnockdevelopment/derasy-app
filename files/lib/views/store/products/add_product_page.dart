import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../../../models/store_models.dart';
import '../../../services/store_service.dart';
import '../../../services/schools_service.dart';
import '../../../models/school_models.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({Key? key}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleEnController = TextEditingController();
  final _titleArController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _shortDescriptionEnController = TextEditingController();
  final _shortDescriptionArController = TextEditingController();
  final _specificationsEnController = TextEditingController();
  final _specificationsArController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();
  final _tagsController = TextEditingController();

  List<Category> _categories = [];
  List<School> _schools = [];
  Category? _selectedCategory;
  List<String> _selectedSchools = [];
  bool _isFeatured = false;
  bool _isActive = true;
  double? _globalDiscount;
  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleArController.dispose();
    _descriptionEnController.dispose();
    _descriptionArController.dispose();
    _shortDescriptionEnController.dispose();
    _shortDescriptionArController.dispose();
    _specificationsEnController.dispose();
    _specificationsArController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load categories
      _categories = await StoreService.getAllCategories();
      
      // Load schools
      final schoolsResponse = await SchoolsService.getAllSchools();
      if (schoolsResponse.success) {
        _schools = schoolsResponse.schools;
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build product data
      final productData = <String, dynamic>{
        'title_en': _titleEnController.text.trim(),
        'title_ar': _titleArController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'stock': int.tryParse(_stockController.text) ?? 0,
        'isFeatured': _isFeatured,
        'isActive': _isActive,
        'schools': _selectedSchools,
        'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      };

      if (_descriptionEnController.text.isNotEmpty) {
        productData['description_en'] = _descriptionEnController.text.trim();
      }
      if (_descriptionArController.text.isNotEmpty) {
        productData['description_ar'] = _descriptionArController.text.trim();
      }
      if (_shortDescriptionEnController.text.isNotEmpty) {
        productData['shortDescription_en'] = _shortDescriptionEnController.text.trim();
      }
      if (_shortDescriptionArController.text.isNotEmpty) {
        productData['shortDescription_ar'] = _shortDescriptionArController.text.trim();
      }
      if (_specificationsEnController.text.isNotEmpty) {
        productData['specifications_en'] = _specificationsEnController.text.trim();
      }
      if (_specificationsArController.text.isNotEmpty) {
        productData['specifications_ar'] = _specificationsArController.text.trim();
      }
      if (_selectedCategory != null) {
        productData['category'] = _selectedCategory!.id;
      }
      if (_skuController.text.isNotEmpty) {
        productData['sku'] = _skuController.text.trim();
      }
      if (_globalDiscount != null && _globalDiscount! > 0) {
        productData['discount'] = {
          'global': _globalDiscount,
        };
      }

      await StoreService.createProduct(productData);

      if (mounted) {
        Get.snackbar(
          'success'.tr,
          'product_added_successfully'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.primaryBlue,
          colorText: Colors.white,
        );
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'error'.tr,
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: Text(
          'add_product'.tr,
          style: AppFonts.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 18),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildSectionTitle('basic_information'.tr),
                    SizedBox(height: 12.h),
                    _buildTextField(_titleArController, 'title_ar'.tr, Icons.title_rounded, required: true),
                    SizedBox(height: 16.h),
                    _buildTextField(_titleEnController, 'title_en'.tr, Icons.title_rounded, required: true),
                    SizedBox(height: 16.h),
                    _buildDropdown<Category>(
                      'category'.tr,
                      _selectedCategory,
                      _categories,
                      (value) => setState(() => _selectedCategory = value),
                      Icons.category_rounded,
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(_priceController, 'price'.tr, Icons.attach_money_rounded, keyboardType: TextInputType.number, required: true),
                    SizedBox(height: 16.h),
                    _buildTextField(_stockController, 'stock'.tr, Icons.inventory_rounded, keyboardType: TextInputType.number, required: true),
                    SizedBox(height: 16.h),
                    _buildTextField(_skuController, 'sku'.tr, Icons.qr_code_rounded),
                    SizedBox(height: 16.h),
                    _buildTextField(_tagsController, 'tags'.tr, Icons.label_rounded, hint: 'tags_hint'.tr),

                    SizedBox(height: 24.h),
                    // Descriptions
                    _buildSectionTitle('descriptions'.tr),
                    SizedBox(height: 12.h),
                    _buildTextField(_shortDescriptionArController, 'short_description_ar'.tr, Icons.short_text_rounded, maxLines: 2),
                    SizedBox(height: 16.h),
                    _buildTextField(_shortDescriptionEnController, 'short_description_en'.tr, Icons.short_text_rounded, maxLines: 2),
                    SizedBox(height: 16.h),
                    _buildTextField(_descriptionArController, 'description_ar'.tr, Icons.description_rounded, maxLines: 4),
                    SizedBox(height: 16.h),
                    _buildTextField(_descriptionEnController, 'description_en'.tr, Icons.description_rounded, maxLines: 4),
                    SizedBox(height: 16.h),
                    _buildTextField(_specificationsArController, 'specifications_ar'.tr, Icons.list_rounded, maxLines: 4),
                    SizedBox(height: 16.h),
                    _buildTextField(_specificationsEnController, 'specifications_en'.tr, Icons.list_rounded, maxLines: 4),

                    SizedBox(height: 24.h),
                    // Settings
                    _buildSectionTitle('settings'.tr),
                    SizedBox(height: 12.h),
                    _buildSwitch('is_featured'.tr, _isFeatured, (value) => setState(() => _isFeatured = value)),
                    SizedBox(height: 16.h),
                    _buildSwitch('is_active'.tr, _isActive, (value) => setState(() => _isActive = value)),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      TextEditingController(text: _globalDiscount?.toString() ?? ''),
                      'global_discount'.tr,
                      Icons.percent_rounded,
                      keyboardType: TextInputType.number,
                      hint: 'discount_percentage'.tr,
                      onChanged: (value) {
                        _globalDiscount = double.tryParse(value);
                      },
                    ),

                    SizedBox(height: 24.h),
                    // Schools
                    _buildSectionTitle('schools'.tr),
                    SizedBox(height: 12.h),
                    _buildSchoolSelection(),

                    SizedBox(height: 32.h),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'add_product'.tr,
                                style: AppFonts.bodyLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppFonts.size16,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppFonts.h3.copyWith(
        color: const Color(0xFF1F2937),
        fontWeight: FontWeight.bold,
        fontSize: AppFonts.size18,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool required = false,
    int maxLines = 1,
    String? hint,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '${'required'.tr} $label';
                }
                return null;
              }
            : null,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown<T>(
    String label,
    T? value,
    List<T> items,
    Function(T?) onChanged,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
        items: items.map((item) {
          String displayText;
          if (item is Category) {
            displayText = item.titleAr;
          } else {
            displayText = item.toString();
          }
          return DropdownMenuItem<T>(
            value: item,
            child: Text(displayText),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF1F2937),
              fontSize: AppFonts.size14,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolSelection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'select_schools'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: const Color(0xFF1F2937),
              fontSize: AppFonts.size14,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _schools.map((school) {
              final isSelected = _selectedSchools.contains(school.id);
              return FilterChip(
                label: Text(school.name),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSchools.add(school.id);
                    } else {
                      _selectedSchools.remove(school.id);
                    }
                  });
                },
                selectedColor: AppColors.primaryBlue,
                labelStyle: AppFonts.bodySmall.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFF1F2937),
                  fontSize: AppFonts.size12,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

