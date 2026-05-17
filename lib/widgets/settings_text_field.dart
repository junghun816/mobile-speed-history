import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/settings/settings_widgets.dart';

class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.icon,
    required this.controller,
    required this.hint,
    this.label,
    this.maxLines = 1,
    this.minLines = 1,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hint;

  // label 있으면: 작은 라벨 + 굵은 텍스트 (제조사/기종 스타일)
  // label 없으면: 일반 텍스트, 멀티라인 가능 (비고 스타일)
  final String? label;

  final int? maxLines; // null = 무제한
  final int minLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final titleColor = cs.onSurface;
    final subtitleColor = cs.onSurfaceVariant;
    final isMultiline = maxLines != 1 || minLines > 1;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          settingsIconBox(icon),
          SizedBox(width: 14.w),
          Expanded(
            child: label != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label!,
                          style: TextStyle(
                              color: subtitleColor, fontSize: 11.sp)),
                      SizedBox(height: 2.h),
                      TextField(
                        controller: controller,
                        maxLines: maxLines,
                        minLines: minLines,
                        style: TextStyle(
                            color: titleColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold),
                        decoration: InputDecoration.collapsed(
                          hintText: hint,
                          hintStyle: TextStyle(
                              color: subtitleColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    ],
                  )
                : TextField(
                    controller: controller,
                    maxLines: maxLines,
                    minLines: minLines,
                    style: TextStyle(color: titleColor, fontSize: 14.sp),
                    decoration: InputDecoration.collapsed(
                      hintText: hint,
                      hintStyle:
                          TextStyle(color: subtitleColor, fontSize: 14.sp),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
