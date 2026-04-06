import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:resq_flutter/models/chat_message.dart';
import 'package:resq_flutter/services/gemini_service.dart';
import 'package:uuid/uuid.dart';

class AiChatService {
  final GeminiService _geminiService;
  final List<ChatMessage> _chatHistory = [];
  String? _currentImageAnalysis;
  ChatSession? _chatSession;
  final _uuid = const Uuid();

  AiChatService(this._geminiService);

  List<ChatMessage> get chatHistory => _chatHistory;

  void initializeChat(String analysisResult, String? imageUrl) {
    _chatHistory.clear();
    _currentImageAnalysis = analysisResult;
    
    // Add initial AI message
    _chatHistory.add(ChatMessage(
      id: _uuid.v4(),
      text: analysisResult,
      imageUrl: imageUrl,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Initialize Gemini Chat Session with context
    final model = _geminiService.getFlashModel(); // We'll need to expose this or a similar method
    _chatSession = model.startChat(history: [
      Content.text('You are a first aid expert assistant. The user uploaded an injury photo and you analyzed it as: $_currentImageAnalysis. Provide helpful, accurate first aid advice based on this context.'),
      Content.model([TextPart(analysisResult)]),
    ]);
  }

  Future<String> sendMessage(String userMessage) async {
    if (_chatSession == null) return "Chat not initialized.";

    // Add user message to history
    final userMsg = ChatMessage(
      id: _uuid.v4(),
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _chatHistory.add(userMsg);

    try {
      final response = await _chatSession!.sendMessage(Content.text(userMessage));
      final aiResponseText = response.text ?? "I'm sorry, I couldn't process that.";

      // Add AI response to history
      _chatHistory.add(ChatMessage(
        id: _uuid.v4(),
        text: aiResponseText,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      return aiResponseText;
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }

  void clearChat() {
    _chatHistory.clear();
    _chatSession = null;
    _currentImageAnalysis = null;
  }
}
