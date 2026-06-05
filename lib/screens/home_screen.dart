import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

import 'camera_screen.dart';
import 'navigation_voice_screen.dart';
import 'todo_screen.dart';
import 'voice_assistant_screen.dart';
import 'ocr_caption_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts _tts = FlutterTts();
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _speechReady = false;
  bool _assistantActive = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initTts();
    _initSpeech();
  }

  @override
  void dispose() {
    _stopAssistant();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.5);
    await _tts.setLanguage("en_IN");
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _initSpeech() async {
    await Permission.microphone.request();

    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          _isListening = false;
        }
      },
      onError: (_) => _isListening = false,
    );

    if (_speechReady && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      _startAssistant();
    }
  }

  Future<void> _startAssistant() async {
    if (!_speechReady || _assistantActive) return;
    _assistantActive = true;

    await _speak(
      "Welcome. You can say camera, navigation, todo list, voice assistant, or OCR.",
    );

    _startListening();
  }

  Future<void> _stopAssistant() async {
    _assistantActive = false;
    _isListening = false;
    await _speech.stop();
    await _tts.stop();
  }

  Future<void> _speak(String text) async {
    if (!_assistantActive) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  void _startListening() {
    if (!_speechReady || _isListening || !_assistantActive) return;

    setState(() => _isListening = true);

    _speech.listen(
      localeId: "en_IN",
      pauseFor: const Duration(seconds: 4),
      onResult: (result) {
        if (!result.finalResult) return;

        final text = result.recognizedWords.toLowerCase();
        _speech.stop();
        setState(() => _isListening = false);

        _handleCommand(text);
      },
    );
  }

  void _handleCommand(String text) async {
    if (!_assistantActive) return;

    if (text.contains("camera")) {
      await _speak("Opening camera assistance");
      _openScreen(const CameraScreen());
      return;
    }

    if (text.contains("navigation") || text.contains("map")) {
      await _speak("Opening navigation");
      _openScreen(const NavigationVoiceScreen());
      return;
    }

    if (text.contains("todo") || text.contains("task")) {
      await _speak("Opening todo list");
      _openScreen(const TodoScreen());
      return;
    }

    if (text.contains("voice")) {
      await _speak("Opening voice assistant");
      _openScreen(const VoiceAssistantScreen());
      return;
    }

    if (text.contains("ocr") || text.contains("read") || text.contains("caption")) {
      await _speak("Opening OCR and captions");
      _openScreen(const OcrCaptionScreen());
      return;
    }

    await _speak("Sorry, I did not understand. Please try again.");
    _startListening();
  }

  void _openScreen(Widget screen) async {
    await _stopAssistant();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      _startAssistant();
    }
  }

  Widget _homeButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 70),
      ),
      onPressed: onTap,
      child: Text(text, style: TextStyle(fontSize: 22, color: textColor)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.mic, color: Colors.white, size: 80),
            Text(
              _isListening ? "Listening..." : "Tap or Speak",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),

            _homeButton(
              text: "Camera Assistance",
              color: Colors.white,
              textColor: Colors.black,
              onTap: () => _openScreen(const CameraScreen()),
            ),

            _homeButton(
              text: "Navigation",
              color: Colors.green,
              textColor: Colors.black,
              onTap: () => _openScreen(const NavigationVoiceScreen()),
            ),

            _homeButton(
              text: "Todo List",
              color: Colors.blue,
              textColor: Colors.white,
              onTap: () => _openScreen(const TodoScreen()),
            ),

            _homeButton(
              text: "OCR & Captions",
              color: Colors.purple,
              textColor: Colors.white,
              onTap: () => _openScreen(const OcrCaptionScreen()),
            ),

            _homeButton(
              text: "Voice Assistant",
              color: Colors.yellow,
              textColor: Colors.black,
              onTap: () => _openScreen(const VoiceAssistantScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
