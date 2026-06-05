import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _camera;
  Interpreter? _interpreter;
  FlutterTts _tts = FlutterTts();

  List<String> _labels = [];
  bool _busy = false;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _initCamera();
    await _loadLabels();
    await _loadModel();
    await _tts.setSpeechRate(0.5);
  }

  // ---------------- INIT CAMERA ----------------
  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

    _camera = CameraController(
      back,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _camera!.initialize();
    setState(() {});
  }

  // ---------------- LOAD LABELS ----------------
  Future<void> _loadLabels() async {
    final data = await rootBundle.loadString('assets/labels.txt');
    _labels = data.split('\n');
  }

  // ---------------- LOAD MODEL ----------------
  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/yolov5n.tflite');
    _modelReady = true;
  }

  // ---------------- TAKE PHOTO → SAVE → ANALYZE ----------------
  Future<void> _captureAndAnalyze() async {
    if (_busy || !_modelReady || !_camera!.value.isInitialized) return;
    _busy = true;

    try {
      // 📸 TAKE PHOTO
      final XFile photo = await _camera!.takePicture();

      // 💾 SAVE IMAGE
      final dir = await getApplicationDocumentsDirectory();
      final savedImage = File('${dir.path}/captured.jpg');
      await savedImage.writeAsBytes(await photo.readAsBytes());

      // 🔁 LOAD IMAGE AGAIN (SAFE)
      final bytes = await savedImage.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception("Image decode failed");

      img.Image image = img.copyResize(decoded, width: 640, height: 640);

      final input = _imageToTensor(image);

      final output = List.generate(
        1,
            (_) => List.generate(25200, (_) => List.filled(85, 0.0)),
      );

      _interpreter!.run(input, output);
      _analyze(output);

    } catch (e) {
      debugPrint("YOLO ERROR: $e");
      _tts.speak("Error detecting objects");
    }

    _busy = false;
  }

  // ---------------- IMAGE → TENSOR ----------------
  Float32List _imageToTensor(img.Image image) {
    final Float32List input = Float32List(3 * 640 * 640);
    int i = 0;

    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final p = image.getPixel(x, y);
          final v = c == 0 ? p.r : c == 1 ? p.g : p.b;
          input[i++] = v / 255.0;
        }
      }
    }
    return input;
  }

  // ---------------- YOLO OUTPUT ----------------
  void _analyze(List output) {
    final Set<String> found = {};

    for (int i = 0; i < 25200; i++) {
      final row = output[0][i];
      if (row[4] < 0.5) continue;

      int cls = -1;
      double score = 0;

      for (int c = 5; c < 85; c++) {
        if (row[c] > score) {
          score = row[c];
          cls = c - 5;
        }
      }

      if (score > 0.6 && cls >= 0 && cls < _labels.length) {
        found.add(_labels[cls]);
      }
    }

    if (found.isEmpty) {
      _tts.speak("I do not see any object");
    } else {
      _tts.speak("I see ${found.join(', ')}");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    if (_camera == null || !_camera!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_camera!),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: _captureAndAnalyze,
                child: const Icon(Icons.camera),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _camera?.dispose();
    _interpreter?.close();
    _tts.stop();
    super.dispose();
  }
}
