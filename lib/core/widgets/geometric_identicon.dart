import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// First colour of the identicon for [seed], so headers and accent bars can
/// match the avatar without re-drawing it.
Color identiconPrimaryColor(String seed) {
  final rng = _SeededRandom(_hash(seed));
  return AppColors
      .identiconPalettes[rng.nextInt(AppColors.identiconPalettes.length)]
      .first;
}

/// Splitwise-style faceted pattern used when a person has no photo.
///
/// The layout is seeded from [seed] (typically the person's name) so the same
/// person always gets the same triangles and colour family. Pass
/// [clipToCircle] false to fill a rectangular banner with the same pattern.
class GeometricIdenticon extends StatelessWidget {
  final String seed;
  final double? size;
  final bool clipToCircle;

  const GeometricIdenticon({
    super.key,
    required this.seed,
    this.size,
    this.clipToCircle = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size != null ? Size.square(size!) : Size.zero,
      painter: GeometricIdenticonPainter(
        seed: seed,
        clipToCircle: clipToCircle,
      ),
      child: size == null ? const SizedBox.expand() : null,
    );
  }
}

class GeometricIdenticonPainter extends CustomPainter {
  final String seed;
  final bool clipToCircle;

  GeometricIdenticonPainter({
    required this.seed,
    this.clipToCircle = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = clipToCircle
        ? size.shortestSide / 2
        : math.max(size.width, size.height);
    final rng = _SeededRandom(_hash(seed));
    final palette =
        AppColors.identiconPalettes[rng.nextInt(AppColors.identiconPalettes.length)];

    canvas.save();
    if (clipToCircle) {
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    canvas.drawCircle(center, radius, Paint()..color = palette.first);

    final hub = Offset(
      center.dx + (rng.nextDouble() - 0.5) * radius * 0.35,
      center.dy + (rng.nextDouble() - 0.5) * radius * 0.35,
    );

    final wedgeCount = 6 + rng.nextInt(3);
    var angle = rng.nextDouble() * math.pi * 2;
    for (var i = 0; i < wedgeCount; i++) {
      final sweep = (math.pi * 2 / wedgeCount) * (0.9 + rng.nextDouble() * 0.35);
      final p1 = _pointOnCircle(center, radius * 1.2, angle);
      final p2 = _pointOnCircle(center, radius * 1.2, angle + sweep);
      canvas.drawPath(
        Path()
          ..moveTo(hub.dx, hub.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..close(),
        Paint()..color = palette[i % palette.length],
      );
      angle += sweep * 0.82;
    }

    final overlays = 3 + rng.nextInt(2);
    for (var i = 0; i < overlays; i++) {
      final a = _pointOnCircle(center, radius * 1.15, rng.nextDouble() * math.pi * 2);
      final b = _pointOnCircle(center, radius * 1.15, rng.nextDouble() * math.pi * 2);
      final c = Offset(
        center.dx + (rng.nextDouble() - 0.5) * radius,
        center.dy + (rng.nextDouble() - 0.5) * radius,
      );
      canvas.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy)
          ..close(),
        Paint()..color = palette[(i + 1) % palette.length].withValues(alpha: 0.85),
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GeometricIdenticonPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.clipToCircle != clipToCircle;
}

Offset _pointOnCircle(Offset center, double radius, double angle) {
  return Offset(
    center.dx + math.cos(angle) * radius,
    center.dy + math.sin(angle) * radius,
  );
}

int _hash(String value) {
  var hash = 2166136261;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

class _SeededRandom {
  int _state;

  _SeededRandom(this._state);

  int nextInt(int max) {
    if (max <= 0) return 0;
    return (nextDouble() * max).floor() % max;
  }

  double nextDouble() {
    _state = (1103515245 * _state + 12345) & 0x7fffffff;
    return _state / 0x7fffffff;
  }
}
