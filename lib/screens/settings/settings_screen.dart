import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          padding: EdgeInsets.all(16.r),
          children: [
            _menuTile(context, Icons.directions_bike_outlined, '주행', '속도 모드 · 자동정지 · GPS · 단위',
                const SettingsRideScreen(), panelColor, titleColor, subtitleColor),
            SizedBox(height: 10.h),
            _menuTile(context, Icons.dashboard_outlined, '화면', '표시 항목 · 속도계 시계',
                const SettingsDisplayScreen(), panelColor, titleColor, subtitleColor),
            SizedBox(height: 10.h),
            _menuTile(context, Icons.notifications_outlined, '알림', '속도 초과 · 미달 · 거리',
                const SettingsAlertScreen(), panelColor, titleColor, subtitleColor),
            SizedBox(height: 10.h),
            _menuTile(context, Icons.map_outlined, '지도', '지도 스타일 · 경로 색상 · 두께 · 추적',
                const SettingsMapScreen(), panelColor, titleColor, subtitleColor),
            SizedBox(height: 10.h),
            _menuTile(context, Icons.person_outline, '사용자', '체중',
                const SettingsUserScreen(), panelColor, titleColor, subtitleColor),
            SizedBox(height: 10.h),
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: Colors.lightBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: Colors.lightBlue, size: 20.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 12.sp)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor, size: 20.r),
          ],
        ),
      ),
    );
  }
}
