class EducationSystemsResponse {
  final bool success;
  final List<EducationSystem> systems;

  EducationSystemsResponse({required this.success, required this.systems});

  factory EducationSystemsResponse.fromJson(Map<String, dynamic> json) {
    return EducationSystemsResponse(
      success: json['success'] ?? false,
      systems: (json['systems'] as List?)
              ?.map((e) => EducationSystem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class EducationSystem {
  final String id;
  final String name;
  final String type;
  final List<Track> tracks;
  final List<Stage> stages;

  EducationSystem({
    required this.id,
    required this.name,
    required this.type,
    required this.tracks,
    required this.stages,
  });

  factory EducationSystem.fromJson(Map<String, dynamic> json) {
    return EducationSystem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      tracks: (json['tracks'] as List?)
              ?.map((e) => Track.fromJson(e))
              .toList() ??
          [],
      stages: (json['stages'] as List?)
              ?.map((e) => Stage.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Track {
  final String id;
  final String name;

  Track({required this.id, required this.name});

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class Stage {
  final String id;
  final String name;
  final List<Grade> grades;

  Stage({required this.id, required this.name, required this.grades});

  factory Stage.fromJson(Map<String, dynamic> json) {
    return Stage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      grades: (json['grades'] as List?)
              ?.map((e) => Grade.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Grade {
  final String id;
  final String name;

  Grade({required this.id, required this.name});

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}
