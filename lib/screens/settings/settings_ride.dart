import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/speed_mode.dart';
import '../../utils/format_utils.dart';
import '../../widgets/number_input_dialog.dart';
import 'settings_widgets.dart';

class SettingsRideScreen extends StatelessWidget {
  const SettingsRideScreen({super.key});

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
      appBar: AppBar(title: const Text('주행')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _speedModeTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            SizedBox(height: 10.h),
            _switchTile(
              context: context,
              icon: Icons.pause_circle_outline,
              title: '자동 일시정지',
              subtitle: '정지 감지 시 타이머 자동 일시정지',
              value: settings.autoPause,
              onChanged: (v) => settings.setAutoPause(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
            ),
            SizedBox(height: 10.h),
            _multiOptionTile(
              icon: Icons.straighten,
              title: '최소 기록 거리',
              subtitle: '미달 시 주행 종료 후 저장 안 됨',
              labels: const ['없음', '0.1 km', '0.5 km', '1.0 km'],
              selectedIndex: const [0.0, 0.1, 0.5, 1.0].indexOf(settings.minRecordDistanceKm),
              onSelect: (i) => settings.setMinRecordDistanceKm(const [0.0, 0.1, 0.5, 1.0][i]),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
            ),
            SizedBox(height: 10.h),
            _multiOptionTile(
              icon: Icons.timer_outlined,
              title: '최소 기록 시간',
              subtitle: '미달 시 주행 종료 후 저장 안 됨',
              labels: const ['없음', '1분', '3분', '5분', '10분'],
              selectedIndex: const [0, 60, 180, 300, 600].indexOf(settings.minRecordDurationSec),
              onSelect: (i) => settings.setMinRecordDurationSec(const [0, 60, 180, 300, 600][i]),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
              fontSize: 11,
            ),
            SizedBox(height: 10.h),
            _toggleTile(
              icon: Icons.speed,
              title: '단위',
              subtitle: '속도/거리 표시 단위',
              leftLabel: 'km/h',
              rightLabel: 'mph',
              isLeft: settings.useKmh,
              onToggle: (v) => settings.setUseKmh(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
            ),
            SizedBox(height: 10.h),
            _toggleTile(
              icon: Icons.gps_fixed,
              title: 'GPS 정확도',
              subtitle: '고정밀 모드는 배터리를 더 소모해요',
              leftLabel: '고정밀',
              rightLabel: '배터리 절약',
              isLeft: settings.gpsHighAccuracy,
              onToggle: (v) => settings.setGpsHighAccuracy(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
              child: Text(
                '런닝',
                style: TextStyle(
                  color: cs.outline,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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

  Widget _speedModeTile(
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBgOff,
    Color btnBorderOff,
    Color btnTextOff,
  ) {
    const modes = SpeedMode.values;
    final selected = settings.speedMode;
    const modeIcons = {
      SpeedMode.normal: Icons.directions_bike,
      SpeedMode.lowSpeed: Icons.directions_run,
    };

    return settingsPanelContainer(
      panelColor: panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              settingsIconBox(modeIcons[selected]!),
              SizedBox(width: 14.w),
              Expanded(child: settingsTileLabel('속도 측정 모드', selected.description, titleColor, subtitleColor)),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: modes.map((mode) {
              final isSelected = mode == selected;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: mode != modes.last ? 6.w : 0),
                  child: GestureDetector(
                    onTap: () {
                      SystemSound.play(SystemSoundType.click);
                      settings.setSpeedMode(mode);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.lightBlue.withOpacity(0.15) : btnBgOff,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: isSelected ? Colors.lightBlue : btnBorderOff),
                      ),
                      child: Column(
                        children: [
                          Icon(modeIcons[mode], size: 18.r,
                              color: isSelected ? Colors.lightBlue : btnTextOff),
                          SizedBox(height: 4.h),
                          Text(mode.label,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.lightBlue : btnTextOff,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _multiOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> labels,
    required int selectedIndex,
    required void Function(int) onSelect,
    required Color panelColor,
    required Color titleColor,
    required Color subtitleColor,
    required Color btnBgOff,
    required Color btnBorderOff,
    required Color btnTextOff,
    double fontSize = 12,
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
            children: List.generate(labels.length, (i) {
              return Expanded(
                child: settingsOptionButton(
                  labels[i],
                  selectedIndex == i,
                  () => onSelect(i),
                  btnBgOff: btnBgOff,
                  btnBorderOff: btnBorderOff,
                  btnTextOff: btnTextOff,
                  fontSize: fontSize,
                  margin: EdgeInsets.only(right: i < labels.length - 1 ? 6.w : 0),
                ),
              );
            }),
          ),
        ],
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
            Icon(Icons.chevron_right, color: subtitleColor, size: 18.r),
          ],
        ),
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
