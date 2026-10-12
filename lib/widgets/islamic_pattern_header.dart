import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// A tasteful, code-drawn Islamic 8-point star ("khatam") geometric
/// tessellation, used as a decorative header band across the app (matches the
/// reference مقرأة-style design). Drawn with a [CustomPainter] rather than an
/// image asset, so there is no binary file to source or ship.
class IslamicPatternHeader extends StatelessWidget {
  final double height;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const IslamicPatternHeader({
    super.key,
    this.height = 150,
    this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: const _IslamicPatternPainter(),
        child: child == null ? null : Padding(padding: padding, child: child),
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  const _IslamicPatternPainter();

  static const double _tile = 44;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(kPrimaryDarkColor), Color(kPrimaryColor)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final cols = (size.width / _tile).ceil() + 1;
    final rows = (size.height / _tile).ceil() + 1;

    for (var row = -1; row < rows; row++) {
      for (var col = -1; col < cols; col++) {
        _drawStarTile(
          canvas,
          line,
          Offset(col * _tile, row * _tile),
          _tile * 0.6,
        );
      }
    }

    // Soft radial glow so the pattern isn't perfectly flat/uniform.
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.06), Colors.transparent],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.8, -size.height * 0.2),
        radius: size.width * 0.7,
      ));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glow);
  }

  /// One "8-point star" motif: a square overlapped with the same square
  /// rotated 45 degrees - the classic construction behind most Islamic
  /// geometric star tessellations.
  void _drawStarTile(Canvas canvas, Paint paint, Offset center, double r) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    canvas.drawPath(_square(r), paint);
    canvas.rotate(math.pi / 4);
    canvas.drawPath(_square(r), paint);

    canvas.restore();
  }

  Path _square(double r) => Path()
    ..addPolygon(
      [Offset(-r, -r), Offset(r, -r), Offset(r, r), Offset(-r, r)],
      true,
    );

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter oldDelegate) => false;
}
