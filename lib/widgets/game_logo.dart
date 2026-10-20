import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Official responsive vector logo for Country Card Game.
/// Combines the central GLOBAL wild-starter card, a latitude/longitude globe with a tilted
/// golden orbital ring, and three fanned country cards (Saudi Arabia Emerald, Japan Crimson,
/// and Australia Outback Gold) inside a deep navy & gold medallion.
class GameLogo extends StatelessWidget {
  final double size;
  final bool withGlow;

  const GameLogo({
    super.key,
    this.size = 96.0,
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: withGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.28),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size.square(size),
        painter: _GameLogoPainter(),
      ),
    );
  }
}

class _GameLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 256.0;
    canvas.save();
    canvas.scale(scale, scale);

    const center = Offset(128, 128);

    // 1. Outer Gold & Navy Medallion Crest
    final medallionRect = Rect.fromCircle(center: center, radius: 118);
    final medallionPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.0, -0.24),
        radius: 0.85,
        colors: [
          Color(0xFF1E293B),
          Color(0xFF0F172A),
          Color(0xFF060D1A),
        ],
        stops: [0.0, 0.58, 1.0],
      ).createShader(medallionRect);
    canvas.drawCircle(center, 118, medallionPaint);

    final goldRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF59D),
          Color(0xFFFFD700),
          Color(0xFFD97706),
          Color(0xFFF59E0B),
        ],
      ).createShader(medallionRect);
    canvas.drawCircle(center, 118, goldRimPaint);

    // Inner dashed-style compass ring
    final innerRingPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.30);
    canvas.drawCircle(center, 105, innerRingPaint);

    // 2. Left Fanned Country Card — Saudi Arabia (Emerald Green)
    _drawFannedCard(
      canvas,
      pivot: const Offset(128, 148),
      angleDeg: -22,
      localOffset: const Offset(-46, -88),
      colors: const [Color(0xFF10B981), Color(0xFF064E3B)],
      accentColor: const Color(0xFF6EE7B7),
      emblemType: 0,
    );

    // 3. Right Fanned Country Card — Australia (Outback Gold)
    _drawFannedCard(
      canvas,
      pivot: const Offset(128, 148),
      angleDeg: 22,
      localOffset: const Offset(-30, -88),
      colors: const [Color(0xFFF59E0B), Color(0xFF78350F)],
      accentColor: const Color(0xFFFDE68A),
      emblemType: 1,
    );

    // 4. Upper-Right Accent Country Card — Japan (Crimson Sun)
    _drawFannedCard(
      canvas,
      pivot: const Offset(128, 144),
      angleDeg: 8,
      localOffset: const Offset(-38, -96),
      colors: const [Color(0xFFF43F5E), Color(0xFF881337)],
      accentColor: const Color(0xFFFFE4E6),
      emblemType: 2,
    );

    // 5. Center Hero Card — GLOBAL Wild Starter Card
    canvas.save();
    canvas.translate(84, 54);
    const heroRect = Rect.fromLTWH(0, 0, 88, 132);
    final heroRRect =
        RRect.fromRectAndRadius(heroRect, const Radius.circular(12));

    canvas.drawRRect(
      heroRRect.shift(const Offset(0, 5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    canvas.drawRRect(
      heroRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF042F2E),
          ],
        ).createShader(heroRect),
    );

    canvas.drawRRect(
      heroRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF59D),
            Color(0xFFFFD700),
            Color(0xFFD97706),
          ],
        ).createShader(heroRect),
    );

    // Inner cyan frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 6, 76, 120),
        const Radius.circular(8),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.45),
    );

    // Central Stylized Globe inside Hero Card
    const globeCenter = Offset(44, 64);
    final globePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF38BDF8);
    canvas.drawCircle(globeCenter, 25, globePaint);
    canvas.drawOval(
      Rect.fromCenter(center: globeCenter, width: 26, height: 50),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.78),
    );
    canvas.drawLine(
      const Offset(19, 64),
      const Offset(69, 64),
      globePaint,
    );
    canvas.drawLine(
      const Offset(44, 39),
      const Offset(44, 89),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.75),
    );

    // Tilted Golden Orbital Ring
    canvas.save();
    canvas.translate(globeCenter.dx, globeCenter.dy);
    canvas.rotate(-22 * math.pi / 180.0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 68, height: 22),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = const Color(0xFFFFD700),
    );
    canvas.restore();
    canvas.restore();

    // 6. Forefront Championship 4-Pointed Gold Star Crest at Bottom Pedestal
    const starCenter = Offset(128, 206);
    canvas.drawCircle(
      starCenter,
      18,
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawCircle(
      starCenter,
      18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..color = const Color(0xFFFFD700),
    );

    final starPath = Path()
      ..moveTo(128, 193)
      ..lineTo(131.8, 202.2)
      ..lineTo(141, 206)
      ..lineTo(131.8, 209.8)
      ..lineTo(128, 219)
      ..lineTo(124.2, 209.8)
      ..lineTo(115, 206)
      ..lineTo(124.2, 202.2)
      ..close();
    canvas.drawPath(
      starPath,
      Paint()..color = const Color(0xFFFFD700),
    );
    canvas.drawCircle(starCenter, 2.8, Paint()..color = Colors.white);

    canvas.restore();
  }

  void _drawFannedCard(
    Canvas canvas, {
    required Offset pivot,
    required double angleDeg,
    required Offset localOffset,
    required List<Color> colors,
    required Color accentColor,
    required int emblemType,
  }) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angleDeg * math.pi / 180.0);
    canvas.translate(localOffset.dx, localOffset.dy);

    const rect = Rect.fromLTWH(0, 0, 76, 112);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );

    if (emblemType == 0) {
      // Saudi Arabia Rub el Hizb motif
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accentColor.withValues(alpha: 0.85);
      canvas.drawRect(const Rect.fromLTWH(24, 34, 28, 28), p);
    } else if (emblemType == 1) {
      // Australia star motif
      canvas.drawCircle(
        const Offset(38, 48),
        12,
        Paint()..color = accentColor.withValues(alpha: 0.45),
      );
    } else {
      // Japan crimson sun motif
      canvas.drawCircle(
        const Offset(38, 46),
        15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accentColor,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
