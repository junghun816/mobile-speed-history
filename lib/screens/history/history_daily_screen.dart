import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets_bar_chart.dart';
import '../../widgets/widgets_badges.dart';
import 'history_detail_map_screen.dart';
import '../../utils/utils_format.dart';
import '../../widgets/widgets_stat_item.dart';

class HistoryDailyScreen extends StatefulWidget {
  const HistoryDailyScreen({super.key});

  @override
  State<HistoryDailyScreen> createState() => _HistoryDailyScreenState();
}

class _HistoryDailyScreenState extends State<HistoryDailyScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = -1;
  int? _recentDays;
  bool _showWeekdayStats = true;
  int _selectedYear = DateTime.now().year;

  Map<int, Map<String, double>> _getWeekdayStats(
      Map<String, List<RideRecord>> grouped) {
    final Map<int, List<double>> weekdayDistances = {};

    for (final key in grouped.keys) {
      final list = grouped[key]!;
      if (list.isEmpty) continue;

      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final weekday = date.weekday - 1;
      final totalDist = list.fold(0.0, (s, r) => s + r.totalDistance);
      weekdayDistances.putIfAbsent(weekday, () => []).add(totalDist);
    }

    final Map<int, Map<String, double>> result = {};
    for (int i = 0; i < 7; i++) {
      final distances = weekdayDistances[i] ?? [];
      result[i] = {
        'avgDistance': distances.isEmpty
            ? 0.0
            : distances.reduce((a, b) => a + b) / distances.length,
        'count': distances.length.toDouble(),
      };
    }
    return result;
  }

  Widget _recentButton(String label, int days) {
    final isSelected = _recentDays == days;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        setState(() {
          _recentDays = isSelected ? null : days;
          _selectedIndex = -1;
        });
      },
      child: Container(
        height: 32.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.orange.withOpacity(0.2)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? Colors.orange
                : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.orange
                : cs.onSurfaceVariant,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final records = context.watch<RideProvider>().filteredRecords;
    final bestIds = context.read<RideProvider>().filteredBestRecordIds;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final weightKg = settings.weightKg;
    final cs = Theme.of(context).colorScheme;

    final cardColor = cs.surfaceContainer;
    final panelColor = cs.surfaceContainerHighest;
    final textColor = cs.onSurface;
    final dividerColor = cs.outlineVariant;
    final borderColor = cs.outlineVariant;

    final allYears = records.map((r) => r.year).toSet().toList()..sort();
    if (allYears.isNotEmpty && !allYears.contains(_selectedYear)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _selectedYear = allYears.last);
      });
    }
    final hasPrev = allYears.any((y) => y < _selectedYear);
    final hasNext = allYears.any((y) => y > _selectedYear);

    final Map<String, List<RideRecord>> grouped = {};
    for (final r in records.where((r) => r.year == _selectedYear)) {
      final key =
          '${r.year}-${r.month.toString().padLeft(2, '0')}-${r.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    if (grouped.isNotEmpty) {
      final allKeys = grouped.keys.toList()..sort();
      final firstDate = DateTime.parse(allKeys.first);
      final today = DateTime.now();
      DateTime cur = firstDate;

      while (!cur.isAfter(today)) {
        final key =
            '${cur.year}-${cur.month.toString().padLeft(2, '0')}-${cur.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(key, () => []);
        cur = cur.add(const Duration(days: 1));
      }
    }

    final weekdayStats = _getWeekdayStats(grouped);
    final allKeys = grouped.keys.toList()..sort();

    final filteredKeys = _recentDays == null
        ? allKeys
        : allKeys.where((k) {
      final parts = k.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return date.isAfter(
          DateTime.now().subtract(Duration(days: _recentDays!)));
    }).toList();

    final labels = filteredKeys.map((k) {
      final parts = k.split('-');
      return '${int.parse(parts[1])}.${int.parse(parts[2])}';
    }).toList();

    final distanceData = filteredKeys.map((k) =>
        grouped[k]!.fold(0.0, (s, r) => s + r.totalDistance)).toList();
    final durationData = filteredKeys.map((k) =>
        grouped[k]!.fold(0.0, (s, r) => s + r.duration)).toList();
    final maxSpeedData = filteredKeys.map((k) =>
    grouped[k]!.isEmpty
        ? 0.0
        : grouped[k]!.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b)).toList();
    final avgSpeedData = filteredKeys.map((k) =>
    grouped[k]!.isEmpty
        ? 0.0
        : grouped[k]!.fold(0.0, (s, r) => s + r.avgSpeed) /
        grouped[k]!.length).toList();

    List<RideRecord> selectedRecords = [];
    String selectedLabel = '';
    if (_selectedIndex >= 0 && _selectedIndex < filteredKeys.length) {
      selectedRecords = grouped[filteredKeys[_selectedIndex]] ?? [];
      final parts = filteredKeys[_selectedIndex].split('-');
      selectedLabel =
      '${parts[0]}년 ${int.parse(parts[1])}월 ${int.parse(parts[2])}일';
    }

    final totalDistance = selectedRecords.fold(0.0, (s, r) => s + r.totalDistance);
    final totalDuration = selectedRecords.fold(0, (s, r) => s + r.duration);
    final maxSpeed = selectedRecords.isEmpty
        ? 0.0
        : selectedRecords.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b);
    final avgSpeed = selectedRecords.isEmpty
        ? 0.0
        : selectedRecords.fold(0.0, (s, r) => s + r.avgSpeed) / selectedRecords.length;

    return SingleChildScrollView(
      child: Column(
      children: [
        // 연도 네비게이션
        Container(
          color: panelColor,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: hasPrev ? () {
                  SystemSound.play(SystemSoundType.click);
                  setState(() {
                    _selectedYear = allYears.lastWhere((y) => y < _selectedYear);
                    _selectedIndex = -1;
                    _recentDays = null;
                  });
                } : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: Icon(Icons.chevron_left,
                      color: hasPrev ? textColor : dividerColor, size: 24.r),
                ),
              ),
              DropdownButton<int>(
                value: allYears.contains(_selectedYear) ? _selectedYear : allYears.lastOrNull,
                underline: const SizedBox(),
                dropdownColor: panelColor,
                isDense: true,
                icon: const SizedBox.shrink(),
                style: TextStyle(color: textColor, fontSize: 15.sp, fontWeight: FontWeight.bold),
                items: allYears.map((y) => DropdownMenuItem(value: y, child: Text('$y년'))).toList(),
                onChanged: (y) {
                  if (y == null) return;
                  SystemSound.play(SystemSoundType.click);
                  setState(() {
                    _selectedYear = y;
                    _selectedIndex = -1;
                    _recentDays = null;
                  });
                },
              ),
              GestureDetector(
                onTap: hasNext ? () {
                  SystemSound.play(SystemSoundType.click);
                  setState(() {
                    _selectedYear = allYears.firstWhere((y) => y > _selectedYear);
                    _selectedIndex = -1;
                    _recentDays = null;
                  });
                } : null,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: Icon(Icons.chevron_right,
                      color: hasNext ? textColor : dividerColor, size: 24.r),
                ),
              ),
            ],
          ),
        ),

        // 기간 필터
        Container(
          color: panelColor,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Expanded(child: _recentButton('7일', 7)),
              SizedBox(width: 6.w),
              Expanded(child: _recentButton('30일', 30)),
              SizedBox(width: 6.w),
              Expanded(child: _recentButton('90일', 90)),
              SizedBox(width: 6.w),
              Expanded(child: _recentButton('180일', 180)),
              SizedBox(width: 6.w),
              Expanded(child: _recentButton('365일', 365)),
            ],
          ),
        ),

        SizedBox(
          height: 300.h,
          child: BarChartWidget(
            key: ValueKey(_recentDays),
            labels: labels,
            distanceData: distanceData,
            durationData: durationData,
            maxSpeedData: maxSpeedData,
            avgSpeedData: avgSpeedData,
            selectedIndex: _selectedIndex,
            useKmh: useKmh,
            onBarTap: (index) {
              SystemSound.play(SystemSoundType.click);
              setState(() {
                if (_selectedIndex == index) {
                  _selectedIndex = -1;
                } else {
                  _selectedIndex = index;
                }
              });
            },
          ),
        ),

        Container(height: 1, color: dividerColor),

        // 요일별 통계
        Container(
          color: panelColor,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  setState(() => _showWeekdayStats = !_showWeekdayStats);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '요일별 평균 거리',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      _showWeekdayStats
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.orange,
                      size: 20.r,
                    ),
                  ],
                ),
              ),
              if (_showWeekdayStats) ...[
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (i) {
                    final dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
                    final stat = weekdayStats[i]!;
                    final avgDist = stat['avgDistance']!;
                    final count = stat['count']!.toInt();
                    final maxDist = weekdayStats.values
                        .map((s) => s['avgDistance']!)
                        .reduce((a, b) => a > b ? a : b);
                    final ratio = maxDist > 0 ? avgDist / maxDist : 0.0;
                    final isWeekend = i == 5 || i == 6;

                    return Column(
                      children: [
                        Container(
                          width: 28.w,
                          height: 60.h,
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOut,
                            width: 28.w,
                            height: (60.h * ratio).clamp(2.0, 60.h),
                            decoration: BoxDecoration(
                              color: isWeekend ? Colors.orange : Colors.blue,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          avgDist > 0
                              ? formatDistance(avgDist, useKmh, decimals: 1)
                              : '-',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            color: isWeekend
                                ? Colors.orange
                                : cs.onSurfaceVariant,
                            fontSize: 11.sp,
                          ),
                        ),
                        Text(
                          '${count}회',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ],
          ),
        ),

        Container(height: 1, color: dividerColor),

        if (_selectedIndex < 0)
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Text(
              '막대를 탭하면 상세 정보를 볼 수 있어요',
              style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ),

        if (_selectedIndex >= 0)
          selectedRecords.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Center(
                    child: Text(
                      '해당 날짜에 기록이 없어요',
                      style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 14.sp),
                    ),
                  ),
                )
              : Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedLabel,
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.blue.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            StatItem(label: '총 거리', value: '${formatDistance(totalDistance, useKmh)} ${distanceUnit(useKmh)}', textColor: textColor, labelBlue: true),
                            StatItem(label: '총 시간', value: formatDuration(totalDuration), textColor: textColor, labelBlue: true),
                            StatItem(label: '최고속도', value: '${formatSpeed(maxSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor, labelBlue: true),
                            if (weightKg != null)
                              StatItem(label: '칼로리', value: '${formatNumber(calcCalories(totalDistance, weightKg)!)} kcal', textColor: textColor, labelBlue: true)
                            else
                              StatItem(label: '평균속도', value: '${formatSpeed(avgSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor, labelBlue: true),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '총 ${formatNumber(selectedRecords.length)}회 주행',
                          style: TextStyle(color: Colors.blue, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  ...selectedRecords.asMap().entries.map((e) {
                    final idx = e.key;
                    final record = e.value;
                    final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
                    final timeStr =
                        '${time.hour.toString().padLeft(2, '0')}:'
                        '${time.minute.toString().padLeft(2, '0')}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HistoryDetailMapScreen(record: record),
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.all(14.r),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${idx + 1}회차  $timeStr 출발',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text('경로 보기',
                                        style: TextStyle(color: Colors.blue, fontSize: 12.sp)),
                                    Icon(Icons.chevron_right, color: Colors.blue, size: 16.r),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            RecordBadges(recordId: record.id, bestIds: bestIds),
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                StatItem(label: '거리', value: '${formatDistance(record.totalDistance, useKmh)} ${distanceUnit(useKmh)}', textColor: textColor),
                                StatItem(label: '시간', value: formatDuration(record.duration), textColor: textColor),
                                StatItem(label: '최고속도', value: '${formatSpeed(record.maxSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor),
                                StatItem(label: '평균속도', value: '${formatSpeed(record.avgSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor),
                              ],
                            ),
                            if (weightKg != null ||
                                (record.memo != null && record.memo!.isNotEmpty)) ...[
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  if (weightKg != null)
                                    Text(
                                      '🔥 ${formatNumber(calcCalories(record.totalDistance, weightKg)!)} kcal',
                                      style: TextStyle(
                                          color: Colors.orange, fontSize: 12.sp),
                                    ),
                                  if (weightKg != null &&
                                      record.memo != null &&
                                      record.memo!.isNotEmpty)
                                    SizedBox(width: 12.w),
                                  if (record.memo != null && record.memo!.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        '📝 ${record.memo}',
                                        style: TextStyle(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 12.sp),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
      ],
      ),
    );
  }

}
