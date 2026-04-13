import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// Top-level function for isolate
List<List<List<List<int>>>>? preprocessImage(Uint8List bytes) {
  try {
    final img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return null;

    final img.Image resizedImage =
        img.copyResize(decodedImage, width: 224, height: 224);

    return List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          },
        ),
      ),
    );
  } catch (e) {
    print("Preprocessing error: $e");
    return null;
  }
}

class OfflineAIService {
  Interpreter? _interpreter;
  List<String>? _labels;

  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/model.tflite');
      final labelsData = await rootBundle.loadString('assets/ml/labels.txt');
      _labels = labelsData.split('\n');
      print('TFLite Model loaded successfully');
    } catch (e) {
      print('Error loading offline model: $e');
    }
  }

  Future<String> analyzeImageOffline(File imageFile, {String? emergencyHint}) async {
    if (_interpreter == null || _labels == null) {
      return "Offline model not loaded. Please try again later.";
    }

    try {
      // Offload image decoding, resizing and tensor matrix creation to an isolate
      // This prevents the UI from freezing (Application Not Responding)
      final bytes = await imageFile.readAsBytes();
      final input = await compute(preprocessImage, bytes);

      if (input == null) return "Failed to decode image.";

      var output = List.generate(1, (i) => List.filled(1001, 0));

      _interpreter!.run(input, output);

      int highestIdx = 0;
      int highestProb = 0;
      final results = output[0];
      for (int i = 0; i < results.length; i++) {
        if (results[i] > highestProb) {
          highestProb = results[i];
          highestIdx = i;
        }
      }

      String detectedLabel = _labels![highestIdx];

      return '''[OFFLINE ANALYSIS]
Detected Object: $detectedLabel (Confidence: ${(highestProb / 255.0 * 100).toStringAsFixed(1)}%)

SEVERITY: Unknown (Offline Mode)

FIRST AID STEPS (Generic):
1. Ensure the scene is safe and remove any immediate danger.
2. If it is a severe injury, call emergency services immediately.
3. Apply pressure to any bleeding using a clean cloth. 
4. Keep the person calm and still while awaiting help.

DO'S:
- Keep the area clean.
- Stay calm.

DON'TS:
- Do not apply unprescribed ointments.
- Do not move the person if a spinal injury is suspected.

SEEK PROFESSIONAL HELP: Yes
REASON: This is an offline generic model analysis, accurate medical assessment requires professional help or ResQ AI online.''';
    } catch (e) {
      print("Offline Analysis Error: $e");
      return "Could not analyze incident offline.";
    }
  }
}
