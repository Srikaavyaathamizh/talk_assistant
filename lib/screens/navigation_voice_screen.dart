import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';

class NavigationVoiceScreen extends StatefulWidget {
  const NavigationVoiceScreen({super.key});

  @override
  State<NavigationVoiceScreen> createState() =>
      _NavigationVoiceScreenState();
}

class _NavigationVoiceScreenState extends State<NavigationVoiceScreen> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isListening = false;
  String _destination = "";

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    await _tts.setSpeechRate(0.5);
    await _tts.speak("Please say your destination");
    await Future.delayed(const Duration(seconds: 2));
    _startListening();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();

    if (!available) {
      await _tts.speak("Speech recognition not available");
      return;
    }

    setState(() => _isListening = true);

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _destination = result.recognizedWords;
          _speech.stop();
          _openGoogleMaps();
        }
      },
      listenMode: stt.ListenMode.confirmation,
    );
  }

  Future<void> _openGoogleMaps() async {
    if (_destination.isEmpty) {
      await _tts.speak("Destination not recognized");
      return;
    }

    await _tts.speak("Navigating to $_destination");

    final Uri mapsUri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_destination)}",
    );

    try {
      await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      await _tts.speak("Unable to open Google Maps");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Voice Navigation"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Text(
          _isListening
              ? "Listening...\nSay destination"
              : "Preparing speech recognition",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
