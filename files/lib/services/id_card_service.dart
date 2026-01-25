import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class IdCard {
  final String id;
  final String studentName;
  final String nationalId;
  final String studentCode;
  final String schoolName;
  final String grade;
  final String section;
  final String? photoUrl;
  final String? qrCode;
  final bool isActive;
  final String? expiryDate;

  IdCard({
    required this.id,
    required this.studentName,
    required this.nationalId,
    required this.studentCode,
    required this.schoolName,
    required this.grade,
    required this.section,
    this.photoUrl,
    this.qrCode,
    required this.isActive,
    this.expiryDate,
  });

  factory IdCard.fromJson(Map<String, dynamic> json) {
    return IdCard(
      id: json['_id'] ?? json['id'] ?? '',
      studentName: json['studentName'] ?? '',
      nationalId: json['nationalId'] ?? '',
      studentCode: json['studentCode'] ?? '',
      schoolName: json['schoolName'] ?? '',
      grade: json['grade'] ?? '',
      section: json['section'] ?? '',
      photoUrl: json['photoUrl'],
      qrCode: json['qrCode'],
      isActive: json['isActive'] ?? true,
      expiryDate: json['expiryDate'],
    );
  }
}

class IdCardService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Get ID card by National ID and Password
  static Future<IdCard> getIdCard(String nationalId, String password) async {
    try {
      print('🆔 [ID CARD] Getting card for NID: $nationalId');

      final url = '$_baseUrl/card/$nationalId/$password';

      print('🆔 [ID CARD] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      );

      print('🆔 [ID CARD] Response status: ${response.statusCode}');
      print('🆔 [ID CARD] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return IdCard.fromJson(responseData['card']);
      } else if (response.statusCode == 404) {
        throw Exception('Card not found or invalid credentials');
      } else {
        throw Exception('Failed to get ID card: ${response.statusCode}');
      }
    } catch (e) {
      print('🆔 [ID CARD] Error getting card: $e');
      rethrow;
    }
  }

  /// Reset ID card password
  static Future<String> resetPassword(String cardId, String customId) async {
    try {
      print('🆔 [ID CARD] Resetting password for card: $cardId');

      final url = '$_baseUrl/card/reset/$cardId/$customId';

      print('🆔 [ID CARD] URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConstants.defaultHeaders,
      );

      print('🆔 [ID CARD] Response status: ${response.statusCode}');
      print('🆔 [ID CARD] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['newPassword'] ?? '';
      } else if (response.statusCode == 404) {
        throw Exception('Card not found');
      } else {
        throw Exception('Failed to reset password: ${response.statusCode}');
      }
    } catch (e) {
      print('🆔 [ID CARD] Error resetting password: $e');
      rethrow;
    }
  }
}


