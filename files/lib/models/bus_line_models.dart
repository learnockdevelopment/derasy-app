import 'bus_models.dart';

class BusStationCoordinates {
  final double lat;
  final double lng;

  BusStationCoordinates({required this.lat, required this.lng});

  factory BusStationCoordinates.fromJson(Map<String, dynamic>? json) {
    return BusStationCoordinates(
      lat: (json?['lat'] ?? 0.0).toDouble(),
      lng: (json?['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class BusStationStudent {
  final BusAssignmentStudent student;
  final String attendanceStatus;
  final DateTime? attendanceTime;
  final String? recordedBy;
  final String? notes;

  BusStationStudent({
    required this.student,
    required this.attendanceStatus,
    this.attendanceTime,
    this.recordedBy,
    this.notes,
  });

  factory BusStationStudent.fromJson(Map<String, dynamic> json) {
    return BusStationStudent(
      student: BusAssignmentStudent.fromJson(json['student'] as Map<String, dynamic>),
      attendanceStatus: json['attendanceStatus']?.toString() ?? 'pending',
      attendanceTime: json['attendanceTime'] != null ? DateTime.tryParse(json['attendanceTime'].toString()) : null,
      recordedBy: json['recordedBy']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class BusStation {
  final int order;
  final String name;
  final String? address;
  final BusStationCoordinates? coordinates;
  final String? arrivalTime;
  final String? departureTime;
  final String status;
  final DateTime? arrivedAt;
  final DateTime? departedAt;
  final List<BusStationStudent> students;

  BusStation({
    required this.order,
    required this.name,
    this.address,
    this.coordinates,
    this.arrivalTime,
    this.departureTime,
    required this.status,
    this.arrivedAt,
    this.departedAt,
    this.students = const [],
  });

  factory BusStation.fromJson(Map<String, dynamic> json) {
    return BusStation(
      order: json['order'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString(),
      coordinates: json['coordinates'] != null ? BusStationCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>) : null,
      arrivalTime: json['arrivalTime']?.toString(),
      departureTime: json['departureTime']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      arrivedAt: json['arrivedAt'] != null ? DateTime.tryParse(json['arrivedAt'].toString()) : null,
      departedAt: json['departedAt'] != null ? DateTime.tryParse(json['departedAt'].toString()) : null,
      students: (json['students'] as List<dynamic>?)
              ?.map((s) => BusStationStudent.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BusLine {
  final String id;
  final String? busId; // Can be String or populated Bus
  final String? busNumber;
  final String? plateNumber;
  final DateTime date;
  final String tripType;
  final String? routeName;
  final List<BusStation> stations;
  final BusPerson? driver;
  final BusPerson? assistant;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? notes;

  BusLine({
    required this.id,
    this.busId,
    this.busNumber,
    this.plateNumber,
    required this.date,
    required this.tripType,
    this.routeName,
    this.stations = const [],
    this.driver,
    this.assistant,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.notes,
  });

  factory BusLine.fromJson(Map<String, dynamic> json) {
    // Handle bus fields which might be direct or in a populated map
    String? bId;
    String? bNum;
    String? bPlate;
    
    if (json['bus'] is Map) {
      final busMap = json['bus'] as Map<String, dynamic>;
      bId = busMap['_id']?.toString() ?? busMap['id']?.toString();
      bNum = busMap['busNumber']?.toString();
      bPlate = busMap['plateNumber']?.toString();
    } else {
      bId = json['bus']?.toString();
    }

    return BusLine(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      busId: bId,
      busNumber: bNum,
      plateNumber: bPlate,
      date: DateTime.parse(json['date'].toString()),
      tripType: json['tripType']?.toString() ?? '',
      routeName: json['routeName']?.toString(),
      stations: (json['stations'] as List<dynamic>?)
              ?.map((s) => BusStation.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      driver: json['driver'] != null ? BusPerson.fromJson(json['driver'] as Map<String, dynamic>) : null,
      assistant: json['assistant'] != null ? BusPerson.fromJson(json['assistant'] as Map<String, dynamic>) : null,
      status: json['status']?.toString() ?? 'scheduled',
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'].toString()) : null,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      notes: json['notes']?.toString(),
    );
  }
}
