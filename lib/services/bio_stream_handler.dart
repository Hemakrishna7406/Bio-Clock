import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../core/vision_engine.dart';
import 'aws_api_service.dart';

class BioStreamHandler extends ChangeNotifier {
  final VisionEngine _visionEngine;
  
  bool _isProcessing = false;
  Timer? _throttleTimer;
  bool _canProcessNext = true;
  
  // Reactive UI State
  String? currentProduce;
  double? freshnessScore;
  String? aiAnalysis;
  double? rulHours;
  bool isApiLoading = false;
  String? uiMessage;

  BioStreamHandler(this._visionEngine);

  /// Analyzes the `CameraImage` directly from the `CameraPreview` stream.
  void processCameraFrame(CameraImage image, double mockTemp, double mockHumid, double mockEthylene) async {
    // 1. Throttle: Only process one frame every 500ms to save CPU
    if (!_canProcessNext || _isProcessing || isApiLoading) return;

    _isProcessing = true;
    _canProcessNext = false;
    
    // Refresh throttle gate
    _throttleTimer?.cancel();
    _throttleTimer = Timer(const Duration(milliseconds: 500), () {
      _canProcessNext = true;
    });

    try {
      // 2. High-Speed Local Inference (Runs on Edge)
      final localData = await _visionEngine.analyzeStateFromBuffer(image);
      final double freshProb = localData['fresh_probability'] ?? 0.0;
      final double rottenProb = localData['rotten_probability'] ?? 0.0;
      final String produceName = localData['item_name'] ?? 'Unknown';

      final double maxConfidence = freshProb > rottenProb ? freshProb : rottenProb;

      // 3. Confidence Gate > 85%
      if (maxConfidence >= 0.85) {
        // Update local reactive state instantly
        currentProduce = produceName;
        freshnessScore = freshProb;
        isApiLoading = true;
        uiMessage = "Analyzing $produceName...";
        notifyListeners(); // Updates the UI StreamBuilder/Consumer instantly

        // 4. Base64 Bridge Conversion
        final String base64Image = _convertYuv420ToBase64(image);

        // 5. Cloud Invocation
        final cloudResponse = await BioClockApiService.analyzeProduce(
          produceClass: produceName,
          freshProb: freshProb,
          rottenProb: rottenProb,
          tempC: mockTemp,
          humidityPct: mockHumid,
          ethylenePpm: mockEthylene,
          base64Image: base64Image,
        );
        
        // Update UI with Cloud Results
        aiAnalysis = cloudResponse['ai_ai_analysis'];
        rulHours = cloudResponse['remaining_useful_life_hours'];
        uiMessage = "Analysis Complete";

      } else {
        // Drop frame silently
      }

    } catch (e) {
      // 6. Error Grace
      uiMessage = "Optimizing Connection...";
      debugPrint("API Error: $e");
    } finally {
      isApiLoading = false;
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Extremely fast conversion of YUV420 Camera bytes to Base64 String
  String _convertYuv420ToBase64(CameraImage image) {
    try {
      // Combine all planes into a single byte buffer
      final int length = image.planes.fold(0, (count, plane) => count + plane.bytes.length);
      final Uint8List allBytes = Uint8List(length);
      int offset = 0;
      for (Plane plane in image.planes) {
        allBytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
        offset += plane.bytes.length;
      }
      return base64Encode(allBytes);
    } catch (e) {
      debugPrint("Image conversion failed: $e");
      return "";
    }
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    super.dispose();
  }
}
