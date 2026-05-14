import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/number_input_dialog.dart';
import 'settings_widgets.dart';

class SettingsAlertScreen extends StatelessWidget {
  const SettingsAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final btnBgOff = cs.surfaceContainerHighest;
    final inactiveTrackColor = cs.outlineVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _alertTile(
              context: context,
              icon: Icons.speed_outlined,
              title: '속도 초과 알림',
              subtitle: '설정 속도 초과 시 진동 + 빨간색 표시',
              isOn: settings.speedAlertKmh != null,
              switchActiveColor: Colors.red,
              onSwitchChanged: (v) => settings.setSpeedAlertKmh(
                  v ? (settings.speedAlertKmh?.toInt() ?? 30).toDouble() : null),
              stepperValue: '${settings.speedAlertKmh?.toInt() ?? 30} km/h',
              onDecrement: () => settings.setSpeedAlertKmh(
                  ((settings.speedAlertKmh?.toInt() ?? 30) - 5).clamp(kDebugMode ? 0 : 1, 999).toDouble()),
              onIncrement: () => settings.setSpeedAlertKmh(
                  ((settings.speedAlertKmh?.toInt() ?? 30) + 5).clamp(kDebugMode ? 0 : 1, 999).toDouble()),
              onTapValue: () async {
                SystemSound.play(SystemSoundType.click);
                final result = await NumberInputDialog.show(context,
                    title: '속도 알림 기준', initialValue: settings.speedAlertKmh,
                    unit: 'km/h', maxDigits: 3, allowEmpty: false, allowDecimal: false);
                if (result != null) settings.setSpeedAlertKmh(result.toDouble());
              },
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              inactiveTrackColor: inactiveTrackColor,
            ),
            SizedBox(height: 10.h),
            _alertTile(
              context: context,
              icon: Icons.speed_outlined,
              title: '속도 미달 알림',
              subtitle: '설정 속도 미만 시 진동 + 파란색 표시',
              isOn: settings.speedMinAlertKmh != null,
              switchActiveColor: Colors.lightBlue,
              onSwitchChanged: (v) => settings.setSpeedMinAlertKmh(
                  v ? (settings.speedMinAlertKmh?.toInt() ?? 10).toDouble() : null),
              stepperValue: '${settings.speedMinAlertKmh?.toInt() ?? 10} km/h',
              onDecrement: () => settings.setSpeedMinAlertKmh(
                  ((settings.speedMinAlertKmh?.toInt() ?? 10) - 5).clamp(kDebugMode ? 0 : 1, 999).toDouble()),
              onIncrement: () => settings.setSpeedMinAlertKmh(
                  ((settings.speedMinAlertKmh?.toInt() ?? 10) + 5).clamp(kDebugMode ? 0 : 1, 999).toDouble()),
              onTapValue: () async {
                SystemSound.play(SystemSoundType.click);
                final result = await NumberInputDialog.show(context,
                    title: '속도 미달 알림 기준', initialValue: settings.speedMinAlertKmh,
                    unit: 'km/h', maxDigits: 3, allowEmpty: false, allowDecimal: false);
                if (result != null) settings.setSpeedMinAlertKmh(result.toDouble());
              },
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              inactiveTrackColor: inactiveTrackColor,
            ),
            SizedBox(height: 10.h),
            _alertTile(
              context: context,
              icon: Icons.social_distance_outlined,
              title: '거리 알림',
              subtitle: '설정 km 도달마다 알림 · 진동',
              isOn: settings.distanceAlertKm != null,
              switchActiveColor: Colors.green,
              onSwitchChanged: (v) => settings.setDistanceAlertKm(v ? (settings.distanceAlertKm ?? 5) : null),
              stepperValue: '${settings.distanceAlertKm ?? 5} km',
              onDecrement: () => settings.setDistanceAlertKm(((settings.distanceAlertKm ?? 5) - 1).clamp(1, 999)),
              onIncrement: () => settings.setDistanceAlertKm(((settings.distanceAlertKm ?? 5) + 1).clamp(1, 999)),
              onTapValue: () async {
                SystemSound.play(SystemSoundType.click);
                final result = await NumberInputDialog.show(context,
                    title: '거리 알림 기준', initialValue: settings.distanceAlertKm,
                    unit: 'km', maxDigits: 3, allowEmpty: false, allowDecimal: false);
                if (result != null) settings.setDistanceAlertKm(result.toInt());
              },
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              inactiveTrackColor: inactiveTrackColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isOn,
    required Color switchActiveColor,
    required void Function(bool) onSwitchChanged,
    required String stepperValue,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Future<void> Function() onTapValue,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color btnBgOff,
    required Color inactiveTrackColor,
  }) {
    return settingsPanelContainer(
      panelColor: panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              settingsIconBox(icon),
              SizedBox(width: 14.w),
              Expanded(child: settingsTileLabel(title, subtitle, titleColor, subtitleColor)),
              Switch(
                value: isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  onSwitchChanged(v);
                },
                activeThumbColor: switchActiveColor,
                activeTrackColor: switchActiveColor.withOpacity(0.4),
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
          if (isOn) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onDecrement,
                  child: Container(
                    width: 40.r, height: 40.r,
                    decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8.r)),
                    child: Icon(Icons.remove, color: titleColor, size: 20.r),
                  ),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: onTapValue,
                  child: Container(
                    width: 90.w,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8.r)),
                    child: Text(stepperValue,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: titleColor, fontSize: 15.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: onIncrement,
                  child: Container(
                    width: 40.r, height: 40.r,
                    decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8.r)),
                    child: Icon(Icons.add, color: titleColor, size: 20.r),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
