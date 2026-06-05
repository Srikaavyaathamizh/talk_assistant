import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'caption_service.dart';

class CaptionCameraScreen extends StatefulWidget {
  const CaptionCameraScreen({super.key});

  @override
  State<CaptionCameraScreen> createState() => _CaptionCameraScreenState();
}

class _CaptionCameraScreenState extends State<CaptionCameraScreen>
    with WidgetsBindingObserver {
  late CameraController _controller;
  late List<CameraDescription> _cameras;

  bool _isInitialized = false;
  bool _isProcessing = false;

  final FlutterTts _tts = FlutterTts();
  String _captionText = "Point the camera and tap capture";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tts.setSpeechRate(0.5);
    _initCamera();
  }

  // 🔁 Handle app lifecycle (prevents camera crash)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();

      _controller = CameraController(
        _cameras.first, // back camera
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller.initialize();
      await _controller.setFlashMode(FlashMode.off);

      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _captionText = "Camera initialization failed";
      });
    }
  }

  Future<void> _captureAndCaption() async {
    if (!_controller.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _captionText = "Analyzing surroundings...";
    });

    await _tts.stop();
    await _tts.speak("Analyzing surroundings");

    try {
      final XFile picture = await _controller.takePicture();
      final File imageFile = File(picture.path);

      final String caption =
      await CaptionService.generateCaption(imageFile);

      setState(() {
        _captionText = caption;
        _isProcessing = false;
      });

      await _tts.speak(caption);
    } catch (e) {
      setState(() {
        _captionText = "Failed to analyze surroundings";
        _isProcessing = false;
      });
      await _tts.speak("Failed to analyze surroundings");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Caption Camera"),
        backgroundColor: Colors.black,
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CameraPreview(_controller),

          // 📝 Caption overlay
          Positioned(
            bottom: 140,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _captionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          // 📸 Capture button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor:
                _isProcessing ? Colors.grey : Colors.blue,
                onPressed: _isProcessing
                    ? null
                    : _captureAndCaption,
                child: const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
