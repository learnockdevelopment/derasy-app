import 'dart:ui';

class SchoolFacility {
  final String id;
  final String name;
  final String icon;

  SchoolFacility({required this.id, required this.name, required this.icon});

  factory SchoolFacility.fromJson(Map<String, dynamic> json) {
    return SchoolFacility(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      icon: (json['icon'] ?? '').toString(),
    );
  }
}

class School {
  final String id;
  final String name;
  final String? shortName;
  final String? slug;
  final String? type;
  final String? gender;
  final String? educationSystem;
  final bool approved;
  final SchoolOwnership ownership;
  final SchoolVisibilitySettings? visibilitySettings;
  final List<SchoolBranch> branches;
  final List<String> gradesOffered;
  final Map<String, dynamic> ageRequirement; 
  final String? bannerImage;
  final List<String> languages;
  final String? mainTeachingLanguage;
  final List<String> accreditations;
  final bool isReligious;
  final String? religionType;
  final bool supportsSpecialNeeds;
  final bool admissionOpen;
  final SchoolAdmissionFee? admissionFee;
  final List<String> documentsRequired;
  final SchoolFeesRange? feesRange;
  final SchoolFeesDetails? feesDetails;
  final SchoolLocation? location;
  final SchoolPrincipal? principal;
  final SchoolAdmissionDetails? admissionDetails;
  final SchoolAcademicDetails? academicDetails;
  final SchoolMedia? media;
  final SchoolIdCard? idCard;
  final List<SchoolIdCardField> studentIdCardFields;
  final SchoolMobileApps? mobileApps;
  final SchoolMoodleDb? moodleDb;
  final SchoolAcademicYear? academicYear;
  final List<SchoolFacility>? facilities;
  final Map<String, dynamic>? workingHours;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      return value['name']?.toString() ?? 
             value['nameAr']?.toString() ?? 
             value['nameEn']?.toString() ?? 
             value['_id']?.toString();
    }
    return value.toString();
  }

  School({
    required this.id,
    required this.name,
    this.shortName,
    this.slug,
    required this.type,
    this.gender,
    this.educationSystem,
    required this.approved,
    required this.ownership,
    this.visibilitySettings,
    required this.branches,
    required this.gradesOffered,
    required this.ageRequirement,
    this.bannerImage,
    required this.languages,
    this.mainTeachingLanguage,
    required this.accreditations,
    required this.isReligious,
    this.religionType,
    required this.supportsSpecialNeeds,
    required this.admissionOpen,
    this.admissionFee,
    required this.documentsRequired,
    this.feesRange,
    this.feesDetails,
    this.location,
    this.principal,
    this.admissionDetails,
    this.academicDetails,
    this.media,
    this.idCard,
    required this.studentIdCardFields,
    this.mobileApps,
    this.moodleDb,
    this.academicYear,
    this.facilities,
    this.workingHours,
    this.createdAt,
    this.updatedAt,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    try {
      return School(
        id: _parseString(json['_id']) ?? '',
        name: _parseString(json['name']) ?? '',
        shortName: _parseString(json['shortName']),
        slug: _parseString(json['slug']),
        type: _parseString(json['type']) ?? '',
        gender: _parseString(json['gender']),
        educationSystem: json['educationSystem'] is Map
            ? json['educationSystem']['_id']?.toString()
            : json['educationSystemId'] is Map
                ? json['educationSystemId']['_id']?.toString()
                : (json['educationSystem'] ?? json['educationSystemId'])?.toString(),
        approved: json['approved'] is bool
            ? json['approved']
            : (json['approved'] == 'true' || json['approved'] == true),
        ownership: json['ownership'] is Map<String, dynamic>
            ? SchoolOwnership.fromJson(json['ownership'])
            : SchoolOwnership.fromJson({}),
        visibilitySettings: json['visibilitySettings'] != null &&
                json['visibilitySettings'] is Map<String, dynamic>
            ? SchoolVisibilitySettings.fromJson(json['visibilitySettings'])
            : null,
        branches: (json['branches'] as List<dynamic>?)
                ?.map((branch) => branch is Map<String, dynamic>
                    ? SchoolBranch.fromJson(branch)
                    : null)
                .where((branch) => branch != null)
                .cast<SchoolBranch>()
                .toList() ??
            [],
        gradesOffered: (json['gradesOffered'] as List<dynamic>?)
                ?.map((grade) => grade.toString())
                .toList() ??
            [],
        ageRequirement: Map<String, dynamic>.from(json['ageRequirement'] ?? {}),
        bannerImage: json['bannerImage'],
        languages: (json['languages'] as List<dynamic>?)
                ?.map((lang) => lang.toString())
                .toList() ??
            [],
        mainTeachingLanguage: json['mainTeachingLanguage'],
        accreditations: (json['accreditations'] as List<dynamic>?)
                ?.map((acc) => acc.toString())
                .toList() ??
            [],
        isReligious: json['isReligious'] is bool
            ? json['isReligious']
            : (json['isReligious'] == 'true' || json['isReligious'] == true),
        religionType: json['religionType'],
        supportsSpecialNeeds: json['supportsSpecialNeeds'] is bool
            ? json['supportsSpecialNeeds']
            : (json['supportsSpecialNeeds'] == 'true' ||
                json['supportsSpecialNeeds'] == true),
        admissionOpen: json['admissionOpen'] is bool
            ? json['admissionOpen']
            : (json['admissionOpen'] == 'true' ||
                json['admissionOpen'] == true),
        admissionFee: json['admissionFee'] != null &&
                json['admissionFee'] is Map<String, dynamic>
            ? SchoolAdmissionFee.fromJson(json['admissionFee'])
            : null,
        documentsRequired: (json['documentsRequired'] as List<dynamic>?)
                ?.map((doc) => doc.toString())
                .toList() ??
            [],
        feesRange: json['feesRange'] != null &&
                json['feesRange'] is Map<String, dynamic>
            ? SchoolFeesRange.fromJson(json['feesRange'])
            : null,
        feesDetails: json['feesDetails'] != null &&
                json['feesDetails'] is Map<String, dynamic>
            ? SchoolFeesDetails.fromJson(json['feesDetails'])
            : null,
        location:
            json['location'] != null && json['location'] is Map<String, dynamic>
                ? SchoolLocation.fromJson(json['location'])
                : null,
        principal: json['principal'] != null &&
                json['principal'] is Map<String, dynamic>
            ? SchoolPrincipal.fromJson(json['principal'])
            : null,
        admissionDetails: json['admissionDetails'] != null &&
                json['admissionDetails'] is Map<String, dynamic>
            ? SchoolAdmissionDetails.fromJson(json['admissionDetails'])
            : null,
        academicDetails: json['academicDetails'] != null &&
                json['academicDetails'] is Map<String, dynamic>
            ? SchoolAcademicDetails.fromJson(json['academicDetails'])
            : null,
        media: json['media'] != null && json['media'] is Map<String, dynamic>
            ? SchoolMedia.fromJson(json['media'])
            : null,
        idCard: json['idCard'] != null && json['idCard'] is Map<String, dynamic>
            ? SchoolIdCard.fromJson(json['idCard'])
            : null,
        studentIdCardFields: (json['studentIdCardFields'] as List<dynamic>?)
                ?.map((field) => field is Map<String, dynamic>
                    ? SchoolIdCardField.fromJson(field)
                    : null)
                .where((field) => field != null)
                .cast<SchoolIdCardField>()
                .toList() ??
            [],
        mobileApps: json['mobileApps'] != null &&
                json['mobileApps'] is Map<String, dynamic>
            ? SchoolMobileApps.fromJson(json['mobileApps'])
            : null,
        moodleDb:
            json['moodleDb'] != null && json['moodleDb'] is Map<String, dynamic>
                ? SchoolMoodleDb.fromJson(json['moodleDb'])
                : null,
        academicYear: json['academicYear'] != null &&
                json['academicYear'] is Map<String, dynamic>
            ? SchoolAcademicYear.fromJson(json['academicYear'])
            : null,
        facilities: (json['facilities'] as List<dynamic>?)?.map((f) {
          if (f is Map<String, dynamic>) {
            return SchoolFacility.fromJson(f);
          } else {
            return SchoolFacility(id: f.toString(), name: f.toString(), icon: f.toString());
          }
        }).toList(),
        workingHours: json['workingHours'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['workingHours'])
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );
    } catch (e) {
      print('🏫 [SCHOOL JSON] Error parsing school: $e');
      return School(
        id: json['_id'] ?? 'unknown',
        name: json['name'] ?? 'Unknown School',
        type: json['type'] ?? 'Unknown',
        approved: false,
        ownership: SchoolOwnership(moderators: []),
        branches: [],
        gradesOffered: [],
        ageRequirement: {},
        languages: [],
        accreditations: [],
        isReligious: false,
        supportsSpecialNeeds: false,
        admissionOpen: false,
        documentsRequired: [],
        studentIdCardFields: [],
      );
    }
  }
}

