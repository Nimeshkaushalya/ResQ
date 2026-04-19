import 'package:cloud_firestore/cloud_firestore.dart';

class AIEvaluationRecord {
  final String id;
  final bool isActualEmergency;   
  final bool isGeminiPredicted;   
  final double geminiConfidence;  
  final DateTime timestamp;

  AIEvaluationRecord({
    required this.id,
    required this.isActualEmergency,
    required this.isGeminiPredicted,
    required this.geminiConfidence,
    required this.timestamp,
  });

  factory AIEvaluationRecord.fromMap(String id, Map<String, dynamic> map) {
    return AIEvaluationRecord(
      id: id,
      isActualEmergency: map['isActualEmergency'] ?? false,
      isGeminiPredicted: map['isGeminiPredicted'] ?? false,
      geminiConfidence: (map['geminiConfidence'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActualEmergency': isActualEmergency,
      'isGeminiPredicted': isGeminiPredicted,
      'geminiConfidence': geminiConfidence,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
