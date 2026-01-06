import 'student_models.dart';
import 'school_models.dart';

// Application Models

// Interview Information
class Interview {
  final DateTime? date;
  final String? time;
  final String? location;
  final String? notes;

  Interview({
    this.date,
    this.time,
    this.location,
    this.notes,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      time: json['time']?.toString(),
      location: json['location']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (date != null) 'date': date!.toIso8601String(),
      if (time != null) 'time': time,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
    };
  }
}

// Event Creator Information
class EventCreator {
  final String id;
  final String name;
  final String? email;
  final String? role;

  EventCreator({
    required this.id,
    required this.name,
    this.email,
    this.role,
  });

  factory EventCreator.fromJson(Map<String, dynamic> json) {
    return EventCreator(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      if (email != null) 'email': email,
      if (role != null) 'role': role,
    };
  }
}

// Application Event/Note
class ApplicationEvent {
  final String id;
  final String type;
  final String title;
  final String? description;
  final DateTime date;
  final EventCreator? createdBy;
  final Map<String, dynamic>? metadata;

  ApplicationEvent({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.date,
    this.createdBy,
    this.metadata,
  });

  factory ApplicationEvent.fromJson(Map<String, dynamic> json) {
    return ApplicationEvent(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type']?.toString() ?? 'other',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      createdBy: json['createdBy'] != null && json['createdBy'] is Map
          ? EventCreator.fromJson(json['createdBy'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'title': title,
      if (description != null) 'description': description,
      'date': date.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy!.toJson(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
class Application {
  final String id;
  final String parent;
  final ChildApplicationInfo child;
  final SchoolApplicationInfo school;
  final String status;
  final PaymentInfo? payment;
  final List<InterviewSlot> preferredInterviewSlots;
  final Interview? interview;
  final List<ApplicationEvent> events;
  final String? applicationType;
  final DateTime? submittedAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Application({
    required this.id,
    required this.parent,
    required this.child,
    required this.school,
    required this.status,
    this.payment,
    required this.preferredInterviewSlots,
    this.interview,
    this.events = const [],
    this.applicationType,
    this.submittedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['_id'] ?? '',
      parent: json['parent']?.toString() ?? '',
      child: json['child'] != null && json['child'] is Map
          ? ChildApplicationInfo.fromJson(json['child'] as Map<String, dynamic>)
          : ChildApplicationInfo(
              id: json['child']?.toString() ?? '',
              fullName: '',
              birthDate: null,
            ),
      school: json['school'] != null && json['school'] is Map
          ? SchoolApplicationInfo.fromJson(json['school'] as Map<String, dynamic>)
          : SchoolApplicationInfo(
              id: json['school']?.toString() ?? '',
              name: '',
              address: '',
            ),
      status: json['status']?.toString() ?? 'pending',
      payment: json['payment'] != null && json['payment'] is Map
          ? PaymentInfo.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
      preferredInterviewSlots: (json['preferredInterviewSlots'] as List<dynamic>?)
              ?.map((slot) => InterviewSlot.fromJson(slot as Map<String, dynamic>))
              .toList() ??
          [],
      interview: json['interview'] != null && json['interview'] is Map
          ? Interview.fromJson(json['interview'] as Map<String, dynamic>)
          : null,
      events: (json['events'] as List<dynamic>?)
              ?.map((event) => ApplicationEvent.fromJson(event as Map<String, dynamic>))
              .toList() ??
          [],
      applicationType: json['applicationType']?.toString(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'parent': parent,
      'child': child.toJson(),
      'school': school.toJson(),
      'status': status,
      'payment': payment?.toJson(),
      'preferredInterviewSlots': preferredInterviewSlots.map((s) => s.toJson()).toList(),
      if (interview != null) 'interview': interview!.toJson(),
      'events': events.map((e) => e.toJson()).toList(),
      if (applicationType != null) 'applicationType': applicationType,
      if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ChildApplicationInfo {
  final String id;
  final String fullName;
  final String? arabicFullName;
  final DateTime? birthDate;
  final String? gender;

  ChildApplicationInfo({
    required this.id,
    required this.fullName,
    this.arabicFullName,
    this.birthDate,
    this.gender,
  });

  factory ChildApplicationInfo.fromJson(Map<String, dynamic> json) {
    return ChildApplicationInfo(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName']?.toString() ?? '',
      arabicFullName: json['arabicFullName']?.toString(),
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      gender: json['gender']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      if (arabicFullName != null) 'arabicFullName': arabicFullName,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
    };
  }
}

class SchoolApplicationInfo {
  final String id;
  final String name;
  final String? nameAr;
  final String? address;

  SchoolApplicationInfo({
    required this.id,
    required this.name,
    this.nameAr,
    this.address,
  });

  factory SchoolApplicationInfo.fromJson(Map<String, dynamic> json) {
    return SchoolApplicationInfo(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name']?.toString() ?? json['nameAr']?.toString() ?? '',
      nameAr: json['nameAr']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'nameAr': nameAr,
      'address': address,
    };
  }
}

class PaymentInfo {
  final bool isPaid;
  final double amount;

  PaymentInfo({
    required this.isPaid,
    required this.amount,
  });

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      isPaid: json['isPaid'] is bool
          ? json['isPaid']
          : (json['isPaid'] == 'true' || json['isPaid'] == true),
      amount: (json['amount'] is int
          ? json['amount'].toDouble()
          : json['amount'] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPaid': isPaid,
      'amount': amount,
    };
  }
}

class InterviewSlot {
  final DateTime date;
  final TimeRange timeRange;

  InterviewSlot({
    required this.date,
    required this.timeRange,
  });

  factory InterviewSlot.fromJson(Map<String, dynamic> json) {
    return InterviewSlot(
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      timeRange: json['timeRange'] != null && json['timeRange'] is Map
          ? TimeRange.fromJson(json['timeRange'] as Map<String, dynamic>)
          : TimeRange(from: '10:00', to: '12:00'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'timeRange': timeRange.toJson(),
    };
  }
}

class TimeRange {
  final String from;
  final String to;

  TimeRange({
    required this.from,
    required this.to,
  });

  factory TimeRange.fromJson(Map<String, dynamic> json) {
    return TimeRange(
      from: json['from']?.toString() ?? '10:00',
      to: json['to']?.toString() ?? '12:00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
    };
  }
}

// Request Models
class ApplyToSchoolsRequest {
  final String childId;
  final List<SelectedSchool> selectedSchools;

  ApplyToSchoolsRequest({
    required this.childId,
    required this.selectedSchools,
  });

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'selectedSchools': selectedSchools.map((school) => school.toJson()).toList(),
    };
  }
}

class SelectedSchool {
  final String id;
  final String name;
  final AdmissionFee admissionFee;

  SelectedSchool({
    required this.id,
    required this.name,
    required this.admissionFee,
  });

  factory SelectedSchool.fromSchool(School school) {
    return SelectedSchool(
      id: school.id,
      name: school.name,
      admissionFee: AdmissionFee(
        amount: school.admissionFee?.amount ?? 0.0,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'admissionFee': admissionFee.toJson(),
    };
  }
}

class AdmissionFee {
  final double amount;

  AdmissionFee({
    required this.amount,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
    };
  }
}

class CreateApplicationRequest {
  final String child;
  final String school;
  final String status;
  final String? notes;

  CreateApplicationRequest({
    required this.child,
    required this.school,
    required this.status,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'child': child,
      'school': school,
      'status': status,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

// Response Models
class ApplyToSchoolsResponse {
  final String message;
  final List<Application> applications;

  ApplyToSchoolsResponse({
    required this.message,
    required this.applications,
  });

  factory ApplyToSchoolsResponse.fromJson(Map<String, dynamic> json) {
    return ApplyToSchoolsResponse(
      message: json['message']?.toString() ?? '',
      applications: (json['applications'] as List<dynamic>?)
              ?.map((app) => Application.fromJson(app as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ApplicationsResponse {
  final List<Application> applications;

  ApplicationsResponse({
    required this.applications,
  });

  factory ApplicationsResponse.fromJson(dynamic json) {
    if (json is List) {
      return ApplicationsResponse(
        applications: json
            .map((app) => Application.fromJson(app as Map<String, dynamic>))
            .toList(),
      );
    } else if (json is Map<String, dynamic>) {
      return ApplicationsResponse(
        applications: (json['applications'] as List<dynamic>?)
                ?.map((app) => Application.fromJson(app as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }
    return ApplicationsResponse(applications: []);
  }
}

// Exception
class AdmissionException implements Exception {
  final String message;
  final int? statusCode;

  AdmissionException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

