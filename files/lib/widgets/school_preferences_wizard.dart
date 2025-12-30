import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../models/school_suggestion_models.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';

class SchoolPreferencesWizard extends StatefulWidget {
  final Function(SchoolPreferences) onPreferencesSubmitted;
  final bool isLoading;
  final bool hasExistingApplication;

  const SchoolPreferencesWizard({
    Key? key,
    required this.onPreferencesSubmitted,
    this.isLoading = false,
    this.hasExistingApplication = false,
  }) : super(key: key);

  @override
  State<SchoolPreferencesWizard> createState() => _SchoolPreferencesWizardState();
}

class _SchoolPreferencesWizardState extends State<SchoolPreferencesWizard> {
  // Education categories
  final List<Map<String, String>> _mainCategories = [
    {'key': 'national', 'label': 'National'},
    {'key': 'international', 'label': 'International'},
  ];

  final Map<String, List<Map<String, String>>> _subTypes = {
    'National': [
      {'key': 'arabic', 'label': 'Arabic'},
      {'key': 'english', 'label': 'English'},
    ],
    'International': [
      {'key': 'american', 'label': 'American'},
      {'key': 'british', 'label': 'British'},
      {'key': 'german', 'label': 'German'},
      {'key': 'french', 'label': 'French'},
      {'key': 'ib', 'label': 'IB'},
      {'key': 'igcse', 'label': 'IGCSE'},
    ],
  };

  // Egyptian governorates with translation keys
  final List<Map<String, String>> _governorates = [
    {'key': 'cairo', 'label': 'Cairo'},
    {'key': 'giza', 'label': 'Giza'},
    {'key': 'alexandria', 'label': 'Alexandria'},
    {'key': 'qalyubia', 'label': 'Qalyubia'},
    {'key': 'sharqia', 'label': 'Sharqia'},
    {'key': 'dakahlia', 'label': 'Dakahlia'},
    {'key': 'beheira', 'label': 'Beheira'},
    {'key': 'kafr_el_sheikh', 'label': 'Kafr El Sheikh'},
    {'key': 'gharbia', 'label': 'Gharbia'},
    {'key': 'monufia', 'label': 'Monufia'},
    {'key': 'damietta', 'label': 'Damietta'},
    {'key': 'port_said', 'label': 'Port Said'},
    {'key': 'ismailia', 'label': 'Ismailia'},
    {'key': 'suez', 'label': 'Suez'},
    {'key': 'north_sinai', 'label': 'North Sinai'},
    {'key': 'south_sinai', 'label': 'South Sinai'},
    {'key': 'faiyum', 'label': 'Faiyum'},
    {'key': 'beni_suef', 'label': 'Beni Suef'},
    {'key': 'minya', 'label': 'Minya'},
    {'key': 'asyut', 'label': 'Asyut'},
    {'key': 'sohag', 'label': 'Sohag'},
    {'key': 'qena', 'label': 'Qena'},
    {'key': 'aswan', 'label': 'Aswan'},
    {'key': 'luxor', 'label': 'Luxor'},
    {'key': 'red_sea', 'label': 'Red Sea'},
    {'key': 'new_valley', 'label': 'New Valley'},
    {'key': 'matrouh', 'label': 'Matrouh'},
  ];

