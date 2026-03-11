import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../core/vision_engine.dart';
import '../core/decay_math.dart';

class CameraScanner extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScanner({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraScannerState createState() => _CameraScannerState();
}

class _CameraScannerState extends State<CameraScanner> {
  late CameraController _controller;
  final VisionEngine _visionEngine = VisionEngine();
  final DecayEngine _decayEngine = DecayEngine();

  bool _isProcessing = false;
  bool _isEngineReady = false;

  // Mocked Hardware Variables (Until ESP32 arrives)
  double _mockTemp = 32.0; // Simulated Chennai Heat
  double _mockHumidity = 80.0;
  double _mockGasPPM = 10.0;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    // 1. Initialize Camera
    _controller = CameraController(widget.cameras[0], ResolutionPreset.high);
    await _controller.initialize();

    // 2. Wake up the Bio Clock AI
    await _visionEngine.initializeEngine();
    
    setState(() {
      _isEngineReady = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndAnalyze() async {
    if (!_controller.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Snap the photo
      final XFile image = await _controller.takePicture();
      File imgFile = File(image.path);

      // 2. Feed to Edge AI
      Map<String, dynamic> aiResult = await _visionEngine.analyzeState(imgFile);
      
      if (aiResult.containsKey("error")) {
        _showError(aiResult["error"]);
        return;
      }

      // 3. Feed AI result + Mocked Sensors to the Math Engine
      Map<String, dynamic> decayResult = _decayEngine.calculateRemainingLife(
        itemName: aiResult["item_name"], 
        visualFreshnessProbability: aiResult["fresh_probability"], 
        currentTempC: _mockTemp, 
        currentHumidity: _mockHumidity, 
        ethyleneGasPPM: _mockGasPPM,
      );

      // 4. Display the Results
      _showResultsBottomSheet(aiResult, decayResult, imgFile);

    } catch (e) {
      _showError("Failed to capture image: $e");
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showResultsBottomSheet(Map<String, dynamic> ai, Map<String, dynamic> math, File image) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("AI Analysis Complete", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Divider(),
              Text("Item Detected: ${ai['item_name']}", style: TextStyle(fontSize: 18)),
              Text("Biological State: ${ai['state']} (${(ai['fresh_probability'] * 100).toStringAsFixed(1)}% Fresh)"),
              const SizedBox(height: 16),
              Text("Bio Clock Countdown", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const Divider(),
              Text("Environment: ${_mockTemp}°C | ${_mockHumidity}% Hum | ${_mockGasPPM} PPM", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Text(math['formatted_time'], style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.green)),
              Text(math['status_alert'], style: TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Scan Another Item"),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEngineReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Bio Clock Edge", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Camera Feed
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller),
          ),
          
          // Environmental Mocking Controls (Temporary until hardware arrives)
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  const Text("Hardware Simulator", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _mockTemp, min: 2.0, max: 45.0, divisions: 43,
                    label: "${_mockTemp.round()}°C",
                    activeColor: Colors.orange,
                    onChanged: (val) => setState(() => _mockTemp = val),
                  ),
                ],
              ),
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text("Processing 18.8MB Edge AI...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _captureAndAnalyze,
        backgroundColor: Colors.green,
        child: const Icon(Icons.camera_alt, size: 36),
      ),
    );
  }
}