class ClassTeachersResponse {
  final Map<String, dynamic>? classData;
  final List<ClassTeacher> teachers;

  ClassTeachersResponse({this.classData, required this.teachers});

  factory ClassTeachersResponse.fromJson(Map<String, dynamic> json) {
    return ClassTeachersResponse(
      classData: json['class'] as Map<String, dynamic>?,
      teachers: (json['teachers'] as List<dynamic>?)
              ?.map((t) => ClassTeacher.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ClassTeacher {
  final String id;
  final String name;
  final String? avatar;
  final String role;

  ClassTeacher({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
  });

  factory ClassTeacher.fromJson(Map<String, dynamic> json) {
    return ClassTeacher(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar']?.toString(),
      role: json['role'] ?? 'teacher',
    );
  }
}
