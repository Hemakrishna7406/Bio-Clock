import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../core/vision_engine.dart';
import '../services/aws_api_service.dart';

class CameraStreamOptimizer {
  final VisionEngine _visionEngine;
  bool _isProcessingFrame = false;
  Timer? _throttleTimer;
  bool _canProcessNextFrame = true;

  // Confidence Threshold for API Invocation
  final double CONFIDENCE_GATE_THRESHOLD = 0.85;

  CameraStreamOptimizer(this._visionEngine);

  /// Attaches to a CameraController's image stream
  void attachToStream(CameraController controller) {
    if (!controller.value.isStreamingImages) {
      controller.startImageStream((CameraImage image) {
        _processFrame(image);
      });
    }
  }

  void _processFrame(CameraImage image) async {
    // 1. Throttle check (max 1 frame per 500ms to save Edge CPU)
    if (!_canProcessNextFrame || _isProcessingFrame) return;

    _isProcessingFrame = true;
    _canProcessNextFrame = false;

    // Reset throttle after 500ms
    _throttleTimer?.cancel();
    _throttleTimer = Timer(const Duration(milliseconds: 500), () {
      _canProcessNextFrame = true;
    });

    try {
      // 2. Fast Local Inference (PyTorch Lite) using YUV420 Image directly
      // Note: This requires the VisionEngine to be modified to accept CameraImage directly 
      // rather than requiring a File, saving disk I/O time.
      Map<String, dynamic> localInference = await _visionEngine.analyzeStateFromBuffer(image);
      
      double freshProb = localInference['fresh_probability'] ?? 0.0;
      double rottenProb = localInference['rotten_probability'] ?? 0.0;
      
      // Determine highest confidence
      double maxConfidence = freshProb > rottenProb ? freshProb : rottenProb;
      
      // 3. The 'Confidence Gate'
      if (maxConfidence >= CONFIDENCE_GATE_THRESHOLD) {
        print("🎯 Confidence Gate Passed (${(maxConfidence * 100).toStringAsFixed(1)}%). Triggering Cloud Analysis...");
        
        // At this point, auto-trigger the AWS API call
        // Normally, you would convert the YUV420 to a JPEG Base64 string here.
        // String base64Image = _convertYUV420toBase64JPEG(image);
        
        // Mocking the call structure based on API integration
        /*
        await BioClockApiService.analyzeProduce(
          produceClass: localInference['item_name'],
          freshProb: freshProb,
          rottenProb: rottenProb,
          tempC: CurrentSensors.temp,
          humidityPct: CurrentSensors.humidity,
          ethylenePpm: CurrentSensors.ethylene,
          base64Image: base64Image
        );
        */
        
        // Fire stream event to UI to show results without button press!
      } else {
        // Silently drop frame, let user keep moving the camera
        if (kDebugMode) {
           print("🌫️ Frame dropped due to low confidence (${(maxConfidence * 100).toStringAsFixed(1)}%).");
        }
      }

    } catch (e) {
      print("Camera Stream Error: \$e");
    } finally {
      _isProcessingFrame = false;
    }
  }

  void dispose() {
    _throttleTimer?.cancel();
  }
}
