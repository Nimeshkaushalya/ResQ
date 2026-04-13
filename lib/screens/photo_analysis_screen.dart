import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:resq_flutter/models/chat_message.dart';
import 'package:resq_flutter/services/ai_chat_service.dart';
import 'package:resq_flutter/services/gemini_service.dart';
import 'package:resq_flutter/services/connectivity_service.dart';
import 'package:resq_flutter/services/offline_ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';

class PhotoAnalysisScreen extends StatefulWidget {
  const PhotoAnalysisScreen({super.key});

  @override
  State<PhotoAnalysisScreen> createState() => _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends State<PhotoAnalysisScreen> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineAIService _offlineAIService = OfflineAIService();
  AiChatService? _chatService;
  
  File? _imageFile;
  bool _isAnalyzing = false;
  String? _analysisResult;
  bool _isOnline = true;
  String? _selectedHint;
  bool _isChatMode = false;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final List<String> _hints = [
    'Unknown', 'Burn', 'Bleeding', 'Fracture', 'Animal Bite', 'Allergic Reaction', 'Head Injury'
  ];

  @override
  void initState() {
    super.initState();
    _offlineAIService.init();
    _checkInitialConnectivity();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialConnectivity() async {
    bool hasInternet = await _connectivityService.checkInternetConnection();
    if (mounted) {
      setState(() {
        _isOnline = hasInternet;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _analysisResult = null;
        _isChatMode = false;
        _chatService?.clearChat();
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      bool hasInternet = await _connectivityService.checkInternetConnection();
      setState(() {
        _isOnline = hasInternet;
      });

      String result;
      if (hasInternet) {
        final gemini = Provider.of<GeminiService>(context, listen: false);
        result = await gemini.analyzeInjuryPhoto(_imageFile!, emergencyHint: _selectedHint);
        
        // Initialize Chat Service
        _chatService = AiChatService(gemini);
        _chatService!.initializeChat(result, _imageFile!.path);
        _isChatMode = true;
      } else {
        result = await _offlineAIService.analyzeImageOffline(_imageFile!, emergencyHint: _selectedHint);
      }

      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to analyze: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _sendMessage([String? text]) async {
    final message = text ?? _chatController.text.trim();
    if (message.isEmpty || _chatService == null) return;

    if (text == null) _chatController.clear();
    
    setState(() {
      _isSending = true;
    });

    await _chatService!.sendMessage(message);
    
    if (mounted) {
      setState(() {
        _isSending = false;
      });
      _scrollToBottom();
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _shareChat() {
    if (_chatService == null) return;
    final history = _chatService!.chatHistory.map((m) => 
      "${m.isUser ? 'User' : 'ResQ AI'}: ${m.text}"
    ).join("\n\n");
    Share.share(history, subject: 'ResQ First Aid Chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Analyze Injury'),
        actions: [
          if (_isChatMode) ...[
            IconButton(
              icon: const Icon(LucideIcons.share2, size: 20),
              onPressed: _shareChat,
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 20),
              onPressed: () => setState(() {
                _isChatMode = false;
                _analysisResult = null;
                _chatService?.clearChat();
              }),
            ),
          ]
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isChatMode ? _buildChatUI() : _buildSelectionUI(),
          ),
          if (_isChatMode) _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildSelectionUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview Image
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            clipBehavior: Clip.hardEdge,
            child: _imageFile != null
                ? Image.file(_imageFile!, fit: BoxFit.cover)
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.imagePlus, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Capture an image of the injury', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          _buildConnectivityIndicator(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 24),
          _buildHintDropdown(),
          const SizedBox(height: 32),
          _buildAnalyzeButton(),
          const SizedBox(height: 24),
          if (!_isOnline && _analysisResult != null) ...[
            const Text('Offline Analysis Result', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: MarkdownBody(data: _analysisResult!),
            ),
            const SizedBox(height: 12),
            const Text('Note: Follow-up chat requires an internet connection.', style: TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectivityIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
          color: _isOnline ? Colors.green : Colors.orange,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          _isOnline ? 'ResQ AI Online' : 'Offline Analysis Mode',
          style: TextStyle(color: _isOnline ? Colors.green : Colors.orange, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _expandableButton(LucideIcons.camera, 'Camera', () => _pickImage(ImageSource.camera)),
        const SizedBox(width: 16),
        _expandableButton(LucideIcons.image, 'Gallery', () => _pickImage(ImageSource.gallery)),
      ],
    );
  }

  Widget _expandableButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildHintDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedHint,
      decoration: InputDecoration(
        labelText: 'Injury Type (Optional)',
        prefixIcon: const Icon(LucideIcons.stethoscope, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _hints.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
      onChanged: (v) => setState(() => _selectedHint = v),
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton(
      onPressed: _imageFile != null && !_isAnalyzing ? _analyzeImage : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isAnalyzing
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Analyze Injury', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildChatUI() {
    final messages = _chatService?.chatHistory ?? [];
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          if (_isSending) return _buildTypingIndicator();
          return _buildQuickReplies();
        }
        return _buildChatBubble(messages[index]);
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isAI = !message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (message.imageUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 150,
              width: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: FileImage(File(message.imageUrl!)), fit: BoxFit.cover)),
            ),
          Row(
            mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isAI) 
                const CircleAvatar(backgroundColor: Color(0xFFDC2626), radius: 14, child: Icon(LucideIcons.bot, size: 16, color: Colors.white)),
              const SizedBox(width: 8),
              Flexible(
                child: GestureDetector(
                  onLongPress: () => _copyToClipboard(message.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAI ? Colors.white : const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(16).copyWith(
                        topLeft: isAI ? const Radius.circular(0) : const Radius.circular(16),
                        topRight: isAI ? const Radius.circular(16) : const Radius.circular(0),
                      ),
                      boxShadow: [if (isAI) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                    ),
                    child: isAI 
                      ? MarkdownBody(data: message.text, styleSheet: MarkdownStyleSheet(p: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4)))
                      : Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(backgroundColor: Colors.grey, radius: 14, child: Icon(LucideIcons.bot, size: 16, color: Colors.white)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text("ResQ AI is thinking...", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    final replies = [
      "What should I do first?",
      "When to see a doctor?",
      "What should I NOT do?",
      "How to clean this?",
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Questions:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: replies.map((r) => ActionChip(
              label: Text(r, style: const TextStyle(fontSize: 12)),
              onPressed: () => _sendMessage(r),
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade200),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: "Ask a follow-up question...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: const Color(0xFFDC2626),
              child: IconButton(
                icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
