class BusPerson {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? username;
  final String? avatar;

  BusPerson({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.username,
    this.avatar,
  });

  factory BusPerson.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return BusPerson(id: '', name: '');
    }
    return BusPerson(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      username: json['username']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }
}

class BusAssignmentStudent {
  final String id;
  final String fullName;
  final String? studentCode;

  BusAssignmentStudent({
    required this.id,
    required this.fullName,
    this.studentCode,
  });

  factory BusAssignmentStudent.fromJson(Map<String, dynamic> json) {
    return BusAssignmentStudent(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      studentCode: json['studentCode']?.toString(),
    );
  }
}

class BusAssignment {
  final String id;
  final BusAssignmentStudent? student;
  final String? route;
  final String? stop;
  final String? pickupTime;
  final String? returnTime;
  final String? status;

  BusAssignment({
    required this.id,
    this.student,
    this.route,
    this.stop,
    this.pickupTime,
    this.returnTime,
    this.status,
  });

  factory BusAssignment.fromJson(Map<String, dynamic> json) {
    return BusAssignment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      student: json['student'] != null
          ? BusAssignmentStudent.fromJson(
              json['student'] as Map<String, dynamic>,
            )
          : null,
      route: json['route']?.toString(),
      stop: json['stop']?.toString(),
      pickupTime: json['pickupTime']?.toString(),
      returnTime: json['returnTime']?.toString(),
      status: json['status']?.toString(),
    );
  }
}

class BusGps {
  final bool enabled;
  final String? deviceId;
  final String? trackingUrl;

  const BusGps({
    required this.enabled,
    this.deviceId,
    this.trackingUrl,
  });

  factory BusGps.fromJson(Map<String, dynamic>? json) {
    return BusGps(
      enabled: json?['enabled'] == true,
      deviceId: json?['deviceId']?.toString(),
      trackingUrl: json?['trackingUrl']?.toString(),
    );
  }
}

class Bus {
  final String id;
  final String busNumber;
  final String? plateNumber;
  final String? motorNumber;
  final String? chassisNumber;
  final int? capacity;
  final int? currentOccupancy;
  final String? status;
  final String? busType;
  final String? manufacturer;
  final String? model;
  final int? year;
  final String? color;
  final BusPerson? driver;
  final BusPerson? assistant;
  final List<BusAssignment> assignedStudents;
  final BusGps gps;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Bus({
    required this.id,
    required this.busNumber,
    this.plateNumber,
    this.motorNumber,
    this.chassisNumber,
    this.capacity,
    this.currentOccupancy,
    this.status,
    this.busType,
    this.manufacturer,
    this.model,
    this.year,
    this.color,
    this.driver,
    this.assistant,
    this.assignedStudents = const [],
    this.gps = const BusGps(enabled: false),
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      busNumber: json['busNumber']?.toString() ?? '',
      plateNumber: json['plateNumber']?.toString(),
      motorNumber: json['motorNumber']?.toString(),
      chassisNumber: json['chassisNumber']?.toString(),
      capacity: json['capacity'] is int ? json['capacity'] : int.tryParse('${json['capacity']}'),
      currentOccupancy: json['currentOccupancy'] is int
          ? json['currentOccupancy']
          : int.tryParse('${json['currentOccupancy']}'),
      status: json['status']?.toString(),
      busType: json['busType']?.toString(),
      manufacturer: json['manufacturer']?.toString(),
      model: json['model']?.toString(),
      year: json['year'] is int ? json['year'] : int.tryParse('${json['year']}'),
      color: json['color']?.toString(),
      driver: json['driver'] != null
          ? BusPerson.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      assistant: json['assistant'] != null
          ? BusPerson.fromJson(json['assistant'] as Map<String, dynamic>)
          : null,
      assignedStudents: (json['assignedStudents'] as List<dynamic>?)
              ?.map((a) => BusAssignment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      gps: BusGps.fromJson(json['gps'] as Map<String, dynamic>?),
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class BusesResponse {
  final List<Bus> buses;
  final bool success;
  final String message;

  BusesResponse({
    required this.buses,
    required this.success,
    required this.message,
  });

  factory BusesResponse.fromJson(Map<String, dynamic> json) {
    return BusesResponse(
      buses: (json['buses'] as List<dynamic>?)
              ?.map((b) => Bus.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      success: json['success'] ?? true,
      message: json['message']?.toString() ?? 'Buses loaded',
    );
  }
}


