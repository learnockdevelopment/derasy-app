import 'student_models.dart';
import 'school_models.dart';

class SchoolSuggestionRequest {
  final Student child;
  final List<School> schools;
  final SchoolPreferences preferences;

  SchoolSuggestionRequest({
    required this.child,
    required this.schools,
    required this.preferences,
  });

  Map<String, dynamic> toJson() {
    return {
      'child': child.toJson(),
      'schools': schools.map((s) => _schoolToJson(s)).toList(),
      'preferences': preferences.toJson(),
    };
  }

  // Helper to send only necessary school fields to save bandwidth/token size
  Map<String, dynamic> _schoolToJson(School school) {
    return {
      '_id': school.id,
      'name': school.name,
      'type': school.type,
      'admissionFee': school.admissionFee != null
          ? {
              'amount': school.admissionFee!.amount,
            }
          : null,
      'feesDetails': school.feesDetails != null
          ? {
            // Include basics if needed, or rely on admissionFee for simple cost analysis
            'yearlyFees': school.feesDetails!.yearlyFees,
          }
          : null,
      'location': school.location != null 
          ? {
             'governorate': school.location!.governorate,
             'city': school.location!.city,
             'district': school.location!.district,
          }
          : null,
    };
  }
}

class SchoolPreferences {
  final double? minFee;
  final double? maxFee;
  final double? busFeeMax;
  final Map<String, double>? yearlyFees;
  final double? admissionFeeMax;
  final String? zone;
  final String? type;
  final String? coed; // mixed, single
  final String? language;

  SchoolPreferences({
    this.minFee,
    this.maxFee,
    this.busFeeMax,
    this.yearlyFees,
    this.admissionFeeMax,
    this.zone,
    this.type,
    this.coed,
    this.language,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (minFee != null) data['minFee'] = minFee;
    if (maxFee != null) data['maxFee'] = maxFee;
    if (busFeeMax != null) data['busFeeMax'] = busFeeMax;
    if (yearlyFees != null) data['yearlyFees'] = yearlyFees;
    if (admissionFeeMax != null) data['admissionFeeMax'] = admissionFeeMax;
    if (zone != null && zone!.isNotEmpty) data['zone'] = zone;
    if (type != null && type!.isNotEmpty) data['type'] = type;
    if (coed != null && coed!.isNotEmpty) data['coed'] = coed;
    if (language != null && language!.isNotEmpty) data['language'] = language;
    return data;
  }
}

class SchoolSuggestionResponse {
  final String message;
  final String? markdown;
  final String? html;
  final List<String> suggestedIds;

  SchoolSuggestionResponse({
    required this.message,
    this.markdown,
    this.html,
    required this.suggestedIds,
  });

  factory SchoolSuggestionResponse.fromJson(Map<String, dynamic> json) {
    return SchoolSuggestionResponse(
      message: json['message'] ?? '',
      markdown: json['markdown'],
      html: json['html'],
      suggestedIds: (json['suggestedIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
