import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import '../core/ble_engine.dart';
import '../core/vision_engine.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final BLEEngine bleEngine = BLEEngine();
  final VisionEngine visionEngine = VisionEngine();

  String temperature = "-- °C";
  String humidity = "-- %";
  String gasLevel = "-- ppm";

  @override
  void initState() {
    super.initState();
    // Start connecting to UNO R4 immediately
    bleEngine.startScan();
    visionEngine.loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bio-Clock Ecosystem"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Hardware Telemetry", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSensorCard("Temp", temperature, Icons.thermostat),
                _buildSensorCard("Humidity", humidity, Icons.water_drop),
                _buildSensorCard("Ethylene", gasLevel, Icons.cloud),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              "Local AI Inference", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
              },
              icon: const Icon(Icons.camera_alt, size: 30),
              label: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Launch Bio-Scanner", style: TextStyle(fontSize: 20)),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.tealAccent),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