  final Map<String, List<Map<String, String>>> _cities = {
    'Cairo': [
      {'key': 'nasr_city', 'label': 'Nasr City'},
      {'key': 'maadi', 'label': 'Maadi'},
      {'key': 'heliopolis', 'label': 'Heliopolis'},
      {'key': 'new_cairo', 'label': 'New Cairo'},
      {'key': 'zamalek', 'label': 'Zamalek'},
      {'key': 'downtown_cairo', 'label': 'Downtown'},
      {'key': 'mokattam', 'label': 'Mokattam'},
      {'key': 'helwan', 'label': 'Helwan'},
      {'key': 'shubra', 'label': 'Shubra'},
      {'key': 'ain_shams', 'label': 'Ain Shams'},
      {'key': 'matariya', 'label': 'Matariya'},
    ],
    'Giza': [
      {'key': '6th_october', 'label': '6th of October'},
      {'key': 'sheikh_zayed', 'label': 'Sheikh Zayed'},
      {'key': 'dokki', 'label': 'Dokki'},
      {'key': 'mohandessin', 'label': 'Mohandessin'},
      {'key': 'haram', 'label': 'Haram'},
      {'key': 'faisal', 'label': 'Faisal'},
      {'key': 'agouza', 'label': 'Agouza'},
      {'key': 'imbaba', 'label': 'Imbaba'},
    ],
    'Alexandria': [
      {'key': 'montaza', 'label': 'Montaza'},
      {'key': 'miami', 'label': 'Miami'},
      {'key': 'sidi_gaber', 'label': 'Sidi Gaber'},
      {'key': 'smouha', 'label': 'Smouha'},
      {'key': 'stanley', 'label': 'Stanley'},
      {'key': 'glim', 'label': 'Glim'},
      {'key': 'agami', 'label': 'Agami'},
      {'key': 'borg_el_arab', 'label': 'Borg El Arab'},
    ],
    'Qalyubia': [
      {'key': 'banha', 'label': 'Banha'},
      {'key': 'shubra_el_kheima', 'label': 'Shubra El Kheima'},
      {'key': 'qalyub', 'label': 'Qalyub'},
      {'key': 'khanka', 'label': 'Khanka'},
      {'key': 'qaha', 'label': 'Qaha'},
    ],
    'Sharqia': [
      {'key': 'zagazig', 'label': 'Zagazig'},
      {'key': '10th_ramadan', 'label': '10th of Ramadan'},
      {'key': 'bilbeis', 'label': 'Bilbeis'},
      {'key': 'abu_hammad', 'label': 'Abu Hammad'},
      {'key': 'faqous', 'label': 'Faqous'},
    ],
    'Dakahlia': [
      {'key': 'mansoura', 'label': 'Mansoura'},
      {'key': 'talkha', 'label': 'Talkha'},
      {'key': 'mit_ghamr', 'label': 'Mit Ghamr'},
      {'key': 'dekernes', 'label': 'Dekernes'},
      {'key': 'aga', 'label': 'Aga'},
    ],
    'Beheira': [
      {'key': 'damanhour', 'label': 'Damanhour'},
      {'key': 'kafr_el_dawwar', 'label': 'Kafr El Dawwar'},
      {'key': 'rashid', 'label': 'Rashid'},
      {'key': 'edku', 'label': 'Edku'},
    ],
    'Kafr El Sheikh': [
      {'key': 'kafr_el_sheikh_city', 'label': 'Kafr El Sheikh'},
      {'key': 'desouk', 'label': 'Desouk'},
      {'key': 'fuwwah', 'label': 'Fuwwah'},
      {'key': 'baltim', 'label': 'Baltim'},
    ],
    'Gharbia': [
      {'key': 'tanta', 'label': 'Tanta'},
      {'key': 'mahalla', 'label': 'El Mahalla El Kubra'},
      {'key': 'kafr_el_zayat', 'label': 'Kafr El Zayat'},
      {'key': 'samanoud', 'label': 'Samanoud'},
    ],
    'Monufia': [
      {'key': 'shibin_el_kom', 'label': 'Shibin El Kom'},
      {'key': 'menouf', 'label': 'Menouf'},
      {'key': 'ashmoun', 'label': 'Ashmoun'},
      {'key': 'quesna', 'label': 'Quesna'},
    ],
    'Damietta': [
      {'key': 'damietta_city', 'label': 'Damietta'},
      {'key': 'new_damietta', 'label': 'New Damietta'},
      {'key': 'ras_el_bar', 'label': 'Ras El Bar'},
      {'key': 'faraskour', 'label': 'Faraskour'},
    ],
    'Port Said': [
      {'key': 'port_said_city', 'label': 'Port Said'},
      {'key': 'port_fouad', 'label': 'Port Fouad'},
    ],
    'Ismailia': [
      {'key': 'ismailia_city', 'label': 'Ismailia'},
      {'key': 'fayed', 'label': 'Fayed'},
      {'key': 'qantara', 'label': 'Qantara'},
    ],
    'Suez': [
      {'key': 'suez_city', 'label': 'Suez'},
      {'key': 'ain_sokhna', 'label': 'Ain Sokhna'},
    ],
    'North Sinai': [
      {'key': 'arish', 'label': 'Arish'},
      {'key': 'sheikh_zuweid', 'label': 'Sheikh Zuweid'},
      {'key': 'rafah', 'label': 'Rafah'},
    ],
    'South Sinai': [
      {'key': 'sharm_el_sheikh', 'label': 'Sharm El Sheikh'},
      {'key': 'dahab', 'label': 'Dahab'},
      {'key': 'nuweiba', 'label': 'Nuweiba'},
      {'key': 'taba', 'label': 'Taba'},
      {'key': 'saint_catherine', 'label': 'Saint Catherine'},
    ],
    'Faiyum': [
      {'key': 'faiyum_city', 'label': 'Faiyum'},
      {'key': 'ibshaway', 'label': 'Ibshaway'},
      {'key': 'tamiya', 'label': 'Tamiya'},
    ],
    'Beni Suef': [
      {'key': 'beni_suef_city', 'label': 'Beni Suef'},
      {'key': 'new_beni_suef', 'label': 'New Beni Suef'},
      {'key': 'biba', 'label': 'Biba'},
    ],
    'Minya': [
      {'key': 'minya_city', 'label': 'Minya'},
      {'key': 'mallawi', 'label': 'Mallawi'},
      {'key': 'samalut', 'label': 'Samalut'},
    ],
    'Asyut': [
      {'key': 'asyut_city', 'label': 'Asyut'},
      {'key': 'new_asyut', 'label': 'New Asyut'},
      {'key': 'abnub', 'label': 'Abnub'},
    ],
    'Sohag': [
      {'key': 'sohag_city', 'label': 'Sohag'},
      {'key': 'akhmim', 'label': 'Akhmim'},
      {'key': 'girga', 'label': 'Girga'},
    ],
    'Qena': [
      {'key': 'qena_city', 'label': 'Qena'},
      {'key': 'nag_hammadi', 'label': 'Nag Hammadi'},
      {'key': 'qus', 'label': 'Qus'},
    ],
    'Aswan': [
      {'key': 'aswan_city', 'label': 'Aswan'},
      {'key': 'kom_ombo', 'label': 'Kom Ombo'},
      {'key': 'edfu', 'label': 'Edfu'},
    ],
    'Luxor': [
      {'key': 'luxor_city', 'label': 'Luxor'},
      {'key': 'esna', 'label': 'Esna'},
      {'key': 'armant', 'label': 'Armant'},
    ],
    'Red Sea': [
      {'key': 'hurghada', 'label': 'Hurghada'},
      {'key': 'safaga', 'label': 'Safaga'},
      {'key': 'marsa_alam', 'label': 'Marsa Alam'},
      {'key': 'quseer', 'label': 'Quseer'},
    ],
    'New Valley': [
      {'key': 'kharga', 'label': 'Kharga'},
      {'key': 'dakhla', 'label': 'Dakhla'},
      {'key': 'farafra', 'label': 'Farafra'},
    ],
    'Matrouh': [
      {'key': 'marsa_matrouh', 'label': 'Marsa Matrouh'},
      {'key': 'alamein', 'label': 'El Alamein'},
      {'key': 'sidi_barrani', 'label': 'Sidi Barrani'},
    ],
  };
  
