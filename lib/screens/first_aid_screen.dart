import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/services/gemini_service.dart';
import 'package:resq_flutter/types.dart'; // For ChatMessage model
import 'package:resq_flutter/screens/photo_analysis_screen.dart' as resq_photo;

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
        role: 'model',
        text:
            "Hello. I am ResQ First Aid Assistant. Briefly describe the emergency (e.g., 'burned hand', 'choking'), and I will guide you.",
        timestamp: DateTime.now().millisecondsSinceEpoch),
  ];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userText = _controller.text.trim();
    setState(() {
      _messages.add(ChatMessage(
          role: 'user',
          text: userText,
          timestamp: DateTime.now().millisecondsSinceEpoch));
      _isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final gemini = Provider.of<GeminiService>(context, listen: false);
      final responseText = await gemini.getFirstAidAdvice(
          userText); // Context is kept in Service if needed, or simple Q&A

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
              role: 'model',
              text: responseText,
              timestamp: DateTime.now().millisecondsSinceEpoch));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
              role: 'model',
              text:
                  "Error connecting to AI. Call emergency services immediately.",
              timestamp: DateTime.now().millisecondsSinceEpoch));
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.heartPulse, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('First Aid Assistant'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const resq_photo.PhotoAnalysisScreen()),
              );
            },
            icon: const Icon(LucideIcons.camera, color: Color(0xFF0F172A)),
            tooltip: 'Analyze Injury Photo',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0F172A)
                          : Colors.white, // Slate-900 vs White
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft:
                            isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight:
                            isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: isUser
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: isUser
                        ? Text(
                            msg.text,
                            style: const TextStyle(color: Colors.white),
                          )
                        : MarkdownBody(
                            data: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                  color: Color(0xFF334155), fontSize: 15),
                              listBullet:
                                  const TextStyle(color: Color(0xFF334155)),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text("ResQ is typing...",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type your situation...",
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9), // Slate-100
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(LucideIcons.send, color: Color(0xFFDC2626)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEF2F2), // Red-50
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
