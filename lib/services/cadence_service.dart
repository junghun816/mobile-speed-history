import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class CadenceService {
  Timer? _timer;
  DateTime? _startTime;
  int _beatCount = 0;
  int _bpm = 0;
  bool _useVibration = false;
  bool _useSound = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  static final Uint8List _beepWav = _generateBeepWav();

  static Uint8List _generateBeepWav() {
    const sampleRate = 44100;
    const durationMs = 50;
    const frequency = 880.0;
    final numSamples = sampleRate * durationMs ~/ 1000;
    final data = Uint8List(44 + numSamples * 2);
    final bd = ByteData.view(data.buffer);

    data.setAll(0, [82, 73, 70, 70]); // "RIFF"
    bd.setUint32(4, 36 + numSamples * 2, Endian.little);
    data.setAll(8, [87, 65, 86, 69]); // "WAVE"
    data.setAll(12, [102, 109, 116, 32]); // "fmt "
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    data.setAll(36, [100, 97, 116, 97]); // "data"
    bd.setUint32(40, numSamples * 2, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final fade = 1.0 - (i / numSamples);
      final sample = (math.sin(2 * math.pi * frequency * t) * 16000 * fade)
          .round()
          .clamp(-32768, 32767);
      bd.setInt16(44 + i * 2, sample, Endian.little);
    }

    return data;
  }

  Future<void> start(int bpm, {bool useVibration = true, bool useSound = false}) async {
    stop();
    if (useSound) {
      await _audioPlayer.setSourceBytes(_beepWav);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    }
    _bpm = bpm;
    _useVibration = useVibration;
    _useSound = useSound;
    _beatCount = 0;
    _startTime = DateTime.now();
    _scheduleNext();
  }

  void _scheduleNext() {
    _beatCount++;
    final nextMs = (60000.0 * _beatCount / _bpm).round();
    final nextTime = _startTime!.add(Duration(milliseconds: nextMs));
    final delay = nextTime.difference(DateTime.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () {
      if (_useSound) _audioPlayer.seek(Duration.zero).then((_) => _audioPlayer.resume());
      if (_useVibration) Vibration.vibrate(duration: 50);
      _scheduleNext();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _startTime = null;
    _beatCount = 0;
  }

  Future<void> dispose() async {
    stop();
    await _audioPlayer.dispose();
  }

  bool get isRunning => _timer != null;
}
