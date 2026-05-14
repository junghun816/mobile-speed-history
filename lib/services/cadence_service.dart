import 'dart:async';
import 'package:flutter/services.dart';

class CadenceService {
  Timer? _timer;

  void start(int bpm, {bool useSound = false}) {
    stop();
    final interval = Duration(milliseconds: (60000 / bpm).round());
    _timer = Timer.periodic(interval, (_) {
      if (useSound) {
        SystemSound.play(SystemSoundType.click);
      } else {
        HapticFeedback.mediumImpact();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isRunning => _timer != null;
}
