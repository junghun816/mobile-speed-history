import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../db/database_helper.dart';
import '../../models/bike_record.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets_number_input.dart';
import 'settings_user_bike.dart';
import 'settings_widgets.dart';

class SettingsUserScreen extends StatefulWidget {
  const SettingsUserScreen({super.key});

  @override
  State<SettingsUserScreen> createState() => _SettingsUserScreenState();
}

class _SettingsUserScreenState extends State<SettingsUserScreen> {
  List<BikeRecord> _bikes = [];

  @override
  void initState() {
    super.initState();
    _loadBikes();
  }

  Future<void> _loadBikes() async {
    final bikes = await DatabaseHelper.instance.getAllBikes();
    if (mounted) setState(() => _bikes = bikes);
  }

  Future<void> _goToEditBike({BikeRecord? bike}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BikeEditScreen(bike: bike)),
    );
    _loadBikes();
  }

  Future<void> _showNameDialog(SettingsProvider settings) async {
    SystemSound.play(SystemSoundType.click);
    final ctrl = TextEditingController(text: settings.userName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(hintText: '이름 입력'),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    if (result != null) settings.setUserName(result);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('사용자')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            // 기본 정보 (이름 + 체중)
            Container(
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showNameDialog(settings),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      child: Row(
                        children: [
                          settingsIconBox(Icons.person_outline),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('이름',
                                    style: TextStyle(
                                        color: titleColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 2.h),
                                Text('앱 내 표시 이름',
                                    style: TextStyle(
                                        color: subtitleColor, fontSize: 12.sp)),
                              ],
                            ),
                          ),
                          Text(
                            settings.userName.isNotEmpty ? settings.userName : '--',
                            style: TextStyle(
                              color: settings.userName.isNotEmpty
                                  ? Colors.blueGrey
                                  : subtitleColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.chevron_right, color: subtitleColor, size: 18.r),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant, indent: 16.w),
                  GestureDetector(
                    onTap: () async {
                      SystemSound.play(SystemSoundType.click);
                      final result = await NumberInputDialog.show(
                        context,
                        title: '체중 입력',
                        initialValue: settings.weightKg,
                        unit: 'kg',
                        maxDigits: 3,
                        allowEmpty: true,
                        allowDecimal: true,
                        rangeHint: '1 ~ 999 kg',
                      );
                      if (result == null) return;
                      if (result == NumberInputDialog.clearValue) {
                        settings.setWeightKg(null);
                      } else {
                        settings.setWeightKg(result.toDouble());
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      child: Row(
                        children: [
                          settingsIconBox(Icons.monitor_weight_outlined),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('체중',
                                    style: TextStyle(
                                        color: titleColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold)),
                                SizedBox(height: 2.h),
                                Text('칼로리 추정에 사용됩니다',
                                    style: TextStyle(
                                        color: subtitleColor, fontSize: 12.sp)),
                              ],
                            ),
                          ),
                          Text(
                            settings.weightKg != null
                                ? '${settings.weightKg!.toStringAsFixed(2)} kg'
                                : '--',
                            style: TextStyle(
                              color: settings.weightKg != null
                                  ? Colors.blueGrey
                                  : subtitleColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(Icons.chevron_right, color: subtitleColor, size: 18.r),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 내 자전거 섹션 헤더
            Padding(
              padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '내 자전거',
                    style: TextStyle(
                      color: cs.outline,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      _goToEditBike();
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add, color: Colors.blueGrey, size: 16.r),
                        SizedBox(width: 2.w),
                        Text(
                          '추가',
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 자전거 목록
            if (_bikes.isEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    '추가된 자전거가 없습니다',
                    style: TextStyle(color: subtitleColor, fontSize: 13.sp),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < _bikes.length; i++) ...[
                    if (i > 0) SizedBox(height: 8.h),
                    _buildBikeCard(_bikes[i], cs, titleColor, subtitleColor, panelColor),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBikeCard(
    BikeRecord bike,
    ColorScheme cs,
    Color titleColor,
    Color subtitleColor,
    Color panelColor,
  ) {
    final hasPhoto = bike.photoPath != null && File(bike.photoPath!).existsSync();
    final fromDate = bike.fromDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(bike.fromDateMs!)
        : null;
    final toDate = bike.toDateMs != null
        ? DateTime.fromMillisecondsSinceEpoch(bike.toDateMs!)
        : null;

    final fmt = DateFormat('yyyy.MM');
    String dateStr = '';
    if (fromDate != null && toDate != null) {
      dateStr = '${fmt.format(fromDate)} ~ ${fmt.format(toDate)}';
    } else if (fromDate != null) {
      dateStr = '${fmt.format(fromDate)} ~';
    } else if (toDate != null) {
      dateStr = '~ ${fmt.format(toDate)}';
    }

    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        _goToEditBike(bike: bike);
      },
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: hasPhoto
                  ? Image.file(
                      File(bike.photoPath!),
                      width: 56.r,
                      height: 56.r,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56.r,
                      height: 56.r,
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.directions_bike_outlined,
                        color: subtitleColor,
                        size: 28.r,
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bike.manufacturer,
                      style: TextStyle(color: subtitleColor, fontSize: 11.sp)),
                  SizedBox(height: 2.h),
                  Text(bike.model,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold)),
                  if (dateStr.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(dateStr,
                        style: TextStyle(color: subtitleColor, fontSize: 11.sp)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor, size: 18.r),
          ],
        ),
      ),
    );
  }
}
