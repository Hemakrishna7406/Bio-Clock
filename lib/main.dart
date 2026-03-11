 import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/prediction_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We can still fetch them here to warm up the hardware, 
  // but we won't force them into the app widget anymore.
  await availableCameras(); 
  runApp(const BioClockApp());
}

class BioClockApp extends StatelessWidget {
  const BioClockApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bio Clock',
      theme: ThemeData.dark(),
      // Removed the 'cameras: cameras' argument to satisfy the compiler
      home: const PredictionScreen(), 
    );
  }
}