import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../models/ride_record.dart';
import '../utils/format_utils.dart';
import '../widgets/memo_bottom_sheet.dart';
import '../widgets/stat_item.dart';

class SpeedometerScreen extends StatefulWidget {
  const SpeedometerScreen({super.key});

  @override
  State<SpeedometerScreen> createState() => _SpeedometerScreenState();
}

class _SpeedometerScreenState extends State<SpeedometerScreen>
    with WidgetsBindingObserver {
  bool _locationGranted = true;
  String _selectedActivityType = 'bike';
  RideProvider? _ride;
  int _lastSpeedAlertCount = 0;
  int _lastDistanceAlertCount = 0;
  bool _showAlertPopup = false;
  bool _isDistanceAlert = false;
  Timer? _alertPopupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _selectedActivityType = context.read<SettingsProvider>().lastActivityType;
        });
        _ride = context.read<RideProvider>();
        _ride!.addListener(_onRideUpdate);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ride?.removeListener(_onRideUpdate);
    _alertPopupTimer?.cancel();
    super.dispose();
  }

  void _onRideUpdate() {
    final ride = _ride;
    if (ride == null) return;
    if (ride.speedAlertTriggerCount != _lastSpeedAlertCount) {
      _lastSpeedAlertCount = ride.speedAlertTriggerCount;
      _alertPopupTimer?.cancel();
      setState(() => _showAlertPopup = true);
      _alertPopupTimer = Timer(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _showAlertPopup = false);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (mounted && granted != _locationGranted) {
      setState(() => _locationGranted = granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isRunning = ride.isRiding
        ? ride.activityType == 'run'
        : _selectedActivityType == 'run';
    final maxSpeed = isRunning ? 30.0 : 60.0;

    final isOverTargetPace = ride.isRiding && ride.isOverTargetPace;

    final speedTextColor = isOverTargetPace ? Colors.orange : cs.onSurface;
    final panelColor = cs.surfaceContainer;
    final unitTextColor = cs.onSurfaceVariant;
    final dividerColor = cs.outlineVariant;
    final statLabelColor = cs.onSurfaceVariant;

    final isPaused = ride.isRiding && ride.isPaused;
    final bgColor = isPaused
        ? Color.lerp(cs.surface, Colors.orange, isDark ? 0.13 : 0.09)!
        : cs.surface;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: bgColor,
        child: Stack(
        children: [
        SafeArea(
        bottom: false,
        child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          // 현재 시각
          if (settings.clockDisplay != 'none')
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                final h = settings.clockDisplay == 'h12'
                    ? (now.hour % 12 == 0 ? 12 : now.hour % 12)
                    : now.hour;
                final m = now.minute.toString().padLeft(2, '0');
                final s = now.second.toString().padLeft(2, '0');
                final prefix = settings.clockDisplay == 'h12'
                    ? (now.hour < 12 ? 'AM ' : 'PM ')
                    : '';
                return Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Text(
                    '$prefix$h:$m:$s',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 52.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      height: 1.0,
                    ),
                  ),
                );
              },
            ),

          // 속도계 게이지
          Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                height: MediaQuery.of(context).size.width * 0.75,
                child: CustomPaint(
                  painter: SpeedometerPainter(
                    speed: ride.currentSpeed,
                    maxSpeed: maxSpeed,
                    isDark: isDark,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 150.h),
                        if (isRunning) ...[
                          Text(
                            ride.currentPaceSecPerKm != null
                                ? formatPace(ride.currentPaceSecPerKm!)
                                : '--:--',
                            style: TextStyle(
                              color: speedTextColor,
                              fontSize: 64.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'min/km',
                            style: TextStyle(
                              color: unitTextColor,
                              fontSize: 18.sp,
                              height: 1.0,
                            ),
                          ),
                          if (ride.isRiding) ...[
                            SizedBox(height: 4.h),
                            Text(
                              '${ride.completedLaps} km 완주',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ] else ...[
                          Text(
                            formatSpeed(ride.currentSpeed, useKmh),
                            style: TextStyle(
                              color: speedTextColor,
                              fontSize: 64.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            speedUnit(useKmh),
                            style: TextStyle(
                              color: unitTextColor,
                              fontSize: 18.sp,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ),

          SizedBox(height: 2.h),

          // 통계 카드 (표시 항목 설정 반영)
          _buildStatsRow(ride, settings, useKmh,
              panelColor: panelColor,
              dividerColor: dividerColor,
              labelColor: statLabelColor,
              valueColor: cs.onSurface,
              isDark: isDark),

          SizedBox(height: 16.h),

          // 일시정지 표시 — 항상 공간 차지, 내용만 페이드
          AnimatedOpacity(
            opacity: isPaused ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.orange.withOpacity(0.6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pause_circle_outline,
                      color: Colors.orange, size: 16.r),
                  SizedBox(width: 6.w),
                  Text(
                    ride.isManuallyPaused ? '일시정지 중' : '자동 일시정지 중',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // 시작/정지 버튼 (중앙) + 속도 모드 (좌) + 일시정지 (우)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                // 왼쪽: 주행 중 - 활동 종목 표시 (잠금) / 비주행 시 - 활동 종목 선택
                Expanded(
                  child: Center(
                    child: ride.isRiding
                        ? _activityTypeLockedBadge(ride.activityType)
                        : _activityTypeBadge(),
                  ),
                ),
                // 중앙: 시작/정지 버튼
                GestureDetector(
                  onTap: () async {
                    SystemSound.play(SystemSoundType.click);
                    if (ride.isRiding) {
                      final useKmh = settings.useKmh;
                      final weightKg = settings.weightKg;
                      final minDist = settings.minRecordDistanceKm;
                      final minDur = settings.minRecordDurationSec;
                      final savedRecord = await ride.stopRide(
                        minRecordDistanceKm: minDist,
                        minRecordDurationSec: minDur,
                      );
                      if (!context.mounted) return;
                      if (savedRecord == null) {
                        final reason = ride.stopFailReason;
                        final msg = reason == 'duration'
                            ? '시간 부족 (최소 ${minDur}초) — 저장 안 됨'
                            : '거리 부족 (최소 ${formatDouble(minDist, 1)} km) — 저장 안 됨';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(msg),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } else {
                        _showRideSummary(context, savedRecord, useKmh, weightKg);
                      }
                    } else {
                      final permission = await Geolocator.checkPermission();
                      if (!context.mounted) return;
                      if (permission == LocationPermission.denied ||
                          permission == LocationPermission.deniedForever) {
                        final forever = permission == LocationPermission.deniedForever;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(forever
                                ? '설정에서 위치 권한을 허용해주세요.'
                                : '위치 권한이 필요합니다.'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                            action: forever
                                ? SnackBarAction(
                                    label: '설정으로',
                                    textColor: Colors.white,
                                    onPressed: () => Geolocator.openAppSettings(),
                                  )
                                : null,
                          ),
                        );
                        return;
                      }
                      final isBike = _selectedActivityType == 'bike';
                      ride.startRide(
                        gpsHighAccuracy: settings.gpsHighAccuracy,
                        autoPause: settings.autoPause,
                        speedAlertKmh: isBike ? settings.speedAlertKmh : null,
                        speedMinAlertKmh: isBike ? settings.speedMinAlertKmh : null,
                        speedMode: settings.speedMode,
                        distanceAlertKm: isBike ? settings.distanceAlertKm : null,
                        useKmh: settings.useKmh,
                        activityType: _selectedActivityType,
                        cadenceBpm: _selectedActivityType == 'run'
                            ? settings.defaultCadenceBpm
                            : null,
                        targetPaceSecPerKm: _selectedActivityType == 'run'
                            ? settings.defaultTargetPaceSecPerKm
                            : null,
                        voiceGuidance: _selectedActivityType == 'run' &&
                            settings.runningVoiceGuidance,
                        cadenceVibration: settings.cadenceVibration,
                        cadenceSound: settings.cadenceSound,
                        speedMaxAlertPopupEnabled: isBike && settings.speedMaxAlertPopup,
                        speedMaxAlertVibrationEnabled: isBike && settings.speedMaxAlertVibration,
                        speedMaxAlertSoundEnabled: isBike && settings.speedMaxAlertSound,
                        speedMinAlertPopupEnabled: isBike && settings.speedMinAlertPopup,
                        speedMinAlertVibrationEnabled: isBike && settings.speedMinAlertVibration,
                        speedMinAlertSoundEnabled: isBike && settings.speedMinAlertSound,
                      );
                    }
                  },
                  child: Container(
                    width: 140.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      color: ride.isRiding ? Colors.red : Colors.green,
                      boxShadow: [
                        BoxShadow(
                          color: (ride.isRiding ? Colors.red : Colors.green)
                              .withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        ride.isRiding ? '종료' : '시작',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // 오른쪽: 일시정지/재개 + (자전거) 랩 버튼
                Expanded(
                  child: ride.isRiding
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _pauseResumeButton(ride),
                              if (ride.activityType == 'bike') ...[
                                SizedBox(height: 8.h),
                                _lapButton(ride),
                              ],
                            ],
                          ),
                        )
                      : const SizedBox(),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),
        ],
        ),
      ),
      if (!_locationGranted)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16.w,
          right: 16.w,
          child: _permissionBanner(cs),
        ),
      if (_showAlertPopup)
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16.w,
          right: 16.w,
          child: _speedAlertBanner(ride, settings, cs),
        ),
      ],
      ),
    ),
  );
  }

  void _showRideSummary(BuildContext context, RideRecord record,
      bool useKmh, double? weightKg) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = TextEditingController();
    final ride = context.read<RideProvider>();
    final int? calories = calcCalories(record.totalDistance, weightKg);
    final cardKey = GlobalKey();
    final isBike = record.activityType == 'bike';

    Future<void> shareCard() async {
      final boundary = cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ride_result.png');
      await file.writeAsBytes(pngBytes);
      await Share.shareXFiles([XFile(file.path)]);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
        child: StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r)),
          insetPadding:
              EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '주행 완료',
                  style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),

                // 공유 카드 (RepaintBoundary로 캡처)
                RepaintBoundary(
                  key: cardKey,
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isBike ? Icons.directions_bike : Icons.directions_run,
                              color: Colors.blue,
                              size: 16.r,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              isBike ? '자전거' : '런닝',
                              style: TextStyle(color: Colors.blue, fontSize: 13.sp, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Text(
                              '${record.year}.${record.month.toString().padLeft(2, '0')}.${record.day.toString().padLeft(2, '0')}',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            StatDetailItem(label: '거리', value: formatDistance(record.totalDistance, useKmh), unit: distanceUnit(useKmh), textColor: cs.onSurface),
                            StatDetailItem(label: '시간', value: formatDuration(record.duration), textColor: cs.onSurface),
                            StatDetailItem(label: '최고속도', value: formatSpeed(record.maxSpeed, useKmh), unit: speedUnit(useKmh), textColor: cs.onSurface),
                            StatDetailItem(label: '평균속도', value: formatSpeed(record.avgSpeed, useKmh), unit: speedUnit(useKmh), textColor: cs.onSurface),
                          ],
                        ),
                        if (calories != null) ...[
                          SizedBox(height: 10.h),
                          Divider(color: cs.outlineVariant, height: 1),
                          SizedBox(height: 10.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_fire_department, color: Colors.orange, size: 14.r),
                              SizedBox(width: 4.w),
                              Text(
                                '${formatNumber(calories)} kcal',
                                style: TextStyle(color: Colors.orange, fontSize: 13.sp, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: 10.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Speed Mobile',
                            style: TextStyle(color: cs.outline, fontSize: 10.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: () async {
                    await showMemoBottomSheet(ctx, controller: ctrl);
                    if (ctx.mounted) setDialogState(() {});
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 70.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: ctrl.text.isEmpty
                        ? Text('메모를 남겨보세요 (탭하여 입력)',
                            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14.sp))
                        : Text(ctrl.text,
                            style: TextStyle(color: cs.onSurface, fontSize: 14.sp)),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: cs.outlineVariant),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        onPressed: () {
                          SystemSound.play(SystemSoundType.click);
                          shareCard();
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share, size: 16.r, color: cs.onSurface),
                            SizedBox(width: 4.w),
                            Text('공유',
                                style: TextStyle(color: cs.onSurface, fontSize: 15.sp)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        onPressed: () async {
                          final memo = ctrl.text.trim();
                          if (memo.isNotEmpty && record.id != null) {
                            await ride.updateMemo(record.id!, memo);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text('확인',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _permissionBanner(ColorScheme cs) {
    return GestureDetector(
      onTap: () => Geolocator.openAppSettings(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(Icons.location_off, color: Colors.white, size: 18.r),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '위치 권한이 없습니다. 탭하여 설정에서 허용해주세요.',
                style: TextStyle(color: Colors.white, fontSize: 13.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _speedAlertBanner(RideProvider ride, SettingsProvider settings, ColorScheme cs) {
    final speed = ride.currentSpeed;
    final isOver = settings.speedAlertKmh != null && speed >= settings.speedAlertKmh!;
    final color = isOver ? Colors.red : Colors.blue;
    final icon = isOver ? Icons.arrow_upward : Icons.arrow_downward;
    final message = isOver ? '속도 초과' : '속도 미달';
    final limit = isOver
        ? '${settings.speedAlertKmh!.toInt()} km/h'
        : '${settings.speedMinAlertKmh!.toInt()} km/h';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.88),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '$message  |  기준 $limit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '현재 ${formatSpeed(speed, settings.useKmh)} ${speedUnit(settings.useKmh)}',
            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _activityTypeLockedBadge(String activityType) {
    final isBike = activityType == 'bike';
    final color = isBike ? Colors.blue : Colors.deepOrange;
    return Container(
      width: 60.r,
      height: 60.r,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isBike ? Icons.directions_bike : Icons.directions_run,
            color: color.withOpacity(0.7),
            size: 22.r,
          ),
          SizedBox(height: 3.h),
          Text(
            isBike ? '자전거' : '런닝',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTypeBadge() {
    final isBike = _selectedActivityType == 'bike';
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        final next = isBike ? 'run' : 'bike';
        setState(() => _selectedActivityType = next);
        context.read<SettingsProvider>().setLastActivityType(next);
      },
      child: Container(
        width: 60.r,
        height: 60.r,
        decoration: BoxDecoration(
          color: (isBike ? Colors.blue : Colors.deepOrange).withOpacity(0.12),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: (isBike ? Colors.blue : Colors.deepOrange).withOpacity(0.35),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isBike ? Icons.directions_bike : Icons.directions_run,
              color: isBike ? Colors.blue : Colors.deepOrange,
              size: 22.r,
            ),
            SizedBox(height: 3.h),
            Text(
              isBike ? '자전거' : '런닝',
              style: TextStyle(
                color: isBike ? Colors.blue : Colors.deepOrange,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pauseResumeButton(RideProvider ride) {
    final isManuallyPaused = ride.isManuallyPaused;
    final color = isManuallyPaused ? Colors.green : Colors.orange;
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        if (isManuallyPaused) {
          ride.resumeRide();
        } else {
          ride.pauseRide();
        }
      },
      child: Container(
        width: 60.r,
        height: 60.r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          isManuallyPaused ? Icons.play_arrow : Icons.pause,
          color: Colors.white,
          size: 28.r,
        ),
      ),
    );
  }

  Widget _lapButton(RideProvider ride) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        ride.recordManualLap();
      },
      child: Container(
        width: 60.r,
        height: 36.r,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.indigo,
          boxShadow: [
            BoxShadow(
              color: Colors.indigo.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'LAP${ride.manualLapCount > 0 ? ' ${ride.manualLapCount}' : ''}',
            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      RideProvider ride, SettingsProvider settings, bool useKmh, {
      required Color panelColor,
      required Color dividerColor,
      required Color labelColor,
      required Color valueColor,
      required bool isDark,
  }) {
    final currentAvgSpeed = ride.duration > 0
        ? ride.totalDistance / (ride.duration / 3600.0)
        : 0.0;
    final isRunMode = ride.isRiding && ride.activityType == 'run';

    final items = <(String, String)>[
      if (settings.showDistance)
        ('거리',
            '${formatDistance(ride.totalDistance, useKmh)} ${distanceUnit(useKmh)}'),
      if (settings.showDuration) ('시간', ride.formattedDuration),
      if (settings.showMaxSpeed)
        isRunMode
            ? ('최고페이스',
                ride.maxSpeed > 0
                    ? '${formatPace(paceFromSpeed(ride.maxSpeed)!)} min/km'
                    : '--:--')
            : ('최고속도',
                '${formatSpeed(ride.maxSpeed, useKmh)} ${speedUnit(useKmh)}'),
      if (settings.showAvgSpeed)
        isRunMode
            ? ('평균페이스',
                currentAvgSpeed > 0
                    ? '${formatPace(paceFromSpeed(currentAvgSpeed)!)} min/km'
                    : '--:--')
            : ('평균속도',
                '${formatSpeed(currentAvgSpeed, useKmh)} ${speedUnit(useKmh)}'),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: !isDark
              ? [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) _divider(dividerColor),
              Expanded(child: _statCard(items[i].$1, items[i].$2, labelColor: labelColor, valueColor: valueColor)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, {required Color labelColor, required Color valueColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(color: labelColor, fontSize: 13.sp),
        ),
      ],
    );
  }

  Widget _divider(Color color) {
    return Container(
      height: 36.h,
      width: 1.w,
      color: color,
    );
  }
}

class SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final bool isDark;

  SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    this.isDark = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    const startAngle = 150.0 * pi / 180;
    const sweepTotal = 240.0 * pi / 180;

    // 배경 호 (회색)
    final bgPaint = Paint()
      ..color = isDark ? Colors.grey[800]! : Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      bgPaint,
    );

    // 속도 호 (속도에 따라 색상 변경)
    final speedRatio = (speed / maxSpeed).clamp(0.0, 1.0);
    final speedSweep = sweepTotal * speedRatio;

    if (speedSweep > 0) {
      final Color arcColor;
      if (speedRatio < 0.5) {
        arcColor = Colors.blue;
      } else if (speedRatio < 0.75) {
        arcColor = Colors.green;
      } else if (speedRatio < 0.9) {
        arcColor = Colors.orange;
      } else {
        arcColor = Colors.red;
      }

      final speedPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        speedSweep,
        false,
        speedPaint,
      );
    }

    // 눈금
    _drawTicks(canvas, center, radius, startAngle, sweepTotal, isDark);

    // 바늘
    _drawNeedle(canvas, center, radius, speedRatio, startAngle, sweepTotal, isDark);

    // 중심 원
    canvas.drawCircle(center, 10, Paint()..color = isDark ? Colors.white : Colors.black87);
    canvas.drawCircle(center, 6, Paint()..color = isDark ? Colors.grey[900]! : const Color(0xFFF2F4F7));
  }

  void _drawTicks(Canvas canvas, Offset center, double radius,
      double startAngle, double sweepTotal, bool isDark) {
    const totalTicks = 24;
    const majorTickInterval = 4;

    for (int i = 0; i <= totalTicks; i++) {
      final angle = startAngle + (sweepTotal / totalTicks) * i;
      final isMajor = i % majorTickInterval == 0;

      final tickLength = isMajor ? 14.0 : 7.0;
      final tickWidth = isMajor ? 2.0 : 1.0;
      final tickColor = isMajor
          ? (isDark ? Colors.white : Colors.black87)
          : (isDark ? Colors.grey[600]! : Colors.grey[400]!);

      final outerR = radius - 18;
      final innerR = outerR - tickLength;

      final outerPoint = Offset(
        center.dx + outerR * cos(angle),
        center.dy + outerR * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + innerR * cos(angle),
        center.dy + innerR * sin(angle),
      );

      canvas.drawLine(
        outerPoint,
        innerPoint,
        Paint()
          ..color = tickColor
          ..strokeWidth = tickWidth,
      );

      // 주요 눈금 숫자
      if (isMajor) {
        final speedLabel =
        ((maxSpeed / totalTicks) * i).round().toString();
        final labelR = outerR - tickLength - 16;
        final labelPoint = Offset(
          center.dx + labelR * cos(angle),
          center.dy + labelR * sin(angle),
        );

        final textPainter = TextPainter(
          text: TextSpan(
            text: speedLabel,
            style: TextStyle(
              color: isDark ? Colors.grey : Colors.grey[600],
              fontSize: 11,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          labelPoint -
              Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius,
      double speedRatio, double startAngle, double sweepTotal, bool isDark) {
    final needleAngle = startAngle + sweepTotal * speedRatio;
    final needleLength = radius - 35;

    final needleEnd = Offset(
      center.dx + needleLength * cos(needleAngle),
      center.dy + needleLength * sin(needleAngle),
    );
    final tailEnd = Offset(
      center.dx - 20 * cos(needleAngle),
      center.dy - 20 * sin(needleAngle),
    );

    canvas.drawLine(
      tailEnd,
      needleEnd,
      Paint()
        ..color = isDark ? Colors.white : Colors.black87
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed ||
        oldDelegate.maxSpeed != maxSpeed ||
        oldDelegate.isDark != isDark;
  }
}
