import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fruits_recognizer/constants.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  XFile? image;
  String result = '';
  List<String> fruitsName = <String>[];
  List<String> defectName = <String>[];
  late CameraController camController;
  late ImageLabeler recognizer, defectDetector;
  bool camFlag = true;

  snackBar(String msg, Color bg, Color fg) {
    return ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: fg)), backgroundColor: bg));
  }

  Future<void> loadLabels() async {
    var file = await rootBundle.loadString('assets/fruits.txt');
    fruitsName = file.split('\n');

    file = await rootBundle.loadString('assets/defects.txt');
    defectName = file.split('\n');
  }

  Future<void> loadModel() async {
    const model1 = "flutter_assets/assets/fruits.tflite";
    final options1 = LocalLabelerOptions(modelPath: model1, confidenceThreshold: 0.7);
    recognizer = GoogleMlKit.vision.imageLabeler(options1);

    const model2 = "flutter_assets/assets/defect.tflite";
    final options2 = LocalLabelerOptions(modelPath: model2, confidenceThreshold: 0.7);
    defectDetector = GoogleMlKit.vision.imageLabeler(options2);
  }

  Future<void> recognizeFruit() async {
    if (image == null) {
      snackBar("Please add an image first!", Colors.red, Colors.white);
      return;
    }

    result = '';
    final InputImage inputImage = InputImage.fromFile(File(image!.path));
    final detectedLabels = await recognizer.processImage(inputImage);
    result += 'Detected ${detectedLabels.length} Fruit(s).\n';
    for (int i = 0; i < detectedLabels.length; i++) {
      final text = fruitsName[detectedLabels[i].index];
      final confidence = '${(detectedLabels[i].confidence * 100).toStringAsFixed(1)}%';
      result += '\n$text, confidence: $confidence';
    }
    setState(() {});
  }

  Future<void> detectDefect() async {
    if (image == null) {
      snackBar("Please add an image first!", Colors.red, Colors.white);
      return;
    }

    result = '';
    final InputImage inputImage = InputImage.fromFile(File(image!.path));
    final detectedLabels = await defectDetector.processImage(inputImage);
    result += 'Detected ${detectedLabels.length} Fruit(s).\n';
    for (int i = 0; i < detectedLabels.length; i++) {
      final text = defectName[detectedLabels[i].index];
      final confidence = '${(detectedLabels[i].confidence * 100).toStringAsFixed(1)}%';
      result += '\n$text, confidence: $confidence';
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    camController = CameraController(cameras[0], ResolutionPreset.high);
    camController.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        snackBar(e.description ?? "Error!", Colors.red, Colors.white);
      }
    });
    loadModel();
    loadLabels();
  }

  @override
  void dispose() {
    camController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appName),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                height: camFlag ? MediaQuery.of(context).size.height * 0.75 : 300,
                child: camController.value.isInitialized && camFlag
                    ? CameraPreview(camController)
                    : image == null
                        ? const Center(child: Text("Please select an image first!"))
                        : Image.file(File(image!.path)),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        camFlag = !camFlag;
                        if (camFlag == true) {
                          camController.resumePreview();
                        } else {
                          camController.pausePreview();
                          camController.takePicture().then((img) {
                            image = img;
                          });
                        }
                      });
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size(120, 40)),
                    child: Text(camFlag ? "Capture" : "Open Camera"),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      var pickedfile = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (pickedfile != null) {
                        image = pickedfile;
                        setState(() {});
                      }
                    },
                    style: OutlinedButton.styleFrom(minimumSize: const Size(120, 40)),
                    child: const Text("Open gallery"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => recognizeFruit(),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(160, 50),
                        backgroundColor: Colors.indigoAccent,
                        foregroundColor: Colors.white),
                    child: const Text("Recognize"),
                  ),
                  OutlinedButton(
                    onPressed: () => detectDefect(),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(160, 50),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white),
                    child: const Text("Defect Detect"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text("Result: ", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(result)
            ],
          ),
        ),
      ),
    );
  }
}
