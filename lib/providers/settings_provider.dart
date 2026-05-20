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
  static const _keyCadenceEnabled = 'cadence_enabled';
  static const _keyCadenceVibration = 'cadence_vibration';
  static const _keyCadenceSound = 'cadence_sound';
  static const _keyDefaultCadenceBpm = 'default_cadence_bpm';
  static const _keyDefaultTargetPaceSecPerKm = 'default_target_pace_sec_per_km';
  static const _keyLastActivityType = 'last_activity_type';
  static const _keySpeedMaxAlertPopup = 'speed_max_alert_popup';
  static const _keySpeedMaxAlertVibration = 'speed_max_alert_vibration';
  static const _keySpeedMaxAlertSound = 'speed_max_alert_sound';
  static const _keySpeedMinAlertPopup = 'speed_min_alert_popup';
  static const _keySpeedMinAlertVibration = 'speed_min_alert_vibration';
  static const _keySpeedMinAlertSound = 'speed_min_alert_sound';
  static const _keyDistanceAlertPopup = 'distance_alert_popup';
  static const _keyDistanceAlertVibration = 'distance_alert_vibration';
  static const _keyDistanceAlertSound = 'distance_alert_sound';
  static const _keyUserName = 'user_name';
  static const _keyLapIntervalKmBike = 'lap_interval_km_bike';
  static const _keyLapIntervalKmRun = 'lap_interval_km_run';

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
  bool _cadenceEnabled = false;
  bool _cadenceVibration = true;
  bool _cadenceSound = false;
  int _defaultCadenceBpm = 160;
  String _lastActivityType = 'bike';
  int? _defaultTargetPaceSecPerKm;
  int _lapIntervalKmBike = 1;
  int _lapIntervalKmRun = 1;
  bool _speedMaxAlertPopup = true;
  bool _speedMaxAlertVibration = true;
  bool _speedMaxAlertSound = false;
  bool _speedMinAlertPopup = true;
  bool _speedMinAlertVibration = true;
  bool _speedMinAlertSound = false;
  bool _distanceAlertPopup = true;
  bool _distanceAlertVibration = true;
  bool _distanceAlertSound = false;
  String _userName = '';

  // 타일 접힘 상태 (in-memory only, 앱 세션 내 유지)
  final Map<String, bool> _tileExpanded = {};
  bool getTileExpanded(String key) => _tileExpanded[key] ?? false;
  void setTileExpanded(String key, bool v) { _tileExpanded[key] = v; }

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
  bool get cadenceEnabled => _cadenceEnabled;
  bool get cadenceVibration => _cadenceVibration;
  bool get cadenceSound => _cadenceSound;
  int get defaultCadenceBpm => _defaultCadenceBpm;
  String get lastActivityType => _lastActivityType;
  int? get defaultTargetPaceSecPerKm => _defaultTargetPaceSecPerKm;
  bool get speedMaxAlertPopup => _speedMaxAlertPopup;
  bool get speedMaxAlertVibration => _speedMaxAlertVibration;
  bool get speedMaxAlertSound => _speedMaxAlertSound;
  bool get speedMinAlertPopup => _speedMinAlertPopup;
  bool get speedMinAlertVibration => _speedMinAlertVibration;
  bool get speedMinAlertSound => _speedMinAlertSound;
  bool get distanceAlertPopup => _distanceAlertPopup;
  bool get distanceAlertVibration => _distanceAlertVibration;
  bool get distanceAlertSound => _distanceAlertSound;
  String get userName => _userName;
  int get lapIntervalKmBike => _lapIntervalKmBike;
  int get lapIntervalKmRun => _lapIntervalKmRun;

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
    _cadenceEnabled = _prefs.getBool(_keyCadenceEnabled) ?? (_prefs.getInt(_keyDefaultCadenceBpm) != null);
    _cadenceVibration = _prefs.getBool(_keyCadenceVibration) ?? true;
    _cadenceSound = _prefs.getBool(_keyCadenceSound) ?? false;
    _defaultCadenceBpm = _prefs.getInt(_keyDefaultCadenceBpm) ?? 160;
    _lastActivityType = _prefs.getString(_keyLastActivityType) ?? 'bike';
    _defaultTargetPaceSecPerKm = _prefs.getInt(_keyDefaultTargetPaceSecPerKm);
    _speedMaxAlertPopup = _prefs.getBool(_keySpeedMaxAlertPopup) ?? true;
    _speedMaxAlertVibration = _prefs.getBool(_keySpeedMaxAlertVibration) ?? true;
    _speedMaxAlertSound = _prefs.getBool(_keySpeedMaxAlertSound) ?? false;
    _speedMinAlertPopup = _prefs.getBool(_keySpeedMinAlertPopup) ?? true;
    _speedMinAlertVibration = _prefs.getBool(_keySpeedMinAlertVibration) ?? true;
    _speedMinAlertSound = _prefs.getBool(_keySpeedMinAlertSound) ?? false;
    _distanceAlertPopup = _prefs.getBool(_keyDistanceAlertPopup) ?? true;
    _distanceAlertVibration = _prefs.getBool(_keyDistanceAlertVibration) ?? true;
    _distanceAlertSound = _prefs.getBool(_keyDistanceAlertSound) ?? false;
    _userName = _prefs.getString(_keyUserName) ?? '';
    _lapIntervalKmBike = _prefs.getInt(_keyLapIntervalKmBike) ?? 1;
    _lapIntervalKmRun = _prefs.getInt(_keyLapIntervalKmRun) ?? 1;
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

  Future<void> setCadenceEnabled(bool value) async {
    _cadenceEnabled = value;
    notifyListeners();
    await _prefs.setBool(_keyCadenceEnabled, value);
  }

  Future<void> setCadenceVibration(bool value) async {
    _cadenceVibration = value;
    notifyListeners();
    await _prefs.setBool(_keyCadenceVibration, value);
  }

  Future<void> setCadenceSound(bool value) async {
    _cadenceSound = value;
    notifyListeners();
    await _prefs.setBool(_keyCadenceSound, value);
  }

  Future<void> setDefaultCadenceBpm(int value) async {
    _defaultCadenceBpm = value.clamp(40, 240);
    notifyListeners();
    await _prefs.setInt(_keyDefaultCadenceBpm, _defaultCadenceBpm);
  }

  Future<void> setDefaultTargetPaceSecPerKm(int? value) async {
    _defaultTargetPaceSecPerKm = value != null ? value.clamp(60, 600) : null;
    notifyListeners();
    _defaultTargetPaceSecPerKm != null
        ? await _prefs.setInt(_keyDefaultTargetPaceSecPerKm, _defaultTargetPaceSecPerKm!)
        : await _prefs.remove(_keyDefaultTargetPaceSecPerKm);
  }

  Future<void> setLastActivityType(String value) async {
    _lastActivityType = value;
    notifyListeners();
    await _prefs.setString(_keyLastActivityType, value);
  }

  Future<void> setSpeedMaxAlertPopup(bool value) async {
    _speedMaxAlertPopup = value;
    notifyListeners();
    await _prefs.setBool(_keySpeedMaxAlertPopup, value);
  }

  Future<void> setSpeedMaxAlertVibration(bool value) async {
    _speedMaxAlertVibration = value;
    notifyListeners();
    await _prefs.setBool(_keySpeedMaxAlertVibration, value);
  }

  Future<void> setSpeedMaxAlertSound(bool value) async {
    _speedMaxAlertSound = value;
    notifyListeners();
    await _prefs.setBool(_keySpeedMaxAlertSound, value);
  }

  Future<void> setSpeedMinAlertPopup(bool value) async {
    _speedMinAlertPopup = value;
    notifyListeners();
    await _prefs.setBool(_keySpeedMinAlertPopup, value);
  }

  Future<void> setSpeedMinAlertVibration(bool value) async {
    _speedMinAlertVibration = value;
    notifyListeners();
    await _prefs.setBool(_keySpeedMinAlertVibration, value);
  }

  Future<void> setSpeedMinAlertSound(bool value) async {
    _speedMinAlertSound = value;
    notifyListeners();
    await _prefs.setBool(_keySpeedMinAlertSound, value);
  }

  Future<void> setDistanceAlertPopup(bool value) async {
    _distanceAlertPopup = value;
    notifyListeners();
    await _prefs.setBool(_keyDistanceAlertPopup, value);
  }

  Future<void> setDistanceAlertVibration(bool value) async {
    _distanceAlertVibration = value;
    notifyListeners();
    await _prefs.setBool(_keyDistanceAlertVibration, value);
  }

  Future<void> setDistanceAlertSound(bool value) async {
    _distanceAlertSound = value;
    notifyListeners();
    await _prefs.setBool(_keyDistanceAlertSound, value);
  }

  Future<void> setUserName(String value) async {
    _userName = value;
    notifyListeners();
    value.isNotEmpty
        ? await _prefs.setString(_keyUserName, value)
        : await _prefs.remove(_keyUserName);
  }

  Future<void> setLapIntervalKmBike(int value) async {
    _lapIntervalKmBike = value.clamp(1, 99);
    notifyListeners();
    await _prefs.setInt(_keyLapIntervalKmBike, _lapIntervalKmBike);
  }

  Future<void> setLapIntervalKmRun(int value) async {
    _lapIntervalKmRun = value.clamp(1, 99);
    notifyListeners();
    await _prefs.setInt(_keyLapIntervalKmRun, _lapIntervalKmRun);
  }
}
