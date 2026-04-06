import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:resq_flutter/models/chat.dart';
import 'package:resq_flutter/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _currentUserId;
  late String _currentUserType;
  
  bool _isUploading = false;
  
  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _currentUserType = _currentUserId == widget.chat.userId ? 'user' : 'responder';
    
    // Mark messages as read
    _chatService.markAsRead(widget.chat.id, _currentUserId);
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    
    final senderName = _currentUserType == 'user' ? widget.chat.userName : widget.chat.responderName;

    await _chatService.sendMessage(
      chatId: widget.chat.id,
      senderId: _currentUserId,
      senderName: senderName,
      senderType: _currentUserType,
      text: text,
    );
    
    _scrollToBottom();
  }

  Future<void> _sendMedia(ImageSource source, String mediaType) async {
    final picker = ImagePicker();
    XFile? pickedFile;
    
    if (mediaType == 'video') {
      pickedFile = await picker.pickVideo(source: source);
    } else {
      pickedFile = await picker.pickImage(source: source);
    }

    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final senderName = _currentUserType == 'user' ? widget.chat.userName : widget.chat.responderName;
      
      await _chatService.sendMediaMessage(
        chatId: widget.chat.id,
        senderId: _currentUserId,
        senderName: senderName,
        senderType: _currentUserType,
        media: File(pickedFile.path),
        mediaType: mediaType,
      );
      
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload media: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _sendMedia(ImageSource.camera, 'image');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('Choose Photo'),
              onTap: () {
                Navigator.pop(context);
                _sendMedia(ImageSource.gallery, 'image');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.video),
              title: const Text('Take Video'),
              onTap: () {
                Navigator.pop(context);
                _sendMedia(ImageSource.camera, 'video');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.film),
              title: const Text('Choose Video'),
              onTap: () {
                Navigator.pop(context);
                _sendMedia(ImageSource.gallery, 'video');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200, // Small buffer
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _makeCall() async {
    final otherPartyId = _currentUserType == 'user' ? widget.chat.responderId : widget.chat.userId;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(otherPartyId).get();
      final phone = doc.data()?['phoneNumber'];
      if (phone != null && phone.toString().isNotEmpty) {
        final Uri url = Uri(scheme: 'tel', path: phone.toString());
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone app')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number not found')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching phone: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResponderView = _currentUserType == 'responder';
    final otherPartyName = isResponderView ? widget.chat.userName : widget.chat.responderName;
    final otherPartyRole = isResponderView ? "Citizen in Need" : widget.chat.responderType.toUpperCase();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 1,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: isResponderView ? Colors.blue.shade100 : Colors.red.shade100,
              child: Icon(
                isResponderView ? LucideIcons.user : LucideIcons.truck,
                color: isResponderView ? Colors.blue : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherPartyName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    otherPartyRole,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.phone, color: Colors.green),
            onPressed: _makeCall,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<RealtimeChatMessage>>(
              stream: _chatService.getChatMessages(widget.chat.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];
                
                // Auto-mark as read + scroll down logic can be handled here or in post-frame callbacks
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && messages.isNotEmpty) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hi!'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Color(0xFFDC2626)),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(RealtimeChatMessage message) {
    bool isMe = message.senderId == _currentUserId;
    bool isSystem = message.senderType == 'system';

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.text,
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade200,
                  child: Text(
                    message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ),
              if (!isMe) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFFDC2626) : Colors.white,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                      bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                    ),
                    border: isMe ? null : Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.mediaType != 'none' && message.mediaUrl.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: message.mediaType == 'image'
                              ? Image.network(message.mediaUrl, width: 200, height: 200, fit: BoxFit.cover)
                              : Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.black87,
                                  child: const Center(child: Icon(LucideIcons.playCircle, color: Colors.white, size: 48)),
                                ), // Placeholder for video
                        ),
                        if (message.text.isNotEmpty) const SizedBox(height: 8),
                      ],
                      if (message.text.isNotEmpty)
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
              if (isMe)
                Icon(
                  message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                  size: 16,
                  color: message.isRead ? Colors.blue : Colors.grey,
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              top: 4,
              left: isMe ? 0 : 40,
              right: isMe ? 28 : 0,
            ),
            child: Text(
              DateFormat('h:mm a').format(message.timestamp.toDate()),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.paperclip, color: Color(0xFF64748B)),
              onPressed: _showMediaOptions,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgController,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
