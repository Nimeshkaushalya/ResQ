import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resq_flutter/models/chat.dart';
import 'package:resq_flutter/services/cloudinary_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Create new chat when responder accepts request
  Future<String> createChat(
      String emergencyId, String userId, String responderId, String userName, String responderName, String responderType) async {
    // Check if chat already exists for this emergency
    final existingChat = await getChatByEmergencyId(emergencyId);
    if (existingChat != null) {
      return existingChat.id;
    }

    final chatRef = _firestore.collection('chats').doc();
    final newChat = Chat(
      id: chatRef.id,
      emergencyId: emergencyId,
      userId: userId,
      responderId: responderId,
      userName: userName,
      responderName: responderName,
      responderType: responderType,
      createdAt: Timestamp.now(),
      lastMessage: "Request Accepted. You can now chat.",
      lastMessageTime: Timestamp.now(),
      isActive: true,
    );

    await chatRef.set(newChat.toMap());
    
    // Add default system message
    await sendMessage(
      chatId: chatRef.id,
      senderId: 'system',
      senderName: 'System',
      senderType: 'system',
      text: "Responder has accepted the request. Help is on the way.",
    );

    return chatRef.id;
  }

  // Send text message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required String text,
    String mediaUrl = '',
    String mediaType = 'none',
  }) async {
    final msgRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    
    final newMessage = RealtimeChatMessage(
      id: msgRef.id,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      text: text,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      timestamp: Timestamp.now(),
      isRead: false,
    );

    await msgRef.set(newMessage.toMap());

    // Update last message in chat document
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': mediaType == 'none' ? text : '📷 $mediaType attached',
      'lastMessageTime': Timestamp.now(),
    });
  }

  // Send media message (photo/video)
  Future<void> sendMediaMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String senderType,
    required File media,
    required String mediaType,
  }) async {
    String? mediaUrl;
    if (mediaType == 'video') {
      mediaUrl = await _cloudinaryService.uploadVideo(media);
    } else {
      mediaUrl = await _cloudinaryService.uploadImage(media);
    }

    if (mediaUrl != null) {
      await sendMessage(
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderType: senderType,
        text: "",
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );
    } else {
      throw Exception("Failed to upload media.");
    }
  }

  // Get chat stream (real-time updates)
  Stream<List<RealtimeChatMessage>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RealtimeChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Mark messages as read
  // (Simple implementation: marks all messages in chat not from me as read)
  Future<void> markAsRead(String chatId, String myUserId) async {
    final unreadMessagesQuery = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadMessagesQuery.docs) {
      if (doc['senderId'] != myUserId) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  // Get chat by emergency ID
  Future<Chat?> getChatByEmergencyId(String emergencyId) async {
    final query = await _firestore
        .collection('chats')
        .where('emergencyId', isEqualTo: emergencyId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return Chat.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  // End chat
  Future<void> endChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isActive': false,
      'lastMessage': 'Chat ended by system.',
      'lastMessageTime': Timestamp.now(),
    });
  }
}
