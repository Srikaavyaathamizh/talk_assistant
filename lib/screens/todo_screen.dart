import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _tasks = [];

  late stt.SpeechToText _speech;
  final FlutterTts _tts = FlutterTts();
  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  bool _isListening = false;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();
    _speech.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          setState(() => _isListening = false);
        }
      },
    );

    _tts.setLanguage("en_IN");
    _tts.setSpeechRate(0.45);

    tz.initializeTimeZones();
    _initNotifications();
    _loadTasks(); // 🔥 LOAD STORED TASKS
  }

  // 🔔 Notifications init
  void _initNotifications() async {
    const androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings =
    InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);
  }

  // 💾 LOAD TASKS
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasks = prefs.getStringList('todos') ?? [];
    });
  }

  // 💾 SAVE TASKS
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('todos', _tasks);
  }

  // 🎤 Mic permission
  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // ⏰ Extract time from speech
  TimeOfDay? _extractTimeFromSpeech(String text) {
    final regExp =
    RegExp(r'(\d{1,2})(?:[:.](\d{1,2}))?\s*(am|pm)?');
    final match = regExp.firstMatch(text.toLowerCase());

    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    int minute =
    match.group(2) != null ? int.parse(match.group(2)!) : 0;
    String? period = match.group(3);

    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  // 🎙️ Start listening
  Future<void> _startListening() async {
    if (!await _requestMicPermission()) return;

    if (_isListening) return;

    await _tts.stop();
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() => _isListening = true);

    _speech.listen(
      listenMode: stt.ListenMode.dictation,
      localeId: "en_IN",
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (!result.finalResult) return;

        final spokenText = result.recognizedWords.toLowerCase();
        final time = _extractTimeFromSpeech(spokenText);

        if (time != null) {
          _selectedTime = time;

          final taskText = spokenText
              .replaceAll(RegExp(r'\d{1,2}.*?(am|pm)'), '')
              .replaceAll('at', '')
              .trim();

          _controller.text = taskText;
          _addTask(); // AUTO ADD
        } else {
          _controller.text = spokenText;
          _speak("Please say time like 5 PM");
        }

        _speech.stop();
        setState(() => _isListening = false);
      },
    );
  }

  // 🗣️ Speak
  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  // ⏰ Pick time manually
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  // ➕ ADD TASK + SAVE
  void _addTask() {
    if (_controller.text.isEmpty || _selectedTime == null) return;

    final task =
        "${_controller.text} ⏰ ${_selectedTime!.format(context)}";

    setState(() {
      _tasks.add(task);
    });

    _saveTasks(); // 🔥 SAVE
    _scheduleNotification(_controller.text, _selectedTime!);

    _controller.clear();
    _selectedTime = null;

    _speak("Todo added");
  }

  // 🔔 Schedule notification
  void _scheduleNotification(String task, TimeOfDay time) async {
    final now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'todo_channel',
      'Todo Alerts',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
    );

    const notificationDetails =
    NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      tzTime.millisecondsSinceEpoch ~/ 1000,
      'Todo Reminder',
      task,
      tzTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ❌ DELETE + SAVE
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks(); // 🔥 SAVE
  }

  // 🧱 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Voice Todo Assistant")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Say: Buy medicine at 5 PM",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.mic),
                  label: Text(_isListening ? "Listening..." : "Speak"),
                  onPressed: _startListening,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _selectedTime == null
                        ? "Pick Time"
                        : _selectedTime!.format(context),
                  ),
                  onPressed: _pickTime,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Add Todo"),
                  onPressed: _addTask,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(_tasks[index]),
                      trailing: IconButton(
                        icon:
                        const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTask(index),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
