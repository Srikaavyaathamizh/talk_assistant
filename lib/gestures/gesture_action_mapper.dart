enum GestureAction {
  obstacleWarning,
  objectDetection,
  ocr,
  voiceCommand,
  emergency,
  unknown,
}

class GestureActionMapper {
  static GestureAction map(int taps) {
    switch (taps) {
      case 1:
        return GestureAction.obstacleWarning;
      case 2:
        return GestureAction.objectDetection;
      case 3:
        return GestureAction.ocr;
      case 4:
        return GestureAction.voiceCommand;
      case 5:
        return GestureAction.emergency;
      default:
        return GestureAction.unknown;
    }
  }
}
