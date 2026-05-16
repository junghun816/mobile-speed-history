import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget settingsIconBox(IconData icon, {Color color = Colors.indigo}) {
  return Container(
    width: 36.r,
    height: 36.r,
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Icon(icon, color: color, size: 20.r),
  );
}

Widget settingsTileLabel(
  String title,
  String subtitle,
  Color titleColor,
  Color subtitleColor,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: TextStyle(color: titleColor, fontSize: 14.sp, fontWeight: FontWeight.bold)),
      SizedBox(height: 2.h),
      Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12.sp)),
    ],
  );
}

Widget settingsTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required Color panelColor,
  required Color titleColor,
  required Color subtitleColor,
  Color iconColor = Colors.lightBlue,
  Widget? trailing,
  VoidCallback? onTap,
}) {
  return GestureDetector(
    onTap: onTap == null
        ? null
        : () {
            SystemSound.play(SystemSoundType.click);
            onTap();
          },
    child: settingsPanelContainer(
      panelColor: panelColor,
      child: Row(
        children: [
          settingsIconBox(icon, color: iconColor),
          SizedBox(width: 14.w),
          Expanded(child: settingsTileLabel(title, subtitle, titleColor, subtitleColor)),
          trailing ?? Icon(Icons.chevron_right, color: subtitleColor, size: 20.r),
        ],
      ),
    ),
  );
}

Widget settingsPanelContainer({
  required Color panelColor,
  required Widget child,
  EdgeInsets? padding,
}) {
  return Container(
    padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12.r)),
    child: child,
  );
}

Widget settingsOptionButton(
  String label,
  bool isSelected,
  VoidCallback onTap, {
  required Color btnBgOff,
  required Color btnBorderOff,
  required Color btnTextOff,
  double fontSize = 12,
  EdgeInsets? margin,
}) {
  return GestureDetector(
    onTap: () {
      SystemSound.play(SystemSoundType.click);
      onTap();
    },
    child: Container(
      margin: margin,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.indigo.withOpacity(0.15) : btnBgOff,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isSelected ? Colors.indigo : btnBorderOff),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? Colors.indigo : btnTextOff,
          fontSize: fontSize.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}
