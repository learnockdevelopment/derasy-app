import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/countries.dart';

class CountrySelector extends StatefulWidget {
  final Country? selectedCountry;
  final Function(Country) onCountrySelected;

  const CountrySelector({
    Key? key,
    this.selectedCountry,
    required this.onCountrySelected,
  }) : super(key: key);

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  Country? _selectedCountry;
  List<Country> _filteredCountries = Countries.countries;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.selectedCountry ?? Countries.countries.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = Countries.searchCountries(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        height: Responsive.h(600),
        margin: Responsive.all(20),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(Responsive.r(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: Responsive.all(20),
              decoration: BoxDecoration(
                color: AppColors.blue1,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Responsive.r(20)),
                  topRight: Radius.circular(Responsive.r(20)),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'select_country'.tr,
                    style: AppFonts.AlmaraiBold18.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: Responsive.w(24),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: Responsive.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCountries,
                decoration: InputDecoration(
                  hintText: 'search_countries'.tr,
                  hintStyle: AppFonts.AlmaraiRegular14.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: Responsive.w(20),
                  ),
                  filled: true,
                  fillColor: AppColors.grey100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Responsive.r(12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: Responsive.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Countries List
            Expanded(
              child: ListView.builder(
                itemCount: _filteredCountries.length,
                itemBuilder: (context, index) {
                  final country = _filteredCountries[index];
                  final isSelected = _selectedCountry?.code == country.code;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCountry = country;
                      });
                      widget.onCountrySelected(country);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: Responsive.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.blue1.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.grey100,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            country.flag,
                            style: TextStyle(fontSize: Responsive.sp(24)),
                          ),
                          SizedBox(width: Responsive.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  country.name,
                                  style: AppFonts.AlmaraiMedium14.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  country.dialCode,
                                  style: AppFonts.AlmaraiRegular12.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: AppColors.blue1,
                              size: Responsive.w(20),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

