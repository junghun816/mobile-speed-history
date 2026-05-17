import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generate icon previews', () async {
    await _generateIcon('icon_preview_blue_cyan.png',
        const ui.Color(0xFF0055EE), const ui.Color(0xFF00CCFF));
    await _generateIcon('icon_preview_green_cyan.png',
        const ui.Color(0xFF00A876), const ui.Color(0xFF00CCCC));
    print('Done');
  }, timeout: const Timeout(Duration(seconds: 30)));
}

Future<void> _generateIcon(String filename, ui.Color c1, ui.Color c2) async {
  const double S = 1024;
  const double cx = S / 2, cy = S / 2;

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, S, S));

  // ── 배경 ──
  canvas.drawRRect(
    ui.RRect.fromRectAndRadius(
        ui.Rect.fromLTWH(0, 0, S, S), const ui.Radius.circular(224)),
    ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset.zero,
        const ui.Offset(S, S),
        [c1, c2],
      ),
  );

  // ── 게이지 호 ──
  const double arcR = S * 0.355;
  const double arcW = S * 0.068;
  const double startDeg = 150.0;
  const double sweepDeg = 240.0;
  final arcRect = ui.Rect.fromCircle(
      center: const ui.Offset(cx, cy), radius: arcR);

  canvas.drawArc(arcRect, _rad(startDeg), _rad(sweepDeg), false,
      ui.Paint()
        ..color = const ui.Color(0x30FFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = arcW
        ..strokeCap = ui.StrokeCap.round);

  canvas.drawArc(arcRect, _rad(startDeg), _rad(sweepDeg), false,
      ui.Paint()
        ..color = const ui.Color(0xE8FFFFFF)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = arcW
        ..strokeCap = ui.StrokeCap.round);

  // ── 눈금 ──
  for (int i = 0; i < 11; i++) {
    final double a = _rad(startDeg + sweepDeg * i / 10);
    final bool major = (i == 0 || i == 5 || i == 10);
    final double inner = arcR - arcW * 0.55 - (major ? 20 : 11);
    final double outer = arcR + arcW * 0.55 + (major ? 20 : 11);
    canvas.drawLine(
      ui.Offset(cx + inner * math.cos(a), cy + inner * math.sin(a)),
      ui.Offset(cx + outer * math.cos(a), cy + outer * math.sin(a)),
      ui.Paint()
        ..color = ui.Color(major ? 0xFFFFFFFF : 0xAAFFFFFF)
        ..strokeWidth = major ? 7 : 4
        ..strokeCap = ui.StrokeCap.round,
    );
  }

  // ── P 글자 (Path로 직접 그리기) ──
  _drawP(canvas, cx, cy - 10);

  // ── PNG 저장 ──
  final img = await recorder.endRecording().toImage(S.toInt(), S.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  await File(filename).writeAsBytes(data!.buffer.asUint8List());
}

/// P 글자를 기하학적 경로로 렌더링
void _drawP(ui.Canvas canvas, double cx, double cy) {
  const double H = 455.0;   // 전체 높이
  const double bW = 68.0;   // 세로 바 너비
  const double bR = 142.0;  // 범프 외부 반지름 (크게 → 더 동그랗게)
  const double hR = 74.0;   // 범프 내부 구멍

  final double top = cy - H / 2;
  final double barLeft = cx - 94.0;
  final double barRight = barLeft + bW;
  final double bumpCx = barRight;
  final double bumpCy = top + bR;

  final layerRect = ui.Rect.fromLTWH(
      barLeft - 20, top - 20, bR * 2 + bW + 40, H + 40);

  // 그림자
  canvas.saveLayer(layerRect, ui.Paint());
  _drawPShape(canvas, barLeft + 5, top + 8, bW, H, bR, hR,
      bumpCx + 5, bumpCy + 8, const ui.Color(0x35000000), hole: false);
  canvas.restore();

  // 본체 (구멍 포함)
  canvas.saveLayer(layerRect, ui.Paint());
  _drawPShape(canvas, barLeft, top, bW, H, bR, hR,
      bumpCx, bumpCy, const ui.Color(0xFFFFFFFF), hole: true);
  canvas.restore();
}

void _drawPShape(
  ui.Canvas canvas,
  double barLeft,
  double top,
  double bW,
  double H,
  double bR,
  double hR,
  double bumpCx,
  double bumpCy,
  ui.Color color, {
  required bool hole,
}) {
  final paint = ui.Paint()..color = color;

  // 세로 바
  canvas.drawRect(ui.Rect.fromLTWH(barLeft, top, bW, H), paint);

  // 외부 범프 (오른쪽 반원 + 닫기)
  final bump = ui.Path()
    ..moveTo(bumpCx, bumpCy - bR)
    ..arcTo(
      ui.Rect.fromCircle(center: ui.Offset(bumpCx, bumpCy), radius: bR),
      -math.pi / 2,
      math.pi,
      false,
    )
    ..lineTo(bumpCx, bumpCy - bR)
    ..close();
  canvas.drawPath(bump, paint);

  if (hole) {
    // 내부 구멍 (BlendMode.clear로 도려내기)
    final clearPaint = ui.Paint()..blendMode = ui.BlendMode.clear;
    final inner = ui.Path()
      ..moveTo(bumpCx, bumpCy - hR)
      ..arcTo(
        ui.Rect.fromCircle(center: ui.Offset(bumpCx, bumpCy), radius: hR),
        -math.pi / 2,
        math.pi,
        false,
      )
      ..lineTo(bumpCx, bumpCy - hR)
      ..close();
    canvas.drawPath(inner, clearPaint);
  }
}

double _rad(double deg) => deg * math.pi / 180;
