class Student {
  final String id;
  final String fullName;
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

  Student({
    required this.id,
    required this.fullName,
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
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      studentCode: json['studentCode'] ?? '',
      nationalId: json['nationalId'] ?? '',
      gender: json['gender'] ?? '',
      birthDate: json['birthDate'] ?? '',
      ageInOctober: json['ageInOctober'] ?? 0,
      address: json['address'] ?? '',
      medicalNotes: json['medicalNotes'] ?? '',
      status: json['status'] ?? '',
      avatar: json['avatar'],
      profileImage: json['profileImage'],
      image: json['image'],
      studentStatus: json['studentStatus'] != null && json['studentStatus'] is Map
          ? StudentStatus.fromJson(json['studentStatus'])
          : StudentStatus.fromJson({}),
      studentClass: json['class'] != null && json['class'] is Map
          ? StudentClass.fromJson(json['class'])
          : StudentClass.fromJson({}),
      parent: json['parent'] != null && json['parent'] is Map
          ? StudentParent.fromJson(json['parent'])
          : StudentParent.fromJson({}),
      schoolId: json['schoolId'] != null && json['schoolId'] is Map
          ? SchoolInfo.fromJson(json['schoolId'])
          : SchoolInfo.fromJson({}),
      stage: json['stage'] != null && json['stage'] is Map
          ? StageInfo.fromJson(json['stage'])
          : StageInfo.fromJson({'name': json['stage']?.toString() ?? 'N/A'}),
      grade: json['grade'] != null && json['grade'] is Map
          ? GradeInfo.fromJson(json['grade'])
          : GradeInfo.fromJson({
              '_id': json['grade']?.toString() ?? '',
              'name': 'N/A'
            }),
      section: json['section'] != null && json['section'] is Map
          ? SectionInfo.fromJson(json['section'])
          : SectionInfo.fromJson({'name': json['section']?.toString() ?? 'N/A'}),
      moodleUser: json['moodleUser'] != null
          ? MoodleUser.fromJson(json['moodleUser'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
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

  SchoolInfo({required this.id, required this.name});

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
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
