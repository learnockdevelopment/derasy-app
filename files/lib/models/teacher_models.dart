class TeacherModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? employeeId;
  final List<TeacherSubject> subjects;
  final List<TeacherGradeLevel> gradeLevels;
  final List<TeacherClassroom> classes;
  final List<String> qualifications;
  final int experienceYears;
  final double salary;
  final String employmentType;
  final bool isActive;
  final List<TimetableItem> timetable;

  TeacherModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.employeeId,
    required this.subjects,
    required this.gradeLevels,
    required this.classes,
    required this.qualifications,
    required this.experienceYears,
    required this.salary,
    required this.employmentType,
    required this.isActive,
    required this.timetable,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    final tData = json['teacher'] as Map<String, dynamic>? ?? {};
    return TeacherModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'teacher',
      employeeId: tData['employeeId']?.toString(),
      subjects: (tData['subjects'] as List? ?? [])
          .map((s) => TeacherSubject.fromJson(s as Map<String, dynamic>))
          .toList(),
      gradeLevels: (tData['gradeLevels'] as List? ?? [])
          .map((g) => TeacherGradeLevel.fromJson(g as Map<String, dynamic>))
          .toList(),
      classes: (tData['class'] as List? ?? tData['classes'] as List? ?? [])
          .map((c) => TeacherClassroom.fromJson(c as Map<String, dynamic>))
          .toList(),
      qualifications: (tData['qualifications'] as List? ?? [])
          .map((q) => q.toString())
          .toList(),
      experienceYears: tData['experienceYears'] as int? ?? 0,
      salary: (tData['salary'] as num? ?? 0.0).toDouble(),
      employmentType: tData['employmentType']?.toString() ?? 'full_time',
      isActive: tData['isActive'] as bool? ?? true,
      timetable: (tData['timetable'] as List? ?? [])
          .map((t) => TimetableItem.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'teacher': {
        'employeeId': employeeId,
        'subjects': subjects.map((s) => s.toJson()).toList(),
        'gradeLevels': gradeLevels.map((g) => g.toJson()).toList(),
        'classes': classes.map((c) => c.toJson()).toList(),
        'qualifications': qualifications,
        'experienceYears': experienceYears,
        'salary': salary,
        'employmentType': employmentType,
        'isActive': isActive,
        'timetable': timetable.map((t) => t.toJson()).toList(),
      }
    };
  }
}

class TeacherSubject {
  final String id;
  final String name;
  final String? gradeName;

  TeacherSubject({required this.id, required this.name, this.gradeName});

  factory TeacherSubject.fromJson(Map<String, dynamic> json) {
    return TeacherSubject(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gradeName: (json['grade'] as Map?)?['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TeacherGradeLevel {
  final String id;
  final String name;

  TeacherGradeLevel({required this.id, required this.name});

  factory TeacherGradeLevel.fromJson(Map<String, dynamic> json) {
    return TeacherGradeLevel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TeacherClassroom {
  final String id;
  final String name;
  final String? gradeName;

  TeacherClassroom({required this.id, required this.name, this.gradeName});

  factory TeacherClassroom.fromJson(Map<String, dynamic> json) {
    return TeacherClassroom(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gradeName: (json['grade'] as Map?)?['name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TimetableItem {
  final String day;
  final String subject;
  final String gradeLevel;
  final String startTime;
  final String endTime;

  TimetableItem({
    required this.day,
    required this.subject,
    required this.gradeLevel,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableItem.fromJson(Map<String, dynamic> json) {
    return TimetableItem(
      day: json['day']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      gradeLevel: json['gradeLevel']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'subject': subject,
      'gradeLevel': gradeLevel,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}

class TeacherJob {
  final String? id;
  final String title;
  final String department;
  final double salary;
  final String employmentType;
  final List<String> requirements;
  final String description;
  final String datePosted;

  TeacherJob({
    this.id,
    required this.title,
    required this.department,
    required this.salary,
    required this.employmentType,
    required this.requirements,
    required this.description,
    required this.datePosted,
  });

  factory TeacherJob.fromJson(Map<String, dynamic> json) {
    return TeacherJob(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      title: json['title']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      salary: (json['salary'] as num? ?? 0.0).toDouble(),
      employmentType: json['employmentType']?.toString() ?? 'full_time',
      requirements: (json['requirements'] as List? ?? []).map((r) => r.toString()).toList(),
      description: json['description']?.toString() ?? '',
      datePosted: json['datePosted']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'department': department,
      'salary': salary,
      'employmentType': employmentType,
      'requirements': requirements,
      'description': description,
      'datePosted': datePosted,
    };
  }
}
