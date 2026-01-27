// Port of types.ts
enum EmergencyType {
  medical,
  fire,
  accident,
  crime,
  other,
}

// Helper to convert string to enum if needed, or just use display labels
extension EmergencyTypeExtension on EmergencyType {
  String get displayName {
    switch (this) {
      case EmergencyType.medical: return 'Medical';
      case EmergencyType.fire: return 'Fire';
      case EmergencyType.accident: return 'Accident';
      case EmergencyType.crime: return 'Crime';
      case EmergencyType.other: return 'Other';
    }
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});
}

class IncidentReport {
  final String id;
  final EmergencyType type;
  final String description;
  final Coordinates? location;
  final int timestamp;
  final String status; // 'pending' | 'dispatched' | 'resolved'
  final String? aiAnalysis;

  IncidentReport({
    required this.id,
    required this.type,
    required this.description,
    this.location,
    required this.timestamp,
    required this.status,
    this.aiAnalysis,
  });
}

class ChatMessage {
  final String role; // 'user' | 'model'
  final String text;
  final int timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });
}
