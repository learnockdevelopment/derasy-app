import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import '../models/chat_models.dart';
import 'user_storage_service.dart';

class ChatService {
  static const String _baseUrl = ApiConstants.baseUrl;

  /// Start or retrieve a conversation with a participant
  static Future<Conversation> createConversation(String participantId) async {
    try {
      print('💬 [CHAT] Creating conversation with participant: $participantId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$_baseUrl${ApiConstants.chatConversationsEndpoint}';
      final headers = ApiConstants.getAuthHeaders(token);
      final body = json.encode({
        'participants': [participantId],
        'type': 'direct'
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('💬 [CHAT] Create conversation status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return ConversationResponse.fromJson(jsonData).conversation;
      } else {
        throw Exception('Failed to create conversation. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💬 [CHAT] Error creating conversation: $e');
      rethrow;
    }
  }

  /// Send a message in a conversation
  static Future<ChatMessage> sendMessage(String conversationId, String content) async {
    try {
      print('💬 [CHAT] Sending message in conversation: $conversationId');

      final token = UserStorageService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '$_baseUrl${ApiConstants.chatMessagesEndpoint}'
          .replaceAll('[conv_id]', conversationId);
      final headers = ApiConstants.getAuthHeaders(token);
      final body = json.encode({
        'content': content,
        'type': 'text'
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 30));

      print('💬 [CHAT] Send message status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        // Assuming the API returns the message object under a "message" key or directly
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('message')) {
          return ChatMessage.fromJson(jsonData['message']);
        }
        return ChatMessage.fromJson(jsonData);
      } else {
        throw Exception('Failed to send message. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💬 [CHAT] Error sending message: $e');
      rethrow;
    }
  }

  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final token = UserStorageService.getAuthToken();
      if (token == null) throw Exception('No authentication token');
      
      final url = '$_baseUrl/chat/messages/$conversationId'; 
      // Note: Assuming endpoint follows pattern. If ApiConstants has it, use that.
      // Checking ApiConstants usage in sendMessage: 
      // '$_baseUrl${ApiConstants.chatMessagesEndpoint}'.replaceAll('[conv_id]', conversationId);
      
      final usedUrl = '$_baseUrl${ApiConstants.chatMessagesEndpoint}'.replaceAll('[conv_id]', conversationId);
      
      final response = await http.get(Uri.parse(usedUrl), headers: ApiConstants.getAuthHeaders(token));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = (json['messages'] as List?) ?? [];
        return list.map((e) => ChatMessage.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading messages: $e');
      return [];
    }
  }
}
