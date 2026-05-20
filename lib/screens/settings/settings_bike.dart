import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/widgets_number_input.dart';
import 'settings_widgets.dart';

class SettingsBikeScreen extends StatelessWidget {
  const SettingsBikeScreen({super.key});

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
            _AlertTileWidget(
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
                  ((settings.speedAlertKmh?.toInt() ?? 30) - 1).clamp(kDebugMode ? 0 : 1, 999).toDouble()),
              onIncrement: () => settings.setSpeedAlertKmh(
                  ((settings.speedAlertKmh?.toInt() ?? 30) + 1).clamp(kDebugMode ? 0 : 1, 999).toDouble()),
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
            _AlertTileWidget(
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
                  ((settings.speedMinAlertKmh?.toInt() ?? 10) - 1).clamp(kDebugMode ? 0 : 1, 999).toDouble()),
              onIncrement: () => settings.setSpeedMinAlertKmh(
                  ((settings.speedMinAlertKmh?.toInt() ?? 10) + 1).clamp(kDebugMode ? 0 : 1, 999).toDouble()),
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
            _AlertTileWidget(
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
            SizedBox(height: 10.h),
            _lapIntervalTile(context, settings, panelColor, titleColor, subtitleColor, cs),
          ],
        ),
      ),
    );
  }

  Widget _lapIntervalTile(BuildContext context, SettingsProvider settings,
      Color panelColor, Color titleColor, Color subtitleColor, ColorScheme cs) {
    return settingsPanelContainer(
      panelColor: panelColor,
      child: Row(
        children: [
          settingsIconBox(Icons.flag_outlined),
          SizedBox(width: 14.w),
          Expanded(child: settingsTileLabel('랩 간격', '자동 랩 기록 거리 기준', titleColor, subtitleColor)),
          GestureDetector(
            onTap: () {
              SystemSound.play(SystemSoundType.click);
              if (settings.lapIntervalKmBike > 1) settings.setLapIntervalKmBike(settings.lapIntervalKmBike - 1);
            },
            child: Container(
              width: 32.r, height: 32.r,
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8.r)),
              child: Icon(Icons.remove, color: titleColor, size: 16.r),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () async {
              SystemSound.play(SystemSoundType.click);
              final result = await NumberInputDialog.show(context,
                  title: '랩 간격', initialValue: settings.lapIntervalKmBike.toDouble(),
                  unit: 'km', maxDigits: 2, allowEmpty: false, allowDecimal: false);
              if (result != null && result > 0) settings.setLapIntervalKmBike(result.toInt());
            },
            child: SizedBox(
              width: 44.w,
              child: Text(
                '${settings.lapIntervalKmBike} km',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.indigo, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () {
              SystemSound.play(SystemSoundType.click);
              settings.setLapIntervalKmBike(settings.lapIntervalKmBike + 1);
            },
            child: Container(
              width: 32.r, height: 32.r,
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8.r)),
              child: Icon(Icons.add, color: titleColor, size: 16.r),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTileWidget extends StatefulWidget {
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isOn;
  final Color switchActiveColor;
  final void Function(bool) onSwitchChanged;
  final String stepperValue;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Future<void> Function() onTapValue;
  final bool? popupValue;
  final void Function(bool)? onPopupChanged;
  final bool? vibrationValue;
  final void Function(bool)? onVibrationChanged;
  final bool? soundValue;
  final void Function(bool)? onSoundChanged;
  final Color panelColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color btnBgOff;
  final Color inactiveTrackColor;
  final Color dividerColor;

  const _AlertTileWidget({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isOn,
    required this.switchActiveColor,
    required this.onSwitchChanged,
    required this.stepperValue,
    required this.onDecrement,
    required this.onIncrement,
    required this.onTapValue,
    this.popupValue,
    this.onPopupChanged,
    this.vibrationValue,
    this.onVibrationChanged,
    this.soundValue,
    this.onSoundChanged,
    required this.panelColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.btnBgOff,
    required this.inactiveTrackColor,
    required this.dividerColor,
  });

  @override
  State<_AlertTileWidget> createState() => _AlertTileWidgetState();
}

class _AlertTileWidgetState extends State<_AlertTileWidget> {
  bool _isExpanded = false;

  @override
  void didUpdateWidget(_AlertTileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOn && !oldWidget.isOn) setState(() => _isExpanded = true);
    if (!widget.isOn && oldWidget.isOn) setState(() => _isExpanded = false);
  }

  void _toggleExpand() {
    SystemSound.play(SystemSoundType.click);
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return settingsPanelContainer(
      panelColor: widget.panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.isOn ? _toggleExpand : null,
                  child: Row(
                    children: [
                      settingsIconBox(widget.icon, color: widget.iconColor),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: settingsTileLabel(
                            widget.title, widget.subtitle, widget.titleColor, widget.subtitleColor),
                      ),
                      if (widget.isOn) ...[
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: widget.subtitleColor,
                          size: 20.r,
                        ),
                        SizedBox(width: 4.w),
                      ],
                    ],
                  ),
                ),
              ),
              Switch(
                value: widget.isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  widget.onSwitchChanged(v);
                },
                activeThumbColor: widget.switchActiveColor,
                activeTrackColor: widget.switchActiveColor.withOpacity(0.4),
                inactiveTrackColor: widget.inactiveTrackColor,
              ),
            ],
          ),
          if (widget.isOn && _isExpanded) ...[
            Divider(height: 1, thickness: 0.5, color: widget.dividerColor),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    widget.onDecrement();
                  },
                  child: Container(
                    width: 40.r, height: 40.r,
                    decoration: BoxDecoration(
                        color: widget.btnBgOff, borderRadius: BorderRadius.circular(8.r)),
                    child: Icon(Icons.remove, color: widget.titleColor, size: 20.r),
                  ),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: widget.onTapValue,
                  child: Container(
                    width: 90.w,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                        color: widget.btnBgOff, borderRadius: BorderRadius.circular(8.r)),
                    child: Text(
                      widget.stepperValue,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: widget.titleColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    widget.onIncrement();
                  },
                  child: Container(
                    width: 40.r, height: 40.r,
                    decoration: BoxDecoration(
                        color: widget.btnBgOff, borderRadius: BorderRadius.circular(8.r)),
                    child: Icon(Icons.add, color: widget.titleColor, size: 20.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (widget.popupValue != null &&
                widget.vibrationValue != null &&
                widget.soundValue != null &&
                widget.onPopupChanged != null &&
                widget.onVibrationChanged != null &&
                widget.onSoundChanged != null) ...[
              Divider(height: 1, thickness: 0.5, color: widget.dividerColor),
              _methodRow(Icons.notifications_outlined, Colors.blueGrey, '팝업',
                  widget.popupValue!, widget.onPopupChanged!, widget.inactiveTrackColor),
              Divider(height: 1, thickness: 0.5, color: widget.dividerColor),
              _methodRow(Icons.vibration, Colors.blueGrey, '진동',
                  widget.vibrationValue!, widget.onVibrationChanged!, widget.inactiveTrackColor),
              Divider(height: 1, thickness: 0.5, color: widget.dividerColor),
              _methodRow(Icons.volume_up_outlined, Colors.blueGrey, '소리',
                  widget.soundValue!, widget.onSoundChanged!, widget.inactiveTrackColor),
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
