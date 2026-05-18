import '../services/user_storage_service.dart';

class TeacherSkill {
  final String id;
  final String name;
  final String category;

  TeacherSkill({
    required this.id,
    required this.name,
    required this.category,
  });

  factory TeacherSkill.fromJson(Map<String, dynamic> json) {
    return TeacherSkill(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }
}

class TeacherCertificate {
  final String name;
  final String issuer;
  final String date;

  TeacherCertificate({
    required this.name,
    required this.issuer,
    required this.date,
  });

  factory TeacherCertificate.fromJson(Map<String, dynamic> json) {
    return TeacherCertificate(
      name: json['name']?.toString() ?? '',
      issuer: json['issuer']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}

class TeacherWorkExperience {
  final String company;
  final String role;
  final String startDate;
  final String endDate;
  final bool isCurrent;

  TeacherWorkExperience({
    required this.company,
    required this.role,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });

  factory TeacherWorkExperience.fromJson(Map<String, dynamic> json) {
    return TeacherWorkExperience(
      company: json['company']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }
}

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

  // New CV Profile Builder properties
  final String headline;
  final String bio;
  final List<TeacherSkill> skills;
  final List<String> languages;
  final List<TeacherCertificate> certificates;
  final List<TeacherWorkExperience> workExperience;

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
    required this.headline,
    required this.bio,
    required this.skills,
    required this.languages,
    required this.certificates,
    required this.workExperience,
  });

  bool get hasCv => qualifications.isNotEmpty || experienceYears > 0 || salary > 0 || headline.isNotEmpty || bio.isNotEmpty || skills.isNotEmpty || workExperience.isNotEmpty;

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    // If the top-level json contains key 'profile', we parse from 'profile'!
    final profileData = json['profile'] as Map<String, dynamic>? ?? json;
    final tData = profileData['teacher'] as Map<String, dynamic>? ?? {};
    
    // Resiliently parse qualifications list
    final qualificationsList = <String>[];
    final rawQualifications = profileData['qualifications'] ?? tData['qualifications'];
    if (rawQualifications is List) {
      for (final q in rawQualifications) {
        if (q != null) {
          qualificationsList.add(q.toString());
        }
      }
    }
        
    final expYears = profileData['experienceYears'] as int? 
        ?? tData['experienceYears'] as int? 
        ?? 0;
        
    final sal = profileData['salary'] as num? 
        ?? tData['salary'] as num? 
        ?? 0.0;

    final empType = profileData['employmentType']?.toString() 
        ?? tData['employmentType']?.toString() 
        ?? 'full_time';

    final active = profileData['isActive'] as bool? 
        ?? tData['isActive'] as bool? 
        ?? true;

    // Add support for the new profile attributes!
    final headlineVal = profileData['headline']?.toString() ?? '';
    final bioVal = profileData['bio']?.toString() ?? '';
    
