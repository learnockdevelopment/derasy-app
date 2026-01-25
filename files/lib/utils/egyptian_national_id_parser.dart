class EgyptianNationalIdParser {
  /// Parse Egyptian National ID to extract birth date, age, and gender
  static Map<String, dynamic> parseNationalId(String nationalId) {
    try {
      // Remove any non-numeric characters
      String cleanId = nationalId.replaceAll(RegExp(r'[^0-9]'), '');

      // Egyptian National ID should be 14 digits
      if (cleanId.length != 14) {
        throw Exception('Invalid Egyptian National ID length');
      }

      // Extract century and year
      String centuryCode = cleanId.substring(0, 1);
      String year = cleanId.substring(1, 3);
      String month = cleanId.substring(3, 5);
      String day = cleanId.substring(5, 7);
      String genderCode = cleanId.substring(12, 13);

      // Determine century
      int century;
      if (centuryCode == '2') {
        century = 1900;
      } else if (centuryCode == '3') {
        century = 2000;
      } else {
        throw Exception('Invalid century code');
      }

      // Calculate birth year
      int birthYear = century + int.parse(year);

      // Validate month
      int monthInt = int.parse(month);
      if (monthInt < 1 || monthInt > 12) {
        throw Exception('Invalid month');
      }

      // Validate day
      int dayInt = int.parse(day);
      if (dayInt < 1 || dayInt > 31) {
        throw Exception('Invalid day');
      }

      // Create birth date
      DateTime birthDate = DateTime(birthYear, monthInt, dayInt);

      // Calculate age
      DateTime now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      // Determine gender (odd = male, even = female)
      String gender = int.parse(genderCode) % 2 == 1 ? 'male' : 'female';

      return {
        'birthDate': birthDate,
        'age': age,
        'gender': gender,
        'isValid': true,
      };
    } catch (e) {
      return {
        'birthDate': null,
        'age': null,
        'gender': null,
        'isValid': false,
        'error': e.toString(),
      };
    }
  }

  /// Format date to YYYY-MM-DD string
  static String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Calculate age in October (for school purposes)
  static int calculateAgeInOctober(DateTime birthDate) {
    DateTime currentYear = DateTime.now();
    DateTime octoberThisYear = DateTime(currentYear.year, 10, 1);

    int age = octoberThisYear.year - birthDate.year;
    if (octoberThisYear.month < birthDate.month ||
        (octoberThisYear.month == birthDate.month &&
            octoberThisYear.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  /// Calculate detailed age with years, months, and days in Arabic
  static String calculateDetailedAge(DateTime birthDate) {
    DateTime now = DateTime.now();

    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    // Adjust for negative days
    if (days < 0) {
      months--;
      days += DateTime(now.year, now.month, 0).day; // Days in previous month
    }

    // Adjust for negative months
    if (months < 0) {
      years--;
      months += 12;
    }

    // Build age string in Arabic
    String ageString = '';

    if (years > 0) {
      ageString += '$years ${years == 1 ? 'سنة' : 'سنة'}';
    }

    if (months > 0) {
      if (ageString.isNotEmpty) ageString += ' و ';
      ageString += '$months ${months == 1 ? 'شهر' : 'شهر'}';
    }

    if (days > 0) {
      if (ageString.isNotEmpty) ageString += ' و ';
      ageString += '$days ${days == 1 ? 'يوم' : 'يوم'}';
    }

    // If all are 0, return "0 يوم"
    if (ageString.isEmpty) {
      ageString = '0 يوم';
    }

    return ageString;
  }
}

