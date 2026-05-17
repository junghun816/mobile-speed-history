import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'settings_ride.dart';
import 'settings_running.dart';
import 'settings_display.dart';
import 'settings_alert.dart';
import 'settings_map.dart';
import 'settings_user.dart';
import 'settings_system.dart';
import 'settings_widgets.dart';

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
          padding: EdgeInsets.all(16.r),
          children: [
            settingsTile(
              icon: Icons.tune,
              title: '일반',
              subtitle: '기본 · 공통 설정',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsRideScreen())),
            ),
            SizedBox(height: 10.h),
            settingsTile(
              icon: Icons.directions_bike,
              title: '자전거',
              subtitle: '자전거 모드 설정',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsAlertScreen())),
            ),
            SizedBox(height: 10.h),
            settingsTile(
              icon: Icons.directions_run,
              title: '런닝',
              subtitle: '런닝 모드 설정',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsRunningScreen())),
            ),
            SizedBox(height: 10.h),
            settingsTile(
              icon: Icons.dashboard_outlined,
              title: '화면',
              subtitle: '속도계 화면 설정',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsDisplayScreen())),
            ),
            SizedBox(height: 10.h),
            settingsTile(
              icon: Icons.map_outlined,
              title: '지도',
              subtitle: '지도 스타일 설정',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsMapScreen())),
            ),
            SizedBox(height: 10.h),
            settingsTile(
              icon: Icons.person_outline,
              title: '사용자',
              subtitle: '',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsUserScreen())),
            ),
            SizedBox(height: 10.h),
            settingsTile(
              icon: Icons.settings_outlined,
              title: '시스템',
              subtitle: '테마 · 시작 탭 · 백업 · 앱 정보',
              panelColor: panelColor,
              titleColor: titleColor,
              subtitleColor: subtitleColor,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsSystemScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
