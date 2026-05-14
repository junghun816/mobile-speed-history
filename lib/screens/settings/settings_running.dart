import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/format_utils.dart';
import '../../widgets/number_input_dialog.dart';
import 'settings_widgets.dart';

class SettingsRunningScreen extends StatelessWidget {
  const SettingsRunningScreen({super.key});

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

    return Scaffold(
      appBar: AppBar(title: const Text('런닝')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _switchTile(
              context: context,
              icon: Icons.record_voice_over_outlined,
              title: '음성 안내',
              subtitle: '랩마다 거리·페이스를 음성으로 안내',
              value: settings.runningVoiceGuidance,
              onChanged: (v) => settings.setRunningVoiceGuidance(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            SizedBox(height: 10.h),
            _toggleTile(
              icon: Icons.vibration,
              title: '케이던스 피드백',
              subtitle: 'BPM 박자 알림 방식',
              leftLabel: '진동',
              rightLabel: '소리',
              isLeft: settings.cadenceFeedbackType == 'vibration',
              onToggle: (v) => settings.setCadenceFeedbackType(v ? 'vibration' : 'sound'),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
            ),
            SizedBox(height: 10.h),
            _inputTile(
              context: context,
              icon: Icons.music_note_outlined,
              title: '케이던스 BPM',
              subtitle: '0이면 비활성. 주행 시작 시 적용',
              value: settings.defaultCadenceBpm != null
                  ? '${settings.defaultCadenceBpm} bpm'
                  : '비활성',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () async {
                final v = await NumberInputDialog.show(
                  context,
                  title: '케이던스 BPM',
                  unit: 'bpm',
                  initialValue: settings.defaultCadenceBpm,
                  allowDecimal: false,
                );
                if (v == null) return;
                await settings.setDefaultCadenceBpm(v < 40 ? null : v.toInt());
              },
            ),
            SizedBox(height: 10.h),
            _inputTile(
              context: context,
              icon: Icons.directions_run,
              title: '목표 페이스',
              subtitle: '초과 시 진동 경고. 설정 안 하면 비활성',
              value: settings.defaultTargetPaceSecPerKm != null
                  ? '${formatPace(settings.defaultTargetPaceSecPerKm!)} min/km'
                  : '비활성',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () async {
                final v = await NumberInputDialog.show(
                  context,
                  title: '목표 페이스 (초/km)',
                  unit: '초',
                  initialValue: settings.defaultTargetPaceSecPerKm,
                  allowDecimal: false,
                );
                if (v == null) return;
                await settings.setDefaultTargetPaceSecPerKm(v <= 0 ? null : v.toInt());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return settingsPanelContainer(
      panelColor: panelColor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          SystemSound.play(SystemSoundType.click);
          onTap();
        },
        child: Row(
          children: [
            settingsIconBox(icon),
            SizedBox(width: 14.w),
            Expanded(child: settingsTileLabel(title, subtitle, titleColor, subtitleColor)),
            Text(
              value,
              style: TextStyle(
                color: Colors.lightBlue,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18.r),
          ],
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String leftLabel,
    required String rightLabel,
    required bool isLeft,
    required void Function(bool) onToggle,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color btnBgOff,
    required Color btnBorderOff,
    required Color btnTextOff,
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
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: settingsOptionButton(leftLabel, isLeft, () => onToggle(true),
                    btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff,
                    fontSize: 13),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: settingsOptionButton(rightLabel, !isLeft, () => onToggle(false),
                    btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff,
                    fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final inactiveTrackColor = Theme.of(context).colorScheme.outlineVariant;
    return settingsPanelContainer(
      panelColor: panelColor,
      child: Row(
        children: [
          settingsIconBox(icon),
          SizedBox(width: 14.w),
          Expanded(child: settingsTileLabel(title, subtitle, titleColor, subtitleColor)),
          Switch(
            value: value,
            onChanged: (v) {
              SystemSound.play(SystemSoundType.click);
              onChanged(v);
            },
            activeThumbColor: Colors.lightBlue,
            activeTrackColor: Colors.lightBlue.withOpacity(0.4),
            inactiveTrackColor: inactiveTrackColor,
          ),
        ],
      ),
    );
  }
}
