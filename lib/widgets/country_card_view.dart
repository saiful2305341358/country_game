import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';

/// Renders modern, high-contrast Country Cards and the "Global" Starting Card
/// with tactile press compression and illegal-move recoil shake.
class CountryCardView extends StatefulWidget {
  final GameCard card;
  final bool isSelected;
  final bool isLegal;
  final bool isInteractive;
  final double width;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onIllegalTap;

  const CountryCardView({
    super.key,
    required this.card,
    this.isSelected = false,
    this.isLegal = true,
    this.isInteractive = false,
    this.width = 90,
    this.height,
    this.onTap,
    this.onIllegalTap,
  });

  double get effectiveHeight => height ?? (width * 2.0);

  @override
  State<CountryCardView> createState() => _CountryCardViewState();
}

class _CountryCardViewState extends State<CountryCardView>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleIllegalTap() {
    _shakeController.forward(from: 0.0);
    widget.onIllegalTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final width = widget.width;
    final effectiveHeight = widget.effectiveHeight;
    final isSelected = widget.isSelected || _isPressed;
    final isLifted = isSelected || _isHovered;
    final isLegal = widget.isLegal;

    final radius = (width * (14.0 / 128.0)).clamp(7.0, 18.0);
    final borderWidth = (width * (5.0 / 128.0)).clamp(2.2, 5.5);

