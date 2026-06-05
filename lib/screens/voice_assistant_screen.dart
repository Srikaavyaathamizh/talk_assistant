import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'camera_screen.dart';
import 'navigation_voice_screen.dart';
import 'todo_screen.dart';
import 'gemini_service.dart';

/// =====================
/// INTENT MODEL
/// =====================
class IntentRule {
  final List<String> keywords;
  final String Function(BuildContext context, String text) response;
  final Future<void> Function(String text)? action;

  IntentRule({
    required this.keywords,
    required this.response,
    this.action,
  });
}

/// =====================
/// MAIN SCREEN
/// =====================
class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _userText = "Tap microphone and speak";
  String _assistantText = "";

  late List<IntentRule> _intents;

  /// =====================
  /// INIT
  /// =====================
  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();
    _tts.setSpeechRate(0.5);
    _tts.setLanguage("en-US");

    _initIntents();

    _speak(
      "Hello. I am your voice assistant. "
          "Say open YouTube, play a song, open Google, or open Instagram.",
    );
  }

  /// =====================
  /// INTENTS (ORDER IS VERY IMPORTANT)
  /// =====================
  void _initIntents() {
    _intents = [

      /// 👋 GREETINGS
      IntentRule(
        keywords: ["hi", "hello", "hey"],
        response: (_, __) => "Hello! How can I help you?",
      ),

      /// ▶️ OPEN YOUTUBE (BEFORE play)
      IntentRule(
        keywords: ["open youtube", "youtube open"],
        response: (_, __) => "Opening YouTube.",
        action: (_) async {
          await _openUrl("https://www.youtube.com");
        },
      ),

      /// 🎵 PLAY SONG ON YOUTUBE
      IntentRule(
        keywords: ["play"],
        response: (_, __) => "Playing on YouTube.",
        action: _playOnYouTube,
      ),

      /// 🔍 GOOGLE SEARCH
      IntentRule(
        keywords: ["open google", "search"],
        response: (_, __) => "Opening Google.",
        action: (text) async {
          final query = text.replaceAll("search", "").trim();
          final url = query.isEmpty
              ? "https://www.google.com"
              : "https://www.google.com/search?q=${Uri.encodeComponent(query)}";
          await _openUrl(url);
        },
      ),

      /// 📸 INSTAGRAM
      IntentRule(
        keywords: ["open instagram"],
        response: (_, __) => "Opening Instagram.",
        action: (_) async {
          await _openUrl("https://www.instagram.com");
        },
      ),

      /// ⏰ TIME
      IntentRule(
        keywords: ["time", "current time"],
        response: (context, __) {
          final time = TimeOfDay.now();
          return "The time is ${time.format(context)}.";
        },
      ),

      /// 📅 DATE
      IntentRule(
        keywords: ["date", "today"],
        response: (_, __) {
          final now = DateTime.now();
          return "Today is ${now.day}-${now.month}-${now.year}.";
        },
      ),

      /// 🎶 MUSIC PLAYER (SAFE)
      IntentRule(
        keywords: ["open music", "music player"],
        response: (_, __) => "Opening music player.",
        action: (_) async {
          await _openUrl(
            "https://play.google.com/store/apps/details?id=com.google.android.music",
          );
        },
      ),

      /// ⏰ CLOCK / ALARM (SAFE)
      IntentRule(
        keywords: ["open clock", "open alarm", "open timer"],
        response: (_, __) => "Opening clock.",
        action: (_) async {
          await _openUrl(
            "https://play.google.com/store/apps/details?id=com.google.android.deskclock",
          );
        },
      ),

      /// 📷 CAMERA
      IntentRule(
        keywords: ["open camera"],
        response: (_, __) => "Opening camera.",
        action: (_) async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CameraScreen()),
          );
        },
      ),

      /// 🧭 NAVIGATION
      IntentRule(
        keywords: ["open navigation"],
        response: (_, __) => "Starting navigation.",
        action: (_) async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NavigationVoiceScreen(),
            ),
          );
        },
      ),

      /// 📝 TODO
      IntentRule(
        keywords: ["open todo"],
        response: (_, __) => "Opening your todo list.",
        action: (_) async {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TodoScreen()),
          );
        },
      ),
    ];
  }

  /// =====================
  /// CORE LOGIC
  /// =====================
  Future<void> _processInput(String text) async {
    setState(() => _userText = text);

    for (final intent in _intents) {
      if (intent.keywords.any(text.contains)) {
        final reply = intent.response(context, text);
        setState(() => _assistantText = reply);
        await _speak(reply);
        if (intent.action != null) {
          await intent.action!(text);
        }
        _speech.stop();
        setState(() => _isListening = false);
        return;
      }
    }

    /// 🤖 GEMINI FALLBACK
    setState(() => _assistantText = "Thinking...");
    await _speak("Please wait");

    final reply = await GeminiService.getReply(text);
    setState(() => _assistantText = reply);
    await _speak(reply);
  }

  /// =====================
  /// HELPERS
  /// =====================
  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await _speak("Unable to open application.");
      }
    } catch (e) {
      await _speak("Error opening application.");
    }
  }

  Future<void> _playOnYouTube(String text) async {
    final song = text.replaceAll("play", "").trim();
    final query = song.isEmpty ? "music" : Uri.encodeComponent(song);
    final url =
        "https://www.youtube.com/results?search_query=$query";
    await _openUrl(url);
  }

  /// =====================
  /// LISTEN
  /// =====================
  Future<void> _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize();
      if (!available) return;

      setState(() => _isListening = true);
      _speech.listen(
        onResult: (r) {
          if (r.finalResult) {
            _processInput(r.recognizedWords.toLowerCase());
          }
        },
      );
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  /// =====================
  /// UI
  /// =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Voice Assistant"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _label("You"),
            _text(_userText, Colors.yellow),
            const SizedBox(height: 20),
            _label("Assistant"),
            _text(_assistantText, Colors.green),
            const SizedBox(height: 30),
            FloatingActionButton(
              backgroundColor: _isListening ? Colors.red : Colors.blue,
              onPressed: _listen,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontSize: 20),
  );

  Widget _text(String text, Color color) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: color, fontSize: 22),
  );
}
