import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'user_storage_service.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class ChatbotRequest {
  final String message;
  final List<ChatMessage> history;

  ChatbotRequest({required this.message, required this.history});

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'history': history.map((msg) => msg.toJson()).toList(),
    };
  }
}

class ChatbotResponse {
  final String reply;

  ChatbotResponse({required this.reply});

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      reply: json['reply'] ?? '',
    );
  }
}

class ChatbotException implements Exception {
  final String message;

  ChatbotException(this.message);

  @override
  String toString() => 'ChatbotException: $message';
}

class ChatbotService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Send a message to the chatbot
  static Future<ChatbotResponse> sendMessage(
    String message,
    List<ChatMessage> history,
  ) async {
    try {
      print('🤖 [CHATBOT] Sending message: $message');
      print('🤖 [CHATBOT] History length: ${history.length}');

      // Get stored token
      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw ChatbotException('No authentication token found');
      }

      final url = _baseUrl + ApiConstants.chatbotEndpoint;
      final headers = ApiConstants.getAuthHeaders(token);

      final request = ChatbotRequest(message: message, history: history);

      print('🤖 [CHATBOT] URL: $url');
      print('🤖 [CHATBOT] Request body: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('🤖 [CHATBOT] Response status: ${response.statusCode}');
      print('🤖 [CHATBOT] Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          return ChatbotResponse.fromJson(responseData);
        } catch (e) {
          throw ChatbotException('Failed to parse response: $e');
        }
      } else if (response.statusCode == 400) {
        try {
          final errorData = jsonDecode(response.body);
          throw ChatbotException(
              errorData['message'] ?? 'Missing message content');
        } catch (e) {
          throw ChatbotException('Bad request: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw ChatbotException('Unauthorized: Invalid token');
      } else {
        throw ChatbotException(
            'Failed to get chatbot response. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('🤖 [CHATBOT] Error: $e');
      if (e is ChatbotException) {
        rethrow;
      } else {
        throw ChatbotException('Network error: ${e.toString()}');
      }
    }
  }
}

