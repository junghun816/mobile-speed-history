import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/ride_record.dart';
import '../models/speed_mode.dart';
import '../db/database_helper.dart';
import '../services/location_service.dart';
import '../services/foreground_service.dart';
import '../services/cadence_service.dart';
import '../services/voice_guidance_service.dart';
import '../utils/utils_format.dart';

class RideProvider extends ChangeNotifier {
  double _currentSpeed = 0.0;
  double _targetSpeed = 0.0;
  double _previousSpeed = 0.0;
  double _maxSpeed = 0.0;
  double _totalDistance = 0.0;
  bool _isRiding = false;
  int _interpolationStep = 0;
  static const int _interpolationSteps = 20;

  DateTime? _startTime;
  int _lastDuration = 0;
  Timer? _durationTimer;

  // 속도 알림
  double? _speedAlertKmh;
  double? _speedMinAlertKmh;
  bool _speedMaxAlertPopupEnabled = true;
  bool _speedMaxAlertVibrationEnabled = true;
  bool _speedMaxAlertSoundEnabled = false;
  bool _speedMinAlertPopupEnabled = true;
  bool _speedMinAlertVibrationEnabled = true;
  bool _speedMinAlertSoundEnabled = false;
  int _speedAlertTriggerCount = 0;
  int _lastSpeedAlertMs = 0;

  // 거리 알림
  int? _distanceAlertKm;
  int _lastAlertedKm = 0;
  bool _distanceAlertPopupEnabled = true;
  bool _distanceAlertVibrationEnabled = true;
  bool _distanceAlertSoundEnabled = false;
  int _distanceAlertTriggerCount = 0;

  // 자동 일시정지
  bool _autoPauseEnabled = false;
  bool _isAutoPaused = false;
  DateTime? _autoPausedAt;
  int _totalPausedMs = 0;
  int _lowSpeedCount = 0;

  // 수동 일시정지
  bool _isManuallyPaused = false;
  DateTime? _manualPausedAt;
  static const double _autoPauseSpeedThreshold = 2.0;
  static const int _autoPauseCountThreshold = 3;

  bool _useKmh = true;
  int _notificationTick = 0;

  // 런닝 모드
  String _activityType = 'bike';
  int? _cadenceBpm;
  int? _targetPaceSecPerKm;
  bool _voiceGuidanceEnabled = false;
  final CadenceService _cadenceService = CadenceService();

  RideProvider() {
    _cadenceService.prepare();
  }

  // 랩 기록 (런닝 자동 1km)
  List<Map<String, dynamic>> _lapData = [];
  int _completedLaps = 0;
  int _lapStartDurationSec = 0;
  double _lapMaxSpeed = 0.0;


  // 목표 페이스 알림 상태
  bool _wasOverTargetPace = false;

  String _historyFilter = 'all';
  String get historyFilter => _historyFilter;

  void setHistoryFilter(String filter) {
    if (_historyFilter == filter) return;
    _historyFilter = filter;
    notifyListeners();
  }

  List<RideRecord> get filteredRecords => _historyFilter == 'all'
      ? records
      : records.where((r) => r.activityType == _historyFilter).toList();

  Map<String, int?> get filteredBestRecordIds {
    final fr = filteredRecords;
    if (fr.isEmpty) return {};
    final maxDistance = fr.reduce((a, b) => a.totalDistance > b.totalDistance ? a : b);
    final maxSpd = fr.reduce((a, b) => a.maxSpeed > b.maxSpeed ? a : b);
    final maxDuration = fr.reduce((a, b) => a.duration > b.duration ? a : b);
    return {
      'distance': maxDistance.id,
      'speed': maxSpd.id,
      'duration': maxDuration.id,
    };
  }

  List<Position> pathPoints = [];
  List<RideRecord> records = [];
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSubscription;

  double get currentSpeed => _currentSpeed;
  double get targetSpeed => _targetSpeed;
  double get maxSpeed => _maxSpeed;
  double get totalDistance => _totalDistance;
  bool get isRiding => _isRiding;
  bool get isAutoPaused => _isAutoPaused;
  bool get isManuallyPaused => _isManuallyPaused;
  bool get isPaused => _isManuallyPaused || _isAutoPaused;
  int get speedAlertTriggerCount => _speedAlertTriggerCount;
  int get distanceAlertTriggerCount => _distanceAlertTriggerCount;
  int get lastAlertedKm => _lastAlertedKm;
  String get activityType => _activityType;
  int get completedLaps => _completedLaps;