    Widget cardBody = RepaintBoundary(
      child: Container(
        width: width,
        height: effectiveHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFC83D) : Colors.white,
            width: borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFFC83D).withValues(alpha: 0.45)
                  : const Color(0xFF140A32).withValues(alpha: 0.25),
              blurRadius: isSelected ? 22 : 24,
              offset: Offset(0, isSelected ? 4 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular((radius - borderWidth).clamp(3.0, 14.0)),
          child: Stack(
            children: [
              // Background Artwork CustomPainter cached in GPU layer
              Positioned.fill(
                child: CustomPaint(
                  painter: CardArtworkPainter(card: card),
                  isComplex: true,
                  willChange: false,
                ),
              ),

              // Modern Typography & Badge Content Overlay
              Positioned.fill(
                child: _buildCardContent(context),
              ),

              // Illegal move overlay (dimmed + clear badge)
              if (!isLegal)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.white70, width: 0.8),
                        ),
                        child: const Text(
                          'SAME TYPE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap != null && isLegal) {
      final liftY = isLifted ? -18.0 * (width / 128.0) : 0.0;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: liftY),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            builder: (context, dy, child) {
              return Transform.translate(
                offset: Offset(0, dy),
                child: child,
              );
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 110),
              scale: _isPressed ? 0.95 : 1.0,
              child: cardBody,
            ),
          ),
        ),
      );
    }

    if (!isLegal && widget.onIllegalTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleIllegalTap,
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final dx = math.sin(_shakeController.value * math.pi * 4) *
                  5.0 *
                  (1.0 - _shakeController.value);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: cardBody,
          ),
        ),
      );
    }

    return cardBody;
  }

  Widget _buildCardContent(BuildContext context) {
    final card = widget.card;
    final width = widget.width;
    final scale = (width / 90.0).clamp(0.48, 1.45);

    if (card.isStartingCard) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 5.0 * scale,
          vertical: 7.0 * scale,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top pill: WILD • STARTER
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 5 * scale,
                vertical: 1.8 * scale,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFF7DD3FC).withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'WILD • STARTER',
                  style: TextStyle(
                    color: const Color(0xFFE0F2FE),
                    fontSize: (7.5 * scale).clamp(5.5, 10.0),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),

            // Center globe emblem (no center text banner)
            Icon(
              Icons.public,
              color: const Color(0xFF38BDF8),
              size: 22 * scale,
            ),

            // Bottom subtitle: strictly GLOBAL
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'GLOBAL',
                style: TextStyle(
                  color: const Color(0xFFFDE68A),
                  fontSize: (8.0 * scale).clamp(6.0, 10.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final type = card.type!;
    final accent = type.accentColor;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 5.5 * scale,
        vertical: 6.5 * scale,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top header: crisp ISO code badge + clean native name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 4.5 * scale,
                  vertical: 1.5 * scale,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.8),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  type.shortCode,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (8.0 * scale).clamp(6.0, 10.5),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              SizedBox(width: 3 * scale),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    type.nativeName,
                    maxLines: 1,
                    style: TextStyle(
                      color: accent,
                      fontSize: (8.5 * scale).clamp(6.5, 11.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Bottom high-contrast country name banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 5 * scale,
              vertical: 4.5 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(6 * scale),
              border: Border.all(
                color: accent.withValues(alpha: 0.75),
                width: 1.0,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                type.displayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: (13.5 * scale).clamp(9.0, 17.0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: const [
                    Shadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering distinct, high-contrast vector motifs for each country
/// and the "Global" minimalist globe/topographic motif for the Starting Card.
class CardArtworkPainter extends CustomPainter {
  final GameCard card;

  const CardArtworkPainter({required this.card});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (card.isStartingCard) {
      _paintTotalWorldCard(canvas, size, rect);
      return;
    }

    final type = card.type!;

    // Vivid high-contrast background gradient unique to each country
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          type.primaryColor,
          Color.lerp(type.primaryColor, type.secondaryColor, 0.55)!,
          type.secondaryColor,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    // Subtle radial highlight at center emblem
    final center = Offset(size.width / 2, size.height * 0.44);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          type.accentColor.withValues(alpha: 0.25),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.42),
      );
    canvas.drawCircle(center, size.width * 0.42, glowPaint);

    switch (type) {
      case CountryType.australia:
        _paintAustraliaEmblem(canvas, size, center, type.accentColor);
        break;
      case CountryType.greatBritain:
        _paintGreatBritainEmblem(canvas, size, center, type.accentColor);
        break;
      case CountryType.saudiArabia:
        _paintSaudiArabiaEmblem(canvas, size, center, type.accentColor);
        break;
      case CountryType.iran:
        _paintIranEmblem(canvas, size, center, type.accentColor);
        break;
      case CountryType.japan:
        _paintJapanEmblem(canvas, size, center, type.accentColor);
        break;
      case CountryType.bangladesh:
        _paintBangladeshEmblem(canvas, size, center, type.accentColor);
        break;
    }

    // Crisp inner card frame line
    final framePaint = Paint()
      ..color = type.accentColor.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(3.0),
        Radius.circular(size.width * 0.08),
      ),
      framePaint,
    );
  }

  void _paintTotalWorldCard(Canvas canvas, Size size, Rect rect) {
    // Deep global cosmos gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F172A),
          Color(0xFF1E1B4B),
          Color(0xFF042F2E),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final center = Offset(size.width / 2, size.height * 0.43);
    final globeRadius = size.width * 0.33;

    // Stylized topographic contour rings outside the globe
    final topoPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, globeRadius * 1.28, topoPaint);
    canvas.drawCircle(center, globeRadius * 1.48, topoPaint);

    // Main Globe Circle
    final globeStroke = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, globeRadius, globeStroke);

    // Longitude Meridians (vertical ellipses)
    final gridPaint = Paint()
      ..color = const Color(0xFF7DD3FC).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: globeRadius * 1.1,
        height: globeRadius * 2.0,
      ),
      gridPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: globeRadius * 0.45,
        height: globeRadius * 2.0,
      ),
      gridPaint,
    );

    // Latitude Parallels & Equator
    canvas.drawLine(
      Offset(center.dx - globeRadius, center.dy),
      Offset(center.dx + globeRadius, center.dy),
      globeStroke,
    );
    final latOffset = globeRadius * 0.52;
    final latHalfWidth =
        math.sqrt(globeRadius * globeRadius - latOffset * latOffset);
    canvas.drawLine(
      Offset(center.dx - latHalfWidth, center.dy - latOffset),
      Offset(center.dx + latHalfWidth, center.dy - latOffset),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - latHalfWidth, center.dy + latOffset),
      Offset(center.dx + latHalfWidth, center.dy + latOffset),
      gridPaint,
    );

    // Golden orbital unity ring
    final orbitPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: globeRadius * 2.35,
        height: globeRadius * 0.72,
      ),
      orbitPaint,
    );
    canvas.restore();
  }

  void _paintAustraliaEmblem(
    Canvas canvas,
    Size size,
    Offset center,
    Color accent,
  ) {
    // Commonwealth 7-pointed Federation Star & sunburst rays
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rOuter = size.width * 0.28;
    final rInner = size.width * 0.13;
    final path = Path();
    const points = 7;
    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? rOuter : rInner;
      final angle = (i * math.pi / points) - math.pi / 2;
      final pt = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, size.width * 0.33, paint..strokeWidth = 1.0);
  }

  void _paintGreatBritainEmblem(
    Canvas canvas,
    Size size,
    Offset center,
    Color accent,
  ) {
    // Regal Union compass rose & concentric shield rings
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final r = size.width * 0.28;
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center, r * 0.68, paint);

    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * (r * 0.25),
          center.dy + math.sin(angle) * (r * 0.25),
        ),
        Offset(
          center.dx + math.cos(angle) * r,
          center.dy + math.sin(angle) * r,
        ),
        paint,
      );
    }
  }

  void _paintSaudiArabiaEmblem(
    Canvas canvas,
    Size size,
    Offset center,
    Color accent,
  ) {
    // Rub el Hizb (two overlapping squares forming an 8-pointed star)
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final halfSide = size.width * 0.21;
    final sqRect = Rect.fromCenter(
      center: center,
      width: halfSide * 2,
      height: halfSide * 2,
    );
    canvas.drawRect(sqRect, paint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: halfSide * 2,
        height: halfSide * 2,
      ),
      paint,
    );
    canvas.restore();

    canvas.drawCircle(center, halfSide * 0.45, paint);
  }

  void _paintIranEmblem(
    Canvas canvas,
    Size size,
    Offset center,
    Color accent,
  ) {
    // Symmetric Persian turquoise geometric rosette
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final r = size.width * 0.16;
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final petalCenter = Offset(
        center.dx + math.cos(angle) * (r * 0.85),
        center.dy + math.sin(angle) * (r * 0.85),
      );
      canvas.drawCircle(petalCenter, r * 0.78, paint);
    }
    canvas.drawCircle(center, size.width * 0.31, paint);
  }

  void _paintJapanEmblem(
    Canvas canvas,
    Size size,
    Offset center,
    Color accent,
  ) {
    // Crisp Rising Sun disc & surrounding Seigaiha wave ring
    final discPaint = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.18, discPaint);

    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(center, size.width * 0.18, ringPaint);
    canvas.drawCircle(center, size.width * 0.30, ringPaint..strokeWidth = 1.0);

    for (int i = 0; i < 12; i++) {
      final angle = i * math.pi / 6;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(angle) * (size.width * 0.20),
          center.dy + math.sin(angle) * (size.width * 0.20),
        ),
        Offset(
          center.dx + math.cos(angle) * (size.width * 0.30),
          center.dy + math.sin(angle) * (size.width * 0.30),
        ),
        ringPaint,
      );
    }
  }

  void _paintBangladeshEmblem(
    Canvas canvas,
    Size size,
    Offset center,
    Color accent,
  ) {
    // Traditional Alpona lotus mandala
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final rOuter = size.width * 0.30;
    final rInner = size.width * 0.18;
    canvas.drawCircle(center, rOuter, paint);
    canvas.drawCircle(center, rInner, paint);

    for (int i = 0; i < 10; i++) {
      final angle = i * math.pi / 5;
      final petal = Offset(
        center.dx + math.cos(angle) * (size.width * 0.24),
        center.dy + math.sin(angle) * (size.width * 0.24),
      );
      canvas.drawCircle(petal, size.width * 0.055, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CardArtworkPainter oldDelegate) {
    return oldDelegate.card.id != card.id;
  }
}
