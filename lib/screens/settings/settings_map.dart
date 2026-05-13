import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'settings_widgets.dart';

class SettingsMapScreen extends StatelessWidget {
  const SettingsMapScreen({super.key});

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
      appBar: AppBar(title: const Text('지도')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _multiOptionTile(
              icon: Icons.map_outlined,
              title: '지도 스타일',
              subtitle: '주행 지도 및 경로 지도에 적용',
              labels: const ['기본', '위성', '하이브리드'],
              selectedIndex: const ['basic', 'satellite', 'hybrid'].indexOf(settings.mapType),
              onSelect: (i) => settings.setMapType(const ['basic', 'satellite', 'hybrid'][i]),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
            ),
            const SizedBox(height: 10),
            _pathColorTile(context, settings, panelColor, titleColor, subtitleColor),
            const SizedBox(height: 10),
            _multiOptionTile(
              icon: Icons.line_weight,
              title: '경로 두께',
              subtitle: '주행·기록 지도의 경로 선 굵기',
              labels: const ['얇게', '보통', '굵게'],
              selectedIndex: const [3, 5, 8].indexOf(settings.pathThickness),
              onSelect: (i) => settings.setPathThickness(const [3, 5, 8][i]),
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              btnBgOff: btnBgOff,
              btnBorderOff: btnBorderOff,
              btnTextOff: btnTextOff,
            ),
            const SizedBox(height: 10),
            _trackingModeTile(settings, panelColor, titleColor, subtitleColor, btnBgOff, btnBorderOff, btnTextOff),
          ],
        ),
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
  }) {
    return settingsPanelContainer(
      panelColor: panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              settingsIconBox(icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(labels.length, (i) => Expanded(
              child: settingsOptionButton(
                labels[i], selectedIndex == i, () => onSelect(i),
                btnBgOff: btnBgOff, btnBorderOff: btnBorderOff, btnTextOff: btnTextOff,
                margin: EdgeInsets.only(right: i < labels.length - 1 ? 6 : 0),
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _trackingModeTile(
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
    Color btnBgOff,
    Color btnBorderOff,
    Color btnTextOff,
  ) {
    const options = ['none', 'follow', 'face'];
    const labels = ['없음', '위치 추적', '방위 추적'];
    const descriptions = ['자동 이동 안 함', '현재 위치 따라감', '진행 방향 위로'];

    return settingsPanelContainer(
      panelColor: panelColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              settingsIconBox(Icons.my_location),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('지도 추적 모드 기본값',
                        style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('주행 지도 시작 시 초기 추적 모드',
                        style: TextStyle(color: subtitleColor, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(options.length, (i) {
              final isSelected = settings.mapTrackingMode == options[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    SystemSound.play(SystemSoundType.click);
                    settings.setMapTrackingMode(options[i]);
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: i < options.length - 1 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.lightBlue.withOpacity(0.15) : btnBgOff,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? Colors.lightBlue : btnBorderOff),
                    ),
                    child: Column(
                      children: [
                        Text(labels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.lightBlue : btnTextOff,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                        Text(descriptions[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.lightBlue.withOpacity(0.7) : subtitleColor,
                              fontSize: 10,
                            )),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _pathColorTile(
    BuildContext context,
    SettingsProvider settings,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    const options = ['blue', 'red', 'green', 'orange', 'purple', 'yellow'];
    const labels = ['파랑', '빨강', '초록', '주황', '보라', '노랑'];

    return settingsPanelContainer(
      panelColor: panelColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          settingsIconBox(Icons.route),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('경로 색상',
                    style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('주행·기록 지도의 경로 선 색상',
                    style: TextStyle(color: subtitleColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.pathColor,
                dropdownColor: panelColor,
                borderRadius: BorderRadius.circular(10),
                onTap: () => SystemSound.play(SystemSoundType.click),
                onChanged: (val) { if (val != null) settings.setPathColor(val); },
                selectedItemBuilder: (_) => List.generate(options.length, (i) {
                  final color = _pathColor(options[i]);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 18, height: 4,
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      Text(labels[i],
                          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  );
                }),
                items: List.generate(options.length, (i) {
                  final color = _pathColor(options[i]);
                  return DropdownMenuItem<String>(
                    value: options[i],
                    child: Row(
                      children: [
                        Container(width: 20, height: 4,
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 10),
                        Text(labels[i], style: TextStyle(color: titleColor, fontSize: 13)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _pathColor(String name) {
    switch (name) {
      case 'red': return Colors.red;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'yellow': return Colors.yellow;
      default: return Colors.blue;
    }
  }
}
