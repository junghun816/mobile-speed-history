import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/speed_mode.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyUseKmh = 'use_kmh';
  static const _keyGpsHighAccuracy = 'gps_high_accuracy';
  static const _keyMinRecordDistance = 'min_record_distance';
  static const _keyAutoPause = 'auto_pause';
  static const _keyWeightKg = 'weight_kg';
  static const _keyShowDistance = 'show_distance';
  static const _keyShowDuration = 'show_duration';
  static const _keyShowMaxSpeed = 'show_max_speed';
  static const _keyShowAvgSpeed = 'show_avg_speed';
  static const _keyAppTheme = 'app_theme';
  static const _keyMinRecordDuration = 'min_record_duration';
  static const _keySpeedAlertKmh = 'speed_alert_kmh';
  static const _keySpeedMinAlertKmh = 'speed_min_alert_kmh';
  static const _keyMapType = 'map_type';
  static const _keyYearlyGoalKm = 'yearly_goal_km';
  static const _keyMonthlyGoalKm = 'monthly_goal_km';
  static const _keyGoalMaxSpeedKmh = 'goal_max_speed_kmh';
  static const _keyGoalMaxDistanceKm = 'goal_max_distance_km';
  static const _keyGoalMaxDurationMin = 'goal_max_duration_min';
  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyLowSpeedMode = 'low_speed_mode'; // 마이그레이션용 구키
  static const _keySpeedMode = 'speed_mode';
  static const _keyDistanceAlertKm = 'distance_alert_km';
  static const _keyClockDisplay = 'clock_display';
  static const _keyPathColor = 'path_color';
  static const _keyPathThickness = 'path_thickness';
  static const _keyMapTrackingMode = 'map_tracking_mode';
  static const _keyStartTab = 'start_tab';
  static const _keyRunningVoiceGuidance = 'running_voice_guidance';
  static const _keyCadenceFeedbackType = 'cadence_feedback_type';
  static const _keyDefaultCadenceBpm = 'default_cadence_bpm';
  static const _keyDefaultTargetPaceSecPerKm = 'default_target_pace_sec_per_km';

  late SharedPreferences _prefs;

  bool _useKmh = true;
  bool _gpsHighAccuracy = true;
  double _minRecordDistanceKm = 0.1;
  bool _autoPause = false;
  double? _weightKg;
  bool _showDistance = true;
  bool _showDuration = true;
  bool _showMaxSpeed = true;
  bool _showAvgSpeed = true;
  String _appTheme = 'dark';
  int _minRecordDurationSec = 0;
  double? _speedAlertKmh;
  double? _speedMinAlertKmh;
  String _mapType = 'basic';
  double? _yearlyGoalKm;
  double? _monthlyGoalKm;
  double? _goalMaxSpeedKmh;
  double? _goalMaxDistanceKm;
  int? _goalMaxDurationMin;
  bool _onboardingDone = false;
  bool _onboardingSkippedThisSession = false;
  SpeedMode _speedMode = SpeedMode.normal;
  int? _distanceAlertKm;
  String _clockDisplay = 'none';
  String _pathColor = 'blue';
  int _pathThickness = 5;
  String _mapTrackingMode = 'none';
  int _startTab = 0;
  bool _runningVoiceGuidance = true;
  String _cadenceFeedbackType = 'vibration'; // 'vibration' | 'sound'
  int? _defaultCadenceBpm;
  int? _defaultTargetPaceSecPerKm;

  bool get useKmh => _useKmh;
  bool get gpsHighAccuracy => _gpsHighAccuracy;
  double get minRecordDistanceKm => _minRecordDistanceKm;
  bool get autoPause => _autoPause;
  double? get weightKg => _weightKg;
  bool get showDistance => _showDistance;
  bool get showDuration => _showDuration;
  bool get showMaxSpeed => _showMaxSpeed;
  bool get showAvgSpeed => _showAvgSpeed;
  String get appTheme => _appTheme;
  ThemeMode get themeMode =>
      _appTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
  int get minRecordDurationSec => _minRecordDurationSec;
  double? get speedAlertKmh => _speedAlertKmh;
  double? get speedMinAlertKmh => _speedMinAlertKmh;
  String get mapType => _mapType;
  double? get yearlyGoalKm => _yearlyGoalKm;
  double? get monthlyGoalKm => _monthlyGoalKm;
  double? get goalMaxSpeedKmh => _goalMaxSpeedKmh;
  double? get goalMaxDistanceKm => _goalMaxDistanceKm;
  int? get goalMaxDurationMin => _goalMaxDurationMin;
  bool get shouldShowOnboarding => !_onboardingDone && !_onboardingSkippedThisSession;
  SpeedMode get speedMode => _speedMode;
  int? get distanceAlertKm => _distanceAlertKm;
  String get clockDisplay => _clockDisplay;
  String get pathColor => _pathColor;
  int get pathThickness => _pathThickness;
  String get mapTrackingMode => _mapTrackingMode;
  int get startTab => _startTab;
  bool get runningVoiceGuidance => _runningVoiceGuidance;
  String get cadenceFeedbackType => _cadenceFeedbackType;
  int? get defaultCadenceBpm => _defaultCadenceBpm;
  int? get defaultTargetPaceSecPerKm => _defaultTargetPaceSecPerKm;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _useKmh = _prefs.getBool(_keyUseKmh) ?? true;
    _gpsHighAccuracy = _prefs.getBool(_keyGpsHighAccuracy) ?? true;
    _minRecordDistanceKm = _prefs.getDouble(_keyMinRecordDistance) ?? 0.1;
    _autoPause = _prefs.getBool(_keyAutoPause) ?? false;
    _weightKg = _prefs.getDouble(_keyWeightKg);
    _showDistance = _prefs.getBool(_keyShowDistance) ?? true;
    _showDuration = _prefs.getBool(_keyShowDuration) ?? true;
    _showMaxSpeed = _prefs.getBool(_keyShowMaxSpeed) ?? true;
    _showAvgSpeed = _prefs.getBool(_keyShowAvgSpeed) ?? true;
    _appTheme = _prefs.getString(_keyAppTheme) ?? 'dark';
    _minRecordDurationSec = _prefs.getInt(_keyMinRecordDuration) ?? 0;
    _speedAlertKmh = _prefs.getDouble(_keySpeedAlertKmh);
    _speedMinAlertKmh = _prefs.getDouble(_keySpeedMinAlertKmh);
    _mapType = _prefs.getString(_keyMapType) ?? 'basic';
    _yearlyGoalKm = _prefs.getDouble(_keyYearlyGoalKm);
    _monthlyGoalKm = _prefs.getDouble(_keyMonthlyGoalKm);
    _goalMaxSpeedKmh = _prefs.getDouble(_keyGoalMaxSpeedKmh);
    _goalMaxDistanceKm = _prefs.getDouble(_keyGoalMaxDistanceKm);
    _goalMaxDurationMin = _prefs.getInt(_keyGoalMaxDurationMin);
    _onboardingDone = _prefs.getBool(_keyOnboardingDone) ?? false;
    final speedModeStr = _prefs.getString(_keySpeedMode);
    if (speedModeStr != null) {
      _speedMode = SpeedMode.fromString(speedModeStr);
    } else {
      // 구버전 low_speed_mode bool 마이그레이션
      _speedMode = (_prefs.getBool(_keyLowSpeedMode) ?? false)
          ? SpeedMode.lowSpeed
          : SpeedMode.normal;
    }
    _distanceAlertKm = _prefs.getInt(_keyDistanceAlertKm);
    _clockDisplay = _prefs.getString(_keyClockDisplay) ?? 'none';
    _pathColor = _prefs.getString(_keyPathColor) ?? 'blue';
    _pathThickness = _prefs.getInt(_keyPathThickness) ?? 5;
    _mapTrackingMode = _prefs.getString(_keyMapTrackingMode) ?? 'none';
    _startTab = _prefs.getInt(_keyStartTab) ?? 0;
    _runningVoiceGuidance = _prefs.getBool(_keyRunningVoiceGuidance) ?? true;
    _cadenceFeedbackType = _prefs.getString(_keyCadenceFeedbackType) ?? 'vibration';
    _defaultCadenceBpm = _prefs.getInt(_keyDefaultCadenceBpm);
    _defaultTargetPaceSecPerKm = _prefs.getInt(_keyDefaultTargetPaceSecPerKm);
    notifyListeners();
  }

  Future<void> completeOnboarding({required bool neverShowAgain}) async {
    _onboardingSkippedThisSession = true;
    if (neverShowAgain) {
      _onboardingDone = true;
      await _prefs.setBool(_keyOnboardingDone, true);
    }
    notifyListeners();
  }

  Future<void> setUseKmh(bool value) async {
    _useKmh = value;
    notifyListeners();
    await _prefs.setBool(_keyUseKmh, value);
  }

  Future<void> setGpsHighAccuracy(bool value) async {
    _gpsHighAccuracy = value;
    notifyListeners();
    await _prefs.setBool(_keyGpsHighAccuracy, value);
  }

  Future<void> setMinRecordDistanceKm(double value) async {
    _minRecordDistanceKm = value;
    notifyListeners();
    await _prefs.setDouble(_keyMinRecordDistance, value);
  }

  Future<void> setAutoPause(bool value) async {
    _autoPause = value;
    notifyListeners();
    await _prefs.setBool(_keyAutoPause, value);
  }

  Future<void> setWeightKg(double? value) async {
    _weightKg = value != null ? value.clamp(1.0, 999.0) : null;
    notifyListeners();
    if (_weightKg != null) {
      await _prefs.setDouble(_keyWeightKg, _weightKg!);
    } else {
      await _prefs.remove(_keyWeightKg);
    }
  }

  Future<void> setShowDistance(bool value) async {
    _showDistance = value;
    notifyListeners();
    await _prefs.setBool(_keyShowDistance, value);
  }

  Future<void> setShowDuration(bool value) async {
    _showDuration = value;
    notifyListeners();
    await _prefs.setBool(_keyShowDuration, value);
  }

  Future<void> setShowMaxSpeed(bool value) async {
    _showMaxSpeed = value;
    notifyListeners();
    await _prefs.setBool(_keyShowMaxSpeed, value);
  }

  Future<void> setShowAvgSpeed(bool value) async {
    _showAvgSpeed = value;
    notifyListeners();
    await _prefs.setBool(_keyShowAvgSpeed, value);
  }

  Future<void> setAppTheme(String value) async {
    _appTheme = value;
    notifyListeners();
    await _prefs.setString(_keyAppTheme, value);
  }

  Future<void> setMinRecordDurationSec(int value) async {
    _minRecordDurationSec = value;
    notifyListeners();
    await _prefs.setInt(_keyMinRecordDuration, value);
  }

  Future<void> setSpeedAlertKmh(double? value) async {
    _speedAlertKmh = value != null ? value.clamp(kDebugMode ? 0.0 : 1.0, 999.0) : null;
    // 미만 알림과 충돌(초과 ≤ 미만)이면 미만 알림 해제
    if (_speedAlertKmh != null && _speedMinAlertKmh != null &&
        _speedAlertKmh! <= _speedMinAlertKmh!) {
      _speedMinAlertKmh = null;
      await _prefs.remove(_keySpeedMinAlertKmh);
    }
    notifyListeners();
    if (_speedAlertKmh != null) {
      await _prefs.setDouble(_keySpeedAlertKmh, _speedAlertKmh!);
    } else {
      await _prefs.remove(_keySpeedAlertKmh);
    }
  }

  Future<void> setSpeedMinAlertKmh(double? value) async {
    _speedMinAlertKmh = value != null ? value.clamp(kDebugMode ? 0.0 : 1.0, 999.0) : null;
    // 초과 알림과 충돌(미만 ≥ 초과)이면 초과 알림 해제
    if (_speedMinAlertKmh != null && _speedAlertKmh != null &&
        _speedMinAlertKmh! >= _speedAlertKmh!) {
      _speedAlertKmh = null;
      await _prefs.remove(_keySpeedAlertKmh);
    }
    notifyListeners();
    if (_speedMinAlertKmh != null) {
      await _prefs.setDouble(_keySpeedMinAlertKmh, _speedMinAlertKmh!);
    } else {
      await _prefs.remove(_keySpeedMinAlertKmh);
    }
  }

  Future<void> setMapType(String value) async {
    _mapType = value;
    notifyListeners();
    await _prefs.setString(_keyMapType, value);
  }

  Future<void> setYearlyGoalKm(double? value) async {
    _yearlyGoalKm = value;
    notifyListeners();
    value != null
        ? await _prefs.setDouble(_keyYearlyGoalKm, value)
        : await _prefs.remove(_keyYearlyGoalKm);
  }

  Future<void> setMonthlyGoalKm(double? value) async {
    _monthlyGoalKm = value;
    notifyListeners();
    value != null
        ? await _prefs.setDouble(_keyMonthlyGoalKm, value)
        : await _prefs.remove(_keyMonthlyGoalKm);
  }

  Future<void> setGoalMaxSpeedKmh(double? value) async {
    _goalMaxSpeedKmh = value;
    notifyListeners();
    value != null
        ? await _prefs.setDouble(_keyGoalMaxSpeedKmh, value)
        : await _prefs.remove(_keyGoalMaxSpeedKmh);
  }

  Future<void> setGoalMaxDistanceKm(double? value) async {
    _goalMaxDistanceKm = value;
    notifyListeners();
    value != null
        ? await _prefs.setDouble(_keyGoalMaxDistanceKm, value)
        : await _prefs.remove(_keyGoalMaxDistanceKm);
  }

  Future<void> setDistanceAlertKm(int? value) async {
    _distanceAlertKm = value != null ? value.clamp(1, 999) : null;
    notifyListeners();
    _distanceAlertKm != null
        ? await _prefs.setInt(_keyDistanceAlertKm, _distanceAlertKm!)
        : await _prefs.remove(_keyDistanceAlertKm);
  }

  Future<void> setClockDisplay(String value) async {
    _clockDisplay = value;
    notifyListeners();
    await _prefs.setString(_keyClockDisplay, value);
  }

  Future<void> setSpeedMode(SpeedMode value) async {
    _speedMode = value;
    notifyListeners();
    await _prefs.setString(_keySpeedMode, value.name);
  }

  Future<void> setPathColor(String value) async {
    _pathColor = value;
    notifyListeners();
    await _prefs.setString(_keyPathColor, value);
  }

  Future<void> setPathThickness(int value) async {
    _pathThickness = value;
    notifyListeners();
    await _prefs.setInt(_keyPathThickness, value);
  }

  Future<void> setStartTab(int value) async {
    _startTab = value.clamp(0, 4);
    notifyListeners();
    await _prefs.setInt(_keyStartTab, _startTab);
  }

  Future<void> setMapTrackingMode(String value) async {
    _mapTrackingMode = value;
    notifyListeners();
    await _prefs.setString(_keyMapTrackingMode, value);
  }

  Future<void> setGoalMaxDurationMin(int? value) async {
    _goalMaxDurationMin = value;
    notifyListeners();
    value != null
        ? await _prefs.setInt(_keyGoalMaxDurationMin, value)
        : await _prefs.remove(_keyGoalMaxDurationMin);
  }

  Future<void> setRunningVoiceGuidance(bool value) async {
    _runningVoiceGuidance = value;
    notifyListeners();
    await _prefs.setBool(_keyRunningVoiceGuidance, value);
  }

  Future<void> setCadenceFeedbackType(String value) async {
    _cadenceFeedbackType = value;
    notifyListeners();
    await _prefs.setString(_keyCadenceFeedbackType, value);
  }

  Future<void> setDefaultCadenceBpm(int? value) async {
    _defaultCadenceBpm = value != null ? value.clamp(40, 240) : null;
    notifyListeners();
    _defaultCadenceBpm != null
        ? await _prefs.setInt(_keyDefaultCadenceBpm, _defaultCadenceBpm!)
        : await _prefs.remove(_keyDefaultCadenceBpm);
  }

  Future<void> setDefaultTargetPaceSecPerKm(int? value) async {
    _defaultTargetPaceSecPerKm = value != null ? value.clamp(60, 1800) : null;
    notifyListeners();
    _defaultTargetPaceSecPerKm != null
        ? await _prefs.setInt(_keyDefaultTargetPaceSecPerKm, _defaultTargetPaceSecPerKm!)
        : await _prefs.remove(_keyDefaultTargetPaceSecPerKm);
  }
}
