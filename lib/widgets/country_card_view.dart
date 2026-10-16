import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';

/// Renders high-fidelity country card fronts mirroring the uploaded images.
class CountryCardView extends StatelessWidget {
  final GameCard card;
  final bool isSelected;
  final bool isLegal;
  final bool isInteractive;
  final double width;
  final double? height;
  final VoidCallback? onTap;

  const CountryCardView({
    super.key,
    required this.card,
    this.isSelected = false,
    this.isLegal = true,
    this.isInteractive = false,
    this.width = 90,
    this.height,
    this.onTap,
  });

  double get effectiveHeight => height ?? (width * 2.0);

  @override
  Widget build(BuildContext context) {
    Widget cardBody = ClipRRect(
      borderRadius: BorderRadius.circular(width * 0.09),
      child: Container(
        width: width,
        height: effectiveHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : const Color(0xFFE5C07B).withValues(alpha: 0.6),
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? -4 : 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Artwork CustomPainter
            Positioned.fill(
              child: CustomPaint(
                painter: CardArtworkPainter(
                  card: card,
                ),
              ),
            ),

            // Content Overlay
            Positioned.fill(
              child: _buildCardContent(context),
            ),

            // Illegal move overlay (dimmed + badge)
            if (!isLegal)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white70, width: 0.8),
                      ),
                      child: const Text(
                        'RESTRICTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap != null && isLegal) {
      return GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: isSelected ? 1.05 : 1.0,
            child: cardBody,
          ),
        ),
      );
    }

    return cardBody;
  }

  Widget _buildCardContent(BuildContext context) {
    final scale = (width / 90.0).clamp(0.5, 1.4);

    if (card.isStartingCard) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0 * scale, vertical: 6.0 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore,
                color: const Color(0xFFFFD700),
                size: 28 * scale,
              ),
              SizedBox(height: 4 * scale),
              Text(
                'STARTING',
                style: TextStyle(
                  color: const Color(0xFFFFE082),
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'CARD',
                style: TextStyle(
                  color: const Color(0xFFFFD54F),
                  fontSize: 8.5 * scale,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final type = card.type!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0 * scale, vertical: 6.0 * scale),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top native name / script
          Flexible(
            child: Text(
              type.nativeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFFFFE57F).withValues(alpha: 0.95),
                fontSize: (8.5 * scale).clamp(7.0, 12.0),
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),

          // Central prominent English Name
          Flexible(
            flex: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3 * scale, vertical: 1.5 * scale),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  type.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFFFF8E1),
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom country tag
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 1.2 * scale),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(3),
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: Text(
                  type.shortCode,
                  style: TextStyle(
                    color: const Color(0xFFFFE082),
                    fontSize: (7.5 * scale).clamp(6.0, 10.0),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering the specific vector motif matching each country image.
class CardArtworkPainter extends CustomPainter {
  final GameCard card;

  const CardArtworkPainter({required this.card});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (card.isStartingCard) {
      _paintStartingCard(canvas, size, rect);
      return;
    }

    switch (card.type!) {
      case CountryType.australia:
        _paintAustralia(canvas, size, rect);
        break;
      case CountryType.greatBritain:
        _paintGreatBritain(canvas, size, rect);
        break;
      case CountryType.saudiArabia:
        _paintSaudiArabia(canvas, size, rect);
        break;
      case CountryType.iran:
        _paintIran(canvas, size, rect);
        break;
      case CountryType.japan:
        _paintJapan(canvas, size, rect);
        break;
      case CountryType.bangladesh:
        _paintBangladesh(canvas, size, rect);
        break;
    }

    // Outer card gold foil border inner bevel
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2.5), const Radius.circular(8)),
      borderPaint,
    );
  }

  void _paintStartingCard(Canvas canvas, Size size, Rect rect) {
    // Celestial deep obsidian gradient
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.1),
        radius: 1.2,
        colors: [
          Color(0xFF1E293B),
          Color(0xFF0F172A),
          Color(0xFF020617),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final goldLine = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2 - 4);

    // Orbital rings
    canvas.drawCircle(center, size.width * 0.38, goldLine);
    canvas.drawCircle(center, size.width * 0.28, goldLine);
    canvas.drawCircle(center, size.width * 0.18, goldLine);

    // 8-point compass star rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFE082).withValues(alpha: 0.35)
      ..strokeWidth = 1.2;

    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4);
      final len = (i % 2 == 0) ? size.width * 0.38 : size.width * 0.26;
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(angle) * len, center.dy + math.sin(angle) * len),
        rayPaint,
      );
    }
  }

  void _paintAustralia(Canvas canvas, Size size, Rect rect) {
    // Navy to warm golden amber gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0A192F),
          Color(0xFF1E3A5F),
          Color(0xFF8B4513),
          Color(0xFFB45309),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Aboriginal wave dot curves in gold
    final dotPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (double x = 10; x < size.width; x += 12) {
      final y1 = 25 + 10 * math.sin(x / 14);
      final y2 = size.height - 30 + 12 * math.cos(x / 14);
      canvas.drawCircle(Offset(x, y1), 1.6, dotPaint);
      canvas.drawCircle(Offset(x, y2), 1.6, dotPaint);
    }

    // Leaping kangaroo silhouette in gold
    final kangarooPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final path = Path();
    final kx = size.width * 0.62;
    final ky = size.height * 0.65;
    path.moveTo(kx, ky);
    path.quadraticBezierTo(kx + 15, ky - 20, kx + 25, ky - 10);
    path.quadraticBezierTo(kx + 20, ky + 10, kx + 10, ky + 25);
    path.quadraticBezierTo(kx - 10, ky + 30, kx - 15, ky + 20);
    path.close();
    canvas.drawPath(path, kangarooPaint);
  }

  void _paintGreatBritain(Canvas canvas, Size size, Rect rect) {
    // Regal British royal navy blue
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0F1E36),
          Color(0xFF152642),
          Color(0xFF0B1424),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Ornate Victorian Tudor rose corners
    final filigreePaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _drawOrnateCorner(canvas, const Offset(12, 12), filigreePaint);
    _drawOrnateCorner(canvas, Offset(size.width - 12, 12), filigreePaint);
    _drawOrnateCorner(canvas, Offset(12, size.height - 12), filigreePaint);
    _drawOrnateCorner(canvas, Offset(size.width - 12, size.height - 12), filigreePaint);

    // Central Lion & Unicorn heraldic watermark
    final crestPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.25, crestPaint);
  }

  void _drawOrnateCorner(Canvas canvas, Offset p, Paint paint) {
    canvas.drawCircle(p, 6, paint);
    canvas.drawArc(
      Rect.fromCircle(center: p, radius: 14),
      0,
      math.pi * 2,
      false,
      paint,
    );
  }

  void _paintSaudiArabia(Canvas canvas, Size size, Rect rect) {
    // Deep emerald green dunes palette
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF063A28),
          Color(0xFF0A4D35),
          Color(0xFF04261A),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Islamic 8-point geometric star pattern
    final starPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height * 0.45);
    final r = size.width * 0.32;
    for (int i = 0; i < 8; i++) {
      final a1 = i * math.pi / 4;
      final a2 = (i + 2) * math.pi / 4;
      canvas.drawLine(
        Offset(center.dx + math.cos(a1) * r, center.dy + math.sin(a1) * r),
        Offset(center.dx + math.cos(a2) * r, center.dy + math.sin(a2) * r),
        starPaint,
      );
    }

    // Dune curves at bottom
    final dunePaint = Paint()
      ..color = const Color(0xFFD97706).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final dune = Path();
    dune.moveTo(0, size.height * 0.8);
    dune.quadraticBezierTo(size.width * 0.5, size.height * 0.72, size.width, size.height * 0.85);
    dune.lineTo(size.width, size.height);
    dune.lineTo(0, size.height);
    dune.close();
    canvas.drawPath(dune, dunePaint);
  }

  void _paintIran(Canvas canvas, Size size, Rect rect) {
    // Persian turquoise to lapis lazuli gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF026D94),
          Color(0xFF0284C7),
          Color(0xFF0F3B5F),
          Color(0xFF0A1E36),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Persian arabesque carpet medallion
    final medallionPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final center = Offset(size.width / 2, size.height * 0.48);
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final p = Offset(center.dx + math.cos(angle) * 25, center.dy + math.sin(angle) * 25);
      canvas.drawCircle(p, 12, medallionPaint);
    }
    canvas.drawCircle(center, 28, medallionPaint);
  }

  void _paintJapan(Canvas canvas, Size size, Rect rect) {
    // Traditional Japanese vermilion crimson red
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF991B1B),
          Color(0xFF7F1D1D),
          Color(0xFF450A0A),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Seigaiha ocean waves pattern
    final wavePaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double y = 20; y < size.height; y += 22) {
      for (double x = 0; x < size.width + 20; x += 24) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(x, y), radius: 12),
          math.pi,
          math.pi,
          false,
          wavePaint,
        );
      }
    }

    // Sakura cherry blossom petals
    final sakuraPaint = Paint()
      ..color = const Color(0xFFFFE4E6).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.25), 4, sakuraPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.72), 5, sakuraPaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.28), 3.5, sakuraPaint);
  }

  void _paintBangladesh(Canvas canvas, Size size, Rect rect) {
    // Warm terracotta rust red
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF9A3412),
          Color(0xFF7C2D12),
          Color(0xFF431407),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Traditional Bengali Alpona circular mandala pattern
    final alponaPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height * 0.45);
    canvas.drawCircle(center, size.width * 0.32, alponaPaint);
    canvas.drawCircle(center, size.width * 0.22, alponaPaint);

    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final petalCenter = Offset(
        center.dx + math.cos(a) * (size.width * 0.27),
        center.dy + math.sin(a) * (size.width * 0.27),
      );
      canvas.drawCircle(petalCenter, 5, alponaPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CardArtworkPainter oldDelegate) {
    return oldDelegate.card.id != card.id;
  }
}