  // Controllers and State
  String? _selectedMainCategory;
  String? _selectedSubType;
  String? _selectedGovernorate;
  String? _selectedCity;
  
  // Fee ranges
  double _minYearlyFee = 0;
  double _maxYearlyFee = 150000;
  double _maxBusFee = 20000;
  double _maxAdmissionFee = 10000;

  @override
  void dispose() {
    super.dispose();
  }

  void _submit() {
    if (_selectedMainCategory == null) {
      Get.snackbar(
        'error'.tr,
        'please_select_education_category'.tr,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedSubType == null) {
      Get.snackbar(
        'error'.tr,
        'please_select_education_type'.tr,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
      return;
    }

    // Combine main category and sub-type for the API
    final combinedType = '$_selectedMainCategory - $_selectedSubType';
    
    // Combine governorate and city for zone
    String? zone;
    if (_selectedGovernorate != null) {
      zone = _selectedCity != null 
          ? '$_selectedGovernorate, $_selectedCity'
          : _selectedGovernorate;
    }

    final prefs = SchoolPreferences(
      type: combinedType,
      zone: zone,
      minFee: _minYearlyFee,
      maxFee: _maxYearlyFee,
      busFeeMax: _maxBusFee,
      admissionFeeMax: _maxAdmissionFee,
      coed: null,
    );

    widget.onPreferencesSubmitted(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          SizedBox(height: 32.h),
          
          // Main Education Category
          _buildSectionTitle('education_category'.tr),
          SizedBox(height: 12.h),
          _buildMainCategoryDropdown(),
          SizedBox(height: 24.h),

          // Sub-type (only show if main category is selected)
          if (_selectedMainCategory != null) ...[
            _buildSectionTitle('education_type'.tr),
            SizedBox(height: 12.h),
            _buildSubTypeDropdown(),
            SizedBox(height: 24.h),
          ],

          // Governorate
          _buildSectionTitle('governorate'.tr),
          SizedBox(height: 12.h),
          _buildGovernorateDropdown(),
          SizedBox(height: 24.h),

          // City (only show if governorate is selected)
          if (_selectedGovernorate != null) ...[
            _buildSectionTitle('city'.tr),
            SizedBox(height: 12.h),
            _buildCityDropdown(),
            SizedBox(height: 24.h),
          ],

          // Yearly Fees Range
          _buildSectionTitle('yearly_fees_range'.tr),
          SizedBox(height: 16.h),
          _buildRangeSlider(  
            label: 'yearly_subscription'.tr,
            minValue: _minYearlyFee,
            maxValue: _maxYearlyFee,
            onChanged: (RangeValues values) {
              setState(() {
                _minYearlyFee = values.start;
                _maxYearlyFee = values.end;
              });
            },
            max: 200000,
            icon: Icons.school,
          ),
          SizedBox(height: 24.h),

          // Additional Fees
          _buildSectionTitle('additional_fees'.tr),
          SizedBox(height: 16.h),
          _buildFeeSlider(
            label: 'bus_fees'.tr,
            value: _maxBusFee,
            onChanged: (val) => setState(() => _maxBusFee = val),
            max: 30000,
            icon: Icons.directions_bus,
          ),
          SizedBox(height: 16.h),
          _buildFeeSlider(
            label: 'admission_fees'.tr,
            value: _maxAdmissionFee,
            onChanged: (val) => setState(() => _maxAdmissionFee = val),
            max: 20000,
            icon: Icons.receipt_long,
          ),
          SizedBox(height: 32.h),
          
          // Submit Button
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.hasExistingApplication
              ? [
                  AppColors.error.withOpacity(0.08),
                  AppColors.error.withOpacity(0.03),
                ]
              : [
                  AppColors.primaryBlue.withOpacity(0.08),
                  AppColors.primaryBlue.withOpacity(0.03),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: widget.hasExistingApplication
              ? AppColors.error.withOpacity(0.15)
              : AppColors.primaryBlue.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: widget.hasExistingApplication
                  ? AppColors.error.withOpacity(0.1)
                  : AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              widget.hasExistingApplication ? Icons.info_outline : Icons.auto_awesome,
              color: widget.hasExistingApplication ? AppColors.error : AppColors.primaryBlue,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              widget.hasExistingApplication
                  ? 'existing_application_message'.tr
                  : 'ai_school_suggestion_desc'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: AppFonts.h4.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 14.sp,
      ),
    );
  }

  Widget _buildMainCategoryDropdown() {
    final isArabic = Get.locale?.languageCode == 'ar';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _selectedMainCategory != null 
              ? AppColors.primaryBlue.withOpacity(0.4)
              : AppColors.grey300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedMainCategory != null
                ? AppColors.primaryBlue.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMainCategory,
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
            child: Text(
              'select_education_category'.tr,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.grey400,
                fontSize: 13.sp,
              ),
            ),
          ),
          isExpanded: true,
          icon: Padding(
            padding: EdgeInsets.only(right: isArabic ? 0 : 14.w, left: isArabic ? 14.w : 0),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryBlue,
              size: 26.sp,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          elevation: 16,
          menuMaxHeight: 350.h,
          itemHeight: 60.h,
          items: _mainCategories.map((category) {
            return DropdownMenuItem(
              value: category['label'],
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                child: Row(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        size: 18.sp,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      category['key']!.tr,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: AppFonts.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedMainCategory = val;
              _selectedSubType = null;
            });
          },
          selectedItemBuilder: (context) {
            return _mainCategories.map((category) {
              return Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Text(
                    category['key']!.tr,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: AppFonts.bodyMedium.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildSubTypeDropdown() {
    final isArabic = Get.locale?.languageCode == 'ar';
    final subTypes = _subTypes[_selectedMainCategory] ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all( 
          color: _selectedSubType != null 
              ? AppColors.primaryBlue.withOpacity(0.4)
              : AppColors.grey300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedSubType != null
                ? AppColors.primaryBlue.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ), 
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSubType,
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
            child: Text(
              'select_education_type'.tr,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: AppFonts.bodySmall.copyWith(
                color: AppColors.grey400,
                fontSize: 13.sp,
              ),
            ),
          ),
          isExpanded: true,
          icon: Padding(
            padding: EdgeInsets.only(right: isArabic ? 0 : 14.w, left: isArabic ? 14.w : 0),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryBlue,
              size: 26.sp,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          elevation: 16,
          menuMaxHeight: 350.h,
          itemHeight: 60.h,
          items: subTypes.map((type) {
            return DropdownMenuItem(
              value: type['label'],
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                child: Row(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        size: 18.sp,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      type['key']!.tr,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: AppFonts.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedSubType = val),
          selectedItemBuilder: (context) {
            return subTypes.map((type) {
              return Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Text(
                    type['key']!.tr,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: AppFonts.bodyMedium.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildGovernorateDropdown() {
    final isArabic = Get.locale?.languageCode == 'ar';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _selectedGovernorate != null 
              ? AppColors.primaryBlue.withOpacity(0.4)
              : AppColors.grey300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedGovernorate != null
                ? AppColors.primaryBlue.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGovernorate,
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
            child: Text(
              'select_governorate'.tr,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.grey400,
                fontSize: 13.sp,
              ),
            ),
          ),
          isExpanded: true,
          icon: Padding(
            padding: EdgeInsets.only(right: isArabic ? 0 : 14.w, left: isArabic ? 14.w : 0),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryBlue,
              size: 26.sp,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          elevation: 16,
          menuMaxHeight: 400.h,
          itemHeight: 60.h,
          items: _governorates.map((gov) {
            return DropdownMenuItem(
              value: gov['label'],
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                child: Row(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.location_city,
                        size: 18.sp,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      gov['key']!.tr,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: AppFonts.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedGovernorate = val;
              _selectedCity = null; // Reset city when governorate changes
            });
          },
          selectedItemBuilder: (context) {
            return _governorates.map((gov) {
              return Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Text(
                    gov['key']!.tr,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: AppFonts.bodyMedium.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    final isArabic = Get.locale?.languageCode == 'ar';
    final cities = _cities[_selectedGovernorate] ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _selectedCity != null 
              ? AppColors.primaryBlue.withOpacity(0.4)
              : AppColors.grey300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _selectedCity != null
                ? AppColors.primaryBlue.withOpacity(0.08)
                : Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCity,
          hint: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
            child: Text(
              'select_city'.tr,
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              style: AppFonts.bodyMedium.copyWith(
                color: AppColors.grey400,
                fontSize: 13.sp,
              ),
            ),
          ),
          isExpanded: true,
          icon: Padding(
            padding: EdgeInsets.only(right: isArabic ? 0 : 14.w, left: isArabic ? 14.w : 0),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryBlue,
              size: 26.sp,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          elevation: 16,
          menuMaxHeight: 400.h,
          itemHeight: 60.h,
          items: cities.map((city) {
            return DropdownMenuItem(
              value: city['label'],
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                child: Row(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 18.sp,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      city['key']!.tr,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      style: AppFonts.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCity = val),
          selectedItemBuilder: (context) {
            return cities.map((city) {
              return Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Text(
                    city['key']!.tr,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: AppFonts.bodyMedium.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildFeeSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double max,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                size: 18.sp,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        // Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: max,
            divisions: (max / 1000).round(),
            activeColor: AppColors.primaryBlue,
            inactiveColor: AppColors.primaryBlue.withOpacity(0.2),
            label: '${(value / 1000).round()}K',
            onChanged: onChanged,
          ),
        ),
        
        // Value display
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 18.sp,
                color: AppColors.primaryBlue,
              ),
              SizedBox(width: 8.w),
              Text(
                '${'max'.tr}: ${_formatCurrency(value)}',
                style: AppFonts.bodyMedium.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K ${'egp'.tr}';
    }
    return '${amount.toStringAsFixed(0)} ${'egp'.tr}';
  }

  Widget _buildRangeSlider({
    required String label,
    required double minValue,
    required double maxValue,
    required ValueChanged<RangeValues> onChanged,
    required double max,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with icon
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                size: 18.sp,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              label,
              style: AppFonts.bodyMedium.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        
        // Range Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6.h,
            rangeThumbShape: RoundRangeSliderThumbShape(enabledThumbRadius: 10.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 20.r),
          ),
          child: RangeSlider(
            values: RangeValues(minValue, maxValue),
            min: 0,
            max: max,
            divisions: (max / 1000).round(),
            activeColor: AppColors.primaryBlue,
            inactiveColor: AppColors.primaryBlue.withOpacity(0.2),
            labels: RangeLabels(
              '${(minValue / 1000).round()}K',
              '${(maxValue / 1000).round()}K',
            ),
            onChanged: onChanged,
          ),
        ),
        
        // Value display
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Min value
              Row(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    size: 16.sp,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${'min'.tr}: ${_formatCurrency(minValue)}',
                    style: AppFonts.bodyMedium.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
              // Max value
              Row(
                children: [
                  Icon(
                    Icons.arrow_upward,
                    size: 16.sp,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${'max'.tr}: ${_formatCurrency(maxValue)}',
                    style: AppFonts.bodyMedium.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: (widget.isLoading || widget.hasExistingApplication) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          disabledBackgroundColor: AppColors.grey300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: widget.isLoading
            ? SizedBox(
                height: 24.h,
                width: 24.h,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 20.sp, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text(
                    'get_ai_suggestions'.tr,
                    style: AppFonts.h4.copyWith(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
