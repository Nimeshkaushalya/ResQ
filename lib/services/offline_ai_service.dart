import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// Top-level function for isolate
List<List<List<List<double>>>>? preprocessImage(Uint8List bytes) {
  try {
    img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) return null;

    // Fix EXIF orientation if needed
    decodedImage = img.bakeOrientation(decodedImage);

    // Center crop to a square to prevent stretching
    int size = decodedImage.width < decodedImage.height ? decodedImage.width : decodedImage.height;
    int x = (decodedImage.width - size) ~/ 2;
    int y = (decodedImage.height - size) ~/ 2;
    img.Image croppedImage = img.copyCrop(decodedImage, x: x, y: y, width: size, height: size);

    final img.Image resizedImage =
        img.copyResize(croppedImage, width: 224, height: 224);

    return List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            // Teachable Machine Floating Point normalization (-1.0 to 1.0)
            return [
              (pixel.r.toInt() - 127.5) / 127.5,
              (pixel.g.toInt() - 127.5) / 127.5,
              (pixel.b.toInt() - 127.5) / 127.5
            ];
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
      _labels = labelsData.split('\n').where((s) => s.trim().isNotEmpty).toList();
      print('TFLite Model loaded successfully with ${_labels!.length} labels');
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

      // Dynamic output shape based on labels. Teachable machine floating point outputs doubles [0.0 - 1.0]
      var output = List.generate(1, (i) => List.filled(_labels!.length, 0.0));

      _interpreter!.run(input, output);

      int highestIdx = 0;
      double highestProb = 0.0;
      final results = output[0];

      Map<String, double> labelProbabilities = {};
      for (int i = 0; i < _labels!.length; i++) {
        String label = _labels![i].trim();
        // Clean up the label from "0 Burn" to "Burn"
        if (label.contains(' ')) {
          label = label.substring(label.indexOf(' ') + 1);
        }
        labelProbabilities[label] = results[i];

        if (results[i] > highestProb) {
          highestProb = results[i];
          highestIdx = i;
        }
      }

      print("!!!!! [FINAL RESULTS] Probabilities Map: $labelProbabilities !!!!!");

      String detectedLabel = _labels![highestIdx];
      // Note: Teachable Machine usually prefixes labels with "0 ClassName", so we can clean it up
      if (detectedLabel.contains(' ')) {
        detectedLabel = detectedLabel.substring(detectedLabel.indexOf(' ') + 1);
      }

      return '''[OFFLINE ANALYSIS]
Detected Object: $detectedLabel (Confidence: ${(highestProb * 100).toStringAsFixed(1)}%)

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
