import 'dart:math' as math;
import 'package:flutter/material.dart';

class CardBackView extends StatelessWidget {
  final double width;
  final double? height;
  final int? cardCountBadge;

  const CardBackView({
    super.key,
    this.width = 45,
    this.height,
    this.cardCountBadge,
  });

  double get effectiveHeight => height ?? (width * 2.0);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(width * 0.1),
      child: Container(
        width: width,
        height: effectiveHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: CardBackPainter(),
              ),
            ),
            if (cardCountBadge != null)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFFD54F),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '$cardCountBadge',
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Deep sapphire-midnight gradient
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Color(0xFF1E293B),
          Color(0xFF0F172A),
          Color(0xFF020617),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Inner gold border
    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(6)),
      borderPaint,
    );

    // Diamond geometric lattice in gold
    final linePaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    const step = 14.0;
    for (double i = -size.height; i < size.width + size.height; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), linePaint);
      canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), linePaint);
    }

    // Central emblem rosette
    final center = Offset(size.width / 2, size.height / 2);
    final rosettePaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, 12, rosettePaint);
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      canvas.drawCircle(
        Offset(center.dx + math.cos(a) * 8, center.dy + math.sin(a) * 8),
        4,
        rosettePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
