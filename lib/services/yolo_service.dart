import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class YoloService {
  late Interpreter _interpreter;
  late List<String> _labels;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset(
      'assets/models/yolov5n.tflite',
      options: InterpreterOptions()..threads = 2,
    );

    _labels = (await rootBundle
        .loadString('assets/models/labels.txt'))
        .split('\n');

    print('YOLO model loaded');
  }

  Interpreter get interpreter => _interpreter;
  List<String> get labels => _labels;

  void close() {
    _interpreter.close();
  }
}
