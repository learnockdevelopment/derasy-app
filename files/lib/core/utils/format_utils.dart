import 'package:get/get.dart';

class FormatUtils {
  /// Converts Western numerals to Arabic-Indic numerals if the current locale is Arabic.
  static String formatNumber(String number) {
    if (Get.locale?.languageCode == 'ar') {
      return number.replaceAllMapped(
        RegExp(r'\d'),
        (match) {
          const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
          final group = match.group(0);
          if (group == null) return '';
          return arabicNumerals[int.parse(group)];
        },
      );
    }
    return number;
  }

  /// Formats a price with commas and two decimal places.
  /// Translates currency if provided and localizes numerals for Arabic.
  static String formatPrice(double amount, [String? currency]) {
    // Add commas for thousands
    final String priceStr = amount.toStringAsFixed(2);
    final List<String> parts = priceStr.split('.');
    String wholePart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '00';

    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    wholePart = wholePart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    
    String formattedAmount = '$wholePart.$decimalPart';

    if (Get.locale?.languageCode == 'ar') {
      formattedAmount = formatNumber(formattedAmount);
      if (currency != null && currency.isNotEmpty) {
        String translatedCurrency = currency.toLowerCase().tr;
        // Fallback common currencies if transition key is missing or same as key
        if (translatedCurrency == currency.toLowerCase()) {
          if (currency.toUpperCase() == 'EGP') translatedCurrency = 'جنيه';
          else if (currency.toUpperCase() == 'SAR') translatedCurrency = 'ريال';
          else if (currency.toUpperCase() == 'USD') translatedCurrency = 'دولار';
        }
        return '$formattedAmount $translatedCurrency';
      }
      return formattedAmount;
    }

    if (currency != null && currency.isNotEmpty) {
      return '$formattedAmount ${currency.toUpperCase()}';
    }
    return formattedAmount;
  }
}

