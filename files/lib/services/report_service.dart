import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/report_models.dart';
import 'user_storage_service.dart';

class ReportService {
  static const String _baseUrl = ApiConstants.baseUrl;

  static Future<SchoolReportResponse> getSchoolReport(String schoolId) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final url = '$_baseUrl/schools/my/$schoolId/reports';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.getAuthHeaders(token),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return SchoolReportResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load report');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<ReportTemplatesResponse> getReportTemplates(String schoolId) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final url = '$_baseUrl/schools/my/$schoolId/reports/list';
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.getAuthHeaders(token),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return ReportTemplatesResponse.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to load report templates');
      }
    } catch (e) {
      rethrow;
    }
  }
}

