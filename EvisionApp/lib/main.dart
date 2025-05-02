// File: lib/main.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'features/image_picker_screen.dart' as image_picker;
import 'features/camera_capture_screen.dart';
import 'features/realtime_detection_screen.dart';
import 'features/video_picker_screen.dart' as video_picker;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EVision',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/image_picker': (context) => const image_picker.ImagePickerScreen(),
        '/camera_capture': (context) => const CameraCaptureScreen(),
        '/realtime_detection': (context) => const RealtimeDetectionScreen(),
        '/video_picker': (context) => const video_picker.VideoPickerScreen(),
      },
    );
  }
}