import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class YoloDetectionService {
  late Interpreter _interpreter;
  late List<String> _labels;

  bool _isLoaded = false;

  // ---------------- LOAD MODEL ----------------
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'models/yolov5n.tflite', // asset path (pubspec)
      options: InterpreterOptions()..threads = 2,
    );

    _labels = (await rootBundle
        .loadString('assets/models/labels.txt'))
        .split('\n');

    _isLoaded = true;
    print('YOLO Detection Service loaded');
  }

  // ---------------- RUN INFERENCE ----------------
  List<List<double>> run(Float32List input) {
    if (!_isLoaded) {
      throw Exception('YOLO model not loaded');
    }

    // YOLOv5n output shape: [1, 25200, 85]
    final output = List.generate(
      1,
          (_) => List.generate(25200, (_) => List.filled(85, 0.0)),
    );

    _interpreter.run(
      input.reshape([1, 640, 640, 3]),
      output,
    );

    return output[0];
  }

  // ---------------- GET LABELS ----------------
  List<String> get labels => _labels;

  // ---------------- CLEANUP ----------------
  void dispose() {
    if (_isLoaded) {
      _interpreter.close();
    }
  }
}