  // 현재 페이스 (초/km). 속도가 너무 낮으면 null
  int? get currentPaceSecPerKm => paceFromSpeed(_currentSpeed);

  // 목표 페이스보다 느린 상태 (페이스 값이 클수록 느림)
  bool get isOverTargetPace {
    if (_targetPaceSecPerKm == null || _activityType != 'run') return false;
    final pace = currentPaceSecPerKm;
    return pace != null && pace > _targetPaceSecPerKm!;
  }

  // stopRide가 null을 반환할 때의 실패 이유 ('distance' or 'duration')
  String? _stopFailReason;
  String? get stopFailReason => _stopFailReason;

  int get duration {
    if (_isRiding && _startTime != null) {
      final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
      var paused = _totalPausedMs;
      if (_isAutoPaused && _autoPausedAt != null) {
        paused += DateTime.now().difference(_autoPausedAt!).inMilliseconds;
      }
      if (_isManuallyPaused && _manualPausedAt != null) {
        paused += DateTime.now().difference(_manualPausedAt!).inMilliseconds;
      }
      return ((elapsed - paused) / 1000).floor().clamp(0, 999999);
    }
    return _lastDuration;
  }

  String get formattedDuration => formatDuration(duration);

  Map<String, int?> get bestRecordIds {
    if (records.isEmpty) return {};

    final maxDistance = records.reduce((a, b) =>
    a.totalDistance > b.totalDistance ? a : b);
    final maxSpeed = records.reduce((a, b) =>
    a.maxSpeed > b.maxSpeed ? a : b);
    final maxDuration = records.reduce((a, b) =>
    a.duration > b.duration ? a : b);

    return {
      'distance': maxDistance.id,
      'speed': maxSpeed.id,
      'duration': maxDuration.id,
    };
  }

  Future<void> loadRecords() async {
    records = await DatabaseHelper.instance.getAllRecords();
    notifyListeners();
  }

  Future<void> startRide({
    bool gpsHighAccuracy = true,
    bool autoPause = false,
    double? speedAlertKmh,
    double? speedMinAlertKmh,
    SpeedMode speedMode = SpeedMode.normal,
    int? distanceAlertKm,
    bool useKmh = true,
    String activityType = 'bike',
    int? cadenceBpm,
    int? targetPaceSecPerKm,
    bool voiceGuidance = false,
    bool cadenceVibration = true,
    bool cadenceSound = false,
    bool speedMaxAlertPopupEnabled = true,
    bool speedMaxAlertVibrationEnabled = true,
    bool speedMaxAlertSoundEnabled = false,
    bool speedMinAlertPopupEnabled = true,
    bool speedMinAlertVibrationEnabled = true,
    bool speedMinAlertSoundEnabled = false,
    bool distanceAlertPopupEnabled = true,
    bool distanceAlertVibrationEnabled = true,
    bool distanceAlertSoundEnabled = false,
  }) async {
    final hasPermission = await LocationService.requestPermission();
    if (!hasPermission) return;

    _isRiding = true;
    _currentSpeed = 0.0;
    _targetSpeed = 0.0;
    _previousSpeed = 0.0;
    _maxSpeed = 0.0;
    _totalDistance = 0.0;
    _lastDuration = 0;
    _interpolationStep = 0;
    _startTime = DateTime.now();
    pathPoints.clear();
    _lastPosition = null;

    _autoPauseEnabled = autoPause;
    _isAutoPaused = false;
    _autoPausedAt = null;
    _totalPausedMs = 0;
    _lowSpeedCount = 0;
    _isManuallyPaused = false;
    _manualPausedAt = null;
    _speedAlertKmh = speedAlertKmh;
    _speedMinAlertKmh = speedMinAlertKmh;
    _speedMaxAlertPopupEnabled = speedMaxAlertPopupEnabled;
    _speedMaxAlertVibrationEnabled = speedMaxAlertVibrationEnabled;
    _speedMaxAlertSoundEnabled = speedMaxAlertSoundEnabled;
    _speedMinAlertPopupEnabled = speedMinAlertPopupEnabled;
    _speedMinAlertVibrationEnabled = speedMinAlertVibrationEnabled;
    _speedMinAlertSoundEnabled = speedMinAlertSoundEnabled;
    _speedAlertTriggerCount = 0;
    _lastSpeedAlertMs = DateTime.now().millisecondsSinceEpoch;
    _distanceAlertKm = distanceAlertKm;
    _lastAlertedKm = 0;
    _distanceAlertPopupEnabled = distanceAlertPopupEnabled;
    _distanceAlertVibrationEnabled = distanceAlertVibrationEnabled;
    _distanceAlertSoundEnabled = distanceAlertSoundEnabled;
    _distanceAlertTriggerCount = 0;
    _useKmh = useKmh;
    _notificationTick = 0;

    _activityType = activityType;
    _cadenceBpm = cadenceBpm;
    _targetPaceSecPerKm = targetPaceSecPerKm;
    _voiceGuidanceEnabled = voiceGuidance;
    _lapData = [];
    _completedLaps = 0;
    _lapStartDurationSec = 0;
    _lapMaxSpeed = 0.0;
    _wasOverTargetPace = false;

    _currentSpeedMode = speedMode;
    _applySpeedMode(speedMode);

    // GPS 스트림
    _positionSubscription =
        LocationService.getPositionStream(highAccuracy: gpsHighAccuracy)
            .listen((position) {
          _onPositionUpdate(position);
        });

    // 50ms 타이머 — 속도 보간은 매 tick, UI 갱신은 5Hz (4tick = 200ms)
    // 침 애니메이션은 위젯 AnimationController가 60fps로 독립 구동
    _durationTimer =
        Timer.periodic(Duration(milliseconds: 1000 ~/ _interpolationSteps), (_) {
          _interpolateSpeed();
          if (_notificationTick % 4 == 0) notifyListeners();
        });

    if (cadenceBpm != null) {
      await _cadenceService.start(cadenceBpm, useVibration: cadenceVibration, useSound: cadenceSound);
    }
    if (voiceGuidance || speedMaxAlertSoundEnabled || speedMinAlertSoundEnabled || distanceAlertSoundEnabled) {
      await VoiceGuidanceService.instance.init();
    }

    await WakelockPlus.enable();
    await ForegroundServiceHelper.start();
    notifyListeners();
  }

