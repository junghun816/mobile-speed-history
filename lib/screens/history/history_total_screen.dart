import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/ride_record.dart';
import '../../providers/ride_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/record_badges.dart';
import '../../utils/format_utils.dart';
import '../../widgets/stat_item.dart';
import '../../widgets/record_detail_dialog.dart';

enum SortType {
  dateDesc,
  dateAsc,
  distanceDesc,
  distanceAsc,
  speedDesc,
  speedAsc,
}

class HistoryTotalScreen extends StatefulWidget {
  const HistoryTotalScreen({super.key});

  @override
  State<HistoryTotalScreen> createState() => _HistoryTotalScreenState();
}

class _HistoryTotalScreenState extends State<HistoryTotalScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int? _filterYear = DateTime.now().year;
  int? _filterMonth;
  int? _filterDay;

  final Set<int> _pendingDeleteIds = {};
  SortType _sortType = SortType.dateDesc;

  String get _sortLabel {
    switch (_sortType) {
      case SortType.dateDesc: return '날짜 최신순';
      case SortType.dateAsc: return '날짜 오래된순';
      case SortType.distanceDesc: return '거리 긴순';
      case SortType.distanceAsc: return '거리 짧은순';
      case SortType.speedDesc: return '속도 빠른순';
      case SortType.speedAsc: return '속도 느린순';
    }
  }

  List<RideRecord> _sortedRecords(List<RideRecord> records) {
    final sorted = List<RideRecord>.from(records);
    switch (_sortType) {
      case SortType.dateDesc: sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt)); break;
      case SortType.dateAsc: sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt)); break;
      case SortType.distanceDesc: sorted.sort((a, b) => b.totalDistance.compareTo(a.totalDistance)); break;
      case SortType.distanceAsc: sorted.sort((a, b) => a.totalDistance.compareTo(b.totalDistance)); break;
      case SortType.speedDesc: sorted.sort((a, b) => b.maxSpeed.compareTo(a.maxSpeed)); break;
      case SortType.speedAsc: sorted.sort((a, b) => a.maxSpeed.compareTo(b.maxSpeed)); break;
    }
    return sorted;
  }

  void _showSortOptions() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  '정렬 기준',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...SortType.values.map((type) {
                final isSelected = _sortType == type;
                String label;
                switch (type) {
                  case SortType.dateDesc: label = '날짜 최신순'; break;
                  case SortType.dateAsc: label = '날짜 오래된순'; break;
                  case SortType.distanceDesc: label = '거리 긴순'; break;
                  case SortType.distanceAsc: label = '거리 짧은순'; break;
                  case SortType.speedDesc: label = '속도 빠른순'; break;
                  case SortType.speedAsc: label = '속도 느린순'; break;
                }

                return ListTile(
                  onTap: () {
                    setState(() => _sortType = type);
                    Navigator.pop(ctx);
                  },
                  leading: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.grey,
                    size: 20.r,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.blue : cs.onSurface,
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<RideRecord> _filteredRecords(List<RideRecord> records) {
    return records.where((r) {
      if (_filterYear != null && r.year != _filterYear) return false;
      if (_filterMonth != null && r.month != _filterMonth) return false;
      if (_filterDay != null && r.day != _filterDay) return false;
      return true;
    }).toList();
  }

  void _confirmDelete(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dialogBg = cs.surfaceContainer;
    final textColor = cs.onSurface;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        title: Text('정말 삭제할까요?', style: TextStyle(color: textColor)),
        content: Text(
          '${_pendingDeleteIds.length}개의 기록을 삭제합니다.\n되돌릴 수 없어요.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in _pendingDeleteIds) {
                await context.read<RideProvider>().deleteRecord(id);
              }
              setState(() => _pendingDeleteIds.clear());
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _filterBox({
    required String label,
    required int? value,
    required List<int> items,
    required void Function(int?)? onChanged,
    required Color cardColor,
    required Color dropdownBg,
    required Color textColor,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        decoration: BoxDecoration(
          color: value != null ? Colors.blue.withOpacity(0.15) : cardColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: value != null
                ? Colors.blue.withOpacity(0.5)
                : borderColor,
          ),
        ),
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: dropdownBg,
          menuMaxHeight: 200,
          hint: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
          ),
          style: TextStyle(color: textColor, fontSize: 13.sp),
          items: [
            DropdownMenuItem<int?>(
              value: null,
              child: Text(
                '$label 전체',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<int?>(value: item, child: Text('$item')),
            ),
          ],
          onChanged: onChanged,
        ),
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

    final cardColor = cs.surfaceContainer;
    final panelColor = cs.surfaceContainer;
    final dropdownBg = cs.surfaceContainerHighest;
    final deleteBg = cs.surface;
    final textColor = cs.onSurface;
    final subTextColor = cs.onSurfaceVariant;
    final borderColor = cs.outlineVariant;
    final resetBtnColor = cs.surfaceContainerHighest;
    final sortBtnColor = cs.surfaceContainerHighest;

    final filtered = _sortedRecords(_filteredRecords(records));
    final years = records.map((r) => r.year).toSet().toList()..sort();
    final months = List.generate(12, (i) => i + 1);
    final days = List.generate(31, (i) => i + 1);

    return Stack(
      children: [
        Column(
          children: [
            // 필터 영역
            Container(
              color: panelColor,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  _filterBox(
                    label: '년',
                    value: years.contains(_filterYear) ? _filterYear : null,
                    items: years,
                    onChanged: (v) => setState(() {
                      _filterYear = v;
                      if (v == null) {
                        _filterMonth = null;
                        _filterDay = null;
                      }
                    }),
                    cardColor: cardColor,
                    dropdownBg: dropdownBg,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  SizedBox(width: 6.w),
                  _filterBox(
                    label: '월',
                    value: _filterMonth,
                    items: months,
                    onChanged: _filterYear == null
                        ? null
                        : (v) => setState(() {
                            _filterMonth = v;
                            if (v == null) _filterDay = null;
                          }),
                    cardColor: cardColor,
                    dropdownBg: dropdownBg,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  SizedBox(width: 6.w),
                  _filterBox(
                    label: '일',
                    value: _filterDay,
                    items: days,
                    onChanged: _filterMonth == null
                        ? null
                        : (v) => setState(() => _filterDay = v),
                    cardColor: cardColor,
                    dropdownBg: dropdownBg,
                    textColor: textColor,
                    borderColor: borderColor,
                  ),
                  SizedBox(width: 6.w),
                  GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      setState(() {
                        _filterYear = null;
                        _filterMonth = null;
                        _filterDay = null;
                      });
                    },
                    child: Container(
                      width: 44.r,
                      height: 44.r,
                      decoration: BoxDecoration(
                        color: _filterYear != null ||
                                _filterMonth != null ||
                                _filterDay != null
                            ? Colors.blue.withOpacity(0.3)
                            : resetBtnColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.refresh,
                        color: _filterYear != null ||
                                _filterMonth != null ||
                                _filterDay != null
                            ? Colors.blue
                            : Colors.grey,
                        size: 20.r,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 총 개수 + 정렬
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 ${formatNumber(filtered.length)}개',
                    style: TextStyle(color: subTextColor, fontSize: 13.sp),
                  ),
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: sortBtnColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sort, color: textColor, size: 16.r),
                          SizedBox(width: 4.w),
                          Text(
                            _sortLabel,
                            style: TextStyle(color: textColor, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 목록
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        '해당 조건의 기록이 없어요',
                        style: TextStyle(color: subTextColor, fontSize: 16.sp),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                        16.w,
                        0,
                        16.w,
                        _pendingDeleteIds.isEmpty ? 16.h : 80.h,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final record = filtered[index];
                        final bestIds = context.read<RideProvider>().bestRecordIds;
                        final isPending =
                            record.id != null &&
                            _pendingDeleteIds.contains(record.id);
                        final time = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
                        final timeStr =
                            '${time.hour.toString().padLeft(2, '0')}:'
                            '${time.minute.toString().padLeft(2, '0')}';

                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: isPending
                                  ? null
                                  : () {
                                      SystemSound.play(SystemSoundType.click);
                                      showRecordDetailDialog(context, record, useKmh, weightKg);
                                    },
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: isPending ? 0.35 : 1.0,
                                child: Container(
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 40.w, 16.h),
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? Colors.red.withOpacity(0.1)
                                        : cardColor,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: isPending
                                          ? Colors.red.withOpacity(0.5)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${record.year}년 ${record.month}월 ${record.day}일  $timeStr 출발',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      RecordBadges(
                                          recordId: record.id, bestIds: bestIds),
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
                                      if (weightKg != null) ...[
                                        SizedBox(height: 8.h),
                                        Text(
                                          '🔥 ${formatNumber(calcCalories(record.totalDistance, weightKg)!)} kcal',
                                          style: TextStyle(
                                              color: Colors.orange, fontSize: 12.sp),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  if (record.id == null) return;
                                  SystemSound.play(SystemSoundType.click);
                                  setState(() {
                                    if (isPending) {
                                      _pendingDeleteIds.remove(record.id);
                                    } else {
                                      _pendingDeleteIds.add(record.id!);
                                    }
                                  });
                                },
                                child: Container(
                                  width: 24.r,
                                  height: 24.r,
                                  decoration: BoxDecoration(
                                    color: isPending
                                        ? Colors.blue
                                        : Colors.red.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPending ? Icons.add : Icons.remove,
                                    color: Colors.white,
                                    size: 16.r,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),

        // 삭제/취소 버튼 (하단 고정)
        if (_pendingDeleteIds.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: deleteBg,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          SystemSound.play(SystemSoundType.click);
                          setState(() => _pendingDeleteIds.clear());
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '취소',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          SystemSound.play(SystemSoundType.click);
                          _confirmDelete(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${_pendingDeleteIds.length}개 삭제',
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
            ),
          ),
      ],
    );
  }

}
