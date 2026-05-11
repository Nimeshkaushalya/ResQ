import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// This function prepares the image before sending it to the AI model
// It runs in the 'background' (isolate) so the app screen doesn't freeze
List<List<List<List<double>>>>? preprocessImage(Uint8List bytes) {
  try {
    img.Image? decodedImage = img.decodeImage(bytes); // Turns bytes into a readable image
    if (decodedImage == null) return null;

    // Fixes the orientation (e.g. if the photo was taken sideways)
    decodedImage = img.bakeOrientation(decodedImage);

    // Crops the image to a square so we don't stretch the picture
    int size = decodedImage.width < decodedImage.height ? decodedImage.width : decodedImage.height;
    int x = (decodedImage.width - size) ~/ 2;
    int y = (decodedImage.height - size) ~/ 2;
    img.Image croppedImage = img.copyCrop(decodedImage, x: x, y: y, width: size, height: size);

    // Resizes the image to 224x224 pixels, which is exactly what the TFLite model requires
    final img.Image resizedImage =
        img.copyResize(croppedImage, width: 224, height: 224);

    // This nested list is the 'Tensor' or matrix that the AI model understands
    return List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            // Normalizing color values to a range of -1.0 to 1.0 (Standard for MobileNet models)
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

// This class handles AI analysis when the user HAS NO INTERNET
class OfflineAIService {
  Interpreter? _interpreter; // This is the AI engine
  List<String>? _labels;    // These are the names of the injuries (e.g. 'Burn', 'Fracture')

  // Loads the model and labels from the assets folder into memory
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

  // The main function that takes a photo and returns the injury type
  Future<String> analyzeImageOffline(File imageFile, {String? emergencyHint}) async {
    if (_interpreter == null || _labels == null) {
      return "Offline model not loaded. Please try again later.";
    }

    try {
      final bytes = await imageFile.readAsBytes();
      // 'compute' runs the heavy preprocessing in a separate background thread
      final input = await compute(preprocessImage, bytes);

      if (input == null) return "Failed to decode image.";

      // Creates an empty list to store the AI's 'probability' results
      var output = List.generate(1, (i) => List.filled(_labels!.length, 0.0));

      // RUN THE AI MODEL: This is the actual calculation part
      _interpreter!.run(input, output);

      // Finding which label has the highest probability score
      int highestIdx = 0;
      double highestProb = 0.0;
      final results = output[0];

      Map<String, double> labelProbabilities = {};
      for (int i = 0; i < _labels!.length; i++) {
        String label = _labels![i].trim();
        // Cleaning the label text (e.g. '0 Burn' becomes 'Burn')
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
      if (detectedLabel.contains(' ')) {
        detectedLabel = detectedLabel.substring(detectedLabel.indexOf(' ') + 1);
      }

      // Get specific first aid steps based on the detected injury
      String firstAidSteps = _getSpecificFirstAid(detectedLabel);

      return '''[OFFLINE ANALYSIS]
Detected Incident: $detectedLabel
Confidence Score: ${(highestProb * 100).toStringAsFixed(1)}%

$firstAidSteps

---
IMPORTANT: This is an offline AI analysis. For a more accurate diagnosis, connect to the internet to use ResQ Online AI or consult a medical professional immediately.''';
    } catch (e) {
      print("Offline Analysis Error: $e");
      return "Could not analyze incident offline.";
    }
  }

  String _getSpecificFirstAid(String label) {
    label = label.toLowerCase().trim();
    
    if (label.contains('burn')) {
      return '''FIRST AID FOR BURNS:
1. Immediately run cool (not cold) water over the burn for at least 10-20 minutes.
2. Remove any jewelry or tight clothing before the area starts to swell.
3. Cover the burn loosely with a clean, dry cloth or sterile bandage.
4. DO NOT pop blisters or apply butter, oil, or ointments.
5. SEEK HELP: If the burn is larger than your palm or looks charred/white.''';
    } else if (label.contains('bruise')) {
      return '''FIRST AID FOR BRUISES:
1. Apply a cold compress or ice pack (wrapped in a towel) for 15-20 minutes.
2. Rest the injured area and keep it elevated if possible.
3. This will help reduce swelling and pain.
4. SEEK HELP: If there is severe pain, extreme swelling, or the bruise is near the eye.''';
    } else if (label.contains('abrasion') || label.contains('cut')) {
      return '''FIRST AID FOR CUTS & ABRASIONS:
1. Wash your hands before touching the wound.
2. Apply gentle pressure with a clean cloth to stop any bleeding.
3. Clean the wound with running water.
4. Apply a thin layer of antibiotic ointment if available.
5. Cover with a clean bandage or dressing.
6. SEEK HELP: If the wound is deep, won't stop bleeding, or was caused by a rusty object.''';
    } else if (label.contains('laseration')) {
      return '''FIRST AID FOR LACERATIONS:
1. Use a clean cloth to apply direct, steady pressure to the wound to stop bleeding.
2. If the cloth gets soaked, place another one on top without removing the first.
3. Clean the area gently with water once bleeding slows down.
4. SEEK HELP: Lacerations often require stitches to heal properly. See a doctor immediately.''';
    } else if (label.contains('normal')) {
      return '''ANALYSIS: NORMAL SKIN
1. No significant injury or emergency was detected in this image.
2. If you are experiencing pain or other symptoms not visible, please seek medical advice.
3. Stay safe!''';
    } else {
      return '''FIRST AID STEPS (Generic):
1. Ensure the scene is safe and remove any immediate danger.
2. Apply pressure to any bleeding using a clean cloth. 
3. Keep the person calm and still while awaiting help.
4. DO NOT move the person if a spinal injury is suspected.''';
    }
  }
}

