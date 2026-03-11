import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../core/vision_engine.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _cameraController;
  final VisionEngine _visionEngine = VisionEngine();
  
  Map<String, String> _synonyms = {};
  Map<String, dynamic> _produceDb = {};
  List<String> _autocompleteOptions = [];
  
  String? _selectedProduceCanonical;
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _initCamera();
  }

  Future<void> _initData() async {
    await _visionEngine.initializeEngine();
    
    String mapString = await rootBundle.loadString('assets/data/synonym_map.json');
    String dbString = await rootBundle.loadString('assets/data/produce_db.json');
    
    Map<String, dynamic> rawMap = json.decode(mapString);
    _synonyms = rawMap.map((key, value) => MapEntry(key, value.toString()));
    _produceDb = json.decode(dbString);
    _autocompleteOptions = _synonyms.keys.toList();
    
    setState(() {});
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  void _onProduceSelected(String searchTerm) {
    setState(() {
      _selectedProduceCanonical = _synonyms[searchTerm.toLowerCase()];
      _analysisResult = null; // Clear old result
    });
  }

  Future<void> _analyzePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_selectedProduceCanonical == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select produce first!")));
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      XFile file = await _cameraController!.takePicture();
      final result = await _visionEngine.analyzeState(File(file.path));
      
      setState(() {
        _analysisResult = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Analysis failed: $e")));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bio-Clock manual Scanner")),
      body: Column(
        children: [
          // Autocomplete Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') return const Iterable<String>.empty();
                return _autocompleteOptions.where((String option) {
                  return option.contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: _onProduceSelected,
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: "Select Produce (English, Tamil, Hindi)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
            ),
          ),

          // Camera Preview
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _cameraController != null && _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!)
                    : const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),

          // Analyze Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzePhoto,
              icon: _isAnalyzing ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt),
              label: Text(_isAnalyzing ? "Analyzing..." : "Analyze Photo"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),

          // Results Card
          if (_analysisResult != null && _selectedProduceCanonical != null)
            _buildResultsCard(),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    final Map<String, dynamic> produceInfo = _produceDb[_selectedProduceCanonical] ?? {};
    final String state = _analysisResult!['state'];
    final bool isFresh = state == "Fresh";

    return Card(
      margin: const EdgeInsets.all(16.0),
      color: isFresh ? Colors.green.shade900 : Colors.red.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed the backslashes to allow string interpolation
            Text("Produce: $_selectedProduceCanonical", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("State: $state", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
            const Divider(color: Colors.white54),
            Text("Optimal Temp: ${produceInfo['optimal_temp_c'] ?? '--'}°C", style: const TextStyle(color: Colors.white)),
            Text("Optimal Humidity: ${produceInfo['optimal_humidity_percent'] ?? '--'}%", style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text("Tip: ${produceInfo['tips'] ?? 'No tips available.'}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}