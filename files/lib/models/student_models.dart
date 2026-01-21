class Student {
  final String id;
  final String fullName;
  final String? arabicFullName;
  final String studentCode;
  final String nationalId;
  final String gender;
  final String birthDate;
  final int ageInOctober;
  final String address;
  final String medicalNotes;
  final String status;
  final String? avatar;
  final String? profileImage;
  final String? image;
  final StudentStatus studentStatus;
  final StudentClass studentClass;
  final StudentParent parent;
  final SchoolInfo schoolId;
  final StageInfo stage;
  final GradeInfo grade;
  final SectionInfo section;
  final MoodleUser? moodleUser;
  final String? nationality;
  final String? passport;
  final Map<String, dynamic>? specialNeeds;

  Student({
    required this.id,
    required this.fullName,
    this.arabicFullName,
    required this.studentCode,
    required this.nationalId,
    required this.gender,
    required this.birthDate,
    required this.ageInOctober,
    required this.address,
    required this.medicalNotes,
    required this.status,
    this.avatar,
    this.profileImage,
    this.image,
    required this.studentStatus,
    required this.studentClass,
    required this.parent,
    required this.schoolId,
    required this.stage,
    required this.grade,
    required this.section,
    this.moodleUser,
    this.nationality,
    this.passport,
    this.specialNeeds,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: _parseStringField(json['_id']) ?? '',
      fullName: _parseStringField(json['fullName']) ?? '',
      arabicFullName: _parseStringField(json['arabicFullName']),
      studentCode: _parseStringField(json['studentCode']) ?? '',
      nationalId: _parseStringField(json['nationalId']) ?? '',
      gender: _parseStringField(json['gender']) ?? '',
      birthDate: _parseStringField(json['birthDate']) ?? '',
      ageInOctober: json['ageInOctober'] is int
          ? json['ageInOctober'] as int
          : (json['ageInOctober'] is String
              ? int.tryParse(json['ageInOctober']) ?? 0
              : 0),
      address: _parseStringField(json['address']) ?? '',
      medicalNotes: _parseStringField(json['medicalNotes']) ?? '',
      status: _parseStringField(json['status']) ?? '',
      avatar: _parseStringField(json['avatar']),
      profileImage: _parseStringField(json['profileImage']),
      image: _parseStringField(json['image']),
      studentStatus: json['studentStatus'] != null && json['studentStatus'] is Map
          ? StudentStatus.fromJson(json['studentStatus'])
          : StudentStatus.fromJson({}),
      studentClass: json['class'] != null && json['class'] is Map
          ? _parseStudentClass(json['class'] as Map<String, dynamic>)
          : StudentClass.fromJson({}),
      parent: json['parent'] != null && json['parent'] is Map
          ? _parseParent(json['parent'] as Map<String, dynamic>)
          : StudentParent.fromJson({}),
      schoolId: json['schoolId'] != null && json['schoolId'] is Map
          ? _parseSchoolInfo(json['schoolId'] as Map<String, dynamic>)
          : SchoolInfo.fromJson({}),
      stage: json['stage'] != null && json['stage'] is Map
          ? _parseStageInfo(json['stage'] as Map<String, dynamic>)
          : StageInfo.fromJson({'name': json['stage']?.toString() ?? 'N/A'}),
      grade: json['grade'] != null && json['grade'] is Map
          ? _parseGradeInfo(json['grade'] as Map<String, dynamic>)
          : GradeInfo.fromJson({
              '_id': json['grade']?.toString() ?? '',
              'name': 'N/A'
            }),
      section: json['section'] != null && json['section'] is Map
          ? _parseSectionInfo(json['section'] as Map<String, dynamic>)
          : SectionInfo.fromJson({'name': json['section']?.toString() ?? 'N/A'}),
      moodleUser: json['moodleUser'] != null
          ? MoodleUser.fromJson(json['moodleUser'])
          : null,
      nationality: _parseStringField(json['nationality']),
      passport: _parseStringField(json['passport']),
      specialNeeds: json['specialNeeds'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['specialNeeds'])
          : null,
    );
  }
 
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'arabicFullName': arabicFullName,
      'studentCode': studentCode,
      'nationalId': nationalId,
      'gender': gender,
      'birthDate': birthDate,
      'ageInOctober': ageInOctober,
      'address': address,
      'medicalNotes': medicalNotes,
      'status': status,
      'avatar': avatar,
      'profileImage': profileImage,
      'image': image,
      'studentStatus': studentStatus.toJson(),
      'class': studentClass.toJson(),
      'parent': parent.toJson(),
      'schoolId': schoolId.toJson(),
      'stage': stage.toJson(),
      'grade': grade.toJson(),
      'section': section.toJson(),
      'moodleUser': moodleUser?.toJson(),
    };
  }

  // Helper method to parse parent which can be either direct or populated via parent.user
  static StudentParent _parseParent(Map<String, dynamic> parentJson) {
    // If parent has a nested 'user' field (populated), extract from there
    if (parentJson.containsKey('user') && parentJson['user'] is Map) {
      final userData = parentJson['user'] as Map<String, dynamic>;
      return StudentParent(
        id: userData['_id'] ?? userData['id'] ?? '',
        name: userData['fullName'] ?? userData['name'] ?? '',
        phone: userData['phone'] ?? '',
      );
    }
    // Otherwise, parse directly
    return StudentParent.fromJson(parentJson);
  }

  // Helper method to parse school info (handles nameAr if needed)
  static SchoolInfo _parseSchoolInfo(Map<String, dynamic> schoolJson) {
    // Use nameAr if available, otherwise use name
    final name = schoolJson['nameAr'] ?? schoolJson['name'] ?? '';
    return SchoolInfo(
      id: schoolJson['_id'] ?? schoolJson['id'] ?? '',
      name: name,
      educationSystem: schoolJson['educationSystem']?.toString(),
    );
  }

  // Helper method to parse stage info (handles nameAr if needed)
  static StageInfo _parseStageInfo(Map<String, dynamic> stageJson) {
    final name = stageJson['nameAr'] ?? stageJson['name'] ?? 'N/A';
    return StageInfo(
      id: stageJson['_id'] ?? stageJson['id'] ?? '',
      name: name,
    );
  }

  // Helper method to parse grade info (handles nameAr if needed)
  static GradeInfo _parseGradeInfo(Map<String, dynamic> gradeJson) {
    final name = gradeJson['nameAr'] ?? gradeJson['name'] ?? 'N/A';
    return GradeInfo(
      id: gradeJson['_id'] ?? gradeJson['id'] ?? '',
      name: name,
    );
  }

  // Helper method to parse section info (handles nameAr if needed)
  static SectionInfo _parseSectionInfo(Map<String, dynamic> sectionJson) {
    final name = sectionJson['nameAr'] ?? sectionJson['name'] ?? 'N/A';
    return SectionInfo(
      id: sectionJson['_id'] ?? sectionJson['id'] ?? '',
      name: name,
    );
  }

  // Helper method to parse student class (handles nameAr if needed)
  static StudentClass _parseStudentClass(Map<String, dynamic> classJson) {
    final name = classJson['nameAr'] ?? classJson['name'] ?? 'N/A';
    return StudentClass(
      id: classJson['_id'] ?? classJson['id'] ?? '',
      name: name,
    );
  }

  // Helper method to safely parse string fields that might be Maps or other types
  static String? _parseStringField(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      // Try to extract a meaningful string from the map
      if (value.containsKey('name')) return value['name']?.toString();
      if (value.containsKey('value')) return value['value']?.toString();
      if (value.containsKey('text')) return value['text']?.toString();
      return null;
    }
    // For other types, try to convert to string
    try {
      return value.toString();
    } catch (e) {
      return null;
    }
  }
}

