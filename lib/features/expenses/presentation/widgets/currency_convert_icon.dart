import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/datasources/currency_catalog.dart';

/// Circling arrows around the default-currency symbol ($ / ₹ / €).
class CurrencyConvertIcon extends StatelessWidget {
  final String currencyCode;
  final Color color;
  final double size;

  const CurrencyConvertIcon({
    super.key,
    required this.currencyCode,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = CurrencyCatalog.symbolFor(currencyCode);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ExchangeArrowsPainter(color),
        child: Center(
          child: Text(
            symbol,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExchangeArrowsPainter extends CustomPainter {
  final Color color;

  _ExchangeArrowsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.shortestSide * 0.1)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, -0.35, math.pi * 0.85, false, stroke);
    canvas.drawArc(rect, math.pi - 0.35, math.pi * 0.85, false, stroke);

    _arrowHead(canvas, fill, center, radius, -0.35 + math.pi * 0.85);
    _arrowHead(canvas, fill, center, radius, math.pi - 0.35 + math.pi * 0.85);
  }

  void _arrowHead(
    Canvas canvas,
    Paint paint,
    Offset center,
    double radius,
    double angle,
  ) {
    final tip = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    final tangent = angle + math.pi / 2;
    final length = radius * 0.32;
    final left = Offset(
      tip.dx - length * math.cos(tangent - 0.55),
      tip.dy - length * math.sin(tangent - 0.55),
    );
    final right = Offset(
      tip.dx - length * math.cos(tangent + 0.55),
      tip.dy - length * math.sin(tangent + 0.55),
    );
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ExchangeArrowsPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
