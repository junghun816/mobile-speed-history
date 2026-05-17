import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/ride_record.dart';
import '../providers/ride_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/utils_format.dart';
import '../widgets/widgets_number_input.dart';
import 'settings/settings_widgets.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RideProvider>().loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final records = context.watch<RideProvider>().records;
    final useKmh = settings.useKmh;
    final cs = Theme.of(context).colorScheme;

    final cardColor = cs.surfaceContainer;
    final textColor = cs.onSurface;
    final subColor = cs.onSurfaceVariant;
    final sectionColor = cs.outline;

    final now = DateTime.now();
    final ytdDist = records
        .where((r) => r.year == now.year)
        .fold(0.0, (s, r) => s + r.totalDistance);
    final mtdDist = records
        .where((r) => r.year == now.year && r.month == now.month)
        .fold(0.0, (s, r) => s + r.totalDistance);
    final currentMaxSpeed = records.isEmpty
        ? 0.0
        : records.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b);
    final currentMaxDist = records.isEmpty
        ? 0.0
        : records.map((r) => r.totalDistance).reduce((a, b) => a > b ? a : b);
    final currentMaxDur = records.isEmpty
        ? 0
        : records.map((r) => r.duration).reduce((a, b) => a > b ? a : b);
    final streak = _calcStreak(records);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _sectionTitle('거리 목표', sectionColor),
            _distanceGoalCard(
              label: '올해',
              current: ytdDist,
              goalKm: settings.yearlyGoalKm,
              useKmh: useKmh,
              color: Colors.blue,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
              onTap: () => _setDistanceGoal(
                title: '올해 거리 목표',
                currentGoalKm: settings.yearlyGoalKm,
                useKmh: useKmh,
                onSet: settings.setYearlyGoalKm,
              ),
            ),
            SizedBox(height: 10.h),
            _distanceGoalCard(
              label: '이번 달',
              current: mtdDist,
              goalKm: settings.monthlyGoalKm,
              useKmh: useKmh,
              color: Colors.teal,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
              onTap: () => _setDistanceGoal(
                title: '이번달 거리 목표',
                currentGoalKm: settings.monthlyGoalKm,
                useKmh: useKmh,
                onSet: settings.setMonthlyGoalKm,
              ),
            ),

            SizedBox(height: 24.h),
            _sectionTitle('도전 목표', sectionColor),
            _challengeCard(
              label: '최고속도',
              icon: Icons.speed,
              color: Colors.orange,
              currentValue: formatSpeed(currentMaxSpeed, useKmh),
              goalValue: settings.goalMaxSpeedKmh != null
                  ? formatSpeed(settings.goalMaxSpeedKmh!, useKmh)
                  : null,
              unit: speedUnit(useKmh),
              achieved: settings.goalMaxSpeedKmh != null &&
                  currentMaxSpeed >= settings.goalMaxSpeedKmh!,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
              onTap: () => _setSpeedGoal(settings, useKmh),
            ),
            SizedBox(height: 10.h),
            _challengeCard(
              label: '최장거리 (1회)',
              icon: Icons.straighten,
              color: Colors.purple,
              currentValue: formatDistance(currentMaxDist, useKmh),
              goalValue: settings.goalMaxDistanceKm != null
                  ? formatDistance(settings.goalMaxDistanceKm!, useKmh)
                  : null,
              unit: distanceUnit(useKmh),
              achieved: settings.goalMaxDistanceKm != null &&
                  currentMaxDist >= settings.goalMaxDistanceKm!,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
              onTap: () => _setDistanceGoal(
                title: '최장거리 목표',
                currentGoalKm: settings.goalMaxDistanceKm,
                useKmh: useKmh,
                onSet: settings.setGoalMaxDistanceKm,
              ),
            ),
            SizedBox(height: 10.h),
            _challengeCard(
              label: '최장시간 (1회)',
              icon: Icons.timer_outlined,
              color: Colors.indigo,
              currentValue: formatDuration(currentMaxDur),
              goalValue: settings.goalMaxDurationMin != null
                  ? formatDuration(settings.goalMaxDurationMin! * 60)
                  : null,
              unit: '',
              achieved: settings.goalMaxDurationMin != null &&
                  currentMaxDur >= settings.goalMaxDurationMin! * 60,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
              onTap: () => _setDurationGoal(settings),
            ),

            SizedBox(height: 24.h),
            _sectionTitle('주행 스트릭', sectionColor),
            _streakCard(
              streak.current,
              streak.best,
              cardColor: cardColor,
              textColor: textColor,
              subColor: subColor,
              dividerColor: cs.outlineVariant,
            ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  ({int current, int best}) _calcStreak(List<RideRecord> records) {
    if (records.isEmpty) return (current: 0, best: 0);

    final uniqueDates = records
        .map((r) => DateTime(r.year, r.month, r.day))
        .toSet()
        .toList()
      ..sort();

    int best = 1, cur = 1;
    for (int i = 1; i < uniqueDates.length; i++) {
      if (uniqueDates[i].difference(uniqueDates[i - 1]).inDays == 1) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 1;
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final daysSinceLast = todayDate.difference(uniqueDates.last).inDays;

    int currentStreak = 0;
    if (daysSinceLast <= 1) {
      currentStreak = 1;
      for (int i = uniqueDates.length - 2; i >= 0; i--) {
        if (uniqueDates[i + 1].difference(uniqueDates[i]).inDays == 1) {
          currentStreak++;
        } else {
          break;
        }
      }
    }

    return (current: currentStreak, best: best);
  }

  Future<void> _setDistanceGoal({
    required String title,
    required double? currentGoalKm,
    required bool useKmh,
    required Future<void> Function(double?) onSet,
  }) async {
    SystemSound.play(SystemSoundType.click);
    final initialVal = currentGoalKm != null
        ? convertDistance(currentGoalKm, useKmh)
        : null;
    final result = await NumberInputDialog.show(
      context,
      title: title,
      initialValue: initialVal,
      unit: distanceUnit(useKmh),
      maxDigits: 5,
      allowEmpty: true,
      allowDecimal: true,
    );
    if (result == null) return;
    if (result == NumberInputDialog.clearValue) {
      await onSet(null);
    } else {
      final km = useKmh ? result : result / 0.621371;
      await onSet(km);
    }
  }

  Future<void> _setSpeedGoal(SettingsProvider settings, bool useKmh) async {
    SystemSound.play(SystemSoundType.click);
    final initialVal = settings.goalMaxSpeedKmh != null
        ? convertSpeed(settings.goalMaxSpeedKmh!, useKmh)
        : null;
    final result = await NumberInputDialog.show(
      context,
      title: '최고속도 목표',
      initialValue: initialVal,
      unit: speedUnit(useKmh),
      maxDigits: 3,
      allowEmpty: true,
      allowDecimal: true,
    );
    if (result == null) return;
    if (result == NumberInputDialog.clearValue) {
      await settings.setGoalMaxSpeedKmh(null);
    } else {
      final kmh = useKmh ? result : result / 0.621371;
      await settings.setGoalMaxSpeedKmh(kmh);
    }
  }

  Future<void> _setDurationGoal(SettingsProvider settings) async {
    SystemSound.play(SystemSoundType.click);
    final result = await NumberInputDialog.show(
      context,
      title: '최장시간 목표',
      initialValue: settings.goalMaxDurationMin,
      unit: '분',
      maxDigits: 4,
      allowEmpty: true,
    );
    if (result == null) return;
    if (result == NumberInputDialog.clearValue) {
      await settings.setGoalMaxDurationMin(null);
    } else {
      await settings.setGoalMaxDurationMin(result.round());
    }
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _distanceGoalCard({
    required String label,
    required double current,
    required double? goalKm,
    required bool useKmh,
    required Color color,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    final displayCurrent = convertDistance(current, useKmh);
    final displayGoal = goalKm != null ? convertDistance(goalKm, useKmh) : null;
    final progress = (displayGoal != null && displayGoal > 0)
        ? (displayCurrent / displayGoal).clamp(0.0, 1.0)
        : 0.0;
    final achieved = displayGoal != null && displayCurrent >= displayGoal;
    final unit = distanceUnit(useKmh);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                settingsIconBox(Icons.flag_outlined, color: color),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    '$label 거리 목표',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (achieved)
                  Icon(Icons.check_circle, color: Colors.green, size: 20.r)
                else
                  Icon(Icons.edit_outlined, color: subColor, size: 16.r),
              ],
            ),
            SizedBox(height: 14.h),
            if (goalKm == null)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Text(
                    '탭하여 목표 설정',
                    style: TextStyle(color: subColor, fontSize: 13.sp),
                  ),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${formatDouble(displayCurrent, 1)} $unit',
                    style: TextStyle(
                      color: achieved ? Colors.green : color,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '목표 ${formatDouble(displayGoal!, 0)} $unit',
                    style: TextStyle(color: subColor, fontSize: 13.sp),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(
                      achieved ? Colors.green : color),
                  minHeight: 8.h,
                ),
              ),
              SizedBox(height: 6.h),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyle(color: subColor, fontSize: 12.sp),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _challengeCard({
    required String label,
    required IconData icon,
    required Color color,
    required String currentValue,
    required String? goalValue,
    required String unit,
    required bool achieved,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            settingsIconBox(icon, color: color),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 2.h),
                  Text(
                    '현재 $currentValue${unit.isNotEmpty ? ' $unit' : ''}',
                    style: TextStyle(color: subColor, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            if (goalValue == null)
              Text('미설정', style: TextStyle(color: subColor, fontSize: 13.sp))
            else if (achieved)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '목표 $goalValue${unit.isNotEmpty ? ' $unit' : ''}',
                    style: TextStyle(color: subColor, fontSize: 12.sp),
                  ),
                  SizedBox(width: 6.w),
                  Icon(Icons.check_circle, color: Colors.green, size: 18.r),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$goalValue${unit.isNotEmpty ? ' $unit' : ''}',
                    style: TextStyle(
                        color: color,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  Text('목표', style: TextStyle(color: subColor, fontSize: 11.sp)),
                ],
              ),
            SizedBox(width: 8.w),
            Icon(Icons.edit_outlined, color: subColor, size: 16.r),
          ],
        ),
      ),
    );
  }

  Widget _streakCard(
    int current,
    int best, {
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required Color dividerColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$current',
                      style: TextStyle(
                        color: current > 0 ? Colors.amber : subColor,
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text('일', style: TextStyle(color: subColor, fontSize: 14.sp)),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_fire_department,
                        color: current > 0 ? Colors.amber : subColor, size: 14.r),
                    SizedBox(width: 4.w),
                    Text('현재 스트릭',
                        style: TextStyle(color: subColor, fontSize: 12.sp)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 1.w,
            height: 56.h,
            color: dividerColor,
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$best',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text('일', style: TextStyle(color: subColor, fontSize: 14.sp)),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events_outlined,
                        color: Colors.amber, size: 14.r),
                    SizedBox(width: 4.w),
                    Text('역대 최장',
                        style: TextStyle(color: subColor, fontSize: 12.sp)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
