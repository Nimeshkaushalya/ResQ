import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String emergencyId;
  final String userId;
  final String responderId;
  final String userName;
  final String responderName;
  final String responderType;
  final Timestamp createdAt;
  final String lastMessage;
  final Timestamp lastMessageTime;
  final bool isActive;

  Chat({
    required this.id,
    required this.emergencyId,
    required this.userId,
    required this.responderId,
    required this.userName,
    required this.responderName,
    required this.responderType,
    required this.createdAt,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.isActive,
  });

  factory Chat.fromMap(Map<String, dynamic> data, String id) {
    return Chat(
      id: id,
      emergencyId: data['emergencyId'] ?? '',
      userId: data['userId'] ?? '',
      responderId: data['responderId'] ?? '',
      userName: data['userName'] ?? '',
      responderName: data['responderName'] ?? '',
      responderType: data['responderType'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: data['lastMessageTime'] ?? Timestamp.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emergencyId': emergencyId,
      'userId': userId,
      'responderId': responderId,
      'userName': userName,
      'responderName': responderName,
      'responderType': responderType,
      'createdAt': createdAt,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'isActive': isActive,
    };
  }
}

class RealtimeChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderType; // 'user' or 'responder'
  final String text;
  final String mediaUrl;
  final String mediaType; // 'image', 'video', 'none'
  final Timestamp timestamp;
  final bool isRead;

  RealtimeChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.text,
    this.mediaUrl = '',
    this.mediaType = 'none',
    required this.timestamp,
    this.isRead = false,
  });

  factory RealtimeChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return RealtimeChatMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderType: data['senderType'] ?? 'user',
      text: data['text'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      mediaType: data['mediaType'] ?? 'none',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}
