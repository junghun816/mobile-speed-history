import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'settings_ride.dart';
import 'settings_display.dart';
import 'settings_alert.dart';
import 'settings_map.dart';
import 'settings_user.dart';
import 'settings_system.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final panelColor = cs.surfaceContainer;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _menuTile(context, Icons.directions_bike_outlined, '주행', '속도 모드 · 자동정지 · GPS · 단위',
                const SettingsRideScreen(), panelColor, titleColor, subtitleColor),
            const SizedBox(height: 10),
            _menuTile(context, Icons.dashboard_outlined, '화면', '표시 항목 · 속도계 시계',
                const SettingsDisplayScreen(), panelColor, titleColor, subtitleColor),
            const SizedBox(height: 10),
            _menuTile(context, Icons.notifications_outlined, '알림', '속도 초과 · 미달 · 거리',
                const SettingsAlertScreen(), panelColor, titleColor, subtitleColor),
            const SizedBox(height: 10),
            _menuTile(context, Icons.map_outlined, '지도', '지도 스타일 · 경로 색상 · 두께 · 추적',
                const SettingsMapScreen(), panelColor, titleColor, subtitleColor),
            const SizedBox(height: 10),
            _menuTile(context, Icons.person_outline, '사용자', '체중',
                const SettingsUserScreen(), panelColor, titleColor, subtitleColor),
            const SizedBox(height: 10),
            _menuTile(context, Icons.settings_outlined, '시스템', '테마 · 시작 탭 · 백업 · 앱 정보',
                const SettingsSystemScreen(), panelColor, titleColor, subtitleColor),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget screen,
    Color panelColor,
    Color titleColor,
    Color subtitleColor,
  ) {
    return GestureDetector(
      onTap: () {
        SystemSound.play(SystemSoundType.click);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.lightBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.lightBlue, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }
}
