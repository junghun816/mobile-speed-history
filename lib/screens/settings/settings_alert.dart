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
      appBar: AppBar(title: const Text('자전거')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _alertTile(
              context: context,
              iconColor: Colors.red,
              icon: Icons.arrow_upward,
              title: '최고 속도',
              subtitle: '설정 속도 초과 시 알림',
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
                    title: '최고 속도 기준', initialValue: settings.speedAlertKmh,
                    unit: 'km/h', maxDigits: 3, allowEmpty: false, allowDecimal: false);
                if (result != null) settings.setSpeedAlertKmh(result.toDouble());
              },
              popupValue: settings.speedMaxAlertPopup,
              onPopupChanged: (v) => settings.setSpeedMaxAlertPopup(v),
              vibrationValue: settings.speedMaxAlertVibration,
              onVibrationChanged: (v) => settings.setSpeedMaxAlertVibration(v),
              soundValue: settings.speedMaxAlertSound,
              onSoundChanged: (v) => settings.setSpeedMaxAlertSound(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              inactiveTrackColor: inactiveTrackColor,
              dividerColor: cs.outlineVariant,
            ),
            SizedBox(height: 10.h),
            _alertTile(
              context: context,
              iconColor: Colors.lightBlue,
              icon: Icons.arrow_downward,
              title: '최저 속도',
              subtitle: '설정 속도 미만 시 알림',
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
                    title: '최저 속도 기준', initialValue: settings.speedMinAlertKmh,
                    unit: 'km/h', maxDigits: 3, allowEmpty: false, allowDecimal: false);
                if (result != null) settings.setSpeedMinAlertKmh(result.toDouble());
              },
              popupValue: settings.speedMinAlertPopup,
              onPopupChanged: (v) => settings.setSpeedMinAlertPopup(v),
              vibrationValue: settings.speedMinAlertVibration,
              onVibrationChanged: (v) => settings.setSpeedMinAlertVibration(v),
              soundValue: settings.speedMinAlertSound,
              onSoundChanged: (v) => settings.setSpeedMinAlertSound(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              inactiveTrackColor: inactiveTrackColor,
              dividerColor: cs.outlineVariant,
            ),
            SizedBox(height: 10.h),
            _alertTile(
              context: context,
              iconColor: Colors.green,
              icon: Icons.social_distance_outlined,
              title: '거리 알림',
              subtitle: '설정 km 도달마다 알림',
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
              popupValue: settings.distanceAlertPopup,
              onPopupChanged: (v) => settings.setDistanceAlertPopup(v),
              vibrationValue: settings.distanceAlertVibration,
              onVibrationChanged: (v) => settings.setDistanceAlertVibration(v),
              soundValue: settings.distanceAlertSound,
              onSoundChanged: (v) => settings.setDistanceAlertSound(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              inactiveTrackColor: inactiveTrackColor,
              dividerColor: cs.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertTile({
    required BuildContext context,
    required Color iconColor,
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
    bool? popupValue,
    void Function(bool)? onPopupChanged,
    bool? vibrationValue,
    void Function(bool)? onVibrationChanged,
    bool? soundValue,
    void Function(bool)? onSoundChanged,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color btnBgOff,
    required Color inactiveTrackColor,
    required Color dividerColor,
  }) {
    return settingsPanelContainer(
      panelColor: panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              settingsIconBox(icon, color: iconColor),
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
            if (popupValue != null &&
                vibrationValue != null &&
                soundValue != null &&
                onPopupChanged != null &&
                onVibrationChanged != null &&
                onSoundChanged != null) ...[
              SizedBox(height: 12.h),
              Divider(height: 1, thickness: 0.5, color: dividerColor),
              _methodRow(Icons.notifications_outlined, Colors.indigo[300]!, '팝업',
                  popupValue, onPopupChanged, inactiveTrackColor),
              Divider(height: 1, thickness: 0.5, color: dividerColor),
              _methodRow(Icons.vibration, Colors.indigo[300]!, '진동',
                  vibrationValue, onVibrationChanged, inactiveTrackColor),
              Divider(height: 1, thickness: 0.5, color: dividerColor),
              _methodRow(Icons.volume_up_outlined, Colors.indigo[300]!, '소리',
                  soundValue, onSoundChanged, inactiveTrackColor),
            ],
          ],
        ],
      ),
    );
  }

  Widget _methodRow(
    IconData icon,
    Color iconColor,
    String title,
    bool value,
    void Function(bool) onChanged,
    Color inactiveTrackColor,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          settingsIconBox(icon, color: iconColor),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                )),
          ),
          Switch(
            value: value,
            onChanged: (v) {
              SystemSound.play(SystemSoundType.click);
              onChanged(v);
            },
            activeThumbColor: iconColor,
            activeTrackColor: iconColor.withOpacity(0.35),
            inactiveTrackColor: inactiveTrackColor,
          ),
        ],
      ),
    );
  }
}
