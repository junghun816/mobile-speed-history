import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/utils_format.dart';
import '../../widgets/widgets_number_input.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('런닝')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _CadenceTile(
              cadenceEnabled: settings.cadenceEnabled,
              cadenceVibration: settings.cadenceVibration,
              cadenceSound: settings.cadenceSound,
              defaultCadenceBpm: settings.defaultCadenceBpm,
              onEnabledChanged: settings.setCadenceEnabled,
              onVibrationChanged: settings.setCadenceVibration,
              onSoundChanged: settings.setCadenceSound,
              onBpmChanged: (v) => settings.setDefaultCadenceBpm(v),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: cs.surfaceContainerHighest,
              inactiveTrackColor: cs.outlineVariant,
              dividerColor: cs.outlineVariant,
              initialExpanded: settings.getTileExpanded('cadence'),
              onExpandChanged: (v) => settings.setTileExpanded('cadence', v),
            ),
            SizedBox(height: 10.h),
            _inputTile(
              context: context,
              icon: Icons.directions_run,
              title: '목표 페이스',
              subtitle: '1:00~10:00 min/km.\n초과 시 진동 경고',
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
                  rangeHint: '60 ~ 600 초 (1:00 ~ 10:00 min/km)',
                );
                if (v == null) return;
                await settings.setDefaultTargetPaceSecPerKm(v <= 0 ? null : v.toInt());
              },
            ),
            SizedBox(height: 10.h),
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
      child: Column(
        children: [
          Row(
            children: [
              settingsIconBox(Icons.flag_outlined),
              SizedBox(width: 14.w),
              Expanded(child: settingsTileLabel('랩 간격', '자동 랩 기록 거리 기준', titleColor, subtitleColor)),
              GestureDetector(
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  if (settings.lapIntervalKmRun > 1) settings.setLapIntervalKmRun(settings.lapIntervalKmRun - 1);
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
                      title: '랩 간격', initialValue: settings.lapIntervalKmRun.toDouble(),
                      unit: 'km', maxDigits: 2, allowEmpty: false, allowDecimal: false,
                      rangeHint: '1 ~ 99 km');
                  if (result != null && result > 0) settings.setLapIntervalKmRun(result.toInt());
                },
                child: SizedBox(
                  width: 44.w,
                  child: Text(
                    '${settings.lapIntervalKmRun} km',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.indigo, fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  SystemSound.play(SystemSoundType.click);
                  settings.setLapIntervalKmRun(settings.lapIntervalKmRun + 1);
                },
                child: Container(
                  width: 32.r, height: 32.r,
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8.r)),
                  child: Icon(Icons.add, color: titleColor, size: 16.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Center(child: Text('1 ~ 99 km', style: TextStyle(color: subtitleColor, fontSize: 11.sp))),
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
                color: Colors.blueGrey,
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
            activeThumbColor: Colors.blueGrey,
            activeTrackColor: Colors.blueGrey.withOpacity(0.4),
            inactiveTrackColor: inactiveTrackColor,
          ),
        ],
      ),
    );
  }
}

class _CadenceTile extends StatefulWidget {
  final bool cadenceEnabled;
  final bool cadenceVibration;
  final bool cadenceSound;
  final int defaultCadenceBpm;
  final void Function(bool) onEnabledChanged;
  final void Function(bool) onVibrationChanged;
  final void Function(bool) onSoundChanged;
  final void Function(int) onBpmChanged;
  final Color panelColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color btnBgOff;
  final Color inactiveTrackColor;
  final Color dividerColor;
  final bool initialExpanded;
  final void Function(bool)? onExpandChanged;

  const _CadenceTile({
    required this.cadenceEnabled,
    required this.cadenceVibration,
    required this.cadenceSound,
    required this.defaultCadenceBpm,
    required this.onEnabledChanged,
    required this.onVibrationChanged,
    required this.onSoundChanged,
    required this.onBpmChanged,
    required this.panelColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.btnBgOff,
    required this.inactiveTrackColor,
    required this.dividerColor,
    this.initialExpanded = false,
    this.onExpandChanged,
  });

  @override
  State<_CadenceTile> createState() => _CadenceTileState();
}

class _CadenceTileState extends State<_CadenceTile> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  void didUpdateWidget(_CadenceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cadenceEnabled && !oldWidget.cadenceEnabled) {
      setState(() => _isExpanded = true);
      widget.onExpandChanged?.call(true);
    }
    if (!widget.cadenceEnabled && oldWidget.cadenceEnabled) {
      setState(() => _isExpanded = false);
      widget.onExpandChanged?.call(false);
    }
  }

  void _toggleExpand() {
    SystemSound.play(SystemSoundType.click);
    setState(() => _isExpanded = !_isExpanded);
    widget.onExpandChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    const mainColor = Colors.green;
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
                  onTap: widget.cadenceEnabled ? _toggleExpand : null,
                  child: Row(
                    children: [
                      settingsIconBox(Icons.music_note_outlined, color: mainColor),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: settingsTileLabel('케이던스', 'BPM 박자에 맞춰 진동·소리 출력',
                            widget.titleColor, widget.subtitleColor),
                      ),
                      if (widget.cadenceEnabled) ...[
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
                value: widget.cadenceEnabled,
                onChanged: (v) {
                  SystemSound.play(SystemSoundType.click);
                  widget.onEnabledChanged(v);
                },
                activeThumbColor: mainColor,
                activeTrackColor: mainColor.withOpacity(0.35),
                inactiveTrackColor: widget.inactiveTrackColor,
              ),
            ],
          ),
          if (widget.cadenceEnabled && _isExpanded) ...[
            Divider(height: 1, thickness: 0.5, color: widget.dividerColor),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    widget.onBpmChanged(widget.defaultCadenceBpm - 1);
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
                  onTap: () async {
                    SystemSound.play(SystemSoundType.click);
                    final result = await NumberInputDialog.show(context,
                        title: '케이던스 BPM',
                        initialValue: widget.defaultCadenceBpm.toDouble(),
                        unit: 'bpm',
                        maxDigits: 3,
                        allowEmpty: false,
                        allowDecimal: false,
                        rangeHint: '40 ~ 240 bpm');
                    if (result != null) widget.onBpmChanged(result.toInt());
                  },
                  child: Container(
                    width: 90.w,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                        color: widget.btnBgOff, borderRadius: BorderRadius.circular(8.r)),
                    child: Text(
                      '${widget.defaultCadenceBpm} bpm',
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
                    widget.onBpmChanged(widget.defaultCadenceBpm + 1);
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
            SizedBox(height: 4.h),
            Center(
              child: Text(
                '40 ~ 240 bpm',
                style: TextStyle(color: widget.subtitleColor, fontSize: 11.sp),
              ),
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, thickness: 0.5, color: widget.dividerColor),
            _methodRow(Icons.vibration, Colors.blueGrey, '진동',
                widget.cadenceVibration, widget.onVibrationChanged, widget.inactiveTrackColor),
            Divider(height: 1, thickness: 0.5, color: widget.dividerColor),
            _methodRow(Icons.volume_up_outlined, Colors.blueGrey, '소리',
                widget.cadenceSound, widget.onSoundChanged, widget.inactiveTrackColor),
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
