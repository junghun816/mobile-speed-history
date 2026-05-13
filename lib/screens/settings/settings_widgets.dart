import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget settingsIconBox(IconData icon) {
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

Widget settingsPanelContainer({
  required Color panelColor,
  required Widget child,
  EdgeInsets? padding,
}) {
  return Container(
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: panelColor, borderRadius: BorderRadius.circular(12)),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.lightBlue.withOpacity(0.15) : btnBgOff,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSelected ? Colors.lightBlue : btnBorderOff),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSelected ? Colors.lightBlue : btnTextOff,
          fontSize: fontSize,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ),
  );
}