  void _applySpeedMode(SpeedMode mode) {
    switch (mode) {
      case SpeedMode.lowSpeed:
        _maxAccuracyMeters = 25.0;
        _minMovementMeters = 1.0;
      case SpeedMode.normal:
        _maxAccuracyMeters = 15.0;
        _minMovementMeters = 5.0;
    }
  }

  void changeSpeedMode(SpeedMode mode) {
    if (!isRiding) return;
    _currentSpeedMode = mode;
    _applySpeedMode(mode);
    notifyListeners();
  }

  static const double _maxSpeedJumpRatio = 3.0;
  static const double _maxSpeedJumpMinKmh = 20.0;
  static const double _minDisplaySpeedKmh = 1.5;

  // 모드별 임계값 (startRide 시 설정)
  double _maxAccuracyMeters = 15.0;
  double _minMovementMeters = 5.0;
  SpeedMode _currentSpeedMode = SpeedMode.normal;
  SpeedMode get currentSpeedMode => _currentSpeedMode;

  void _onPositionUpdate(Position position) {
    if (_isManuallyPaused) return;

    // GPS 정확도가 낮으면 스킵
    if (position.accuracy > _maxAccuracyMeters) return;

    double rawSpeed = position.speed * 3.6;
    if (rawSpeed < 0) rawSpeed = 0;
    // 소음 수준의 미세 속도는 정지로 처리
    if (rawSpeed < _minDisplaySpeedKmh) rawSpeed = 0;

    // 속도 스파이크 필터: 이전 속도 대비 3배 이상 급등 시 무시
    if (rawSpeed > _maxSpeedJumpMinKmh &&
        _targetSpeed > 0 &&
        rawSpeed > _targetSpeed * _maxSpeedJumpRatio) {
      return;
    }

    _previousSpeed = _currentSpeed;
    _targetSpeed = rawSpeed;
    _interpolationStep = 0;

    if (rawSpeed > _maxSpeed) _maxSpeed = rawSpeed;

    if (_lastPosition != null) {
      final distanceInMeters = LocationService.calculateDistance(
        _lastPosition!, position,
      );
      // 드리프트 방지: 최소 이동 거리 미만이면 거리 누적 안 함
      if (distanceInMeters >= _minMovementMeters) {
        _totalDistance += distanceInMeters / 1000;

        // 거리 알림: 설정 km 배수 도달 시 1회
        final alertKm = _distanceAlertKm;
        if (alertKm != null) {
          final reached = (_totalDistance / alertKm).floor() * alertKm;
          if (reached > 0 && reached > _lastAlertedKm) {
            _lastAlertedKm = reached;
            ForegroundServiceHelper.showDistanceAlert(reached);
            if (_distanceAlertPopupEnabled) _distanceAlertTriggerCount++;
            if (_distanceAlertVibrationEnabled) HapticFeedback.heavyImpact();
            if (_distanceAlertSoundEnabled) {
              VoiceGuidanceService.instance.speak('$reached킬로미터 도달');
            }
          }
        }

        // 랩 기록: 1km 단위 자동 랩
        final newLap = _totalDistance.floor();
        if (newLap > _completedLaps) {
          final currentDurationSec = duration;
          final lapTimeSec = currentDurationSec - _lapStartDurationSec;
          _lapData.add({
            'lap': newLap,
            'timeMs': lapTimeSec * 1000,
            'paceSecPerKm': lapTimeSec,
            'maxSpeedKmh': _lapMaxSpeed,
          });
          _completedLaps = newLap;
          _lapStartDurationSec = currentDurationSec;
          _lapMaxSpeed = 0.0;

          if (_voiceGuidanceEnabled) {
            VoiceGuidanceService.instance.speak(
              '$newLap킬로미터 완주, 페이스 ${lapTimeSec ~/ 60}분 ${lapTimeSec % 60}초',
            );
          }
        }

        // 랩 내 최고속도 추적
        if (rawSpeed > _lapMaxSpeed) _lapMaxSpeed = rawSpeed;
      }
    }

    // 목표 페이스 알림: 목표보다 느려질 때 1회 진동
    final targetPace = _targetPaceSecPerKm;
    if (targetPace != null && _activityType == 'run' && rawSpeed > 0) {
      final curPace = paceFromSpeed(rawSpeed);
      final isOver = curPace != null && curPace > targetPace;
      if (isOver && !_wasOverTargetPace) {
        HapticFeedback.heavyImpact();
      }
      _wasOverTargetPace = isOver;
    }

    pathPoints.add(position);
    _lastPosition = position;

    // 자동 일시정지
    if (_autoPauseEnabled) {
      if (rawSpeed < _autoPauseSpeedThreshold) {
        _lowSpeedCount++;
        if (_lowSpeedCount >= _autoPauseCountThreshold && !_isAutoPaused) {
          _isAutoPaused = true;
          _autoPausedAt = DateTime.now();
          _cadenceService.pause();
        }
      } else {
        _lowSpeedCount = 0;
        if (_isAutoPaused) {
          _isAutoPaused = false;
          _totalPausedMs +=
              DateTime.now().difference(_autoPausedAt!).inMilliseconds;
          _autoPausedAt = null;
          _cadenceService.resume();
        }
      }
    }
  }

