import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'ocr_camera_screen.dart';
import 'caption_camera_screen.dart';

class OcrCaptionScreen extends StatefulWidget {
  const OcrCaptionScreen({super.key});

  @override
  State<OcrCaptionScreen> createState() => _OcrCaptionScreenState();
}

class _OcrCaptionScreenState extends State<OcrCaptionScreen> {
  final FlutterTts _tts = FlutterTts();
  late stt.SpeechToText _speech;

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _speak(
      "OCR and captions screen. "
          "Say open OCR to read documents. "
          "Say open captions to describe surroundings.",
    );
  }

  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(0.5);
    await _tts.stop();
    await _tts.speak(text);
  }

  // 🎤 Listen for voice commands
  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (!available) return;

      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            _handleVoiceCommand(result.recognizedWords.toLowerCase());
          }
        },
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // 🧠 Voice command logic
  void _handleVoiceCommand(String command) {
    setState(() => _isListening = false);
    _speech.stop();

    if (command.contains("ocr")) {
      _speak("Opening OCR camera");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OcrCameraScreen()),
      );
    } else if (command.contains("caption") ||
        command.contains("describe")) {
      _speak("Opening caption camera");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CaptionCameraScreen()),
      );
    } else {
      _speak("Sorry, please say open OCR or open captions");
    }
  }

  Widget _button(String text, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 70),
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: const TextStyle(fontSize: 22, color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("OCR & Captions"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _button(
              "OCR - Read Document",
              Colors.white,
                  () {
                _speak("Opening OCR camera");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OcrCameraScreen(),
                  ),
                );
              },
            ),
            _button(
              "Captions - Describe Scene",
              Colors.orange,
                  () {
                _speak("Opening caption camera");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaptionCameraScreen(),
                  ),
                );
              },
            ),

            // 🎤 Voice command button
            FloatingActionButton(
              backgroundColor: _isListening ? Colors.red : Colors.blue,
              onPressed: _listen,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
