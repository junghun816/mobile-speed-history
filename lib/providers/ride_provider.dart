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
import '../utils/format_utils.dart';

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
  bool _wasAboveSpeedAlert = false;
  double? _speedMinAlertKmh;
  bool _wasBelowSpeedAlert = false;

  // 거리 알림
  int? _distanceAlertKm;
  int _lastAlertedKm = 0;

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

  // 랩 기록
  List<Map<String, dynamic>> _lapData = [];
  int _completedLaps = 0;
  int _lapStartDurationSec = 0;
  double _lapMaxSpeed = 0.0;

  // 목표 페이스 알림 상태
  bool _wasOverTargetPace = false;

  List<Position> pathPoints = [];
  List<RideRecord> records = [];
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSubscription;

  double get currentSpeed => _currentSpeed;
  double get maxSpeed => _maxSpeed;
  double get totalDistance => _totalDistance;
  bool get isRiding => _isRiding;
  bool get isAutoPaused => _isAutoPaused;
  bool get isManuallyPaused => _isManuallyPaused;
  bool get isPaused => _isManuallyPaused || _isAutoPaused;
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
    bool cadenceUseSound = false,
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
    _wasAboveSpeedAlert = false;
    _speedMinAlertKmh = speedMinAlertKmh;
    _wasBelowSpeedAlert = false;
    _distanceAlertKm = distanceAlertKm;
    _lastAlertedKm = 0;
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

    // 0.2초마다 타이머 — 속도 보간 + UI 갱신
    _durationTimer =
        Timer.periodic(Duration(milliseconds: 1000 ~/ _interpolationSteps), (_) {
          _interpolateSpeed();
          notifyListeners();
        });

    if (cadenceBpm != null) {
      _cadenceService.start(cadenceBpm, useSound: cadenceUseSound);
    }
    if (voiceGuidance) {
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
        _minMovementMeters = 2.0;
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

    // 속도 초과 알림: 임계값 상향 돌파 시 1회 진동
    final alertKmh = _speedAlertKmh;
    if (alertKmh != null) {
      final isAbove = rawSpeed >= alertKmh;
      if (isAbove && !_wasAboveSpeedAlert) {
        HapticFeedback.heavyImpact();
      }
      _wasAboveSpeedAlert = isAbove;
    }

    // 속도 미만 알림: 임계값 하향 돌파 시 1회 진동 (정지·일시정지·초과 알림 활성 중 억제)
    final minAlertKmh = _speedMinAlertKmh;
    if (minAlertKmh != null) {
      final suppressed = rawSpeed == 0 || _isManuallyPaused || _isAutoPaused || _wasAboveSpeedAlert;
      final isBelow = !suppressed && rawSpeed < minAlertKmh;
      if (isBelow && !_wasBelowSpeedAlert) {
        HapticFeedback.heavyImpact();
      }
      _wasBelowSpeedAlert = isBelow;
    }

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
        }
      } else {
        _lowSpeedCount = 0;
        if (_isAutoPaused) {
          _isAutoPaused = false;
          _totalPausedMs +=
              DateTime.now().difference(_autoPausedAt!).inMilliseconds;
          _autoPausedAt = null;
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
    notifyListeners();
  }

  void resumeRide() {
    if (!_isManuallyPaused) return;
    _totalPausedMs += DateTime.now().difference(_manualPausedAt!).inMilliseconds;
    _isManuallyPaused = false;
    _manualPausedAt = null;
    _lastPosition = null; // 재개 시 이전 위치 초기화로 드리프트 방지
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