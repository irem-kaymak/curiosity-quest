import 'dart:math' as math;

import 'package:flutter/material.dart';

class NatureBackground extends StatelessWidget {
  final bool older;
  final Widget child;
  const NatureBackground({super.key, required this.older, required this.child});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _Landscape(older), child: child);
}

class _Landscape extends CustomPainter {
  final bool older;
  const _Landscape(this.older);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: older
              ? const [
                  Color(0xFFBFE8FF),
                  Color(0xFFE2F5F9),
                  Color(0xFFB0E1C5),
                ]
              : const [
                  Color(0xFFFFEDD4),
                  Color(0xFFFFDEA4),
                  Color(0xFFD0E593),
                ],
        ).createShader(rect),
    );
    void oval(double x, double y, double w, double h, Color color) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x * size.width, y * size.height),
          width: w,
          height: h,
        ),
        Paint()..color = color,
      );
    }

    for (final x in [.08, .68, .95]) {
      oval(x, .08, 85, 24, Colors.white.withValues(alpha: .65));
      oval(x + .035, .065, 38, 35, Colors.white.withValues(alpha: .65));
    }

    final sun = Offset(size.width * .87, size.height * .19);
    canvas.drawCircle(sun, 25, Paint()..color = const Color(0xFFFFC85B));
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        sun + Offset(math.cos(angle) * 33, math.sin(angle) * 33),
        sun + Offset(math.cos(angle) * 40, math.sin(angle) * 40),
        Paint()
          ..color = const Color(0xFFFFC85B)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    if (older) {
      for (var i = 0; i < 5; i++) {
        final x = i * size.width / 3 - 70;
        final path = Path()
          ..moveTo(x, size.height * .68)
          ..lineTo(x + 90, size.height * (.26 + i % 2 * .07))
          ..lineTo(x + 200, size.height * .68)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..color = i.isEven
                ? const Color(0xFFABD2E3)
                : const Color(0xFFC2E0EA),
        );
      }
    }

    final hillColors = older
        ? const [Color(0xFFBFE4CE), Color(0xFFAAD7C0), Color(0xFF96CDB3)]
        : const [Color(0xFFCEE697), Color(0xFFB9D778), Color(0xFFA0C969)];
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.68 + i * .12);
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * .45, y - 70, size.width, y + 20)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = hillColors[i]);
    }

    for (final side in [0.02, .98]) {
      for (var i = 0; i < 5; i++) {
        final y = .36 + i * .14;
        oval(side, y, 12, 55, const Color(0xFF80B678));
        oval(side - .025, y - .02, 28, 13, const Color(0xFF9DC97D));
        oval(side + .03, y - .04, 26, 15, const Color(0xFF7BAE70));
      }
      for (var i = 0; i < 4; i++) {
        final center = Offset(side * size.width, size.height * (.5 + i * .15));
        for (var j = 0; j < 5; j++) {
          final angle = j * math.pi * 2 / 5;
          canvas.drawCircle(
            center + Offset(math.cos(angle) * 6, math.sin(angle) * 6),
            5,
            Paint()..color = const Color(0xFFFFD276),
          );
        }
        canvas.drawCircle(center, 3, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(_Landscape oldDelegate) => older != oldDelegate.older;
}
