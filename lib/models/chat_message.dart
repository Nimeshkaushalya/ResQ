class ChatMessage {
  final String id;
  final String text;
  final String? imageUrl;
  final bool isUser; // true = user message, false = AI message
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.isUser,
    required this.timestamp,
  });
}
