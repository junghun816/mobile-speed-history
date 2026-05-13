import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'settings_widgets.dart';

class SettingsDisplayScreen extends StatelessWidget {
  const SettingsDisplayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final btnBgOff = cs.surfaceContainerHighest;
    final btnBorderOff = cs.outlineVariant;
    final btnTextOff = cs.onSurfaceVariant;

    final displayItems = [
      ('거리', settings.showDistance, settings.setShowDistance),
      ('시간', settings.showDuration, settings.setShowDuration),
      ('최고속도', settings.showMaxSpeed, settings.setShowMaxSpeed),
      ('평균속도', settings.showAvgSpeed, settings.setShowAvgSpeed),
    ];

    const clockOptions = [
      ('none', '표시 안 함'),
      ('h24', '24시간'),
      ('h12', '12시간'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('화면')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            settingsPanelContainer(
              panelColor: panelColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      settingsIconBox(Icons.dashboard_outlined),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('주행 중 표시 항목',
                                style: TextStyle(color: titleColor, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2.h),
                            Text('속도계 하단에 표시할 통계 선택',
                                style: TextStyle(color: subtitleColor, fontSize: 12.sp)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: displayItems.asMap().entries.map((e) {
                      final i = e.key;
                      final (label, isOn, setter) = e.value;
                      return Expanded(
                        child: settingsOptionButton(
                          label, isOn, () => setter(!isOn),
                          btnBgOff: btnBgOff,
                          btnBorderOff: btnBorderOff,
                          btnTextOff: btnTextOff,
                          margin: EdgeInsets.only(right: i < displayItems.length - 1 ? 6.w : 0),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            settingsPanelContainer(
              panelColor: panelColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      settingsIconBox(Icons.access_time),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('속도계 시계',
                                style: TextStyle(color: titleColor, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2.h),
                            Text('속도계 화면 상단에 현재 시각 표시',
                                style: TextStyle(color: subtitleColor, fontSize: 12.sp)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: clockOptions.asMap().entries.map((e) {
                      final (val, label) = e.value;
                      final isLast = e.key == clockOptions.length - 1;
                      return Expanded(
                        child: settingsOptionButton(
                          label, settings.clockDisplay == val,
                          () => settings.setClockDisplay(val),
                          btnBgOff: btnBgOff,
                          btnBorderOff: btnBorderOff,
                          btnTextOff: btnTextOff,
                          margin: EdgeInsets.only(right: isLast ? 0 : 6.w),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
