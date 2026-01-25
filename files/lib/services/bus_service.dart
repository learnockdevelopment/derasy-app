import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/bus_models.dart';
import 'user_storage_service.dart';

class BusService {
  static const String _baseUrl = ApiConstants.baseUrl;

  static Future<BusesResponse> getBuses(
    String schoolId, {
    String? status,
    String? busType,
    String? search,
  }) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams['status'] = status;
    }
    if (busType != null && busType.isNotEmpty && busType != 'all') {
      queryParams['busType'] = busType;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final query = Uri(queryParameters: queryParams).query;
    final endpoint =
        ApiConstants.getBusesEndpoint.replaceFirst('[id]', schoolId);
    final url = '$_baseUrl$endpoint${query.isNotEmpty ? '?$query' : ''}';
    final headers = ApiConstants.getAuthHeaders(token);

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return BusesResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load buses (${response.statusCode})');
  }

  static Future<Bus> getBusDetails(String schoolId, String busId) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final endpoint = ApiConstants.getBusDetailsEndpoint
        .replaceFirst('[id]', schoolId)
        .replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final headers = ApiConstants.getAuthHeaders(token);
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Bus.fromJson(json['bus'] ?? json);
    }
    throw Exception('Failed to load bus (${response.statusCode})');
  }

  static Future<Bus> createBus(String schoolId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final url = '$_baseUrl${ApiConstants.createBusEndpoint.replaceFirst('[id]', schoolId)}';
    final response = await http.post(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode == 201 || response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Bus.fromJson(json['bus'] ?? json);
    }
    throw Exception('Failed to create bus (${response.statusCode})');
  }

  static Future<Bus> updateBus(String schoolId, String busId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.updateBusEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.put(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Bus.fromJson(json['bus'] ?? json);
    }
    throw Exception('Failed to update bus (${response.statusCode})');
  }

  static Future<void> deleteBus(String schoolId, String busId) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.deleteBusEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.delete(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete bus (${response.statusCode})');
    }
  }

  static Future<List<dynamic>> getRoutes(String schoolId, String busId) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busRoutesEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.get(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['routes'] as List?) ?? [];
    }
    throw Exception('Failed to load routes (${response.statusCode})');
  }

  static Future<void> addRoute(String schoolId, String busId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busRoutesEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.post(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add route (${response.statusCode})');
    }
  }

  static Future<void> updateRoute(String schoolId, String busId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busRoutesEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.put(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to update route (${response.statusCode})');
    }
  }

  static Future<void> deleteRoute(String schoolId, String busId, String routeId) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = '${ApiConstants.busRoutesEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId)}?routeId=$routeId';
    final url = '$_baseUrl$endpoint';
    final response = await http.delete(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete route (${response.statusCode})');
    }
  }

  static Future<List<dynamic>> getStudents(String schoolId, String busId, {String? status}) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final qp = status != null && status.isNotEmpty ? '?status=$status' : '';
    final endpoint = '${ApiConstants.busStudentsEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId)}$qp';
    final url = '$_baseUrl$endpoint';
    final response = await http.get(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['students'] as List?) ?? [];
    }
    throw Exception('Failed to load bus students (${response.statusCode})');
  }

  static Future<void> assignStudent(String schoolId, String busId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busStudentsEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.post(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to assign student (${response.statusCode})');
    }
  }

  static Future<void> updateAssignment(String schoolId, String busId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busStudentsEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.put(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to update assignment (${response.statusCode})');
    }
  }

  static Future<void> removeStudent(String schoolId, String busId, String assignmentId) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = '${ApiConstants.busStudentsEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId)}?assignmentId=$assignmentId';
    final url = '$_baseUrl$endpoint';
    final response = await http.delete(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Failed to remove student (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getLocation(String schoolId, String busId, {int? hours}) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final qp = hours != null ? '?hours=$hours' : '';
    final endpoint = '${ApiConstants.busLocationEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId)}$qp';
    final url = '$_baseUrl$endpoint';
    final response = await http.get(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load location (${response.statusCode})');
  }

  static Future<void> updateLocation(String schoolId, String busId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busLocationEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.post(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to update location (${response.statusCode})');
    }
  }

  // Lines
  static Future<List<dynamic>> getLines(String schoolId, String busId, {String? date, String? tripType, String? status}) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final params = <String, String>{};
    if (date != null && date.isNotEmpty) params['date'] = date;
    if (tripType != null && tripType.isNotEmpty) params['tripType'] = tripType;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final qp = Uri(queryParameters: params).query;
    final endpoint = ApiConstants.busLinesEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint${qp.isNotEmpty ? '?$qp' : ''}';
    final response = await http.get(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['busLines'] as List?) ?? (json['lines'] as List?) ?? [];
    }
    throw Exception('Failed to load lines (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> getLine(String schoolId, String busId, String lineId) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busLineDetailsEndpoint
        .replaceFirst('[id]', schoolId)
        .replaceFirst('[busId]', busId)
        .replaceFirst('[lineId]', lineId);
    final url = '$_baseUrl$endpoint';
    final response = await http.get(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['busLine'] as Map<String, dynamic>? ?? json;
    }
    throw Exception('Failed to load line (${response.statusCode})');
  }

  static Future<void> createLine(String schoolId, String busId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busLinesEndpoint.replaceFirst('[id]', schoolId).replaceFirst('[busId]', busId);
    final url = '$_baseUrl$endpoint';
    final response = await http.post(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create line (${response.statusCode})');
    }
  }

  static Future<void> updateLine(String schoolId, String busId, String lineId, Map<String, dynamic> data) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busLineDetailsEndpoint
        .replaceFirst('[id]', schoolId)
        .replaceFirst('[busId]', busId)
        .replaceFirst('[lineId]', lineId);
    final url = '$_baseUrl$endpoint';
    final response = await http.put(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token), body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to update line (${response.statusCode})');
    }
  }

  static Future<void> deleteLine(String schoolId, String busId, String lineId) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busLineDetailsEndpoint
        .replaceFirst('[id]', schoolId)
        .replaceFirst('[busId]', busId)
        .replaceFirst('[lineId]', lineId);
    final url = '$_baseUrl$endpoint';
    final response = await http.delete(Uri.parse(url), headers: ApiConstants.getAuthHeaders(token));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete line (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> updateStudentAttendanceAtStation({
    required String schoolId,
    required String busId,
    required String lineId,
    required int stationOrder,
    required String studentId,
    required String attendanceStatus,
    String? attendanceTime,
    String? notes,
  }) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busStationAttendanceEndpoint
        .replaceFirst('[id]', schoolId)
        .replaceFirst('[busId]', busId)
        .replaceFirst('[lineId]', lineId)
        .replaceFirst('[stationOrder]', stationOrder.toString());
    final url = '$_baseUrl$endpoint';
    final payload = <String, dynamic>{
      'studentId': studentId,
      'attendanceStatus': attendanceStatus,
    };
    if (attendanceTime != null && attendanceTime.isNotEmpty) payload['attendanceTime'] = attendanceTime;
    if (notes != null && notes.isNotEmpty) payload['notes'] = notes;
    final response = await http.post(
      Uri.parse(url),
      headers: ApiConstants.getAuthHeaders(token),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update attendance (${response.statusCode})');
  }

  // Bulk update (PUT)
  static Future<Map<String, dynamic>> bulkUpdateAttendanceAtStation({
    required String schoolId,
    required String busId,
    required String lineId,
    required int stationOrder,
    required List<Map<String, dynamic>> attendanceRecords,
  }) async {
    final token = UserStorageService.getAuthToken();
    if (token == null) throw Exception('No authentication token found');
    final endpoint = ApiConstants.busStationAttendanceEndpoint
        .replaceFirst('[id]', schoolId)
        .replaceFirst('[busId]', busId)
        .replaceFirst('[lineId]', lineId)
        .replaceFirst('[stationOrder]', stationOrder.toString());
    final url = '$_baseUrl$endpoint';
    final payload = <String, dynamic>{'attendanceRecords': attendanceRecords};
    final response = await http.put(
      Uri.parse(url),
      headers: ApiConstants.getAuthHeaders(token),
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to update attendance (${response.statusCode})');
  }
}


