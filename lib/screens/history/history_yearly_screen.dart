import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets_bar_chart.dart';
import '../../utils/utils_format.dart';
import '../../widgets/widgets_stat_item.dart';

class HistoryYearlyScreen extends StatefulWidget {
  const HistoryYearlyScreen({super.key});

  @override
  State<HistoryYearlyScreen> createState() => _HistoryYearlyScreenState();
}

class _HistoryYearlyScreenState extends State<HistoryYearlyScreen>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = -1;
  bool _showMonthlyBreakdown = true;

  Map<int, Map<String, double>> _getMonthlyStats(
      List<RideRecord> records) {
    final Map<int, List<RideRecord>> monthGroups = {};
    for (final r in records) {
      monthGroups.putIfAbsent(r.month, () => []).add(r);
    }

    final Map<int, Map<String, double>> result = {};
    for (int m = 1; m <= 12; m++) {
      final list = monthGroups[m] ?? [];
      result[m] = {
        'distance': list.fold(0.0, (s, r) => s + r.totalDistance),
        'duration': list.fold(0.0, (s, r) => s + r.duration),
        'maxSpeed': list.isEmpty ? 0.0
            : list.map((r) => r.maxSpeed)
            .reduce((a, b) => a > b ? a : b),
        'avgSpeed': list.isEmpty ? 0.0
            : list.fold(0.0, (s, r) => s + r.avgSpeed) /
            list.length,
        'count': list.length.toDouble(),
      };
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final records = context.watch<RideProvider>().filteredRecords;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final cs = Theme.of(context).colorScheme;

    final cardColor = cs.surfaceContainer;
    final panelColor = cs.surfaceContainerHighest;
    final textColor = cs.onSurface;
    final dividerColor = cs.outlineVariant;
    final borderColor = cs.outlineVariant;

    final Map<int, List<RideRecord>> grouped = {};
    for (final r in records) {
      grouped.putIfAbsent(r.year, () => []).add(r);
    }
    final years = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    final labels = years.map((y) => '$y년').toList();
    final distanceData = years.map((y) =>
        grouped[y]!.fold(0.0, (s, r) => s + r.totalDistance)).toList();
    final durationData = years.map((y) =>
        grouped[y]!.fold(0.0, (s, r) => s + r.duration)).toList();
    final maxSpeedData = years.map((y) =>
        grouped[y]!.map((r) => r.maxSpeed)
            .reduce((a, b) => a > b ? a : b)).toList();
    final avgSpeedData = years.map((y) {
      final list = grouped[y]!;
      return list.fold(0.0, (s, r) => s + r.avgSpeed) / list.length;
    }).toList();

    List<RideRecord> selectedRecords = [];
    int selectedYear = 0;
    if (_selectedIndex >= 0 && _selectedIndex < years.length) {
      selectedRecords = grouped[years[_selectedIndex]] ?? [];
      selectedYear = years[_selectedIndex];
    }

    final totalDistance = selectedRecords.fold(
        0.0, (s, r) => s + r.totalDistance);
    final totalDuration = selectedRecords.fold(
        0, (s, r) => s + r.duration);
    final maxSpeed = selectedRecords.isEmpty ? 0.0
        : selectedRecords.map((r) => r.maxSpeed)
        .reduce((a, b) => a > b ? a : b);
    final avgSpeed = selectedRecords.isEmpty ? 0.0
        : selectedRecords.fold(0.0, (s, r) => s + r.avgSpeed) /
        selectedRecords.length;

    final monthlyStats = selectedYear > 0
        ? _getMonthlyStats(selectedRecords)
        : <int, Map<String, double>>{};

    final monthLabels = ['1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월'];

    return Column(
      children: [
        SizedBox(
          height: 300.h,
          child: BarChartWidget(
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
                  _showMonthlyBreakdown = true;
                }
              });
            },
          ),
        ),

        Container(height: 1, color: dividerColor),

        if (_selectedIndex < 0)
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Text(
              '막대를 탭하면 상세 정보를 볼 수 있어요',
              style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ),

        if (_selectedIndex >= 0)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedYear년',
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
                            StatItem(label: '평균속도', value: '${formatSpeed(avgSpeed, useKmh)} ${speedUnit(useKmh)}', textColor: textColor, labelBlue: true),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '총 ${formatNumber(selectedRecords.length)}회 주행',
                          style: TextStyle(
                              color: Colors.blue, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  Container(
                    color: panelColor,
                    padding: EdgeInsets.all(12.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            SystemSound.play(SystemSoundType.click);
                            setState(() => _showMonthlyBreakdown = !_showMonthlyBreakdown);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '월별 통계',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                _showMonthlyBreakdown
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.orange,
                                size: 20.r,
                              ),
                            ],
                          ),
                        ),
                        if (_showMonthlyBreakdown) ...[
                          SizedBox(height: 12.h),
                          ...List.generate(12, (i) {
                            final month = i + 1;
                            final stat = monthlyStats[month]!;
                            final count = stat['count']!.toInt();
                            if (count == 0) return const SizedBox();
                            final distance = stat['distance']!;
                            final duration = stat['duration']!.toInt();
                            final maxSpd = stat['maxSpeed']!;
                            final avgSpd = stat['avgSpeed']!;

                            return Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        monthLabels[i],
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '$count회 주행',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      StatItem(label: '거리', value: '${formatDistance(distance, useKmh)} ${distanceUnit(useKmh)}', textColor: textColor),
                                      StatItem(label: '시간', value: formatDuration(duration), textColor: textColor),
                                      StatItem(label: '최고속도', value: '${formatSpeed(maxSpd, useKmh)} ${speedUnit(useKmh)}', textColor: textColor),
                                      StatItem(label: '평균속도', value: '${formatSpeed(avgSpd, useKmh)} ${speedUnit(useKmh)}', textColor: textColor),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

}
