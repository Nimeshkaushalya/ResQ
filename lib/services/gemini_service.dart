import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  GeminiService() {
    // Check if API key is provided, else warn (or handle strictly)
    if (_apiKey.isEmpty) {
      print('WARNING: GEMINI_API_KEY is missing from .env file. AI features will fail.');
    }
  }

  // Helper to get client with specific model config if needed
  GenerativeModel _getModel(String modelName, {Content? systemInstruction}) {
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
      systemInstruction: systemInstruction,
    );
  }

  GenerativeModel getFlashModel({Content? systemInstruction}) {
    return _getModel('gemini-flash-latest', systemInstruction: systemInstruction);
  }

  Future<String> getFirstAidAdvice(String query) async {
    try {
      final systemInstruction = Content.system(
          '''You are ResQ, an intelligent emergency first aid assistant. 
        Provide clear, concise, step-by-step first aid instructions for the user's situation. 
        If the situation sounds life-threatening (e.g., no breathing, severe bleeding, chest pain), start by IMMEDIATELY telling the user to call emergency services.
        Use bullet points for steps. Keep it simple and reassuring.''');

      final model =
          _getModel('gemini-flash-latest', systemInstruction: systemInstruction);

      final response = await model.generateContent([Content.text(query)]);
      return response.text ??
          "I apologize, I could not generate advice at this moment. Please call emergency services immediately.";
    } catch (e) {
      print("Gemini API Error: $e");
      return "Network error or API Key issue. Please call emergency services immediately.";
    }
  }

  Future<String> analyzeIncident(String description, XFile? image) async {
    try {
      final model = _getModel('gemini-flash-latest');

      final prompt =
          '''Analyze this emergency situation report and provide a brief summary for first responders. 
    Assess severity (High/Medium/Low) and suggest immediate equipment needed. 
    Report Description: $description''';

      final List<Part> parts = [TextPart(prompt)];

      if (image != null) {
        final bytes = await image.readAsBytes();
        final mime = image.mimeType ?? 'image/jpeg';
        parts.insert(0, DataPart(mime, bytes));
      }

      final response = await model.generateContent([Content.multi(parts)]);
      return response.text ?? "Analysis pending...";
    } catch (e) {
      print("Gemini Analysis Error: $e");
      return "Could not analyze incident due to network error.";
    }
  }

  Future<String> analyzeInjuryPhoto(File image, {String? emergencyHint}) async {
    try {
      final model = _getModel('gemini-flash-latest');

      const prompt = '''You are a highly skilled medical first aid expert AI. Analyze this injury photo carefully.
DISCLAIMER: Always state that this is an AI analysis and the user must seek professional medical help for severe injuries.

Provide response in this EXACT format (use markdown):

**DISCLAIMER**: This is an AI analysis. Seek professional help.
**INJURY TYPE**: [Specific type of injury detected]
**SEVERITY**: [Mild / Moderate / Severe / Critical]
**CONFIDENCE**: [Give an exact percentage between 80-99%]

**FIRST AID STEPS**:
1. [Clear actionable step]
2. [Clear actionable step]

**DO'S**:
- [Crucial do]
- [Crucial do]

**DON'TS**:
- [Crucial don't]
- [Crucial don't]

**SEEK PROFESSIONAL HELP**: [Yes/No]
**REASON**: [Why professional help is or isn't needed]''';

      final bytes = await image.readAsBytes();
      final mimeType = image.path.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final parts = <Part>[TextPart(prompt), DataPart(mimeType, bytes)];

      final response = await model.generateContent([Content.multi(parts)]);
      return response.text ?? "Could not generate analysis.";
    } catch (e) {
      print("Gemini Injury Analysis Error: $e");
      return "Error connecting to AI. Please try again or seek professional help.";
    }
  }
}
