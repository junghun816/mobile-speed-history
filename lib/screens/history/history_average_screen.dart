import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/ride_record.dart';
import '../../utils/format_utils.dart';

class HistoryAverageScreen extends StatelessWidget {
  const HistoryAverageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RideProvider>().records;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final weightKg = settings.weightKg;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey : Colors.grey[600]!;

    if (records.isEmpty) {
      return Center(
        child: Text(
          '아직 주행기록이 없어요',
          style: TextStyle(
            color: isDark ? Colors.grey : Colors.grey[600],
            fontSize: 16.sp,
          ),
        ),
      );
    }

    final avgDistance =
        records.fold(0.0, (s, r) => s + r.totalDistance) / records.length;
    final avgDuration =
        records.fold(0, (s, r) => s + r.duration) ~/ records.length;
    final avgMaxSpeed =
        records.fold(0.0, (s, r) => s + r.maxSpeed) / records.length;
    final avgAvgSpeed =
        records.fold(0.0, (s, r) => s + r.avgSpeed) / records.length;
    final totalDist = records.fold(0.0, (s, r) => s + r.totalDistance);
    final totalDuration = records.fold(0, (s, r) => s + r.duration);
    final bestSpeed =
        records.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b);

    final totalCalories = calcCalories(totalDist, weightKg);
    final avgCalories = calcCalories(avgDistance, weightKg);

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recent = records.where((r) {
      final date = DateTime(r.year, r.month, r.day);
      return !date.isBefore(thirtyDaysAgo);
    }).toList();
    final recentAvgDist = recent.isEmpty
        ? null
        : recent.fold(0.0, (s, r) => s + r.totalDistance) / recent.length;
    final recentAvgSpeed = recent.isEmpty
        ? null
        : recent.fold(0.0, (s, r) => s + r.avgSpeed) / recent.length;

    int? avgIntervalDays;
    if (records.length >= 2) {
      final sorted = List.from(records)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      int totalGap = 0;
      for (int i = 1; i < sorted.length; i++) {
        final prev =
            DateTime.fromMillisecondsSinceEpoch(sorted[i - 1].createdAt);
        final curr =
            DateTime.fromMillisecondsSinceEpoch(sorted[i].createdAt);
        totalGap += curr.difference(prev).inDays;
      }
      avgIntervalDays = totalGap ~/ (sorted.length - 1);
    }

    final weekdayTotals = List.filled(7, 0.0);
    final weekdayCounts = List.filled(7, 0);
    for (final r in records) {
      final wd = DateTime(r.year, r.month, r.day).weekday - 1;
      weekdayTotals[wd] += r.totalDistance;
      weekdayCounts[wd]++;
    }
    final weekdayAvgs = List.generate(
        7, (i) => weekdayCounts[i] > 0 ? weekdayTotals[i] / weekdayCounts[i] : 0.0);
    final maxWeekdayAvg = weekdayAvgs.reduce((a, b) => a > b ? a : b);
    final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final bestDayIdx = weekdayCounts.every((c) => c == 0)
        ? -1
        : weekdayAvgs.indexOf(weekdayAvgs.reduce((a, b) => a > b ? a : b));

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 누적 헤더 카드
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.blue.shade900, Colors.blue.shade600]
                    : [Colors.blue.shade500, Colors.blue.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Text('전체 누적',
                    style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _bigStat('총 횟수', '${formatNumber(records.length)}회',
                        Icons.directions_bike),
                    _vDivider(),
                    _bigStat(
                        '총 거리',
                        '${formatDistance(totalDist, useKmh, decimals: 1)} ${distanceUnit(useKmh)}',
                        Icons.straighten),
                    _vDivider(),
                    _bigStat('총 시간', formatDuration(totalDuration), Icons.timer),
                  ],
                ),
                if (totalCalories != null) ...[
                  SizedBox(height: 14.h),
                  const Divider(color: Colors.white24, height: 1),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _bigStat('총 칼로리',
                          '${formatNumber(totalCalories)} kcal',
                          Icons.local_fire_department),
                      _vDivider(),
                      _bigStat(
                          '최고 속도',
                          '${formatSpeed(bestSpeed, useKmh)} ${speedUnit(useKmh)}',
                          Icons.speed),
                    ],
                  ),
                ] else ...[
                  SizedBox(height: 14.h),
                  const Divider(color: Colors.white24, height: 1),
                  SizedBox(height: 14.h),
                  _bigStat(
                      '최고 속도',
                      '${formatSpeed(bestSpeed, useKmh)} ${speedUnit(useKmh)}',
                      Icons.speed),
                ],
              ],
            ),
          ),

          SizedBox(height: 24.h),
          _sectionLabel('1회 평균', textColor),
          SizedBox(height: 10.h),

          Row(
            children: [
              Expanded(
                child: _avgCard('거리',
                    '${formatDistance(avgDistance, useKmh)}',
                    distanceUnit(useKmh), Icons.straighten, Colors.blue,
                    cardColor, textColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _avgCard('시간', formatDuration(avgDuration), '',
                    Icons.timer, Colors.teal, cardColor, textColor),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _avgCard(
                    '최고속도',
                    '${formatSpeed(avgMaxSpeed, useKmh)}',
                    speedUnit(useKmh),
                    Icons.speed,
                    Colors.orange,
                    cardColor,
                    textColor),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _avgCard(
                    '평균속도',
                    '${formatSpeed(avgAvgSpeed, useKmh)}',
                    speedUnit(useKmh),
                    Icons.trending_up,
                    Colors.purple,
                    cardColor,
                    textColor),
              ),
            ],
          ),
          if (avgCalories != null) ...[
            SizedBox(height: 10.h),
            _statTile('1회 평균 칼로리', '${formatNumber(avgCalories)} kcal',
                icon: Icons.local_fire_department,
                iconColor: Colors.deepOrange,
                cardColor: cardColor,
                textColor: textColor,
                subTextColor: subTextColor),
          ],

          SizedBox(height: 24.h),
          _sectionLabel('최근 30일', textColor),
          SizedBox(height: 10.h),

          recent.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('최근 30일 기록 없음',
                      style: TextStyle(color: subTextColor, fontSize: 13.sp),
                      textAlign: TextAlign.center),
                )
              : Row(
                  children: [
                    Expanded(
                      child: _compareCard(
                        '평균 거리',
                        '${formatDistance(recentAvgDist!, useKmh)} ${distanceUnit(useKmh)}',
                        '전체 ${formatDistance(avgDistance, useKmh)}',
                        recentAvgDist > avgDistance,
                        cardColor,
                        textColor,
                        subTextColor,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _compareCard(
                        '평균 속도',
                        '${formatSpeed(recentAvgSpeed!, useKmh)} ${speedUnit(useKmh)}',
                        '전체 ${formatSpeed(avgAvgSpeed, useKmh)}',
                        recentAvgSpeed > avgAvgSpeed,
                        cardColor,
                        textColor,
                        subTextColor,
                      ),
                    ),
                  ],
                ),

          SizedBox(height: 24.h),
          _sectionLabel('주행 패턴', textColor),
          SizedBox(height: 10.h),

          Row(
            children: [
              if (avgIntervalDays != null)
                Expanded(
                  child: _statTile(
                    '평균 주행 간격',
                    avgIntervalDays == 0 ? '매일' : '$avgIntervalDays일에 1번',
                    icon: Icons.calendar_today,
                    iconColor: Colors.cyan,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                ),
              if (avgIntervalDays != null && bestDayIdx >= 0)
                SizedBox(width: 10.w),
              if (bestDayIdx >= 0)
                Expanded(
                  child: _statTile(
                    '가장 많이 탄 요일',
                    weekdayNames[bestDayIdx],
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                  ),
                ),
            ],
          ),

          SizedBox(height: 10.h),

          // 요일별 막대
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('요일별 평균 거리',
                    style: TextStyle(color: subTextColor, fontSize: 12.sp)),
                SizedBox(height: 14.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final ratio = maxWeekdayAvg > 0
                        ? weekdayAvgs[i] / maxWeekdayAvg
                        : 0.0;
                    final isMax = i == bestDayIdx && weekdayCounts[i] > 0;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: Column(
                          children: [
                            weekdayCounts[i] > 0
                                ? Text(
                                    formatDistance(weekdayAvgs[i], useKmh, decimals: 1),
                                    style: TextStyle(
                                      color: isMax
                                          ? Colors.blue
                                          : (isDark ? Colors.grey[600]! : Colors.grey[500]!),
                                      fontSize: 9.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : SizedBox(height: 13.h),
                            SizedBox(height: 3.h),
                            Container(
                              height: 60.h * ratio +
                                  (weekdayCounts[i] > 0 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: isMax
                                    ? Colors.blue
                                    : weekdayCounts[i] > 0
                                        ? (isDark ? Colors.grey[700]! : Colors.grey[400]!)
                                        : (isDark ? Colors.grey[850]! : Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              weekdayNames[i],
                              style: TextStyle(
                                color: isMax ? Colors.blue : subTextColor,
                                fontSize: 12.sp,
                                fontWeight: isMax
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),
          _sectionLabel('월별 거리 추이', textColor),
          SizedBox(height: 10.h),
          _buildMonthlyChart(records, useKmh, isDark, cardColor, textColor, subTextColor),

          SizedBox(height: 24.h),
          _sectionLabel('시간대별 패턴', textColor),
          SizedBox(height: 10.h),
          _buildTimeOfDayChart(records, isDark, cardColor, textColor, subTextColor),

          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, Color textColor) {
    return Text(text,
        style: TextStyle(
            color: textColor,
            fontSize: 15.sp,
            fontWeight: FontWeight.bold));
  }

  Widget _bigStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 18.r),
        SizedBox(height: 6.h),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 2.h),
        Text(label,
            style: TextStyle(color: Colors.white54, fontSize: 11.sp)),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 48.h, color: Colors.white24);

  Widget _avgCard(String label, String value, String unit, IconData icon,
      Color color, Color cardColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(height: 10.h),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(color: color, fontSize: 11.sp)),
          SizedBox(height: 4.h),
          Text(label,
              style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _compareCard(
      String label, String recentVal, String overallVal, bool isUp,
      Color cardColor, Color textColor, Color subTextColor) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: subTextColor, fontSize: 12.sp)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_upward : Icons.arrow_downward,
                color: isUp ? Colors.green : Colors.red,
                size: 14.r,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(recentVal,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(overallVal,
              style: TextStyle(color: subTextColor, fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value,
      {IconData? icon,
      Color? iconColor,
      required Color cardColor,
      required Color textColor,
      required Color subTextColor}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? Colors.grey, size: 16.r),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: Text(label,
                style: TextStyle(color: subTextColor, fontSize: 13.sp)),
          ),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart(List<RideRecord> records, bool useKmh, bool isDark,
      Color cardColor, Color textColor, Color subTextColor) {
    final Map<String, double> monthly = {};
    for (final r in records) {
      final key = '${r.year}-${r.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + r.totalDistance;
    }

    final sortedKeys = monthly.keys.toList()..sort();
    final displayKeys = sortedKeys.length > 6
        ? sortedKeys.sublist(sortedKeys.length - 6)
        : sortedKeys;

    if (displayKeys.isEmpty) return const SizedBox.shrink();

    final maxDist =
        displayKeys.map((k) => monthly[k]!).reduce((a, b) => a > b ? a : b);
    final multiYear =
        displayKeys.map((k) => k.split('-')[0]).toSet().length > 1;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('최근 ${displayKeys.length}개월',
              style: TextStyle(color: subTextColor, fontSize: 12.sp)),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: displayKeys.map((key) {
              final dist = monthly[key]!;
              final ratio = maxDist > 0 ? dist / maxDist : 0.0;
              final parts = key.split('-');
              final month = int.parse(parts[1]);
              final year = parts[0].substring(2);
              final label = multiYear ? '$month월\n\'$year' : '$month월';
              final isMax = dist == maxDist;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: Column(
                    children: [
                      Text(
                        formatDistance(dist, useKmh, decimals: 1),
                        style: TextStyle(
                          color: isMax
                              ? Colors.blue
                              : (isDark
                                  ? Colors.grey[600]!
                                  : Colors.grey[500]!),
                          fontSize: 9.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 3.h),
                      Container(
                        height: 60.h * ratio + 4,
                        decoration: BoxDecoration(
                          color: isMax
                              ? Colors.blue
                              : (isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        label,
                        style: TextStyle(
                          color: isMax ? Colors.blue : subTextColor,
                          fontSize: 10.sp,
                          fontWeight:
                              isMax ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOfDayChart(List<RideRecord> records, bool isDark,
      Color cardColor, Color textColor, Color subTextColor) {
    const slotLabels = ['새벽\n0-6시', '오전\n6-12시', '오후\n12-18시', '저녁\n18-24시'];
    const slotColors = [Colors.indigo, Colors.orange, Colors.blue, Colors.deepPurple];
    final counts = [0, 0, 0, 0];

    for (final r in records) {
      final hour = DateTime.fromMillisecondsSinceEpoch(r.createdAt).hour;
      if (hour < 6) {
        counts[0]++;
      } else if (hour < 12) {
        counts[1]++;
      } else if (hour < 18) {
        counts[2]++;
      } else {
        counts[3]++;
      }
    }

    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    if (maxCount == 0) return const SizedBox.shrink();
    final bestIdx = counts.indexOf(maxCount);

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('시간대별 주행 패턴',
              style: TextStyle(color: subTextColor, fontSize: 12.sp)),
          SizedBox(height: 14.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (i) {
              final ratio = counts[i] / maxCount;
              final isMax = i == bestIdx;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: Column(
                    children: [
                      counts[i] > 0
                          ? Text(
                              '${counts[i]}회',
                              style: TextStyle(
                                color: isMax
                                    ? slotColors[i]
                                    : (isDark
                                        ? Colors.grey[600]!
                                        : Colors.grey[500]!),
                                fontSize: 9.sp,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : SizedBox(height: 13.h),
                      SizedBox(height: 3.h),
                      Container(
                        height: 60.h * ratio + (counts[i] > 0 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: isMax
                              ? slotColors[i]
                              : (counts[i] > 0
                                  ? (isDark
                                      ? Colors.grey[700]!
                                      : Colors.grey[400]!)
                                  : (isDark
                                      ? Colors.grey[850]!
                                      : Colors.grey[300]!)),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        slotLabels[i],
                        style: TextStyle(
                          color: isMax ? slotColors[i] : subTextColor,
                          fontSize: 10.sp,
                          fontWeight:
                              isMax ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
