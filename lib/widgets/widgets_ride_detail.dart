import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../models/ride_record.dart';
import '../providers/ride_provider.dart';
import '../screens/history/history_detail_map_screen.dart';
import '../utils/utils_format.dart';
import '../utils/utils_gpx.dart';
import 'widgets_memo_sheet.dart';
import 'widgets_stat_item.dart';

Widget _buildLapTable(
    List<Map<String, dynamic>> laps, Color textColor, ColorScheme cs) {
  return Container(
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            children: [
              SizedBox(width: 32.w, child: Text('랩', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp, fontWeight: FontWeight.bold))),
              Expanded(child: Text('페이스', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp, fontWeight: FontWeight.bold))),
              Expanded(child: Text('시간', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp, fontWeight: FontWeight.bold))),
              Expanded(child: Text('최고속도', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.sp, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Divider(color: cs.outlineVariant, height: 1),
        ...laps.asMap().entries.map((entry) {
          final i = entry.key;
          final lap = entry.value;
          final paceSecPerKm = (lap['paceSecPerKm'] as num).toInt();
          final timeSec = (lap['timeMs'] as num).toInt() ~/ 1000;
          final maxSpeed = (lap['maxSpeedKmh'] as num).toDouble();
          return Container(
            decoration: BoxDecoration(
              color: i.isOdd ? cs.surfaceContainerHighest : cs.surfaceContainer,
              borderRadius: i == laps.length - 1
                  ? BorderRadius.vertical(bottom: Radius.circular(12.r))
                  : null,
            ),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: [
                SizedBox(
                  width: 32.w,
                  child: Text('${lap['lap']}', style: TextStyle(color: textColor, fontSize: 13.sp, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Text(formatPace(paceSecPerKm), textAlign: TextAlign.center, style: TextStyle(color: Colors.lightBlue, fontSize: 13.sp, fontWeight: FontWeight.bold))),
                Expanded(child: Text(formatDuration(timeSec), textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 13.sp))),
                Expanded(child: Text('${maxSpeed.toStringAsFixed(1)} km/h', textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 13.sp))),
              ],
            ),
          );
        }),
      ],
    ),
  );
}

void showRecordDetailDialog(
    BuildContext context, RideRecord record, bool useKmh, double? weightKg) {
  final cs = Theme.of(context).colorScheme;
  final ride = context.read<RideProvider>();
  final int? calories = calcCalories(record.totalDistance, weightKg);
  final ctrl = TextEditingController(text: record.memo ?? '');
  final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
  final timeStr = '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  final dialogBg = cs.surfaceContainer;
  final memoBoxColor = cs.surfaceContainerHighest;
  final btnBg = cs.surfaceContainerHighest;
  final textColor = cs.onSurface;
  bool isSharing = false;
  final isRunning = record.activityType == 'run';
  final List<Map<String, dynamic>> lapData = record.lapSplits != null
      ? List<Map<String, dynamic>>.from(jsonDecode(record.lapSplits!))
      : [];

  showDialog(
    context: context,
    builder: (ctx) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(viewInsets: EdgeInsets.zero),
      child: StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: dialogBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${record.year}년 ${record.month}월 ${record.day}일',
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('$timeStr 출발',
                            style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        SystemSound.play(SystemSoundType.click);
                        Navigator.pop(ctx);
                      },
                      child: Icon(Icons.close, color: Colors.grey, size: 22.r),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatDetailItem(label: '거리', value: formatDistance(record.totalDistance, useKmh), unit: distanceUnit(useKmh), textColor: textColor),
                          StatDetailItem(label: '시간', value: formatDuration(record.duration), textColor: textColor),
                          StatDetailItem(label: '최고속도', value: formatSpeed(record.maxSpeed, useKmh), unit: speedUnit(useKmh), textColor: textColor),
                          StatDetailItem(label: '평균속도', value: formatSpeed(record.avgSpeed, useKmh), unit: speedUnit(useKmh), textColor: textColor),
                        ],
                      ),
                      if (calories != null) ...[
                        SizedBox(height: 10.h),
                        Divider(color: Colors.blue.withOpacity(0.3), height: 1),
                        SizedBox(height: 10.h),
                        StatDetailItem(label: '칼로리', value: formatNumber(calories), unit: 'kcal', textColor: textColor),
                      ],
                    ],
                  ),
                ),
                if (isRunning && lapData.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  _buildLapTable(lapData, textColor, cs),
                ],
                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: () async {
                    await showMemoBottomSheet(ctx, controller: ctrl);
                    if (ctx.mounted) {
                      if (record.id != null) {
                        await ride.updateMemo(record.id!, ctrl.text.trim());
                      }
                      setDialogState(() {});
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(minHeight: 60.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: memoBoxColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: ctrl.text.isEmpty
                        ? Text('메모를 남겨보세요 (탭하여 입력)',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13.sp))
                        : Text(ctrl.text,
                            style: TextStyle(color: textColor, fontSize: 13.sp)),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnBg,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HistoryDetailMapScreen(record: record)),
                          );
                        },
                        icon: Icon(Icons.map_outlined, color: textColor, size: 18.r),
                        label: Text('경로 보기',
                            style: TextStyle(
                                color: textColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnBg,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        onPressed: isSharing ? null : () async {
                          setDialogState(() => isSharing = true);
                          try {
                            await shareGpx(record);
                          } finally {
                            if (ctx.mounted) setDialogState(() => isSharing = false);
                          }
                        },
                        icon: isSharing
                            ? SizedBox(
                                width: 18.r,
                                height: 18.r,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: textColor))
                            : Icon(Icons.route,
                                color: Colors.deepPurple, size: 18.r),
                        label: Text('GPX 공유',
                            style: TextStyle(
                                color: isSharing ? Colors.grey : textColor,
                                fontSize: 14.sp,
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
