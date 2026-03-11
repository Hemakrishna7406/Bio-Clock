import 'dart:io';
import 'dart:typed_data';
import 'package:pytorch_lite/pytorch_lite.dart';

class VisionEngine {
  ClassificationModel? _classificationModel;
  bool _isLoaded = false;

  Future<void> initializeEngine() async {
    try {
      print("🧠 Waking up BIO-CLOCK Vision Engine (State-Only Mode)...");
      _classificationModel = await PytorchLite.loadClassificationModel(
        "assets/models/bio_clock_edge.ptl", 
        224, 
        224, 
        65, 
        labelPath: "assets/models/bio_clock_item_mapping.json", 
      );
      _isLoaded = true;
      print("✅ BIO-CLOCK Vision Engine Online.");
    } catch (e) {
      print("❌ CRITICAL ERROR loading model: \$e");
    }
  }

  Future<Map<String, dynamic>> analyzeState(File imageFile) async {
    if (!_isLoaded || _classificationModel == null) {
      throw Exception("Vision Engine is offline.");
    }

    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      
      // rawScores contains 65 values
      List<double> rawScores = await _classificationModel!.getImagePredictionList(imageBytes);

      // --- HEAD 2: BIOLOGICAL STATE (Indices 63 and 64) ---
      // IGNORING 0-62 (Item identification is now manual)
      double freshProb = rawScores[63];
      double rottenProb = rawScores[64];
      
      String currentState = (rottenProb > freshProb) ? "Rotten" : "Fresh";

      print("🎯 BIO-CLOCK STATE INFERENCE COMPLETE:");
      print("State: \$currentState (F: \${freshProb.toStringAsFixed(2)}, R: \${rottenProb.toStringAsFixed(2)})");

      return {
        "state": currentState,
        "rotten_probability": rottenProb,
        "fresh_probability": freshProb,
      };
    } catch (e) {
      print("❌ INFERENCE CRASH: \$e");
      rethrow;
    }
  }
}