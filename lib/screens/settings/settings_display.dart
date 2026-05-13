import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('화면')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _displayItemsTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
            const SizedBox(height: 10),
            _clockDisplayTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
          ],
        ),
      ),
    );
  }

  Widget _displayItemsTile(
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBgOff,
    Color btnBorderOff,
    Color btnTextOff,
  ) {
    final items = [
      ('거리', settings.showDistance, settings.setShowDistance),
      ('시간', settings.showDuration, settings.setShowDuration),
      ('최고속도', settings.showMaxSpeed, settings.setShowMaxSpeed),
      ('평균속도', settings.showAvgSpeed, settings.setShowAvgSpeed),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.dashboard_outlined),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('주행 중 표시 항목',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 하단에 표시할 통계 선택',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final (label, isOn, setter) = e.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    setter(!isOn);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < items.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn ? Colors.lightBlue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOn ? Colors.lightBlue : btnBorderOff),
                    ),
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isOn ? Colors.lightBlue : btnTextOff,
                          fontSize: 12,
                          fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _clockDisplayTile(
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBgOff,
    Color btnBorderOff,
    Color btnTextOff,
  ) {
    const options = [
      ('none', '표시 안 함'),
      ('h24', '24시간'),
      ('h12', '12시간'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconBox(Icons.access_time),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('속도계 시계',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('속도계 화면 상단에 현재 시각 표시',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: options.asMap().entries.map((e) {
              final (val, label) = e.value;
              final isLast = e.key == options.length - 1;
              final isOn = settings.clockDisplay == val;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setClockDisplay(val);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: isLast ? 0 : 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isOn ? Colors.lightBlue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOn ? Colors.lightBlue : btnBorderOff),
                    ),
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isOn ? Colors.lightBlue : btnTextOff,
                          fontSize: 12,
                          fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