class StudentStatus {
  final String status;

  StudentStatus({required this.status});

  factory StudentStatus.fromJson(Map<String, dynamic> json) {
    return StudentStatus(
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
    };
  }
}

class StudentClass {
  final String id;
  final String name;

  StudentClass({required this.id, required this.name});

  factory StudentClass.fromJson(Map<String, dynamic> json) {
    return StudentClass(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class StudentParent {
  final String id;
  final String name;
  final String phone;

  StudentParent({required this.id, required this.name, required this.phone});

  factory StudentParent.fromJson(Map<String, dynamic> json) {
    return StudentParent(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'phone': phone,
    };
  }
}

class SchoolInfo {
  final String id;
  final String name;
  final String? educationSystem;

  SchoolInfo({required this.id, required this.name, this.educationSystem});

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      educationSystem: json['educationSystem']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      if (educationSystem != null) 'educationSystem': educationSystem,
    };
  }
}

class StageInfo {
  final String id;
  final String name;

  StageInfo({required this.id, required this.name});

  factory StageInfo.fromJson(Map<String, dynamic> json) {
    return StageInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class GradeInfo {
  final String id;
  final String name;

  GradeInfo({required this.id, required this.name});

  factory GradeInfo.fromJson(Map<String, dynamic> json) {
    return GradeInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class SectionInfo {
  final String id;
  final String name;

  SectionInfo({required this.id, required this.name});

  factory SectionInfo.fromJson(Map<String, dynamic> json) {
    return SectionInfo(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }
}

class MoodleUser {
  final String id;
  final String username;

  MoodleUser({required this.id, required this.username});

  factory MoodleUser.fromJson(Map<String, dynamic> json) {
    return MoodleUser(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
    };
  }
}

class StudentsResponse {
  final bool success;
  final String message;
  final List<Student> students;

  StudentsResponse({
    required this.success,
    required this.message,
    required this.students,
  });

  factory StudentsResponse.fromJson(Map<String, dynamic> json) {
    return StudentsResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      students: (json['students'] as List<dynamic>?)
              ?.map((student) => Student.fromJson(student))
              .toList() ??
          [],
    );
  }
}

class StudentsError {
  final String message;
  final String? error;

  StudentsError({required this.message, this.error});

  factory StudentsError.fromJson(Map<String, dynamic> json) {
    return StudentsError(
      message: json['message'] ?? '',
      error: json['error'],
    );
  }
}

class StudentsException implements Exception {
  final String message;
  final StudentsError? error;

  StudentsException(this.message, {this.error});

  @override
  String toString() => 'StudentsException: $message';
}

// Add Child Request Models
class AddChildRequest {
  final String? arabicFullName;
  final String? fullName;
  final String gender;
  final String birthDate;
  final String? desiredGrade;
  final String? nationalId;
  final String? nationality;
  final String? religion;
  final String? birthPlace;
  final String? currentSchool;
  final String? currentGrade;
  final String? schoolId;
  final int? ageInOctober;
  final Map<String, dynamic>? birthCertificate;

  AddChildRequest({
    this.arabicFullName,
    this.fullName,
    required this.gender,
    required this.birthDate,
    this.desiredGrade,
    this.nationalId,
    this.nationality,
    this.religion,
    this.birthPlace,
    this.currentSchool,
    this.currentGrade,
    this.schoolId,
    this.ageInOctober,
    this.birthCertificate,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'gender': gender,
      'birthDate': birthDate,
    };
    
    if (arabicFullName != null && arabicFullName!.isNotEmpty) {
      json['arabicFullName'] = arabicFullName;
    }
    if (fullName != null && fullName!.isNotEmpty) {
      json['fullName'] = fullName;
    }
    if (desiredGrade != null && desiredGrade!.isNotEmpty) {
      json['desiredGrade'] = desiredGrade;
    }
    if (nationalId != null && nationalId!.isNotEmpty) {
      json['nationalId'] = nationalId;
    }
    if (nationality != null && nationality!.isNotEmpty) {
      json['nationality'] = nationality;
    }
    if (religion != null && religion!.isNotEmpty) {
      json['religion'] = religion;
    }
    if (birthPlace != null && birthPlace!.isNotEmpty) {
      json['birthPlace'] = birthPlace;
    }
    if (currentSchool != null && currentSchool!.isNotEmpty) {
      json['currentSchool'] = currentSchool;
    }
    if (currentGrade != null && currentGrade!.isNotEmpty) {
      json['currentGrade'] = currentGrade;
    }
    if (schoolId != null && schoolId!.isNotEmpty) {
      json['schoolId'] = schoolId;
    }
    // Add ageInOctober: 163 if student is not added to a school
    if (schoolId == null || schoolId!.isEmpty) {
      json['ageInOctober'] = ageInOctober ?? 163;
    } else if (ageInOctober != null) {
      json['ageInOctober'] = ageInOctober;
    }
    if (birthCertificate != null) {
      json['birthCertificate'] = birthCertificate;
    }
    
    return json;
  }
}

class AddChildrenResponse {
  final String message;
  final List<Student> children;

  AddChildrenResponse({
    required this.message,
    required this.children,
  });

  factory AddChildrenResponse.fromJson(Map<String, dynamic> json) {
    return AddChildrenResponse(
      message: json['message']?.toString() ?? 'Child(ren) added successfully',
      children: (json['children'] as List<dynamic>?)
              ?.map((child) => Student.fromJson(child as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

// Birth Certificate Extraction Models
class BirthCertificateExtractionResponse {
  final bool success;
  final ExtractedData extractedData;
  final String? extractedText;
  final String? documentType;

  BirthCertificateExtractionResponse({
    required this.success,
    required this.extractedData,
    this.extractedText,
    this.documentType,
  });

  factory BirthCertificateExtractionResponse.fromJson(Map<String, dynamic> json) {
    // Handle success field - it can be bool or string "true"/"false"
    bool successValue = false;
    if (json['success'] != null) {
      if (json['success'] is bool) {
        successValue = json['success'] as bool;
      } else if (json['success'] is String) {
        successValue = json['success'].toString().toLowerCase() == 'true';
      } else {
        successValue = json['success'] == true || json['success'] == 1;
      }
    }
    
    print('📄 [MODEL] Parsing success field: ${json['success']} (type: ${json['success'].runtimeType}) -> $successValue');
    
    return BirthCertificateExtractionResponse(
      success: successValue,
      extractedData: ExtractedData.fromJson(json['extractedData'] as Map<String, dynamic>),
      extractedText: json['extractedText']?.toString(),
      documentType: json['documentType']?.toString(),
    );
  }
}

class ExtractedData {
  final String? arabicFullName;
  final String? fullName;
  final String? arabicFirstName;
  final String? arabicLastName;
  final String? firstName;
  final String? lastName;
  final String? nationalId;
  final String? birthDate;
  final String? gender;
  final String? nationality;
  final String? birthPlace;
  final String? religion;
  final AgeInComingOctober? ageInComingOctober;
  final String? fatherNationalId;
  final String? motherNationalId;
  final List<String>? parentNationalIds;
  final BirthCertificateImage? birthCertificateImage;
  final NationalIdImages? nationalIdImages;
  final String? address;

  ExtractedData({
    this.arabicFullName,
    this.fullName,
    this.arabicFirstName,
    this.arabicLastName,
    this.firstName,
    this.lastName,
    this.nationalId,
    this.birthDate,
    this.gender,
    this.nationality,
    this.birthPlace,
    this.religion,
    this.ageInComingOctober,
    this.fatherNationalId,
    this.motherNationalId,
    this.parentNationalIds,
    this.birthCertificateImage,
    this.nationalIdImages,
    this.address,
  });

  factory ExtractedData.fromJson(Map<String, dynamic> json) {
    return ExtractedData(
      arabicFullName: json['arabicFullName']?.toString(),
      fullName: json['fullName']?.toString(),
      arabicFirstName: json['arabicFirstName']?.toString(),
      arabicLastName: json['arabicLastName']?.toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      nationalId: json['nationalId']?.toString(),
      birthDate: json['birthDate']?.toString(),
      gender: json['gender']?.toString(),
      nationality: json['nationality']?.toString(),
      birthPlace: json['birthPlace']?.toString(),
      religion: json['religion']?.toString(),
      ageInComingOctober: json['ageInComingOctober'] != null
          ? AgeInComingOctober.fromJson(json['ageInComingOctober'] as Map<String, dynamic>)
          : null,
      fatherNationalId: json['fatherNationalId']?.toString(),
      motherNationalId: json['motherNationalId']?.toString(),
      parentNationalIds: json['parentNationalIds'] != null
          ? (json['parentNationalIds'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      birthCertificateImage: json['birthCertificateImage'] != null
          ? BirthCertificateImage.fromJson(json['birthCertificateImage'] as Map<String, dynamic>)
          : null,
      nationalIdImages: json['nationalIdImages'] != null
          ? NationalIdImages.fromJson(json['nationalIdImages'] as Map<String, dynamic>)
          : null,
      address: json['address']?.toString(),
    );
  }
}

class AgeInComingOctober {
  final int years;
  final int months;
  final int totalMonths;
  final String targetDate;
  final String formatted;

  AgeInComingOctober({
    required this.years,
    required this.months,
    required this.totalMonths,
    required this.targetDate,
    required this.formatted,
  });

  factory AgeInComingOctober.fromJson(Map<String, dynamic> json) {
    return AgeInComingOctober(
      years: json['years'] ?? 0,
      months: json['months'] ?? 0,
      totalMonths: json['totalMonths'] ?? 0,
      targetDate: json['targetDate']?.toString() ?? '',
      formatted: json['formatted']?.toString() ?? '',
    );
  }
}

class BirthCertificateImage {
  final String data;
  final String mimeType;
  final int size;
  final String name;

  BirthCertificateImage({
    required this.data,
    required this.mimeType,
    required this.size,
    required this.name,
  });

  factory BirthCertificateImage.fromJson(Map<String, dynamic> json) {
    return BirthCertificateImage(
      data: json['data']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? 'image/jpeg',
      size: json['size'] ?? 0,
      name: json['name']?.toString() ?? 'birth_certificate.jpg',
    );
  }
}

class BirthCertificateExtractionException implements Exception {
  final String message;
  final bool canContinue;

  BirthCertificateExtractionException(this.message, {this.canContinue = false});

  @override
  String toString() => 'BirthCertificateExtractionException: $message';
}

// National ID Extraction Models
class NationalIdExtractionResponse {
  final bool success;
  final ExtractedData extractedData;
  final String? extractedText;
  final String documentType;

  NationalIdExtractionResponse({
    required this.success,
    required this.extractedData,
    this.extractedText,
    required this.documentType,
  });

  factory NationalIdExtractionResponse.fromJson(Map<String, dynamic> json) {
    // Handle success field - it can be bool or string "true"/"false"
    bool successValue = false;
    if (json['success'] != null) {
      if (json['success'] is bool) {
        successValue = json['success'] as bool;
      } else if (json['success'] is String) {
        successValue = json['success'].toString().toLowerCase() == 'true';
      } else {
        successValue = json['success'] == true || json['success'] == 1;
      }
    }
    
    print('🆔 [MODEL] Parsing National ID extraction response: ${json['success']} (type: ${json['success'].runtimeType}) -> $successValue');
    
    return NationalIdExtractionResponse(
      success: successValue,
      extractedData: ExtractedData.fromJson(json['extractedData'] as Map<String, dynamic>),
      extractedText: json['extractedText']?.toString(),
      documentType: json['documentType']?.toString() ?? 'national_id',
    );
  }
}

class NationalIdImages {
  final NationalIdImage? front;
  final NationalIdImage? back;

  NationalIdImages({
    this.front,
    this.back,
  });

  factory NationalIdImages.fromJson(Map<String, dynamic> json) {
    return NationalIdImages(
      front: json['front'] != null
          ? NationalIdImage.fromJson(json['front'] as Map<String, dynamic>)
          : null,
      back: json['back'] != null
          ? NationalIdImage.fromJson(json['back'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (front != null) 'front': front!.toJson(),
      if (back != null) 'back': back!.toJson(),
    };
  }
}

class NationalIdImage {
  final String url;
  final String publicId;
  final DateTime uploadedAt;

  NationalIdImage({
    required this.url,
    required this.publicId,
    required this.uploadedAt,
  });

  factory NationalIdImage.fromJson(Map<String, dynamic> json) {
    return NationalIdImage(
      url: json['url']?.toString() ?? '',
      publicId: json['publicId']?.toString() ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}

class NationalIdExtractionException implements Exception {
  final String message;
  final bool canContinue;

  NationalIdExtractionException(this.message, {this.canContinue = false});

  @override
  String toString() => 'NationalIdExtractionException: $message';
}

// Request Models
class AddStudentRequest {
  final String fullName;
  final String nationalId;
  final String nationality;
  final String gender;
  final String birthDate;
  final String ageInOctober;
  final String address;
  final String medicalNotes;
  final String status;
  final String? passport;
  final String? grade;

  AddStudentRequest({
    required this.fullName,
    required this.nationalId,
    required this.nationality,
    required this.gender,
    required this.birthDate,
    required this.ageInOctober,
    required this.address,
    required this.medicalNotes,
    required this.status,
    this.passport,
    this.grade,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'nationalId': nationalId,
      'nationality': nationality,
      'gender': gender,
      'birthDate': birthDate,
      'ageInOctober': ageInOctober,
      'address': address,
      'medicalNotes': medicalNotes,
      'status': status,
      if (passport != null) 'passport': passport,
      if (grade != null) 'grade': grade,
    };
  }
}

class UpdateStudentRequest {
  final String fullName;
  final String studentCode;
  final String nationalId;
  final String nationality;
  final String gender;
  final String birthDate;
  final String ageInOctober;
  final String address;
  final String medicalNotes;
  final String status;
  final String? passport;
  final String? grade;
  final String moodleUsername;
  final String moodlePassword;
  final String parentName;
  final String parentPhone1;
  final String parentEmail;
  final String parentRelation;
  final String parentNationalId;
  final String parentName2;
  final String parentPhone2;
  final String parentEmail2;
  final String parentRelation2;
  final String parentNationalId2;

  UpdateStudentRequest({
    required this.fullName,
    required this.studentCode,
    required this.nationalId,
    required this.nationality,
    required this.gender,
    required this.birthDate,
    required this.ageInOctober,
    required this.address,
    required this.medicalNotes,
    required this.status,
    this.passport,
    this.grade,
    required this.moodleUsername,
    required this.moodlePassword,
    required this.parentName,
    required this.parentPhone1,
    required this.parentEmail,
    required this.parentRelation,
    required this.parentNationalId,
    required this.parentName2,
    required this.parentPhone2,
    required this.parentEmail2,
    required this.parentRelation2,
    required this.parentNationalId2,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'studentCode': studentCode,
      'nationalId': nationalId,
      'nationality': nationality,
      'gender': gender,
      'birthDate': birthDate,
      'ageInOctober': ageInOctober,
      'address': address,
      'medicalNotes': medicalNotes,
      'status': status,
      if (passport != null) 'passport': passport,
      if (grade != null) 'grade': grade,
      'moodleUsername': moodleUsername,
      'moodlePassword': moodlePassword,
      'parentName': parentName,
      'parentPhone1': parentPhone1,
      'parentEmail': parentEmail,
      'parentRelation': parentRelation,
      'parentNationalId': parentNationalId,
      'parentName2': parentName2,
      'parentPhone2': parentPhone2,
      'parentEmail2': parentEmail2,
      'parentRelation2': parentRelation2,
      'parentNationalId2': parentNationalId2,
    };
  }
}

class StudentResponse {
  final bool success;
  final String message;
  final Student? student;

  StudentResponse({
    required this.success,
    required this.message,
    this.student,
  });

  factory StudentResponse.fromJson(Map<String, dynamic> json) {
    return StudentResponse(
      success: json['success'] ?? true, // Default to true if not present
      message: json['message'] ?? 'Operation completed successfully',
      student:
          json['student'] != null ? Student.fromJson(json['student']) : null,
    );
  }
}

// OTP Models
class SendOtpRequest {
  final String childId;
  final String guardianUserId;
  final String phoneNumber;

  SendOtpRequest({
    required this.childId,
    required this.guardianUserId,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'guardianUserId': guardianUserId,
      'phoneNumber': phoneNumber,
    };
  }
}

class VerifyOtpRequest {
  final String childId;
  final String guardianUserId;
  final String otp;

  VerifyOtpRequest({
    required this.childId,
    required this.guardianUserId,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'guardianUserId': guardianUserId,
      'otp': otp,
    };
  }
}

class VerifyOtpResponse {
  final String message;
  final Student child;

  VerifyOtpResponse({
    required this.message,
    required this.child,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      message: json['message']?.toString() ?? '',
      child: Student.fromJson(json['child'] as Map<String, dynamic>),
    );
  }
}

// Non Egyptian Request Models
class NonEgyptianRequest {
  final String id;
  final String fullName;
  final String? arabicFullName;
  final DateTime birthDate;
  final String gender;
  final String nationality;
  final String status;
  final RequestPassport parentPassport;
  final RequestPassport childPassport;
  final DateTime requestedAt;
  final String? rejectionReason;
  final SchoolInfo? schoolId;
  final GradeInfo? grade;

  NonEgyptianRequest({
    required this.id,
    required this.fullName,
    this.arabicFullName,
    required this.birthDate,
    required this.gender,
    required this.nationality,
    required this.status,
    required this.parentPassport,
    required this.childPassport,
    required this.requestedAt,
    this.rejectionReason,
    this.schoolId,
    this.grade,
  });

  factory NonEgyptianRequest.fromJson(Map<String, dynamic> json) {
    return NonEgyptianRequest(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      arabicFullName: json['arabicFullName'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : DateTime.now(),
      gender: json['gender'] ?? '',
      nationality: json['nationality'] ?? 'Non-Egyptian',
      status: json['status'] ?? 'pending',
      parentPassport: RequestPassport.fromJson(json['parentPassport'] ?? {}),
      childPassport: RequestPassport.fromJson(json['childPassport'] ?? {}),
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : DateTime.now(),
      rejectionReason: json['rejectionReason'],
      schoolId: json['schoolId'] != null && json['schoolId'] is Map
          ? SchoolInfo.fromJson(json['schoolId'] as Map<String, dynamic>)
          : null,
      grade: json['grade'] != null && json['grade'] is Map
          ? GradeInfo.fromJson(json['grade'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RequestPassport {
  final String url;
  final DateTime? uploadedAt;

  RequestPassport({
    required this.url,
    this.uploadedAt,
  });

  factory RequestPassport.fromJson(Map<String, dynamic> json) {
    return RequestPassport(
      url: json['url'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : null,
    );
  }
}

class NonEgyptianRequestsResponse {
  final List<NonEgyptianRequest> requests;
  final int count;

  NonEgyptianRequestsResponse({
    required this.requests,
    required this.count,
  });

  factory NonEgyptianRequestsResponse.fromJson(Map<String, dynamic> json) {
    final requestsList = (json['requests'] as List<dynamic>?)
            ?.map((e) => NonEgyptianRequest.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return NonEgyptianRequestsResponse(
      requests: requestsList,
      count: json['count'] ?? requestsList.length,
    );
  }
}
