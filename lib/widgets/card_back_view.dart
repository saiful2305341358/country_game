import 'dart:math' as math;
import 'package:flutter/material.dart';

class CardBackView extends StatelessWidget {
  final double width;
  final double? height;
  final int? cardCountBadge;
  final bool showStackShadow;

  const CardBackView({
    super.key,
    this.width = 112,
    this.height,
    this.cardCountBadge,
    this.showStackShadow = false,
  });

  double get effectiveHeight => height ?? (width * (164.0 / 112.0));

  @override
  Widget build(BuildContext context) {
    final h = effectiveHeight;
    final radius = (width * (14.0 / 112.0)).clamp(5.0, 18.0);
    final borderWidth = (width * (5.0 / 112.0)).clamp(1.8, 6.0);

    return RepaintBoundary(
      child: Container(
        width: width,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2160),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white,
            width: borderWidth,
          ),
          boxShadow: [
            if (showStackShadow)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                offset: const Offset(4, 4),
                blurRadius: 0,
              ),
            BoxShadow(
              color: const Color(0xFF140A46).withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular((radius - borderWidth).clamp(2.0, 14.0)),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(
                  painter: CardBackPainter(),
                  isComplex: true,
                  willChange: false,
                ),
              ),
              if (cardCountBadge != null)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2160).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFC83D),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      '$cardCountBadge',
                      style: const TextStyle(
                        color: Color(0xFFFFC83D),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the exact `.pile.back` design from the HTML specification:
/// `#2A2160` background with a `#FFC83D` oval inset (`34px 12px` on `112x164`) rotated `-20deg`.
class CardBackPainter extends CustomPainter {
  const CardBackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF2A2160);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final insetX = size.width * (12.0 / 112.0);
    final insetY = size.height * (34.0 / 164.0);
    final ovalRect = Rect.fromLTRB(
      insetX,
      insetY,
      size.width - insetX,
      size.height - insetY,
    );

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-20.0 * math.pi / 180.0);
    canvas.translate(-size.width / 2, -size.height / 2);

    final ovalPaint = Paint()
      ..color = const Color(0xFFFFC83D)
      ..style = PaintingStyle.fill;
    canvas.drawOval(ovalRect, ovalPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
