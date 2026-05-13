import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/number_input_dialog.dart';
import 'settings_widgets.dart';

class SettingsUserScreen extends StatelessWidget {
  const SettingsUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final btnBgOff = cs.surfaceContainerHighest;

    return Scaffold(
      appBar: AppBar(title: const Text('사용자')),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            settingsPanelContainer(
              panelColor: panelColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      settingsIconBox(Icons.person_outline),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('체중',
                                style: TextStyle(color: titleColor, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('칼로리 추정에 사용됩니다',
                                style: TextStyle(color: subtitleColor, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          SystemSound.play(SystemSoundType.click);
                          settings.setWeightKg((settings.weightKg ?? 70) - 1);
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.remove, color: titleColor, size: 20),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () async {
                          SystemSound.play(SystemSoundType.click);
                          final result = await NumberInputDialog.show(context,
                              title: '체중 입력', initialValue: settings.weightKg,
                              unit: 'kg', maxDigits: 3, allowEmpty: true, allowDecimal: true);
                          if (result == null) return;
                          if (result == NumberInputDialog.clearValue) {
                            settings.setWeightKg(null);
                          } else {
                            settings.setWeightKg(result.toDouble());
                          }
                        },
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            settings.weightKg != null ? '${settings.weightKg!.toInt()} kg' : '--',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: settings.weightKg != null ? titleColor : subtitleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          SystemSound.play(SystemSoundType.click);
                          settings.setWeightKg((settings.weightKg ?? 70) + 1);
                        },
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: btnBgOff, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.add, color: titleColor, size: 20),
                        ),
                      ),
                    ],
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
