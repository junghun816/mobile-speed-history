import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/utils_format.dart';

class HistoryHeatmapFullScreen extends StatefulWidget {
  final int initialYear;

  const HistoryHeatmapFullScreen({super.key, required this.initialYear});

  @override
  State<HistoryHeatmapFullScreen> createState() =>
      _HistoryHeatmapFullScreenState();
}

class _HistoryHeatmapFullScreenState
    extends State<HistoryHeatmapFullScreen> {
  late int _selectedYear;
  DateTime? _tappedDay;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

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

  String _weekdayLabel(int weekday) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final records = context.watch<RideProvider>().records;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = cs.onSurface;

    final years = records.map((r) => r.year).toSet().toList()..sort();
    if (years.isEmpty) years.add(DateTime.now().year);
    final displayYear =
        years.contains(_selectedYear) ? _selectedYear : years.last;

    final yearStart = DateTime(displayYear, 1, 1);
    final daysInYear =
        DateTime(displayYear, 12, 31).difference(yearStart).inDays + 1;
    final startOffset = yearStart.weekday - 1;

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
    final numWeeks = ((startOffset + daysInYear) / 7).ceil();

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
    final levels = _levelColors(isDark);

    // 탭된 날 정보 계산
    int? tappedOffset;
    double tappedKm = 0;
    int tappedCount = 0;
    if (_tappedDay != null) {
      final rawOffset = _tappedDay!.difference(yearStart).inDays;
      if (rawOffset >= 0 && rawOffset < daysInYear) {
        tappedOffset = rawOffset;
        tappedKm = dayKm[rawOffset] ?? 0;
        tappedCount = dayCount[rawOffset] ?? 0;
      }
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 헤더: 연도 칩 + 합계 + 닫기 ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Row(
                children: [
                  Expanded(
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
                              margin: EdgeInsets.only(right: 6.w),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: selected
                                    ? Colors.indigo
                                    : cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              child: Text(
                                '$y년',
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : textColor,
                                  fontSize: 12.sp,
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
                  SizedBox(width: 10.w),
                  Text(
                    '총 ${formatNumber(totalRides)}회  '
                    '${formatDistance(totalKm, useKmh)} ${distanceUnit(useKmh)}',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.close_fullscreen,
                          color: textColor, size: 18.r),
                    ),
                  ),
                ],
              ),
            ),

            // ── 탭 정보 표시 영역 ──
            Container(
              height: 28.h,
              padding: EdgeInsets.symmetric(horizontal: 14.w),
              alignment: Alignment.centerLeft,
              child: tappedOffset != null
                  ? Row(
                      children: [
                        Text(
                          '${_tappedDay!.month}월 ${_tappedDay!.day}일'
                          ' (${_weekdayLabel(_tappedDay!.weekday)})',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 10.w),
                        if (tappedCount > 0) ...[
                          Text(
                            '${formatNumber(tappedCount)}회',
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12.sp),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${formatDistance(tappedKm, useKmh)} ${distanceUnit(useKmh)}',
                            style: TextStyle(
                                color: Colors.indigo,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold),
                          ),
                        ] else
                          Text(
                            '기록 없음',
                            style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12.sp),
                          ),
                      ],
                    )
                  : Text(
                      '날짜를 탭하면 상세 정보를 볼 수 있어요',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 11.sp),
                    ),
            ),

            // ── 히트맵 그리드 ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 2.h, 12.w, 2.h),
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    const dayLabelWidth = 18.0;
                    const labelGap = 3.0;
                    const monthLabelH = 14.0;
                    final gridWidth =
                        constraints.maxWidth - dayLabelWidth - labelGap;
                    final cellStep = gridWidth / numWeeks;
                    final cellSize = cellStep - 1.5;
                    final margin = (cellStep - cellSize) / 2;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 요일 라벨
                        Column(
                          children: [
                            const SizedBox(height: monthLabelH),
                            ...List.generate(
                              7,
                              (i) => SizedBox(
                                height: cellStep,
                                width: dayLabelWidth,
                                child: Center(
                                  child: Text(
                                    dayLabels[i],
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 8.sp),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: labelGap),
                        // 그리드
                        SizedBox(
                          width: gridWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 월 레이블
                              SizedBox(
                                height: monthLabelH,
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
                                      width: cellStep,
                                      child: label != null
                                          ? Text(label,
                                              style: TextStyle(
                                                  color: cs.onSurfaceVariant,
                                                  fontSize: 8.sp))
                                          : null,
                                    );
                                  }),
                                ),
                              ),
                              // 셀
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children:
                                    List.generate(numWeeks, (col) {
                                  return Column(
                                    children: List.generate(7, (row) {
                                      final cellIdx = col * 7 + row;
                                      final offset = cellIdx - startOffset;

                                      if (offset < 0 ||
                                          offset >= daysInYear) {
                                        return SizedBox(
                                            width: cellStep,
                                            height: cellStep);
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
                                          SystemSound.play(
                                              SystemSoundType.click);
                                          setState(() {
                                            _tappedDay =
                                                isTapped ? null : date;
                                          });
                                        },
                                        child: Container(
                                          width: cellSize,
                                          height: cellSize,
                                          margin:
                                              EdgeInsets.all(margin),
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
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── 범례 ──
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
              child: Row(
                children: [
                  Text('적음',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 10.sp)),
                  SizedBox(width: 4.w),
                  ...List.generate(
                    5,
                    (i) => Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 1.5),
                      decoration: BoxDecoration(
                        color: levels[i],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Text('많음',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 10.sp)),
                  SizedBox(width: 10.w),
                  Text('(10 / 20 / 40 km)',
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 9.sp)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