  void _interpolateSpeed() {
    if (_interpolationStep < _interpolationSteps) {
      _interpolationStep++;
      final t = _interpolationStep / _interpolationSteps;
      _currentSpeed =
          _previousSpeed + (_targetSpeed - _previousSpeed) * t;
    } else {
      _currentSpeed = _targetSpeed;
    }

    // 속도 구간 이탈 시 주기적 알림 (3초 간격)
    if (_isRiding && !_isManuallyPaused && !_isAutoPaused) {
      final isOver = _speedAlertKmh != null && _currentSpeed >= _speedAlertKmh!;
      final isUnder = _speedMinAlertKmh != null && _currentSpeed > 0 && _currentSpeed < _speedMinAlertKmh!;
      if (isOver || isUnder) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        if (nowMs - _lastSpeedAlertMs >= 3000) {
          _lastSpeedAlertMs = nowMs;
          if (isOver) {
            if (_speedMaxAlertPopupEnabled) _speedAlertTriggerCount++;
            if (_speedMaxAlertVibrationEnabled) HapticFeedback.heavyImpact();
            if (_speedMaxAlertSoundEnabled) VoiceGuidanceService.instance.speak('속도 초과');
          } else {
            if (_speedMinAlertPopupEnabled) _speedAlertTriggerCount++;
            if (_speedMinAlertVibrationEnabled) HapticFeedback.heavyImpact();
            if (_speedMinAlertSoundEnabled) VoiceGuidanceService.instance.speak('속도 미달');
          }
        }
      }
    }

