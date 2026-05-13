import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget settingsIconBox(IconData icon) {
  return Container(
    width: 36.r,
    height: 36.r,
    decoration: BoxDecoration(
      color: Colors.lightBlue.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10.r),
    ),
    child: Icon(icon, color: Colors.lightBlue, size: 20.r),
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
        color: isSelected ? Colors.lightBlue.withOpacity(0.15) : btnBgOff,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isSelected ? Colors.lightBlue : btnBorderOff),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? Colors.lightBlue : btnTextOff,
          fontSize: fontSize.sp,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}
