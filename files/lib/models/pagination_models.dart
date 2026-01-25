import 'student_models.dart';

class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalStudents;
  final bool hasNextPage;
  final bool hasPrevPage;
  final int limit;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalStudents,
    required this.hasNextPage,
    required this.hasPrevPage,
    required this.limit,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalStudents: json['totalStudents'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
      limit: json['limit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalStudents': totalStudents,
      'hasNextPage': hasNextPage,
      'hasPrevPage': hasPrevPage,
      'limit': limit,
    };
  }
}

class PaginatedStudentsResponse {
  final List<Student> students;
  final PaginationInfo pagination;

  PaginatedStudentsResponse({
    required this.students,
    required this.pagination,
  });

  factory PaginatedStudentsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedStudentsResponse(
      students: (json['students'] as List<dynamic>?)
              ?.map((student) => Student.fromJson(student))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'students': students.map((student) => student.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class StudentsRequest {
  final int? page;
  final int? limit;
  final String? search;
  final String? grade;
  final int? age;
  final String? classId;

  StudentsRequest({
    this.page,
    this.limit,
    this.search,
    this.grade,
    this.age,
    this.classId,
  });

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (search != null && search!.isNotEmpty) params['search'] = search!;
    if (grade != null && grade!.isNotEmpty) params['grade'] = grade!;
    if (age != null) params['age'] = age.toString();
    if (classId != null && classId!.isNotEmpty) params['class'] = classId!;
    return params;
  }
}

