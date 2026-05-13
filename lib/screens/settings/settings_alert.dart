import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/number_input_dialog.dart';

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
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _speedAlertTile(context, settings, panelColor, titleColor, subtitleColor, btnBgOff, inactiveTrackColor),
            const SizedBox(height: 10),
            _speedMinAlertTile(context, settings, panelColor, titleColor, subtitleColor, btnBgOff, inactiveTrackColor),
            const SizedBox(height: 10),
            _distanceAlertTile(context, settings, panelColor, titleColor, subtitleColor, btnBgOff, inactiveTrackColor),
          ],
        ),
      ),
    );
  }

  Widget _speedAlertTile(
    BuildContext context,
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBgOff,
    Color inactiveTrackColor,
  ) {
    final isOn = settings.speedAlertKmh != null;
    final currentKmh = settings.speedAlertKmh?.toInt() ?? 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.speed_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('속도 초과 알림',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('설정 속도 초과 시 진동 + 빨간색 표시',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  settings.setSpeedAlertKmh(v ? currentKmh.toDouble() : null);
                },
                activeThumbColor: Colors.red,
                activeTrackColor: Colors.red.withOpacity(0.4),
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            _stepper(
              context: context,
              value: '$currentKmh km/h',
              onDecrement: () {
                SystemSound.play(SystemSoundType.click);
                settings.setSpeedAlertKmh(
                    (currentKmh - 5).clamp(kDebugMode ? 0 : 1, 999).toDouble());
              },
              onIncrement: () {
                SystemSound.play(SystemSoundType.click);
                settings.setSpeedAlertKmh(
                    (currentKmh + 5).clamp(kDebugMode ? 0 : 1, 999).toDouble());
              },
              onTapValue: () async {
                SystemSound.play(SystemSoundType.click);
                final result = await NumberInputDialog.show(
                  context,
                  title: '속도 알림 기준',
                  initialValue: settings.speedAlertKmh,
                  unit: 'km/h',
                  maxDigits: 3,
                  allowEmpty: false,
                  allowDecimal: false,
                );
                if (result == null) return;
                settings.setSpeedAlertKmh(result.toDouble());
              },
              titleColor: titleColor,
              btnBgOff: btnBgOff,
            ),
          ],
        ],
      ),
    );
  }

  Widget _speedMinAlertTile(
    BuildContext context,
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBgOff,
    Color inactiveTrackColor,
  ) {
    final isOn = settings.speedMinAlertKmh != null;
    final currentKmh = settings.speedMinAlertKmh?.toInt() ?? 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.speed_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('속도 미달 알림',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('설정 속도 미만 시 진동 + 파란색 표시',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  settings.setSpeedMinAlertKmh(v ? currentKmh.toDouble() : null);
                },
                activeThumbColor: Colors.lightBlue,
                activeTrackColor: Colors.lightBlue.withOpacity(0.4),
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            _stepper(
              context: context,
              value: '$currentKmh km/h',
              onDecrement: () {
                SystemSound.play(SystemSoundType.click);
                settings.setSpeedMinAlertKmh(
                    (currentKmh - 5).clamp(kDebugMode ? 0 : 1, 999).toDouble());
              },
              onIncrement: () {
                SystemSound.play(SystemSoundType.click);
                settings.setSpeedMinAlertKmh(
                    (currentKmh + 5).clamp(kDebugMode ? 0 : 1, 999).toDouble());
              },
              onTapValue: () async {
                SystemSound.play(SystemSoundType.click);
                final result = await NumberInputDialog.show(
                  context,
                  title: '속도 미달 알림 기준',
                  initialValue: settings.speedMinAlertKmh,
                  unit: 'km/h',
                  maxDigits: 3,
                  allowEmpty: false,
                  allowDecimal: false,
                );
                if (result == null) return;
                settings.setSpeedMinAlertKmh(result.toDouble());
              },
              titleColor: titleColor,
              btnBgOff: btnBgOff,
            ),
          ],
        ],
      ),
    );
  }

  Widget _distanceAlertTile(
    BuildContext context,
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBgOff,
    Color inactiveTrackColor,
  ) {
    final isOn = settings.distanceAlertKm != null;
    final currentKm = settings.distanceAlertKm ?? 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.social_distance_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('거리 알림',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('설정 km 도달마다 알림 · 진동',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: isOn,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  settings.setDistanceAlertKm(v ? currentKm : null);
                },
                activeThumbColor: Colors.green,
                activeTrackColor: Colors.green.withOpacity(0.4),
                inactiveTrackColor: inactiveTrackColor,
              ),
            ],
          ),
          if (isOn) ...[
            const SizedBox(height: 12),
            _stepper(
              context: context,
              value: '$currentKm km',
              onDecrement: () {
                SystemSound.play(SystemSoundType.click);
                settings.setDistanceAlertKm((currentKm - 1).clamp(1, 999));
              },
              onIncrement: () {
                SystemSound.play(SystemSoundType.click);
                settings.setDistanceAlertKm((currentKm + 1).clamp(1, 999));
              },
              onTapValue: () async {
                SystemSound.play(SystemSoundType.click);
                final result = await NumberInputDialog.show(
                  context,
                  title: '거리 알림 기준',
                  initialValue: currentKm,
                  unit: 'km',
                  maxDigits: 3,
                  allowEmpty: false,
                  allowDecimal: false,
                );
                if (result == null) return;
                settings.setDistanceAlertKm(result.toInt());
              },
              titleColor: titleColor,
              btnBgOff: btnBgOff,
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepper({
    required BuildContext context,
    required String value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Future<void> Function() onTapValue,
    required Color titleColor,
    required Color btnBgOff,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.remove, color: titleColor, size: 20),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: onTapValue,
          child: Container(
            width: 90,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8)),
            child: Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(color: titleColor, fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.add, color: titleColor, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.lightBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: Colors.lightBlue, size: 20),
    );
  }
}
