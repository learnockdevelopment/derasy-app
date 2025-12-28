class Country {
  final String code;
  final String name;
  final String dialCode;
  final String flag;

  const Country({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.flag,
  });
}

class Countries {
  static const List<Country> countries = [
    Country(code: 'US', name: 'United States', dialCode: '+1', flag: '🇺🇸'),
    Country(code: 'CA', name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
    Country(code: 'GB', name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
    Country(code: 'AU', name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
    Country(code: 'DE', name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
    Country(code: 'FR', name: 'France', dialCode: '+33', flag: '🇫🇷'),
    Country(code: 'IT', name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
    Country(code: 'ES', name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
    Country(code: 'NL', name: 'Netherlands', dialCode: '+31', flag: '🇳🇱'),
    Country(code: 'BE', name: 'Belgium', dialCode: '+32', flag: '🇧🇪'),
    Country(code: 'CH', name: 'Switzerland', dialCode: '+41', flag: '🇨🇭'),
    Country(code: 'AT', name: 'Austria', dialCode: '+43', flag: '🇦🇹'),
    Country(code: 'SE', name: 'Sweden', dialCode: '+46', flag: '🇸🇪'),
    Country(code: 'NO', name: 'Norway', dialCode: '+47', flag: '🇳🇴'),
    Country(code: 'DK', name: 'Denmark', dialCode: '+45', flag: '🇩🇰'),
    Country(code: 'FI', name: 'Finland', dialCode: '+358', flag: '🇫🇮'),
    Country(code: 'IE', name: 'Ireland', dialCode: '+353', flag: '🇮🇪'),
    Country(code: 'PT', name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
    Country(code: 'GR', name: 'Greece', dialCode: '+30', flag: '🇬🇷'),
    Country(code: 'PL', name: 'Poland', dialCode: '+48', flag: '🇵🇱'),
    Country(code: 'CZ', name: 'Czech Republic', dialCode: '+420', flag: '🇨🇿'),
    Country(code: 'HU', name: 'Hungary', dialCode: '+36', flag: '🇭🇺'),
    Country(code: 'RO', name: 'Romania', dialCode: '+40', flag: '🇷🇴'),
    Country(code: 'BG', name: 'Bulgaria', dialCode: '+359', flag: '🇧🇬'),
    Country(code: 'HR', name: 'Croatia', dialCode: '+385', flag: '🇭🇷'),
    Country(code: 'SI', name: 'Slovenia', dialCode: '+386', flag: '🇸🇮'),
    Country(code: 'SK', name: 'Slovakia', dialCode: '+421', flag: '🇸🇰'),
    Country(code: 'LT', name: 'Lithuania', dialCode: '+370', flag: '🇱🇹'),
    Country(code: 'LV', name: 'Latvia', dialCode: '+371', flag: '🇱🇻'),
    Country(code: 'EE', name: 'Estonia', dialCode: '+372', flag: '🇪🇪'),
    Country(code: 'LU', name: 'Luxembourg', dialCode: '+352', flag: '🇱🇺'),
    Country(code: 'MT', name: 'Malta', dialCode: '+356', flag: '🇲🇹'),
    Country(code: 'CY', name: 'Cyprus', dialCode: '+357', flag: '🇨🇾'),
    Country(code: 'JP', name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
    Country(code: 'KR', name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
    Country(code: 'CN', name: 'China', dialCode: '+86', flag: '🇨🇳'),
    Country(code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳'),
    Country(code: 'SG', name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
    Country(code: 'HK', name: 'Hong Kong', dialCode: '+852', flag: '🇭🇰'),
    Country(code: 'TW', name: 'Taiwan', dialCode: '+886', flag: '🇹🇼'),
    Country(code: 'TH', name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
    Country(code: 'MY', name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
    Country(code: 'ID', name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
    Country(code: 'PH', name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
    Country(code: 'VN', name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
    Country(code: 'BR', name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
    Country(code: 'AR', name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
    Country(code: 'MX', name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
    Country(code: 'CL', name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
    Country(code: 'CO', name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
    Country(code: 'PE', name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
    Country(code: 'VE', name: 'Venezuela', dialCode: '+58', flag: '🇻🇪'),
    Country(code: 'ZA', name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
    Country(code: 'EG', name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
    Country(code: 'NG', name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
    Country(code: 'KE', name: 'Kenya', dialCode: '+254', flag: '🇰🇪'),
    Country(code: 'MA', name: 'Morocco', dialCode: '+212', flag: '🇲🇦'),
    Country(code: 'TN', name: 'Tunisia', dialCode: '+216', flag: '🇹🇳'),
    Country(code: 'DZ', name: 'Algeria', dialCode: '+213', flag: '🇩🇿'),
    Country(code: 'SA', name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
    Country(code: 'AE', name: 'United Arab Emirates', dialCode: '+971', flag: '🇦🇪'),
    Country(code: 'QA', name: 'Qatar', dialCode: '+974', flag: '🇶🇦'),
    Country(code: 'KW', name: 'Kuwait', dialCode: '+965', flag: '🇰🇼'),
    Country(code: 'BH', name: 'Bahrain', dialCode: '+973', flag: '🇧🇭'),
    Country(code: 'OM', name: 'Oman', dialCode: '+968', flag: '🇴🇲'),
    Country(code: 'JO', name: 'Jordan', dialCode: '+962', flag: '🇯🇴'),
    Country(code: 'LB', name: 'Lebanon', dialCode: '+961', flag: '🇱🇧'),
    Country(code: 'IL', name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
    Country(code: 'TR', name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
    Country(code: 'RU', name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
    Country(code: 'UA', name: 'Ukraine', dialCode: '+380', flag: '🇺🇦'),
    Country(code: 'BY', name: 'Belarus', dialCode: '+375', flag: '🇧🇾'),
    Country(code: 'KZ', name: 'Kazakhstan', dialCode: '+7', flag: '🇰🇿'),
    Country(code: 'UZ', name: 'Uzbekistan', dialCode: '+998', flag: '🇺🇿'),
    Country(code: 'KG', name: 'Kyrgyzstan', dialCode: '+996', flag: '🇰🇬'),
    Country(code: 'TJ', name: 'Tajikistan', dialCode: '+992', flag: '🇹🇯'),
    Country(code: 'TM', name: 'Turkmenistan', dialCode: '+993', flag: '🇹🇲'),
    Country(code: 'AF', name: 'Afghanistan', dialCode: '+93', flag: '🇦🇫'),
    Country(code: 'PK', name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
    Country(code: 'BD', name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
    Country(code: 'LK', name: 'Sri Lanka', dialCode: '+94', flag: '🇱🇰'),
    Country(code: 'NP', name: 'Nepal', dialCode: '+977', flag: '🇳🇵'),
    Country(code: 'BT', name: 'Bhutan', dialCode: '+975', flag: '🇧🇹'),
    Country(code: 'MV', name: 'Maldives', dialCode: '+960', flag: '🇲🇻'),
    Country(code: 'MM', name: 'Myanmar', dialCode: '+95', flag: '🇲🇲'),
    Country(code: 'LA', name: 'Laos', dialCode: '+856', flag: '🇱🇦'),
    Country(code: 'KH', name: 'Cambodia', dialCode: '+855', flag: '🇰🇭'),
    Country(code: 'BN', name: 'Brunei', dialCode: '+673', flag: '🇧🇳'),
    Country(code: 'FJ', name: 'Fiji', dialCode: '+679', flag: '🇫🇯'),
    Country(code: 'PG', name: 'Papua New Guinea', dialCode: '+675', flag: '🇵🇬'),
    Country(code: 'NZ', name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
    Country(code: 'IS', name: 'Iceland', dialCode: '+354', flag: '🇮🇸'),
    Country(code: 'LI', name: 'Liechtenstein', dialCode: '+423', flag: '🇱🇮'),
    Country(code: 'MC', name: 'Monaco', dialCode: '+377', flag: '🇲🇨'),
    Country(code: 'SM', name: 'San Marino', dialCode: '+378', flag: '🇸🇲'),
    Country(code: 'VA', name: 'Vatican City', dialCode: '+379', flag: '🇻🇦'),
    Country(code: 'AD', name: 'Andorra', dialCode: '+376', flag: '🇦🇩'),
  ];

  static Country getCountryByCode(String code) {
    return countries.firstWhere(
      (country) => country.code == code,
      orElse: () => countries.first, // Default to first country if not found
    );
  }

  static List<Country> searchCountries(String query) {
    if (query.isEmpty) return countries;
    
    return countries.where((country) {
      return country.name.toLowerCase().contains(query.toLowerCase()) ||
             country.code.toLowerCase().contains(query.toLowerCase()) ||
             country.dialCode.contains(query);
    }).toList();
  }

  // Get translated country name
  static String getTranslatedName(String code) {
    final translationKey = 'country_${code.toLowerCase()}';
    // Try to get translation, fallback to English name
    try {
      // This will be handled by Get.tr in the UI
      return translationKey;
    } catch (e) {
      return getCountryByCode(code).name;
    }
  }
}
