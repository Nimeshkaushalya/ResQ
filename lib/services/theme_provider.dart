import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  String _language = 'English';
  bool _notificationsEnabled = true;

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  bool get notificationsEnabled => _notificationsEnabled;

  final Map<String, Map<String, String>> _localizedValues = {
    'English': {
      'app_title': 'ResQ',
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'emergency_reported': 'Emergency reported successfully!',
      'need_help': 'Need help? Report an Emergency',
      'not_set': 'Not set',
      'blood_group': 'Blood Group',
      'recent_activity': 'Recent Activity',
      'logout': 'Logout',
      'emergency_question': 'Are you in an emergency?',
      'sos_instruction': 'Press the SOS button or select an emergency type below.',
      'police': 'Police',
      'ambulance': 'Ambulance',
      'report_incident': 'Report Incident',
      'medical': 'Medical',
      'fire': 'Fire',
      'accident': 'Accident',
      'crime': 'Crime',
    },
    'සිංහල': {
      'app_title': 'ResQ',
      'home': 'ප්‍රධාන පිටුව',
      'profile': 'පරිශීලක තොරතුරු',
      'settings': 'සැකසුම්',
      'emergency_reported': 'හදිසි වාර්තාව සාර්ථකව යොමු කරන ලදී!',
      'need_help': 'උදව් අවශ්‍යද? හදිසි තත්වයක් වාර්තා කරන්න',
      'not_set': 'සකසා නැත',
      'blood_group': 'ලේ වර්ගය',
      'recent_activity': 'මෑතකාලීන ක්‍රියාකාරකම්',
      'logout': 'ඇප් එකෙන් ඉවත් වන්න',
      'emergency_question': 'ඔබ හදිසි අවස්ථාවකද?',
      'sos_instruction': 'SOS බොත්තම ඔබන්න හෝ පහතින් හදිසි අවස්ථාව තෝරන්න.',
      'police': 'පොලිසිය',
      'ambulance': 'ගිලන් රථ',
      'report_incident': 'සිදුවීම වාර්තා කරන්න',
      'medical': 'වෛද්‍ය',
      'fire': 'ගිනි ගැනීම්',
      'accident': 'අනතුරු',
      'crime': 'අපරාධ',
    },
    'தமிழ்': {
      'app_title': 'ResQ',
      'home': 'முகப்பு',
      'profile': 'சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'emergency_reported': 'அவசர அறிக்கை வெற்றிகரமாக சமர்ப்பிக்கப்பட்டது!',
      'need_help': 'உதவி வேண்டுமா? அவசரநிலையைப் புகாரளிக்கவும்',
      'not_set': 'அமைக்கப்படவில்லை',
      'blood_group': 'இரத்த வகை',
      'recent_activity': 'சமீபத்திய செயல்பாடு',
      'logout': 'வெளியேறு',
      'emergency_question': 'நீங்கள் அவசரத்தில் இருக்கிறீர்களா?',
      'sos_instruction': 'SOS பொத்தானை அழுத்தவும் அல்லது கீழே உள்ள அவசர வகையைத் தேர்ந்தெடுக்கவும்.',
      'police': 'போலீஸ்',
      'ambulance': 'ஆம்புலன்ஸ்',
      'report_incident': 'சம்பவத்தைப் புகாரளிக்கவும்',
      'medical': 'மருத்துவம்',
      'fire': 'நெருப்பு',
      'accident': 'விபத்து',
      'crime': 'குற்றம்',
    }
  };

  String t(String key) {
    return _localizedValues[_language]?[key] ?? _localizedValues['English']![key] ?? key;
  }

  ThemeProvider() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _language = prefs.getString('language') ?? 'English';
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    notifyListeners();
  }
}
