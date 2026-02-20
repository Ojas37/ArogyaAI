import 'chat_message.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<ChatMessage> messages;
  final bool isActive;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.messages,
    this.isActive = false,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      'isActive': isActive,
    };
  }

  // Create from JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  // Create a copy with updated fields
  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    List<ChatMessage>? messages,
    bool? isActive,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      messages: messages ?? this.messages,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get a preview of the last message
  String get preview {
    if (messages.isEmpty) return 'No messages';
    final lastMessage = messages.last;
    return lastMessage.text.length > 60
        ? '${lastMessage.text.substring(0, 60)}...'
        : lastMessage.text;
  }

  // Auto-generate title from first user message
  static String generateTitle(List<ChatMessage> messages) {
    final userMessage = messages.firstWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(
        text: 'New Conversation',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );

    String title = userMessage.text.trim();
    if (title.length > 50) {
      title = '${title.substring(0, 50)}...';
    }
    return title.isEmpty ? 'New Conversation' : title;
  }
}