    _notificationTick++;
    if (_notificationTick >= _interpolationSteps) {
      _notificationTick = 0;
      ForegroundServiceHelper.updateNotification(
        speed: formatSpeed(_currentSpeed, _useKmh),
        speedUnit: speedUnit(_useKmh),
        distance: formatDistance(_totalDistance, _useKmh),
        distanceUnit: distanceUnit(_useKmh),
        duration: formattedDuration,
      );
    }
  }

  // 저장됐으면 RideRecord, 조건 미달로 스킵됐으면 null (stopFailReason 참조)
  Future<RideRecord?> stopRide({
    double minRecordDistanceKm = 0.0,
    int minRecordDurationSec = 0,
  }) async {
    final durationSeconds = duration; // _isRiding 변경 전에 캡처
    _isRiding = false;
    _isAutoPaused = false;
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    notifyListeners(); // 버튼 UI 즉시 갱신

    final startedAt = _startTime?.millisecondsSinceEpoch;
    _cadenceService.stop();
    await VoiceGuidanceService.instance.stop();
    await WakelockPlus.disable();
    await ForegroundServiceHelper.stop();
    _lastDuration = durationSeconds;
    _startTime = null;

    // 최소 기록 시간 미달 시 저장 안 함
    if (minRecordDurationSec > 0 && durationSeconds < minRecordDurationSec) {
      _stopFailReason = 'duration';
      notifyListeners();
      return null;
    }

    // 최소 기록 거리 미달 시 저장 안 함
    if (_totalDistance < minRecordDistanceKm) {
      _stopFailReason = 'distance';
      notifyListeners();
      return null;
    }
    _stopFailReason = null;

    final pathJson = jsonEncode(
      pathPoints.map((p) => {
        'lat': p.latitude,
        'lng': p.longitude,
      }).toList(),
    );
    final lapSplitsJson = _lapData.isNotEmpty ? jsonEncode(_lapData) : null;
    final durationHours = durationSeconds / 3600.0;
    final avgSpeed = durationHours > 0
        ? _totalDistance / durationHours
        : 0.0;

    final now = DateTime.now();
    final record = RideRecord(
      year: now.year,
      month: now.month,
      day: now.day,
      totalDistance: _totalDistance,
      maxSpeed: _maxSpeed,
      avgSpeed: avgSpeed,
      duration: durationSeconds,
      pathPoints: pathJson,
      createdAt: startedAt ?? now.millisecondsSinceEpoch,
      activityType: _activityType,
      lapSplits: lapSplitsJson,
      targetPace: _targetPaceSecPerKm,
      cadenceBpm: _cadenceBpm,
    );

    final id = await DatabaseHelper.instance.insertRecord(record);
    await loadRecords();
    notifyListeners();
    return RideRecord(
      id: id,
      year: record.year,
      month: record.month,
      day: record.day,
      totalDistance: record.totalDistance,
      maxSpeed: record.maxSpeed,
      avgSpeed: record.avgSpeed,
      duration: record.duration,
      pathPoints: record.pathPoints,
      createdAt: record.createdAt,
      activityType: record.activityType,
      lapSplits: record.lapSplits,
      targetPace: record.targetPace,
      cadenceBpm: record.cadenceBpm,
    );
  }


  void pauseRide() {
    if (!_isRiding || _isManuallyPaused) return;
    _isManuallyPaused = true;
    _manualPausedAt = DateTime.now();
    _cadenceService.pause();
    notifyListeners();
  }

  void resumeRide() {
    if (!_isManuallyPaused) return;
    _totalPausedMs += DateTime.now().difference(_manualPausedAt!).inMilliseconds;
    _isManuallyPaused = false;
    _manualPausedAt = null;
    _lastPosition = null; // 재개 시 이전 위치 초기화로 드리프트 방지
    _cadenceService.resume();
    notifyListeners();
  }

  Future<void> updateMemo(int id, String memo) async {
    await DatabaseHelper.instance.updateMemo(id, memo);
    await loadRecords();
  }

  Future<void> deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    await loadRecords();
  }

}