import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_player.dart';

/// Renders a player avatar (`.pl`) and name badge (`.tag`) converted from the HTML table design,
/// with an animated luminous turn indicator glow around the active/exchanging player's avatar.
class PlayerSeat extends StatefulWidget {
  final GamePlayer player;
  final bool isCurrentTurn;
  final bool isThinking;
  final bool isExchanging;
  final bool isWinner;
  final bool isCompact;
  final bool isSevenPlayerMode;
  final Animation<double>? exchangeAnimation;

  const PlayerSeat({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.isThinking = false,
    this.isExchanging = false,
    this.isWinner = false,
    this.isCompact = false,
    this.isSevenPlayerMode = false,
    this.exchangeAnimation,
  });

  @override
  State<PlayerSeat> createState() => _PlayerSeatState();
}

class _PlayerSeatState extends State<PlayerSeat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turnBloomController;

  @override
  void initState() {
    super.initState();
    _turnBloomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (_isActiveGlow) {
      _turnBloomController.forward(from: 0.0);
    }
  }

  bool get _isActiveGlow =>
      widget.isCurrentTurn ||
      widget.isThinking ||
      widget.isExchanging ||
      widget.isWinner;

  @override
  void didUpdateWidget(covariant PlayerSeat oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = oldWidget.isCurrentTurn ||
        oldWidget.isThinking ||
        oldWidget.isExchanging ||
        oldWidget.isWinner;
    if (_isActiveGlow && !wasActive) {
      _turnBloomController.forward(from: 0.0);
    } else if (!_isActiveGlow && wasActive) {
      _turnBloomController.reset();
    }
  }

  @override
  void dispose() {
    _turnBloomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showTurnGlow = _isActiveGlow;
    final listenable = widget.exchangeAnimation != null
        ? Listenable.merge([_turnBloomController, widget.exchangeAnimation!])
        : _turnBloomController;

    final isSevenPlayer = widget.isSevenPlayerMode;
    final avatarDiameter = isSevenPlayer ? 104.0 : 112.0;
    final innerAvatarSize = isSevenPlayer ? 95.0 : 102.0;

    final avatarArtwork = ClipOval(
      child: CustomPaint(
        size: Size(innerAvatarSize, innerAvatarSize),
        painter: HtmlAvatarPainter(
          avatarIndex: playerId,
          isMe: widget.player.isHuman,
        ),
        isComplex: true,
        willChange: false,
      ),
    );

    return RepaintBoundary(
      child: SizedBox(
        width: 156,
        height: isSevenPlayer ? 152 : 162,
        child: AnimatedBuilder(
          animation: listenable,
          child: avatarArtwork,
          builder: (context, cachedAvatar) {
            final bloomT = _turnBloomController.value;
            final bloomBoost = math.sin(bloomT * math.pi);
            final exchangeT = widget.exchangeAnimation?.value ?? 0.0;
            final exchangeBoost = widget.isExchanging
                ? math.sin(exchangeT * math.pi).clamp(0.0, 1.0)
                : 0.0;
            final pulseIntensity =
                (0.65 + 0.35 * math.max(bloomBoost, exchangeBoost))
                    .clamp(0.0, 1.0);

            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                // 1. Radiant outer halo & luminous turn ring behind the avatar
                if (showTurnGlow)
                  Positioned(
                    top: isSevenPlayer ? -22 : -26,
                    left: isSevenPlayer ? 0 : -4,
                    width: isSevenPlayer ? 156 : 164,
                    height: isSevenPlayer ? 156 : 164,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: ActiveAvatarTurnGlowPainter(
                          intensity: pulseIntensity,
                          isExchanging: widget.isExchanging,
                          exchangeProgress: exchangeT,
                          isWinner: widget.isWinner,
                        ),
                      ),
                    ),
                  ),

                // 2. Avatar Circle with glowing multi-layered turn border & halo shadows
                Positioned(
                  top: 0,
                  child: Container(
                    width: avatarDiameter,
                    height: avatarDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: showTurnGlow
                            ? const Color(0xFFFFF176)
                            : const Color(0xFFBFE3A5),
                        width: showTurnGlow ? 5.5 : 5.0,
                      ),
                      boxShadow: [
                        const BoxShadow(
                          color: Color(0xFF2A2160),
                          spreadRadius: 3,
                          blurRadius: 0,
                        ),
                        if (showTurnGlow) ...[
                          const BoxShadow(
                            color: Color(0xFFFFC83D),
                            spreadRadius: 10,
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFD54F).withValues(
                              alpha: 0.78 * pulseIntensity,
                            ),
                            spreadRadius: 12 + 4 * pulseIntensity,
                            blurRadius: 22 + 10 * pulseIntensity,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF9800).withValues(
                              alpha: 0.48 * pulseIntensity,
                            ),
                            spreadRadius: 16 + 6 * pulseIntensity,
                            blurRadius: 34 + 12 * pulseIntensity,
                          ),
                        ],
                      ],
                    ),
                    child: cachedAvatar,
                  ),
                ),

                // 3. Subtle deliberation ("thinking") bubble shown while bot evaluates its card swap
                if (widget.isThinking &&
                    !widget.isExchanging &&
                    !widget.isWinner)
                  Positioned(
                    top: -6,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2160),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFE082),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFE082),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFE082)
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFFFE082)
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. Name tag pill (.tag)
                Positioned(
                  top: isSevenPlayer ? 111 : 120,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    decoration: BoxDecoration(
                      color: showTurnGlow
                          ? const Color(0xFFFFC83D)
                          : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: showTurnGlow
                            ? const Color(0xFF2A2160)
                            : const Color(0xFFDAD3F5),
                        width: 2,
                      ),
                      boxShadow: showTurnGlow
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFC83D).withValues(
                                  alpha: 0.72 * pulseIntensity,
                                ),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      widget.player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2A2160),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  int get playerId => widget.player.id;
}

