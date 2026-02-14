class ConversationResponse {
  final Conversation conversation;

  ConversationResponse({required this.conversation});

  factory ConversationResponse.fromJson(Map<String, dynamic> json) {
    return ConversationResponse(
      conversation: Conversation.fromJson(json['conversation'] as Map<String, dynamic>),
    );
  }
}

class Conversation {
  final String id;
  final String type;

  Conversation({required this.id, required this.type});

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'direct',
    );
  }
}

class ChatMessage {
  final String id;
  final String content;
  final String type;
  final String senderId;
  final String role;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.senderId,
    required this.role,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      senderId: json['sender'] is Map ? (json['sender']['_id'] ?? '') : (json['senderId'] ?? ''),
      role: json['role'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}
