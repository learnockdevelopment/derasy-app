class LookupsResponse {
  final bool success;
  final LookupData data;

  LookupsResponse({required this.success, required this.data});

  factory LookupsResponse.fromJson(Map<String, dynamic> json) {
    return LookupsResponse(
      success: json['success'] ?? false,
      data: LookupData.fromJson(json['data'] ?? {}),
    );
  }
}

class LookupData {
  final List<LookupItem> schoolTypes;
  final List<LookupItem> genderPolicies;
  final List<LookupItem> religionTypes;
  final List<LookupItem> specialNeedsTypes;
  final LocationData locations;
  final List<FacilityItem> facilities;

  LookupData({
    required this.schoolTypes,
    required this.genderPolicies,
    required this.religionTypes,
    required this.specialNeedsTypes,
    required this.locations,
    required this.facilities,
  });

  factory LookupData.fromJson(Map<String, dynamic> json) {
    return LookupData(
      schoolTypes: (json['schoolTypes'] as List?)
              ?.map((e) => LookupItem.fromJson(e))
              .toList() ??
          [],
      genderPolicies: (json['genderPolicies'] as List?)
              ?.map((e) => LookupItem.fromJson(e))
              .toList() ??
          [],
      religionTypes: (json['religionTypes'] as List?)
              ?.map((e) => LookupItem.fromJson(e))
              .toList() ??
          [],
      specialNeedsTypes: (json['specialNeedsTypes'] as List?)
              ?.map((e) => LookupItem.fromJson(e))
              .toList() ??
          [],
      locations: LocationData.fromJson(json['locations'] ?? {}),
      facilities: (json['facilities'] as List?)
              ?.map((e) => FacilityItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class LookupItem {
  final String id;
  final String label;
  final String? labelEn;

  LookupItem({required this.id, required this.label, this.labelEn});

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      labelEn: json['labelEn']?.toString(),
    );
  }
}

class LocationData {
  final List<Governorate> governorates;
  final Map<String, List<Administration>> administrations;

  LocationData({required this.governorates, required this.administrations});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    final Map<String, List<Administration>> admins = {};
    if (json['administrations'] != null) {
      (json['administrations'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          admins[key] = value.map((e) => Administration.fromJson(e)).toList();
        }
      });
    }

    return LocationData(
      governorates: (json['governorates'] as List?)
              ?.map((e) => Governorate.fromJson(e))
              .toList() ??
          [],
      administrations: admins,
    );
  }
}

class Governorate {
  final String id;
  final String nameAr;
  final String nameEn;

  Governorate({required this.id, required this.nameAr, required this.nameEn});

  factory Governorate.fromJson(Map<String, dynamic> json) {
    return Governorate(
      id: json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
    );
  }
}

class Administration {
  final String id;
  final String nameAr;
  final String nameEn;

  Administration({required this.id, required this.nameAr, required this.nameEn});

  factory Administration.fromJson(Map<String, dynamic> json) {
    return Administration(
      id: json['id']?.toString() ?? '',
      nameAr: json['nameAr']?.toString() ?? '',
      nameEn: json['nameEn']?.toString() ?? '',
    );
  }
}

class FacilityItem {
  final String id;
  final String name;
  final String icon;
  final String type;

  FacilityItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  factory FacilityItem.fromJson(Map<String, dynamic> json) {
    return FacilityItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
    );
  }
}
