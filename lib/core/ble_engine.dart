import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class BLEEngine {
  final String targetServiceUUID = "19B10000-E8F2-537E-4F6C-D104768A1214";
  BluetoothDevice? connectedDevice;

  void startScan() async {
    print("🌍 Scanning for Bio-Clock Sensors...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName == "BioClockSensor") {
          print("✅ Found Bio-Clock UNO R4");
          FlutterBluePlus.stopScan();
          _connectToDevice(r.device);
          break;
        }
      }
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;
    print("🔌 Connected to Bio-Clock Hardware");

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase() == targetServiceUUID) {
        for (var char in service.characteristics) {
          if (char.properties.notify || char.properties.read) {
            await char.setNotifyValue(true);
            char.onValueReceived.listen((value) {
              String telemetry = utf8.decode(value);
              print("📡 Telemetry Stream: \$telemetry");
              // Parse 'T: 25.0, H: 50.0, G: 0.0' and push to DecayMath
            });
          }
        }
      }
    }
  }
}