class SchoolOwnership {
  final SchoolOwner? owner;
  final List<SchoolModerator> moderators;

  SchoolOwnership({this.owner, required this.moderators});

  factory SchoolOwnership.fromJson(Map<String, dynamic> json) {
    return SchoolOwnership(
      owner: json['owner'] != null && json['owner'] is Map<String, dynamic>
          ? SchoolOwner.fromJson(json['owner'])
          : null,
      moderators: (json['moderators'] as List<dynamic>?)
              ?.map((mod) {
                if (mod is Map<String, dynamic>) {
                  return SchoolModerator.fromJson(mod);
                }
                return null;
              })
              .where((mod) => mod != null)
              .cast<SchoolModerator>()
              .toList() ??
          [],
    );
  }
}

class SchoolOwner {
  final String id;
  final String name;
  final String email;
  final String? phone;

  SchoolOwner({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory SchoolOwner.fromJson(Map<String, dynamic> json) {
    return SchoolOwner(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
    );
  }
}

class SchoolModerator {
  final String id;
  final String name;
  final String email;
  final String? phone;

  SchoolModerator({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory SchoolModerator.fromJson(Map<String, dynamic> json) {
    return SchoolModerator(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
    );
  }
}

class SchoolVisibilitySettings {
  final bool showInSearch;
  final SchoolLogo? officialLogo;
  final SchoolTheme? theme;

  SchoolVisibilitySettings({
    required this.showInSearch,
    this.officialLogo,
    this.theme,
  });

  factory SchoolVisibilitySettings.fromJson(Map<String, dynamic> json) {
    return SchoolVisibilitySettings(
      showInSearch: json['showInSearch'] ?? false,
      officialLogo: json['officialLogo'] != null
          ? SchoolLogo.fromJson(json['officialLogo'])
          : null,
      theme: json['theme'] != null ? SchoolTheme.fromJson(json['theme']) : null,
    );
  }
}

class SchoolLogo {
  final String url;

  SchoolLogo({required this.url});

  factory SchoolLogo.fromJson(Map<String, dynamic> json) {
    return SchoolLogo(url: json['url'] ?? '');
  }
}

class SchoolTheme {
  final String template;
  final String primaryColor;
  final String secondaryColor;

  SchoolTheme({
    required this.template,
    required this.primaryColor,
    required this.secondaryColor,
  });

  factory SchoolTheme.fromJson(Map<String, dynamic> json) {
    return SchoolTheme(
      template: json['template'] ?? '',
      primaryColor: json['primaryColor'] ?? '',
      secondaryColor: json['secondaryColor'] ?? '',
    );
  }
}

class SchoolBranch {
  final String name;
  final String governorate;
  final String zone;
  final String address;
  final String? contactEmail;
  final String? contactPhone;
  final SchoolCoordinates? coordinates;
  final List<String> facilities;
  final String? id;

  SchoolBranch({
    required this.name,
    required this.governorate,
    required this.zone,
    required this.address,
    this.contactEmail,
    this.contactPhone,
    this.coordinates,
    required this.facilities,
    this.id,
  });

  factory SchoolBranch.fromJson(Map<String, dynamic> json) {
    return SchoolBranch(
      name: json['name'] ?? '',
      governorate: json['governorate'] ?? '',
      zone: json['zone'] ?? '',
      address: json['address'] ?? '',
      contactEmail: json['contactEmail'],
      contactPhone: json['contactPhone'],
      coordinates: json['coordinates'] != null
          ? SchoolCoordinates.fromJson(json['coordinates'])
          : null,
      facilities: (json['facilities'] as List<dynamic>?)
              ?.map((facility) => facility.toString())
              .toList() ??
          [],
      id: json['_id'],
    );
  }
}

class SchoolCoordinates {
  final double lat;
  final double lng;

  SchoolCoordinates({required this.lat, required this.lng});

  factory SchoolCoordinates.fromJson(Map<String, dynamic> json) {
    return SchoolCoordinates(
      lat: (json['lat'] is int ? json['lat'].toDouble() : json['lat'] ?? 0.0),
      lng: (json['lng'] is int ? json['lng'].toDouble() : json['lng'] ?? 0.0),
    );
  }
}

class SchoolAdmissionFee {
  final double amount;
  final String currency;
  final bool isRefundable;

  SchoolAdmissionFee({
    required this.amount,
    required this.currency,
    required this.isRefundable,
  });

  factory SchoolAdmissionFee.fromJson(Map<String, dynamic> json) {
    return SchoolAdmissionFee(
      amount: (json['amount'] is int
          ? json['amount'].toDouble()
          : json['amount'] ?? 0.0),
      currency: json['currency'] ?? '',
      isRefundable: json['isRefundable'] is bool
          ? json['isRefundable']
          : (json['isRefundable'] == 'true' || json['isRefundable'] == true),
    );
  }
}

class SchoolFeesRange {
  final double min;
  final double max;

  SchoolFeesRange({required this.min, required this.max});

  factory SchoolFeesRange.fromJson(Map<String, dynamic> json) {
    return SchoolFeesRange(
      min: (json['min'] is int ? json['min'].toDouble() : json['min'] ?? 0.0),
      max: (json['max'] is int ? json['max'].toDouble() : json['max'] ?? 0.0),
    );
  }
}

class SchoolFeesDetails {
  final Map<String, dynamic>? yearlyFees;
  final SchoolBusFees? bus;
  final bool? hasSiblingDiscounts;

  SchoolFeesDetails({this.yearlyFees, this.bus, this.hasSiblingDiscounts});

  factory SchoolFeesDetails.fromJson(Map<String, dynamic> json) {
    return SchoolFeesDetails(
      yearlyFees: json['yearlyFees'] != null
          ? Map<String, dynamic>.from(json['yearlyFees'])
          : null,
      bus: json['bus'] != null ? SchoolBusFees.fromJson(json['bus']) : null,
      hasSiblingDiscounts: json['hasSiblingDiscounts'] is bool
          ? json['hasSiblingDiscounts']
          : (json['hasSiblingDiscounts'] == 'true' ||
              json['hasSiblingDiscounts'] == true),
    );
  }
}

class SchoolBusFees {
  final double amount;
  final List<String> coverageAreas;

  SchoolBusFees({required this.amount, required this.coverageAreas});

  factory SchoolBusFees.fromJson(Map<String, dynamic> json) {
    return SchoolBusFees(
      amount: (json['amount'] is int
          ? json['amount'].toDouble()
          : json['amount'] ?? 0.0),
      coverageAreas: (json['coverageAreas'] as List<dynamic>?)
              ?.map((area) => area.toString())
              .toList() ??
          [],
    );
  }
}

class SchoolLocation {
  final String governorate;
  final String city;
  final String? district;
  final String? educationalAdministration;
  final String? mainPhone;
  final String? secondaryPhone;
  final String? officialEmail;
  final String? website;
  final String? address;
  final double? latitude;
  final double? longitude;
  final Map<String, String>? socialMedia;

  SchoolLocation({
    required this.governorate,
    required this.city,
    this.district,
    this.educationalAdministration,
    this.mainPhone,
    this.secondaryPhone,
    this.officialEmail,
    this.website,
    this.address,
    this.latitude,
    this.longitude,
    this.socialMedia,
  });

  factory SchoolLocation.fromJson(Map<String, dynamic> json) {
    return SchoolLocation(
      governorate: School._parseString(json['governorate']) ?? '',
      city: School._parseString(json['city']) ?? '',
      district: School._parseString(json['district']),
      educationalAdministration: School._parseString(json['educationalAdministration']),
      mainPhone: json['mainPhone']?.toString(),
      secondaryPhone: json['secondaryPhone']?.toString(),
      officialEmail: json['officialEmail']?.toString(), 
      website: json['website']?.toString(),
      address: (json['address'] ?? json['detailedAddress'])?.toString(),
      latitude: json['coordinates']?['lat'] != null ? double.tryParse(json['coordinates']!['lat'].toString()) : null,
      longitude: json['coordinates']?['lng'] != null ? double.tryParse(json['coordinates']!['lng'].toString()) : null,
      socialMedia: json['socialMedia'] != null
          ? Map<String, String>.from(json['socialMedia'])
          : null,
    );
  }
}

class SchoolPrincipal {
  final String name;
  final String email;
  final String phone;

  SchoolPrincipal({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory SchoolPrincipal.fromJson(Map<String, dynamic> json) {
    return SchoolPrincipal(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}

class SchoolAdmissionDetails {
  final bool? hasInterview;
  final bool? acceptsOnlineApplications;
  final String? generalPolicy;
  final List<String>? applicationPeriods;
  final List<String>? requiredDocuments;
  final String? admissionTermsLink;

  SchoolAdmissionDetails({
    this.hasInterview,
    this.acceptsOnlineApplications,
    this.generalPolicy,
    this.applicationPeriods,
    this.requiredDocuments,
    this.admissionTermsLink,
  });

  factory SchoolAdmissionDetails.fromJson(Map<String, dynamic> json) {
    return SchoolAdmissionDetails(
      hasInterview: json['hasInterview'] is bool
          ? json['hasInterview']
          : (json['hasInterview'] == 'true' || json['hasInterview'] == true),
      acceptsOnlineApplications: json['acceptsOnlineApplications'] is bool
          ? json['acceptsOnlineApplications']
          : (json['acceptsOnlineApplications'] == 'true' ||
              json['acceptsOnlineApplications'] == true),
      generalPolicy: json['generalPolicy'],
      applicationPeriods: (json['applicationPeriods'] as List<dynamic>?)
          ?.map((period) => period.toString())
          .toList(),
      requiredDocuments: (json['requiredDocuments'] as List<dynamic>?)
          ?.map((doc) => doc.toString())
          .toList(),
      admissionTermsLink: json['admissionTermsLink'],
    );
  }
}

class SchoolAcademicDetails {
  final int? avgStudentsPerClass;
  final bool? isCoeducational;
  final bool? offersExtraActivities;

  SchoolAcademicDetails({
    this.avgStudentsPerClass,
    this.isCoeducational,
    this.offersExtraActivities,
  });

  factory SchoolAcademicDetails.fromJson(Map<String, dynamic> json) {
    return SchoolAcademicDetails(
      avgStudentsPerClass: json['avgStudentsPerClass'],
      isCoeducational: json['isCoeducational'] is bool
          ? json['isCoeducational']
          : (json['isCoeducational'] == 'true' ||
              json['isCoeducational'] == true),
      offersExtraActivities: json['offersExtraActivities'] is bool
          ? json['offersExtraActivities']
          : (json['offersExtraActivities'] == 'true' ||
              json['offersExtraActivities'] == true),
    );
  }
}

class SchoolMedia {
  final List<SchoolImage>? schoolImages;

  SchoolMedia({this.schoolImages});

  factory SchoolMedia.fromJson(Map<String, dynamic> json) {
    return SchoolMedia(
      schoolImages: (json['schoolImages'] as List<dynamic>?)
          ?.map((img) => SchoolImage.fromJson(img))
          .toList(),
    );
  }
}

class SchoolImage {
  final String url;
  final String? label;
  final String? id;

  SchoolImage({required this.url, this.label, this.id});

  factory SchoolImage.fromJson(Map<String, dynamic> json) {
    return SchoolImage(
      url: json['url'] ?? '',
      label: json['label'],
      id: json['_id'],
    );
  }
}

class SchoolIdCard {
  final bool enabled;
  final String aspectRatio;
  final int height;
  final String? publicId;
  final String? url;
  final int width;
  final SchoolEnvelope? envelope;

  SchoolIdCard({
    required this.enabled,
    required this.aspectRatio,
    required this.height,
    this.publicId,
    this.url,
    required this.width,
    this.envelope,
  });

  factory SchoolIdCard.fromJson(Map<String, dynamic> json) {
    return SchoolIdCard(
      enabled: json['enabled'] is bool
          ? json['enabled']
          : (json['enabled'] == 'true' || json['enabled'] == true),
      aspectRatio: json['aspectRatio'] ?? '',
      height: json['height'] ?? 0,
      publicId: json['publicId'],
      url: json['url'],
      width: json['width'] ?? 0,
      envelope: json['envelope'] != null && json['envelope'] is Map<String, dynamic>
          ? SchoolEnvelope.fromJson(json['envelope'])
          : null,
    );
  }
}

class SchoolEnvelope {
  final String? front;
  final String? back;

  SchoolEnvelope({this.front, this.back});

  factory SchoolEnvelope.fromJson(Map<String, dynamic> json) {
    return SchoolEnvelope(
      front: json['front'],
      back: json['back'],
    );
  }
}

class SchoolIdCardField {
  final String key;
  final String label;
  final String? placeholder;
  final bool required;
  final String type;
  final bool mandatory;
  final List<String> options;
  final SchoolIdCardFieldStyle style;
  final String? id;

  SchoolIdCardField({
    required this.key,
    required this.label,
    this.placeholder,
    required this.required,
    required this.type,
    required this.mandatory,
    required this.options,
    required this.style,
    this.id,
  });

  factory SchoolIdCardField.fromJson(Map<String, dynamic> json) {
    return SchoolIdCardField(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      placeholder: json['placeholder'],
      required: json['required'] is bool
          ? json['required']
          : (json['required'] == 'true' || json['required'] == true),
      type: json['type'] ?? '',
      mandatory: json['mandatory'] is bool
          ? json['mandatory']
          : (json['mandatory'] == 'true' || json['mandatory'] == true),
      options: (json['options'] as List<dynamic>?)
              ?.map((opt) => opt.toString())
              .toList() ??
          [],
      style: SchoolIdCardFieldStyle.fromJson(json['style'] ?? {}),
      id: json['_id'],
    );
  }
}

class SchoolIdCardFieldStyle {
  final double x;
  final double xPercentage;
  final double y;
  final double yPercentage;
  final int fontSize;
  final String fontWeight;
  final String textAlign;
  final String backgroundColor;
  final String borderColor;
  final int borderRadius;
  final String color;
  final String fontFamily;
  final double width;
  final double height;
  final int characterLimit;

  SchoolIdCardFieldStyle({
    required this.x,
    required this.xPercentage,
    required this.y,
    required this.yPercentage,
    required this.fontSize,
    required this.fontWeight,
    required this.textAlign,
    required this.backgroundColor,
    required this.borderColor,
    required this.borderRadius,
    required this.color,
    required this.fontFamily,
    required this.width,
    required this.height,
    required this.characterLimit,
  });

  factory SchoolIdCardFieldStyle.fromJson(Map<String, dynamic> json) {
    return SchoolIdCardFieldStyle(
      x: (json['x'] is int ? json['x'].toDouble() : json['x'] ?? 0.0),
      xPercentage: (json['xPercentage'] is int
          ? json['xPercentage'].toDouble()
          : json['xPercentage'] ?? 0.0),
      y: (json['y'] is int ? json['y'].toDouble() : json['y'] ?? 0.0),
      yPercentage: (json['yPercentage'] is int
          ? json['yPercentage'].toDouble()
          : json['yPercentage'] ?? 0.0),
      fontSize:
          json['fontSize'] is int ? json['fontSize'] : (json['fontSize'] ?? 12),
      fontWeight: json['fontWeight'] ?? 'normal',
      textAlign: json['textAlign'] ?? 'left',
      backgroundColor: json['backgroundColor'] ?? 'transparent',
      borderColor: json['borderColor'] ?? '#000000',
      borderRadius: json['borderRadius'] is int
          ? json['borderRadius']
          : (json['borderRadius'] ?? 0),
      color: json['color'] ?? '#000000',
      fontFamily: json['fontFamily'] ?? 'Arial',
      width: (json['width'] is int
          ? json['width'].toDouble()
          : json['width'] ?? 0.0),
      height: (json['height'] is int
          ? json['height'].toDouble()
          : json['height'] ?? 0.0),
      characterLimit: json['characterLimit'] is int
          ? json['characterLimit']
          : (json['characterLimit'] ?? 100),
    );
  }
}

class SchoolMobileApps {
  final SchoolApp? android;
  final SchoolApp? ios;

  SchoolMobileApps({this.android, this.ios});

  factory SchoolMobileApps.fromJson(Map<String, dynamic> json) {
    return SchoolMobileApps(
      android: json['android'] != null && json['android'] is Map<String, dynamic>
          ? SchoolApp.fromJson(json['android'])
          : null,
      ios: json['ios'] != null && json['ios'] is Map<String, dynamic>
          ? SchoolApp.fromJson(json['ios'])
          : null,
    );
  }
}

class SchoolApp {
  final bool enabled;
  final String? url;
  final String? appLink;

  SchoolApp({required this.enabled, this.url, this.appLink});

  factory SchoolApp.fromJson(Map<String, dynamic> json) {
    return SchoolApp(
      enabled: json['enabled'] is bool
          ? json['enabled']
          : (json['enabled'] == 'true' || json['enabled'] == true),
      url: json['url'],
      appLink: json['appLink'],
    );
  }
}

class SchoolMoodleDb {
  final String? domain;
  final String? token;
  final String? host;
  final String? user;
  final String? password;
  final String? database;
  final int? port;
  final bool? configured;
  final bool? groupsCreated;
  final bool? restrictionsApplied;
  final bool? sectionsCreated;
  final bool? sectionsLastSync;
  final bool? groupsLastSync;

  SchoolMoodleDb({
    this.domain,
    this.token,
    this.host,
    this.user,
    this.password,
    this.database,
    this.port,
    this.configured,
    this.groupsCreated,
    this.restrictionsApplied,
    this.sectionsCreated,
    this.sectionsLastSync,
    this.groupsLastSync,
  });

  factory SchoolMoodleDb.fromJson(Map<String, dynamic> json) {
    return SchoolMoodleDb(
      domain: json['domain'],
      token: json['token'],
      host: json['host'],
      user: json['user'],
      password: json['password'],
      database: json['database'],
      port: json['port'],
      configured: json['configured'] is bool
          ? json['configured']
          : (json['configured'] == 'true' || json['configured'] == true),
      groupsCreated: json['groupsCreated'] is bool
          ? json['groupsCreated']
          : (json['groupsCreated'] == 'true' || json['groupsCreated'] == true),
      restrictionsApplied: json['restrictionsApplied'] is bool
          ? json['restrictionsApplied']
          : (json['restrictionsApplied'] == 'true' ||
              json['restrictionsApplied'] == true),
      sectionsCreated: json['sectionsCreated'] is bool
          ? json['sectionsCreated']
          : (json['sectionsCreated'] == 'true' ||
              json['sectionsCreated'] == true),
      sectionsLastSync: json['sectionsLastSync'] is bool
          ? json['sectionsLastSync']
          : (json['sectionsLastSync'] == 'true' ||
              json['sectionsLastSync'] == true),
      groupsLastSync: json['groupsLastSync'] is bool
          ? json['groupsLastSync']
          : (json['groupsLastSync'] == 'true' ||
              json['groupsLastSync'] == true),
    );
  }
}

class SchoolAcademicYear {
  final DateTime startDate;
  final DateTime endDate;

  SchoolAcademicYear({required this.startDate, required this.endDate});

  factory SchoolAcademicYear.fromJson(Map<String, dynamic> json) {
    return SchoolAcademicYear(
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }
}

class SchoolsResponse {
  final bool success;
  final String message;
  final List<School> schools;

  SchoolsResponse({
    required this.success,
    required this.message,
    required this.schools,
  });

  factory SchoolsResponse.fromJson(dynamic json) {
    try {
      if (json is List) {
        return SchoolsResponse(
          success: true,
          message: 'Schools loaded successfully',
          schools: json
              .map((school) => school is Map<String, dynamic>
                  ? School.fromJson(school)
                  : null)
              .where((school) => school != null)
              .cast<School>()
              .toList(),
        );
      }
      
      if (json is Map<String, dynamic>) {
        return SchoolsResponse(
          success: json['success'] ?? true,
          message: json['message'] ?? '',
          schools: (json['schools'] as List<dynamic>?)
                  ?.map((school) => school is Map<String, dynamic>
                      ? School.fromJson(school)
                      : null)
                  .where((school) => school != null)
                  .cast<School>()
                  .toList() ??
              [],
        );
      }
      
      throw Exception('Unexpected JSON format: ${json.runtimeType}');
    } catch (e) {
      return SchoolsResponse(
        success: false,
        message: 'Error parsing schools data: $e',
        schools: [],
      );
    }
  }
}

class SchoolsError {
  final String message;
  final String? error;

  SchoolsError({required this.message, this.error});

  factory SchoolsError.fromJson(Map<String, dynamic> json) {
    return SchoolsError(
      message: json['message'] ?? '',
      error: json['error'],
    );
  }
}

class SchoolsException implements Exception {
  final String message;
  final SchoolsError? error;

  SchoolsException(this.message, {this.error});

  @override
  String toString() => 'SchoolsException: $message';
}
