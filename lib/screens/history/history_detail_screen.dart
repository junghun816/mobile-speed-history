import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../widgets/record_badges.dart';
import '../../utils/format_utils.dart';
import '../../widgets/stat_item.dart';
import '../../widgets/record_detail_dialog.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({super.key});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDateFromCalendar() async {
    final records = context.read<RideProvider>().records;
    final cs = Theme.of(context).colorScheme;
    final sheetBg = cs.surfaceContainer;
    final dialogBg = cs.surfaceContainer;
    final dropdownBg = cs.surfaceContainerHighest;
    final textColor = cs.onSurface;

    final recordedDays = records
        .map((r) => DateTime(r.year, r.month, r.day))
        .toSet();
    final recordYears = records.map((r) => r.year).toSet().toList()..sort();
    if (recordYears.isEmpty) recordYears.add(DateTime.now().year);

    final firstDay = recordedDays.isEmpty
        ? DateTime(DateTime.now().year)
        : recordedDays.reduce((a, b) => a.isBefore(b) ? a : b);

    await showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        DateTime focusedDay = _selectedDate;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void showYearMonthPicker() {
              _showYearMonthPickerDialog(
                ctx: ctx,
                initialYear: focusedDay.year,
                initialMonth: focusedDay.month,
                recordYears: recordYears,
                dialogBg: dialogBg,
                dropdownBg: dropdownBg,
                textColor: textColor,
                onConfirm: (date) => setModalState(() => focusedDay = date),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '날짜 선택',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TableCalendar(
                      locale: 'ko_KR',
                      firstDay: firstDay,
                      lastDay: DateTime.now(),
                      focusedDay: focusedDay,
                      sixWeekMonthsEnforced: true,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, _selectedDate),
                      onDaySelected: (selected, focused) {
                        setState(() => _selectedDate = selected);
                        Navigator.pop(ctx);
                      },
                      onPageChanged: (focused) {
                        setModalState(() => focusedDay = focused);
                      },
                      calendarBuilders: CalendarBuilders(
                        headerTitleBuilder: (context, day) {
                          return GestureDetector(
                            onTap: showYearMonthPicker,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${day.year}년 ${day.month}월',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: textColor,
                                  size: 22.r,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        defaultTextStyle: TextStyle(color: textColor),
                        weekendTextStyle: TextStyle(color: textColor),
                        outsideTextStyle:
                            TextStyle(color: cs.outlineVariant),
                        selectedDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(color: textColor),
                        markerDecoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        markersMaxCount: 1,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                        rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: cs.onSurfaceVariant),
                        weekendStyle: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      eventLoader: (day) {
                        final key = DateTime(day.year, day.month, day.day);
                        return recordedDays.contains(key) ? [true] : [];
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showYearMonthPickerDialog({
    required BuildContext ctx,
    required int initialYear,
    required int initialMonth,
    required List<int> recordYears,
    required Color dialogBg,
    required Color dropdownBg,
    required Color textColor,
    required void Function(DateTime) onConfirm,
  }) {
    int tempYear = initialYear;
    int tempMonth = initialMonth;

    showDialog(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: dialogBg,
          title: Text('연도 / 월 선택',
              style: TextStyle(color: textColor, fontSize: 15.sp)),
          content: Row(
            children: [
              Expanded(
                child: DropdownButton<int>(
                  value: tempYear,
                  isExpanded: true,
                  dropdownColor: dropdownBg,
                  style: TextStyle(color: textColor),
                  underline: const SizedBox(),
                  items: recordYears
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y년')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => tempYear = v);
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: DropdownButton<int>(
                  value: tempMonth,
                  isExpanded: true,
                  dropdownColor: dropdownBg,
                  style: TextStyle(color: textColor),
                  underline: const SizedBox(),
                  items: List.generate(12, (i) => i + 1)
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m월')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => tempMonth = v);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                onConfirm(DateTime(tempYear, tempMonth, 1));
                Navigator.pop(dialogCtx);
              },
              child: const Text('이동', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectPicker() {
    final cs = Theme.of(context).colorScheme;
    final sheetBg = cs.surfaceContainer;
    final textColor = cs.onSurface;
    final dropdownBg = cs.surfaceContainerHighest;
    final boxColor = cs.surfaceContainerHighest;
    final borderColor = cs.outlineVariant;

    int tempYear = _selectedDate.year;
    int tempMonth = _selectedDate.month;
    int tempDay = _selectedDate.day;

    final records = context.read<RideProvider>().records;
    final years = records.map((r) => r.year).toSet().toList()..sort();
    if (years.isEmpty) years.add(DateTime.now().year);
    final months = List.generate(12, (i) => i + 1);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final daysInMonth = DateUtils.getDaysInMonth(tempYear, tempMonth);
            final days = List.generate(daysInMonth, (i) => i + 1);
            if (tempDay > daysInMonth) tempDay = daysInMonth;

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '날짜 선택',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: _selectBox(
                            value: tempYear,
                            items: years,
                            onChanged: (v) => setModalState(() => tempYear = v!),
                            format: (v) => '$v년',
                            boxColor: boxColor,
                            borderColor: borderColor,
                            dropdownBg: dropdownBg,
                            textColor: textColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _selectBox(
                            value: tempMonth,
                            items: months,
                            onChanged: (v) => setModalState(() => tempMonth = v!),
                            format: (v) => '$v월',
                            boxColor: boxColor,
                            borderColor: borderColor,
                            dropdownBg: dropdownBg,
                            textColor: textColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _selectBox(
                            value: tempDay,
                            items: days,
                            onChanged: (v) => setModalState(() => tempDay = v!),
                            format: (v) => '$v일',
                            boxColor: boxColor,
                            borderColor: borderColor,
                            dropdownBg: dropdownBg,
                            textColor: textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(tempYear, tempMonth, tempDay);
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '확인',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _selectBox<T>({
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) format,
    required Color boxColor,
    required Color borderColor,
    required Color dropdownBg,
    required Color textColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: dropdownBg,
        menuMaxHeight: 200,
        style: TextStyle(color: textColor, fontSize: 14.sp),
        items: items.map((item) => DropdownMenuItem<T>(
          value: item,
          child: Text(format(item)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final records = context.watch<RideProvider>().records;
    final settings = context.watch<SettingsProvider>();
    final useKmh = settings.useKmh;
    final weightKg = settings.weightKg;
    final cs = Theme.of(context).colorScheme;

    final bgColor = cs.surface;
    final cardColor = cs.surfaceContainer;
    final navBtnColor = cs.surfaceContainerHighest;
    final navBtnDisabledColor = cs.surfaceContainer;
    final textColor = cs.onSurface;
    final subTextColor = cs.onSurfaceVariant;

    final dayRecords = records.where((r) =>
    r.year == _selectedDate.year &&
        r.month == _selectedDate.month &&
        r.day == _selectedDate.day,
    ).toList();

    final totalDistance = dayRecords.fold(0.0, (s, r) => s + r.totalDistance);
    final totalDuration = dayRecords.fold(0, (s, r) => s + r.duration);
    final maxSpeed = dayRecords.isEmpty
        ? 0.0
        : dayRecords.map((r) => r.maxSpeed).reduce((a, b) => a > b ? a : b);
    final avgSpeed = dayRecords.isEmpty
        ? 0.0
        : dayRecords.fold(0.0, (s, r) => s + r.avgSpeed) / dayRecords.length;

    final isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            // 날짜 선택 영역
            Container(
              color: cardColor,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      setState(() {
                        _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                      });
                    },
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: navBtnColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.chevron_left, color: textColor, size: 20.r),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  Expanded(
                    child: Text(
                      '${_selectedDate.year}년 '
                          '${_selectedDate.month}월 '
                          '${_selectedDate.day}일',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  GestureDetector(
                    onTap: isToday
                        ? null
                        : () {
                      SystemSound.play(SystemSoundType.click);
                      setState(() {
                        _selectedDate = _selectedDate.add(const Duration(days: 1));
                      });
                    },
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: isToday ? navBtnDisabledColor : navBtnColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: isToday ? subTextColor : textColor,
                        size: 20.r,
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      _showSelectPicker();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: navBtnColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.list, color: textColor, size: 16.r),
                          SizedBox(width: 4.w),
                          Text('선택', style: TextStyle(color: textColor, fontSize: 13.sp)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 8.w),

                  GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      _pickDateFromCalendar();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: navBtnColor,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: textColor, size: 16.r),
                          SizedBox(width: 4.w),
                          Text('달력', style: TextStyle(color: textColor, fontSize: 13.sp)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 하루 합계 요약
            if (dayRecords.isNotEmpty)
              Container(
                margin: EdgeInsets.all(16.r),
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
                    if (weightKg != null) ...[
                      SizedBox(height: 10.h),
                      Divider(color: Colors.blue.withOpacity(0.3), height: 1),
                      SizedBox(height: 10.h),
                      StatItem(label: '총 칼로리', value: '${formatNumber(calcCalories(totalDistance, weightKg)!)} kcal', textColor: textColor, labelBlue: true),
                    ],
                  ],
                ),
              ),

            // 기록 목록
            Expanded(
              child: dayRecords.isEmpty
                  ? Center(
                child: Text(
                  '해당 날짜에 주행기록이 없어요',
                  style: TextStyle(color: subTextColor, fontSize: 16.sp),
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: dayRecords.length,
                itemBuilder: (context, index) {
                  final record = dayRecords[index];
                  final bestIds = context.read<RideProvider>().bestRecordIds;
                  final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
                  final timeStr =
                      '${time.hour.toString().padLeft(2, '0')}:'
                      '${time.minute.toString().padLeft(2, '0')}';

                  return GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      showRecordDetailDialog(context, record, useKmh, weightKg);
                    },
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$timeStr 출발',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          RecordBadges(recordId: record.id, bestIds: bestIds),
                          SizedBox(height: 12.h),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
