import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrCameraScreen extends StatefulWidget {
  const OcrCameraScreen({super.key});

  @override
  State<OcrCameraScreen> createState() => _OcrCameraScreenState();
}

class _OcrCameraScreenState extends State<OcrCameraScreen> {
  late CameraController _cameraController;
  bool _isCameraReady = false;
  bool _isProcessing = false;

  bool _flashOn = false; // 🔦 Flash state

  final FlutterTts _tts = FlutterTts();
  final TextRecognizer _textRecognizer =
  TextRecognizer(script: TextRecognitionScript.latin);

  // OCR result storage
  String detectedText = "";
  String captionText = "";

  // 🔵 Blue rectangle size (ROI)
  double rectWidth = 300;
  double rectHeight = 180;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initTts();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _textRecognizer.close();
    _tts.stop();
    super.dispose();
  }

  // 🔊 TTS setup
  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  // 📷 Camera setup
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController.initialize();

    // 🔥 FLASH OFF BY DEFAULT
    await _cameraController.setFlashMode(FlashMode.off);

    setState(() => _isCameraReady = true);
  }

  // 🔦 Flash toggle
  Future<void> _toggleFlash() async {
    if (!_cameraController.value.isInitialized) return;

    _flashOn = !_flashOn;

    await _cameraController.setFlashMode(
      _flashOn ? FlashMode.torch : FlashMode.off,
    );

    setState(() {});
  }

  // 🔍 Capture + OCR
  Future<void> _scanText() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final XFile picture = await _cameraController.takePicture();
    final inputImage = InputImage.fromFile(File(picture.path));

    final RecognizedText recognizedText =
    await _textRecognizer.processImage(inputImage);

    if (recognizedText.text.isNotEmpty) {
      detectedText = recognizedText.text;
      captionText = _generateCaptionText(detectedText);

      // 🔵 Adjust rectangle based on text size
      rectHeight = detectedText.length < 30 ? 120 : 220;

      setState(() {});

      // 🔊 Speak exactly what is shown
      await _tts.speak(detectedText);
      await _tts.speak(captionText);
    } else {
      detectedText = "No readable text detected";
      captionText = "Please adjust the camera and try again";
      setState(() {});
      await _tts.speak(detectedText);
    }

    _isProcessing = false;
  }

  // 🧠 Caption logic (simple + effective)
  String _generateCaptionText(String text) {
    if (text.length < 25) {
      return "Short text detected";
    } else if (text.contains(RegExp(r'\d'))) {
      return "This looks like a document with numbers";
    } else {
      return "This appears to be printed text content";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("OCR Camera"),
        backgroundColor: Colors.black,
        actions: [
          // 🔦 FLASH BUTTON
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 📷 Camera preview
          CameraPreview(_cameraController),

          // 🔵 Blue OCR rectangle
          Center(
            child: Container(
              width: rectWidth,
              height: rectHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // 📝 OCR result + caption display
          Positioned(
            bottom: 110,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Detected Text:",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                  Text(
                    detectedText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Caption:",
                    style: TextStyle(color: Colors.orange, fontSize: 16),
                  ),
                  Text(
                    captionText,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          // 🔘 Capture button
          Positioned(
            bottom: 25,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.blue,
                onPressed: _scanText,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