/// Paints a soft radial golden aura and luminous turn ring around the active player's avatar.
class ActiveAvatarTurnGlowPainter extends CustomPainter {
  final double intensity;
  final bool isExchanging;
  final double exchangeProgress;
  final bool isWinner;

  const ActiveAvatarTurnGlowPainter({
    required this.intensity,
    this.isExchanging = false,
    this.exchangeProgress = 0.0,
    this.isWinner = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final outerRadius = (size.width / 2.0) * (0.94 + 0.06 * intensity);

    // 1. Soft radial bloom halo behind the avatar
    final radialRect = Rect.fromCircle(center: center, radius: outerRadius);
    final primaryGlowColor =
        isWinner ? const Color(0xFF69F0AE) : const Color(0xFFFFE082);
    final secondaryGlowColor =
        isWinner ? const Color(0xFF00E676) : const Color(0xFFFFB300);

    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryGlowColor.withValues(alpha: 0.62 * intensity),
          secondaryGlowColor.withValues(alpha: 0.36 * intensity),
          secondaryGlowColor.withValues(alpha: 0.0),
        ],
        stops: const [0.55, 0.78, 1.0],
      ).createShader(radialRect);
    canvas.drawCircle(center, outerRadius, radialPaint);

    // 2. Soft outer neon-gold ring around the chip border (zero offscreen MaskFilter.blur)
    final ringRadius = 66.0 + 2.0 * intensity;
    final outerHaloRingPaint = Paint()
      ..color = primaryGlowColor.withValues(alpha: 0.45 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0;
    canvas.drawCircle(center, ringRadius, outerHaloRingPaint);

    // 3. Crisp bright highlight ring
    final coreRingPaint = Paint()
      ..color = const Color(0xFFFFFDE7).withValues(alpha: 0.88 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawCircle(center, 65.5, coreRingPaint);

    // 4. Dynamic sweeping highlight arcs during card exchange
    if (isExchanging) {
      final arcRect = Rect.fromCircle(center: center, radius: 67.5);
      final sweepAngle = math.pi * 0.65;
      final baseAngle = -math.pi / 2.0 + (exchangeProgress * math.pi * 2.0);
      final arcPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, baseAngle, sweepAngle, false, arcPaint);
      canvas.drawArc(
          arcRect, baseAngle + math.pi, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ActiveAvatarTurnGlowPainter oldDelegate) {
    return oldDelegate.intensity != intensity ||
        oldDelegate.isExchanging != isExchanging ||
        oldDelegate.exchangeProgress != exchangeProgress ||
        oldDelegate.isWinner != isWinner;
  }
}

/// Direct Dart Canvas conversion of the HTML `avatar(i, me)` SVG generator:
/// ```js
/// const skins=['#F7C9A0','#F2B48A','#FBD9BD'],bgs=['#8CC5B7','#90CAF9','#FDE7C8','#7FD3CF','#C9B8F5'];
/// ```
class HtmlAvatarPainter extends CustomPainter {
  final int avatarIndex;
  final bool isMe;

  const HtmlAvatarPainter({
    required this.avatarIndex,
    this.isMe = false,
  });

  static const List<Color> _skins = [
    Color(0xFFF7C9A0),
    Color(0xFFF2B48A),
    Color(0xFFFBD9BD),
  ];

  static const List<Color> _bgs = [
    Color(0xFF8CC5B7),
    Color(0xFF90CAF9),
    Color(0xFFFDE7C8),
    Color(0xFF7FD3CF),
    Color(0xFFC9B8F5),
  ];

  static const List<Color> _hairs = [
    Color(0xFF4A2C1D),
    Color(0xFF2B1B12),
    Color(0xFFF2C14E),
  ];

  static const List<Color> _shirts = [
    Color(0xFF2A2160),
    Color(0xFF14909A),
    Color(0xFFFFB000),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 100.0;
    final sy = size.height / 100.0;
    canvas.save();
    canvas.scale(sx, sy);

    // 1. Background rect: <rect width="100" height="100" fill="${bg}"/>
    final bgColor =
        isMe ? const Color(0xFFBBD7F7) : _bgs[avatarIndex % _bgs.length];
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = bgColor,
    );

    // 2. Shoulders: <path d="M18 100c2-22 16-30 32-30s30 8 32 30z"/>
    final shirtColor =
        isMe ? const Color(0xFF0B47C9) : _shirts[avatarIndex % _shirts.length];
    final bodyPath = Path()
      ..moveTo(18, 100)
      ..cubicTo(20, 78, 34, 70, 50, 70)
      ..cubicTo(66, 70, 80, 78, 82, 100)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = shirtColor);

    // 3. Head circle: <circle cx="50" cy="44" r="19"/>
    final skinColor =
        isMe ? const Color(0xFF0B47C9) : _skins[avatarIndex % _skins.length];
    canvas.drawCircle(
      const Offset(50, 44),
      19,
      Paint()..color = skinColor,
    );

    if (!isMe) {
      // 4. Hair: <path d="M30 44c-2-20 12-28 22-26 12 1 20 10 18 26-4-9-10-13-20-13s-16 5-20 13z"/>
      final hairColor = _hairs[avatarIndex % _hairs.length];
      final hairPath = Path()
        ..moveTo(30, 44)
        ..cubicTo(28, 24, 42, 16, 52, 18)
        ..cubicTo(64, 19, 72, 28, 70, 44)
        ..cubicTo(66, 35, 60, 31, 50, 31)
        ..cubicTo(40, 31, 34, 36, 30, 44)
        ..close();
      canvas.drawPath(hairPath, Paint()..color = hairColor);

      // 5. Eyes: <circle cx="43" cy="46" r="2"/> <circle cx="57" cy="46" r="2"/>
      final inkPaint = Paint()..color = const Color(0xFF2A2160);
      canvas.drawCircle(const Offset(43, 46), 2, inkPaint);
      canvas.drawCircle(const Offset(57, 46), 2, inkPaint);

      // 6. Smile: <path d="M44 54q6 5 12 0" stroke="#2A2160" stroke-width="2" fill="none" stroke-linecap="round"/>
      final smilePath = Path()
        ..moveTo(44, 54)
        ..quadraticBezierTo(50, 59, 56, 54);
      final smilePaint = Paint()
        ..color = const Color(0xFF2A2160)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(smilePath, smilePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HtmlAvatarPainter oldDelegate) {
    return oldDelegate.avatarIndex != avatarIndex || oldDelegate.isMe != isMe;
  }
}
