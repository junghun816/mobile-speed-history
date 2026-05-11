import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/speed_mode.dart';

class SettingsProvider extends ChangeNotifier {
  static const _keyUseKmh = 'use_kmh';
  static const _keyGpsHighAccuracy = 'gps_high_accuracy';
  static const _keyMinRecordDistance = 'min_record_distance';
  static const _keyAutoPause = 'auto_pause';
  static const _keyDefaultGaugeSpeed = 'default_gauge_speed';
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

  bool _useKmh = true;
  bool _gpsHighAccuracy = true;
  double _minRecordDistanceKm = 0.1;
  bool _autoPause = false;
  int _defaultGaugeSpeed = 60;
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

  bool get useKmh => _useKmh;
  bool get gpsHighAccuracy => _gpsHighAccuracy;
  double get minRecordDistanceKm => _minRecordDistanceKm;
  bool get autoPause => _autoPause;
  int get defaultGaugeSpeed => _defaultGaugeSpeed;
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

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _useKmh = prefs.getBool(_keyUseKmh) ?? true;
    _gpsHighAccuracy = prefs.getBool(_keyGpsHighAccuracy) ?? true;
    _minRecordDistanceKm = prefs.getDouble(_keyMinRecordDistance) ?? 0.1;
    _autoPause = prefs.getBool(_keyAutoPause) ?? false;
    _defaultGaugeSpeed = prefs.getInt(_keyDefaultGaugeSpeed) ?? 60;
    _weightKg = prefs.getDouble(_keyWeightKg);
    _showDistance = prefs.getBool(_keyShowDistance) ?? true;
    _showDuration = prefs.getBool(_keyShowDuration) ?? true;
    _showMaxSpeed = prefs.getBool(_keyShowMaxSpeed) ?? true;
    _showAvgSpeed = prefs.getBool(_keyShowAvgSpeed) ?? true;
    _appTheme = prefs.getString(_keyAppTheme) ?? 'dark';
    _minRecordDurationSec = prefs.getInt(_keyMinRecordDuration) ?? 0;
    _speedAlertKmh = prefs.getDouble(_keySpeedAlertKmh);
    _speedMinAlertKmh = prefs.getDouble(_keySpeedMinAlertKmh);
    _mapType = prefs.getString(_keyMapType) ?? 'basic';
    _yearlyGoalKm = prefs.getDouble(_keyYearlyGoalKm);
    _monthlyGoalKm = prefs.getDouble(_keyMonthlyGoalKm);
    _goalMaxSpeedKmh = prefs.getDouble(_keyGoalMaxSpeedKmh);
    _goalMaxDistanceKm = prefs.getDouble(_keyGoalMaxDistanceKm);
    _goalMaxDurationMin = prefs.getInt(_keyGoalMaxDurationMin);
    _onboardingDone = prefs.getBool(_keyOnboardingDone) ?? false;
    final speedModeStr = prefs.getString(_keySpeedMode);
    if (speedModeStr != null) {
      _speedMode = SpeedMode.fromString(speedModeStr);
    } else {
      // 구버전 low_speed_mode bool 마이그레이션
      _speedMode = (prefs.getBool(_keyLowSpeedMode) ?? false)
          ? SpeedMode.lowSpeed
          : SpeedMode.normal;
    }
    _distanceAlertKm = prefs.getInt(_keyDistanceAlertKm);
    _clockDisplay = prefs.getString(_keyClockDisplay) ?? 'none';
    _pathColor = prefs.getString(_keyPathColor) ?? 'blue';
    _pathThickness = prefs.getInt(_keyPathThickness) ?? 5;
    _mapTrackingMode = prefs.getString(_keyMapTrackingMode) ?? 'none';
    _startTab = prefs.getInt(_keyStartTab) ?? 0;
    notifyListeners();
  }

  Future<void> completeOnboarding({required bool neverShowAgain}) async {
    _onboardingSkippedThisSession = true;
    if (neverShowAgain) {
      _onboardingDone = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingDone, true);
    }
    notifyListeners();
  }

  Future<void> setUseKmh(bool value) async {
    _useKmh = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseKmh, value);
  }

  Future<void> setGpsHighAccuracy(bool value) async {
    _gpsHighAccuracy = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGpsHighAccuracy, value);
  }

  Future<void> setMinRecordDistanceKm(double value) async {
    _minRecordDistanceKm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMinRecordDistance, value);
  }

  Future<void> setAutoPause(bool value) async {
    _autoPause = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoPause, value);
  }

  Future<void> setDefaultGaugeSpeed(int value) async {
    _defaultGaugeSpeed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultGaugeSpeed, value);
  }

  Future<void> setWeightKg(double? value) async {
    _weightKg = value != null ? value.clamp(1.0, 999.0) : null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_weightKg != null) {
      await prefs.setDouble(_keyWeightKg, _weightKg!);
    } else {
      await prefs.remove(_keyWeightKg);
    }
  }

  Future<void> setShowDistance(bool value) async {
    _showDistance = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDistance, value);
  }

  Future<void> setShowDuration(bool value) async {
    _showDuration = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDuration, value);
  }

  Future<void> setShowMaxSpeed(bool value) async {
    _showMaxSpeed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowMaxSpeed, value);
  }

  Future<void> setShowAvgSpeed(bool value) async {
    _showAvgSpeed = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAvgSpeed, value);
  }

  Future<void> setAppTheme(String value) async {
    _appTheme = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppTheme, value);
  }

  Future<void> setMinRecordDurationSec(int value) async {
    _minRecordDurationSec = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMinRecordDuration, value);
  }

  Future<void> setSpeedAlertKmh(double? value) async {
    _speedAlertKmh = value != null ? value.clamp(kDebugMode ? 0.0 : 1.0, 999.0) : null;
    // 미만 알림과 충돌(초과 ≤ 미만)이면 미만 알림 해제
    if (_speedAlertKmh != null && _speedMinAlertKmh != null &&
        _speedAlertKmh! <= _speedMinAlertKmh!) {
      _speedMinAlertKmh = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySpeedMinAlertKmh);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_speedAlertKmh != null) {
      await prefs.setDouble(_keySpeedAlertKmh, _speedAlertKmh!);
    } else {
      await prefs.remove(_keySpeedAlertKmh);
    }
  }

  Future<void> setSpeedMinAlertKmh(double? value) async {
    _speedMinAlertKmh = value != null ? value.clamp(kDebugMode ? 0.0 : 1.0, 999.0) : null;
    // 초과 알림과 충돌(미만 ≥ 초과)이면 초과 알림 해제
    if (_speedMinAlertKmh != null && _speedAlertKmh != null &&
        _speedMinAlertKmh! >= _speedAlertKmh!) {
      _speedAlertKmh = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySpeedAlertKmh);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (_speedMinAlertKmh != null) {
      await prefs.setDouble(_keySpeedMinAlertKmh, _speedMinAlertKmh!);
    } else {
      await prefs.remove(_keySpeedMinAlertKmh);
    }
  }

  Future<void> setMapType(String value) async {
    _mapType = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMapType, value);
  }

  Future<void> setYearlyGoalKm(double? value) async {
    _yearlyGoalKm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    value != null
        ? await prefs.setDouble(_keyYearlyGoalKm, value)
        : await prefs.remove(_keyYearlyGoalKm);
  }

  Future<void> setMonthlyGoalKm(double? value) async {
    _monthlyGoalKm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    value != null
        ? await prefs.setDouble(_keyMonthlyGoalKm, value)
        : await prefs.remove(_keyMonthlyGoalKm);
  }

  Future<void> setGoalMaxSpeedKmh(double? value) async {
    _goalMaxSpeedKmh = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    value != null
        ? await prefs.setDouble(_keyGoalMaxSpeedKmh, value)
        : await prefs.remove(_keyGoalMaxSpeedKmh);
  }

  Future<void> setGoalMaxDistanceKm(double? value) async {
    _goalMaxDistanceKm = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    value != null
        ? await prefs.setDouble(_keyGoalMaxDistanceKm, value)
        : await prefs.remove(_keyGoalMaxDistanceKm);
  }

  Future<void> setDistanceAlertKm(int? value) async {
    _distanceAlertKm = value != null ? value.clamp(1, 999) : null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    _distanceAlertKm != null
        ? await prefs.setInt(_keyDistanceAlertKm, _distanceAlertKm!)
        : await prefs.remove(_keyDistanceAlertKm);
  }

  Future<void> setClockDisplay(String value) async {
    _clockDisplay = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyClockDisplay, value);
  }

  Future<void> setSpeedMode(SpeedMode value) async {
    _speedMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySpeedMode, value.name);
  }

  Future<void> setPathColor(String value) async {
    _pathColor = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPathColor, value);
  }

  Future<void> setPathThickness(int value) async {
    _pathThickness = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPathThickness, value);
  }

  Future<void> setStartTab(int value) async {
    _startTab = value.clamp(0, 4);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStartTab, _startTab);
  }

  Future<void> setMapTrackingMode(String value) async {
    _mapTrackingMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMapTrackingMode, value);
  }

  Future<void> setGoalMaxDurationMin(int? value) async {
    _goalMaxDurationMin = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    value != null
        ? await prefs.setInt(_keyGoalMaxDurationMin, value)
        : await prefs.remove(_keyGoalMaxDurationMin);
  }
}
