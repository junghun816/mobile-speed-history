import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

// Isolate.spawn은 top-level 함수만 허용
void _cadenceLoop(List<dynamic> args) async {
  final sendPort = args[0] as SendPort;
  final bpm = args[1] as int;
  final stopwatch = Stopwatch()..start();
  int beat = 0;
  while (true) {
    beat++;
    final targetMs = (60000.0 * beat / bpm).round();
    final waitMs = targetMs - stopwatch.elapsedMilliseconds;
    // 나머지 1ms는 tight spin으로 정밀도 확보 (이솔레이트 전용이라 부하 없음)
    if (waitMs > 1) await Future.delayed(Duration(milliseconds: waitMs - 1));
    while (stopwatch.elapsedMilliseconds < targetMs) {}
    sendPort.send(null);
  }
}

class CadenceService {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  bool _useVibration = false;
  bool _useSound = false;
  bool _running = false;
  int _bpm = 0;
  int _lastBeatMs = 0;
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

  Future<void> start(int bpm,
      {bool useVibration = true, bool useSound = false}) async {
    stop();
    _useVibration = useVibration;
    _useSound = useSound;
    _bpm = bpm;
    _lastBeatMs = 0;
    _running = true;

    if (useSound) {
      await _audioPlayer.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    }

    _receivePort = ReceivePort();
    _isolate =
        await Isolate.spawn(_cadenceLoop, [_receivePort!.sendPort, bpm]);

    _receivePort!.listen((_) {
      if (!_running) return;
      // 큐 쌓임 방지: 최소 간격(비트 주기의 70%) 이내 재발화 무시
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final minIntervalMs = (60000 / _bpm * 0.7).round();
      if (nowMs - _lastBeatMs < minIntervalMs) return;
      _lastBeatMs = nowMs;

      // 진동·소리 동시 fire-and-forget
      if (_useVibration) Vibration.vibrate(duration: 50);
      if (_useSound) _audioPlayer.play(BytesSource(_beepWav));
    });
  }

  void stop() {
    _running = false;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    _audioPlayer.stop();
  }

  Future<void> dispose() async {
    stop();
    await _audioPlayer.dispose();
  }

  bool get isRunning => _running;
}
