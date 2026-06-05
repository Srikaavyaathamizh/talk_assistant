import 'dart:async';

class TapGestureHandler {
  int _tapCount = 0;
  Timer? _timer;

  void registerTap(Function(int) onComplete) {
    _tapCount++;

    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), () {
      onComplete(_tapCount);
      _tapCount = 0;
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}
