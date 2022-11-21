import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fruits_recognizer/app_screen.dart';
import 'package:fruits_recognizer/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