    // Bulletproof parsing of skills list
    final skillsList = <TeacherSkill>[];
    final rawSkills = profileData['skills'];
    if (rawSkills is List) {
      for (final s in rawSkills) {
        if (s is Map) {
          skillsList.add(TeacherSkill.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    // Bulletproof parsing of languages list
    final languagesList = <String>[];
    final rawLanguages = profileData['languages'];
    if (rawLanguages is List) {
      for (final l in rawLanguages) {
        if (l != null) {
          languagesList.add(l.toString());
        }
      }
    }

    // Bulletproof parsing of certificates list
    final certsList = <TeacherCertificate>[];
    final rawCerts = profileData['certificates'];
    if (rawCerts is List) {
      for (final c in rawCerts) {
        if (c is Map) {
          certsList.add(TeacherCertificate.fromJson(Map<String, dynamic>.from(c)));
        }
      }
    }

    // Bulletproof parsing of workExperience list
    final workExpList = <TeacherWorkExperience>[];
    final rawWorkExp = profileData['workExperience'];
    if (rawWorkExp is List) {
      for (final w in rawWorkExp) {
        if (w is Map) {
          workExpList.add(TeacherWorkExperience.fromJson(Map<String, dynamic>.from(w)));
        }
      }
    }

    return TeacherModel(
      id: profileData['_id']?.toString() ?? profileData['id']?.toString() ?? '',
      name: (profileData['name']?.toString() ?? json['name']?.toString() ?? '').isNotEmpty 
          ? (profileData['name']?.toString() ?? json['name']?.toString() ?? '')
          : (UserStorageService.getCurrentUser()?.name ?? ''),
      email: (profileData['email']?.toString() ?? json['email']?.toString() ?? '').isNotEmpty 
          ? (profileData['email']?.toString() ?? json['email']?.toString() ?? '')
          : (UserStorageService.getCurrentUser()?.email ?? ''),
      role: profileData['role']?.toString() ?? json['role']?.toString() ?? 'teacher',
      employeeId: tData['employeeId']?.toString() ?? profileData['employeeId']?.toString(),
      subjects: (tData['subjects'] as List? ?? profileData['subjects'] as List? ?? [])
          .map((s) => TeacherSubject.fromJson(s as Map<String, dynamic>))
          .toList(),
      gradeLevels: (tData['gradeLevels'] as List? ?? profileData['gradeLevels'] as List? ?? [])
          .map((g) => TeacherGradeLevel.fromJson(g as Map<String, dynamic>))
          .toList(),
      classes: (tData['class'] as List? ?? tData['classes'] as List? ?? profileData['class'] as List? ?? profileData['classes'] as List? ?? [])
          .map((c) => TeacherClassroom.fromJson(c as Map<String, dynamic>))
          .toList(),
      qualifications: qualificationsList,
      experienceYears: expYears,
      salary: sal.toDouble(),
      employmentType: empType,
      isActive: active,
      timetable: (tData['timetable'] as List? ?? profileData['timetable'] as List? ?? [])
          .map((t) => TimetableItem.fromJson(t as Map<String, dynamic>))
          .toList(),
      headline: headlineVal,
      bio: bioVal,
      skills: skillsList,
      languages: languagesList,
      certificates: certsList,
      workExperience: workExpList,
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
  
  // New API fields
  final double? salaryMin;
  final double? salaryMax;
  final int? experienceRequired;
  final String? slug;

  TeacherJob({
    this.id,
    required this.title,
    required this.department,
    required this.salary,
    required this.employmentType,
    required this.requirements,
    required this.description,
    required this.datePosted,
    this.salaryMin,
    this.salaryMax,
    this.experienceRequired,
    this.slug,
  });

  factory TeacherJob.fromJson(Map<String, dynamic> json) {
    final sMin = (json['salaryMin'] as num?)?.toDouble();
    final sMax = (json['salaryMax'] as num?)?.toDouble();
    final exp = json['experienceRequired'] as int?;
    
    // UI Fallbacks
    final double salaryVal = sMin ?? (json['salary'] as num? ?? 0.0).toDouble();
    final String descVal = json['description']?.toString() ?? 'No description provided';
    final reqRaw = json['requirements'];
    List<String> reqList = [];
    if (reqRaw is List) {
      reqList = reqRaw.map((r) => r.toString()).toList();
    } else if (reqRaw is String) {
      if (reqRaw.contains(',')) {
        reqList = reqRaw.split(',').map((r) => r.trim()).toList();
      } else if (reqRaw.contains('\n')) {
        reqList = reqRaw.split('\n').map((r) => r.trim()).toList();
      } else if (reqRaw.isNotEmpty) {
        reqList = [reqRaw];
      }
    }
    final String deptVal = json['department']?.toString() ?? 'General';
    final String dateVal = json['createdAt']?.toString() ?? json['datePosted']?.toString() ?? '';

    return TeacherJob(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      title: json['title']?.toString() ?? '',
      department: deptVal,
      salary: salaryVal,
      employmentType: json['employmentType']?.toString() ?? 'full_time',
      requirements: reqList,
      description: descVal,
      datePosted: dateVal.length >= 10 ? dateVal.substring(0, 10) : dateVal,
      salaryMin: sMin,
      salaryMax: sMax,
      experienceRequired: exp,
      slug: json['slug']?.toString(),
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
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      if (experienceRequired != null) 'experienceRequired': experienceRequired,
      if (slug != null) 'slug': slug,
    };
  }
}

class TeacherInterview {
  final String date;
  final String time;
  final String type;
  final String meetingLink;
  final String notes;

  TeacherInterview({
    required this.date,
    required this.time,
    required this.type,
    required this.meetingLink,
    required this.notes,
  });

  factory TeacherInterview.fromJson(Map<String, dynamic> json) {
    return TeacherInterview(
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      meetingLink: json['meetingLink']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }
}

class TeacherJobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String slug;
  final String status;
  final double progress;
  final String appliedDate;
  final String schoolName;
  final double salary;
  final TeacherInterview? interview;

  TeacherJobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.slug,
    required this.status,
    required this.progress,
    required this.appliedDate,
    required this.schoolName,
    required this.salary,
    this.interview,
  });

  factory TeacherJobApplication.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final jobData = json['jobId'] as Map<String, dynamic>? ?? json['job'] as Map<String, dynamic>? ?? {};
    
    final jobIdVal = jobData['_id']?.toString() ?? jobData['id']?.toString() ?? '';
    final jobTitleVal = jobData['title']?.toString() ?? 'Job Opportunity';
    final slugVal = jobData['slug']?.toString() ?? '';
    
    final statusVal = json['status']?.toString() ?? 'Applied';
    
    double progress = 0.25;
    if (statusVal.toLowerCase().contains('interview')) {
      progress = 0.50;
    } else if (statusVal.toLowerCase().contains('shortlist')) {
      progress = 0.75;
    } else if (statusVal.toLowerCase().contains('accept') || statusVal.toLowerCase().contains('hire') || statusVal.toLowerCase().contains('success')) {
      progress = 1.0;
    } else if (statusVal.toLowerCase().contains('reject') || statusVal.toLowerCase().contains('fail')) {
      progress = 1.0;
    }
    
    final schoolData = json['school'] as Map<String, dynamic>? ?? jobData['school'] as Map<String, dynamic>? ?? {};
    final schoolNameVal = json['schoolName']?.toString() ?? schoolData['name']?.toString() ?? 'Premium School';
    final salaryVal = (json['salary'] as num? ?? jobData['salary'] as num? ?? jobData['salaryMin'] as num? ?? 0.0).toDouble();

    final appliedVal = json['createdAt']?.toString() ?? json['appliedDate']?.toString() ?? '';
    
    TeacherInterview? interviewVal;
    if (json['interview'] != null && json['interview'] is Map<String, dynamic>) {
      interviewVal = TeacherInterview.fromJson(json['interview'] as Map<String, dynamic>);
    }

    return TeacherJobApplication(
      id: id,
      jobId: jobIdVal,
      jobTitle: jobTitleVal,
      slug: slugVal,
      status: statusVal,
      progress: progress,
      appliedDate: appliedVal.length >= 10 ? appliedVal.substring(0, 10) : appliedVal,
      schoolName: schoolNameVal,
      salary: salaryVal,
      interview: interviewVal,
    );
  }
}

class TeacherRecruitmentStats {
  final int appliedJobsCount;
  final int interviewsCount;
  final int shortlistedCount;
  final int hiredCount;

  TeacherRecruitmentStats({
    required this.appliedJobsCount,
    required this.interviewsCount,
    required this.shortlistedCount,
    required this.hiredCount,
  });

  factory TeacherRecruitmentStats.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};
    return TeacherRecruitmentStats(
      appliedJobsCount: stats['appliedJobsCount'] as int? ?? 0,
      interviewsCount: stats['interviewsCount'] as int? ?? 0,
      shortlistedCount: stats['shortlistedCount'] as int? ?? 0,
      hiredCount: stats['hiredCount'] as int? ?? 0,
    );
  }
}
