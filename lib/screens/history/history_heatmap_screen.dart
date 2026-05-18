import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/utils_format.dart';
import 'history_heatmap_full_screen.dart';

class HistoryHeatmapScreen extends StatefulWidget {
  const HistoryHeatmapScreen({super.key});

  @override
  State<HistoryHeatmapScreen> createState() => _HistoryHeatmapScreenState();
}

class _HistoryHeatmapScreenState extends State<HistoryHeatmapScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedYear = DateTime.now().year;
  DateTime? _tappedDay;

  // 셀 크기 (ScreenUtil 없이 고정값 — 히트맵은 픽셀 밀도 기반 시각화)
  static const double _cell = 12.0;
  static const double _gap = 2.0;
  static const double _step = _cell + _gap;

  List<Color> _levelColors(bool isDark) => [
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        isDark ? const Color(0xFF1A4A2E) : const Color(0xFFC6E48B),
        isDark ? const Color(0xFF2B6E45) : const Color(0xFF7BC96F),
        isDark ? const Color(0xFF3B9D5B) : const Color(0xFF239A3B),
        isDark ? const Color(0xFF4AC16D) : const Color(0xFF196127),
      ];

  int _kmLevel(double km) {
    if (km <= 0) return 0;
    if (km < 10) return 1;
    if (km < 20) return 2;
    if (km < 40) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final records = context.watch<RideProvider>().records;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = cs.onSurface;

    final years = records.map((r) => r.year).toSet().toList()..sort();
    if (years.isEmpty) years.add(DateTime.now().year);
    final displayYear = years.contains(_selectedYear) ? _selectedYear : years.last;

    // 선택 연도 데이터 집계
    final yearStart = DateTime(displayYear, 1, 1);
    final daysInYear =
        DateTime(displayYear, 12, 31).difference(yearStart).inDays + 1;
    final startOffset = yearStart.weekday - 1; // 0=월, 6=일

    final Map<int, double> dayKm = {};
    final Map<int, int> dayCount = {};
    for (final r in records) {
      if (r.year != displayYear) continue;
      final offset =
          DateTime(r.year, r.month, r.day).difference(yearStart).inDays;
      dayKm[offset] = (dayKm[offset] ?? 0) + r.totalDistance;
      dayCount[offset] = (dayCount[offset] ?? 0) + 1;
    }

    final totalKm = dayKm.values.fold(0.0, (s, v) => s + v);
    final totalRides = dayCount.values.fold(0, (s, v) => s + v);

    final activeDays = dayKm.keys.length;
    final avgPerActive = activeDays > 0 ? totalKm / activeDays : 0.0;

    final Map<int, double> monthKmMap = {};
    for (final e in dayKm.entries) {
      final month = yearStart.add(Duration(days: e.key)).month;
      monthKmMap[month] = (monthKmMap[month] ?? 0) + e.value;
    }
    int busiestMonth = 0;
    double busiestMonthKm = 0;
    for (final e in monthKmMap.entries) {
      if (e.value > busiestMonthKm) {
        busiestMonthKm = e.value;
        busiestMonth = e.key;
      }
    }

    int longestStreak = 0, curStreak = 0;
    for (int i = 0; i < daysInYear; i++) {
      if (dayKm.containsKey(i)) {
        curStreak++;
        if (curStreak > longestStreak) longestStreak = curStreak;
      } else {
        curStreak = 0;
      }
    }

    final numWeeks = ((startOffset + daysInYear) / 7).ceil();
    final levels = _levelColors(isDark);

    // 월 레이블: 각 월 첫날의 컬럼 인덱스
    final Map<int, int> monthCol = {};
    for (int m = 1; m <= 12; m++) {
      final offset =
          DateTime(displayYear, m, 1).difference(yearStart).inDays;
      monthCol[m] = (offset + startOffset) ~/ 7;
    }
    const monthLabels = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
    ];
    const dayLabels = ['월', '', '수', '', '금', '', '일'];

    // 탭된 날 정보
    int? tappedOffset;
    double tappedKm = 0;
    int tappedCount = 0;
    if (_tappedDay != null) {
      tappedOffset = _tappedDay!.difference(yearStart).inDays;
      tappedKm = dayKm[tappedOffset] ?? 0;
      tappedCount = dayCount[tappedOffset] ?? 0;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 연도 선택 칩
          Container(
            color: cs.surfaceContainer,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: years.map((y) {
                  final selected = y == displayYear;
                  return GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      setState(() {
                        _selectedYear = y;
                        _tappedDay = null;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: 8.w),
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.indigo
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '$y년',
                        style: TextStyle(
                          color: selected ? Colors.white : textColor,
                          fontSize: 13.sp,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 연도 합계 요약
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
            child: Row(
              children: [
                Text(
                  '총 ${formatNumber(totalRides)}회',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12.w),
                Text(
                  '${formatDistance(totalKm, useKmh)} ${distanceUnit(useKmh)}',
                  style: TextStyle(
                      color: Colors.indigo,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistoryHeatmapFullScreen(
                            initialYear: displayYear),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(Icons.open_in_full,
                        color: textColor, size: 18.r),
                  ),
                ),
              ],
            ),
          ),

          // 히트맵 그리드
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 요일 라벨 (월/수/금/일)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 16), // 월 레이블 높이
                    ...List.generate(7, (i) => SizedBox(
                          height: _step,
                          width: 16,
                          child: Center(
                            child: Text(
                              dayLabels[i],
                              style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 8.5.sp),
                            ),
                          ),
                        )),
                  ],
                ),
                const SizedBox(width: 4),

                // 주 컬럼 (가로 스크롤)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 월 레이블 행
                        SizedBox(
                          height: 16,
                          child: Row(
                            children: List.generate(numWeeks, (col) {
                              String? label;
                              for (final e in monthCol.entries) {
                                if (e.value == col) {
                                  label = monthLabels[e.key - 1];
                                  break;
                                }
                              }
                              return SizedBox(
                                width: _step,
                                child: label != null
                                    ? Text(label,
                                        style: TextStyle(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 8.5.sp))
                                    : null,
                              );
                            }),
                          ),
                        ),

                        // 셀 그리드 (numWeeks × 7)
                        SizedBox(
                          height: 7 * _step,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(numWeeks, (col) {
                              return Column(
                                children: List.generate(7, (row) {
                                  final cellIdx = col * 7 + row;
                                  final offset = cellIdx - startOffset;

                                  if (offset < 0 || offset >= daysInYear) {
                                    return const SizedBox(
                                        width: _step, height: _step);
                                  }

                                  final km = dayKm[offset] ?? 0.0;
                                  final level = _kmLevel(km);
                                  final date = yearStart
                                      .add(Duration(days: offset));
                                  final isTapped = _tappedDay != null &&
                                      _tappedDay!.year == date.year &&
                                      _tappedDay!.month == date.month &&
                                      _tappedDay!.day == date.day;

                                  return GestureDetector(
                                    onTap: () {
                                      SystemSound.play(SystemSoundType.click);
                                      setState(() {
                                        _tappedDay =
                                            isTapped ? null : date;
                                      });
                                    },
                                    child: Container(
                                      width: _cell,
                                      height: _cell,
                                      margin: const EdgeInsets.all(_gap / 2),
                                      decoration: BoxDecoration(
                                        color: levels[level],
                                        borderRadius:
                                            BorderRadius.circular(2),
                                        border: isTapped
                                            ? Border.all(
                                                color: Colors.white70,
                                                width: 1.5)
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 탭된 날 정보
          if (_tappedDay != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_tappedDay!.month}월 ${_tappedDay!.day}일 (${_weekdayLabel(_tappedDay!.weekday)})',
                      style: TextStyle(
                          color: textColor,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 12.w),
                    if (tappedCount > 0) ...[
                      Text(
                        '${formatNumber(tappedCount)}회',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13.sp),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${formatDistance(tappedKm, useKmh)} ${distanceUnit(useKmh)}',
                        style: TextStyle(
                            color: Colors.indigo,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold),
                      ),
                    ] else
                      Text(
                        '기록 없음',
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13.sp),
                      ),
                  ],
                ),
              ),
            ),

          // 범례
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
            child: Row(
              children: [
                Text('적음',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 11.sp)),
                SizedBox(width: 6.w),
                ...List.generate(
                    5,
                    (i) => Container(
                          width: _cell,
                          height: _cell,
                          margin: const EdgeInsets.only(right: _gap),
                          decoration: BoxDecoration(
                            color: levels[i],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )),
                SizedBox(width: 4.w),
                Text('많음',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 11.sp)),
                SizedBox(width: 16.w),
                Text('(하루 거리 기준: 10 / 20 / 40 km)',
                    style: TextStyle(
                        color: cs.onSurfaceVariant, fontSize: 10.sp)),
              ],
            ),
          ),

          // 통계 패널
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCell('활동일', '$activeDays일', textColor, cs),
                  Container(width: 1, height: 30.h, color: cs.outlineVariant),
                  _statCell(
                    '일평균 거리',
                    activeDays > 0
                        ? '${formatDistance(avgPerActive, useKmh)} ${distanceUnit(useKmh)}'
                        : '--',
                    textColor,
                    cs,
                  ),
                  Container(width: 1, height: 30.h, color: cs.outlineVariant),
                  _statCell(
                    '최다 활동월',
                    busiestMonth > 0 ? '$busiestMonth월' : '--',
                    textColor,
                    cs,
                  ),
                  Container(width: 1, height: 30.h, color: cs.outlineVariant),
                  _statCell('최장 연속', '$longestStreak일', textColor, cs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(int weekday) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[weekday - 1];
  }

  Widget _statCell(
      String label, String value, Color textColor, ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                color: textColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold)),
        SizedBox(height: 3.h),
        Text(label,
            style:
                TextStyle(color: cs.onSurfaceVariant, fontSize: 11.sp)),
      ],
    );
  }
}
