import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../widgets/country_card_view.dart';
import '../widgets/game_logo.dart';
import '../widgets/playing_table.dart';

/// A short, ultra-lightweight 2.3-second choreographed intro sequence that plays
/// strictly once on app launch.
///
/// Designed specifically for mobile phones and low-end Android & iOS devices
/// (zero MP4/MediaCodec decoding overhead, pre-cached card layers inside
/// [RepaintBoundary]s, and pure GPU transform animations) while visually telling
/// the core game story:
///   1. A hand of 3× Japan cards + 1× mismatched Australia card faces a Japan card on the grass table.
///   2. The Australia card swaps smoothly onto the table and the table's Japan card glides into the hand.
///   3. All 4× Japan cards lock into a glowing "4 OF A KIND!" winning set with a golden star burst.
class IntroVideoScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const IntroVideoScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen>
    with SingleTickerProviderStateMixin {
  static const Cubic _swapCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const double _cardW = 84.0;
  static const double _cardH = 124.0;

  late final AnimationController _controller;

  late final Widget _japanCard0;
  late final Widget _japanCard1;
  late final Widget _japanCard3;
  late final Widget _australiaDiscardCard;
  late final Widget _japanTableCard;

  bool _playedSwapLaunchCue = false;
  bool _playedSwapLandCue = false;
  bool _playedMatchChime = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    // Pre-cache the 5 card widgets once in RepaintBoundaries so zero card widget
    // rebuilds occur during the 60fps animation on low-end mobile devices.
    _japanCard0 = _buildCachedCard('intro_jp_0', CountryType.japan);
    _japanCard1 = _buildCachedCard('intro_jp_1', CountryType.japan);
    _japanCard3 = _buildCachedCard('intro_jp_3', CountryType.japan);
    _australiaDiscardCard =
        _buildCachedCard('intro_au_2', CountryType.australia);
    _japanTableCard = _buildCachedCard('intro_jp_table', CountryType.japan);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    )
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _finishIntro();
        }
      });

    _controller.forward();
  }

  Widget _buildCachedCard(String id, CountryType type) {
    return RepaintBoundary(
      child: CountryCardView(
        card: GameCard(id: id, type: type),
        width: _cardW,
        height: _cardH,
        isLegal: true,
      ),
    );
  }

  void _onTick() {
    final t = _controller.value;
    if (!_playedSwapLaunchCue && t >= 0.28) {
      _playedSwapLaunchCue = true;
      AudioService.instance.playCardTap();
    }
    if (!_playedSwapLandCue && t >= 0.46) {
      _playedSwapLandCue = true;
      AudioService.instance.playCardPlace();
    }
    if (!_playedMatchChime && t >= 0.68) {
      _playedMatchChime = true;
      AudioService.instance.playVictory();
      HapticService.instance.cardPass();
    }
  }

  void _finishIntro() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04140E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Lightweight grass field background
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: StageLawnBackgroundPainter(),
                isComplex: true,
                willChange: false,
              ),
            ),
          ),

          // 2. Soft cinematic vignette overlay for contrast
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.95,
                  colors: [
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.60),
                  ],
                ),
              ),
            ),
          ),

          // 3. Choreographed 800x450 widescreen stage scaled via FittedBox for mobile screens
          SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 800,
                  height: 450,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return _buildChoreographedStage(_controller.value);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoreographedStage(double t) {
    // Stage coordinates (800x450) tuned for mobile landscape clarity
    const Offset leftTableSlot = Offset(304, 92);
    const Offset rightTableSlot = Offset(412, 92);

    // 4 hand card slot positions at bottom center with clean clearance above caption pill
    const List<Offset> handSlots = <Offset>[
      Offset(226, 250),
      Offset(314, 240),
      Offset(402, 240),
      Offset(490, 250),
    ];
    const List<double> handAngles = <double>[-0.14, -0.05, 0.05, 0.14];

    // Smooth stage fade-in and gentle exit fade into MainMenuScreen
    final double stageFadeIn = (t / 0.08).clamp(0.0, 1.0);
    final double stageFadeOut =
        t > 0.93 ? ((1.0 - t) / 0.07).clamp(0.0, 1.0) : 1.0;
    final double stageOpacity = (stageFadeIn * stageFadeOut).clamp(0.0, 1.0);

    // Phase 1 (0.00 -> 0.22): Cards deal/appear into position
    final double dealProgress = (t / 0.22).clamp(0.0, 1.0);
    final double dealEase = Curves.easeOutBack.transform(dealProgress);

    // Phase 2 (0.26 -> 0.46): Outgoing Australia card (slot 2) moves from handSlots[2] to rightTableSlot
    final double inRaw = ((t - 0.26) / 0.20).clamp(0.0, 1.0);
    final double inT = _swapCurve.transform(inRaw);

    // Phase 3 (0.48 -> 0.68): Previous table Japan card moves from leftTableSlot to handSlots[2]
    final double outRaw = ((t - 0.48) / 0.20).clamp(0.0, 1.0);
    final double outT = _swapCurve.transform(outRaw);

    // Phase 4 (0.68 -> 1.00): 4-of-a-Kind celebration & title reveal
    final double celebrateT = ((t - 0.68) / 0.32).clamp(0.0, 1.0);
    final double celebratePop = celebrateT > 0.0
        ? math.sin(celebrateT * math.pi).clamp(0.0, 1.0)
        : 0.0;

    final Offset discardPos = Offset.lerp(handSlots[2], rightTableSlot, inT)!;
    final double discardAngle = handAngles[2] * (1.0 - inT);

    final Offset tableJapanPos =
        Offset.lerp(leftTableSlot, handSlots[2], outT)!;
    final double tableJapanAngle = handAngles[2] * outT;

    // Dynamic story caption at bottom
    final String stepCaption;
    if (t < 0.26) {
      stepCaption = 'COLLECT MATCHING COUNTRY CARDS...';
    } else if (t < 0.68) {
      stepCaption = 'SWAP ONE CARD WITH THE TABLE...';
    } else {
      stepCaption = 'COMPLETE THE COUNTRY SET TO WIN!';
    }

    return Opacity(
      opacity: stageOpacity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Subtle tabletop card-swap zone ring behind the center table cards
          Positioned(
            left: 274,
            top: 78,
            width: 252,
            height: 152,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF06291D).withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFFD54F).withValues(alpha: 0.32),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // 2. Subtle golden aura behind the completed 4-of-a-kind hand during Act 3
          if (celebrateT > 0.0)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _IntroCelebrationBurstPainter(progress: celebrateT),
                ),
              ),
            ),

          // 3. Top Title Emblem ("COUNTRY GAME")
          Positioned(
            left: 120,
            right: 120,
            top: 14,
            child: Opacity(
              opacity: dealProgress.clamp(0.0, 1.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.85),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GameLogo(size: 24, withGlow: false),
                        const SizedBox(width: 8),
                        const Text(
                          'COUNTRY GAME',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.2,
                          ),
                        ),
                        if (celebrateT > 0.05) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '4 OF A KIND!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Hand Card 0 (Japan)
          _buildAnimatedCardLayer(
            pos: handSlots[0] + Offset(0, -10.0 * celebratePop),
            angle: handAngles[0],
            scale: dealEase + 0.05 * celebratePop,
            child: _japanCard0,
          ),

          // 5. Hand Card 1 (Japan)
          _buildAnimatedCardLayer(
            pos: handSlots[1] + Offset(0, -12.0 * celebratePop),
            angle: handAngles[1],
            scale: dealEase + 0.05 * celebratePop,
            child: _japanCard1,
          ),

          // 6. Hand Card 3 (Japan)
          _buildAnimatedCardLayer(
            pos: handSlots[3] + Offset(0, -10.0 * celebratePop),
            angle: handAngles[3],
            scale: dealEase + 0.05 * celebratePop,
            child: _japanCard3,
          ),

          // 7. Outgoing / Table Card: Keep actively moving card on top
          if (t < 0.48) ...[
            _buildAnimatedCardLayer(
              pos: tableJapanPos,
              angle: tableJapanAngle,
              scale: dealEase,
              child: _japanTableCard,
            ),
            _buildAnimatedCardLayer(
              pos: discardPos,
              angle: discardAngle,
              scale: dealEase,
              child: _australiaDiscardCard,
            ),
          ] else ...[
            _buildAnimatedCardLayer(
              pos: discardPos,
              angle: discardAngle,
              scale: 1.0,
              child: _australiaDiscardCard,
            ),
            _buildAnimatedCardLayer(
              pos: tableJapanPos + Offset(0, -12.0 * celebratePop),
              angle: tableJapanAngle,
              scale: 1.0 + 0.05 * celebratePop,
              child: _japanTableCard,
            ),
          ],

          // 8. Bottom Story Caption & Lightweight Timeline Bar
          Positioned(
            left: 160,
            right: 160,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFD54F).withValues(alpha: 0.48),
                    ),
                  ),
                  child: Text(
                    stepCaption,
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 220,
                    height: 3.5,
                    child: LinearProgressIndicator(
                      value: t.clamp(0.0, 1.0),
                      backgroundColor: Colors.black38,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFD54F),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedCardLayer({
    required Offset pos,
    required double angle,
    required double scale,
    required Widget child,
  }) {
    final clampedScale = scale.clamp(0.0, 1.15);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: _cardW,
      height: _cardH,
      child: Transform.rotate(
        angle: angle,
        child: Transform.scale(
          scale: clampedScale,
          child: child,
        ),
      ),
    );
  }
}

/// Lightweight vector burst painter for the final 4-of-a-kind reveal in the intro.
class _IntroCelebrationBurstPainter extends CustomPainter {
  final double progress;

  const _IntroCelebrationBurstPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0.0) return;

    const center = Offset(400, 304);
    final ringOpacity = (1.0 - p).clamp(0.0, 1.0);

    // Expanding golden glow ring around the matched hand
    final ringPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.55 * ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * (1.0 - 0.5 * p);
    canvas.drawCircle(center, 70.0 + p * 170.0, ringPaint);

    // 12 lightweight radial star sparks
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi * 2.0 / 12.0) - math.pi / 2.0;
      final dist = 55.0 + Curves.easeOutCubic.transform(p) * 145.0;
      final pos = Offset(
        center.dx + math.cos(angle) * dist,
        center.dy + math.sin(angle) * dist * 0.68,
      );
      final radius = (6.0 * (1.0 - p * 0.65)).clamp(1.5, 6.0);
      sparkPaint.color = (i.isEven
              ? const Color(0xFFFFD700)
              : const Color(0xFF34D399))
          .withValues(alpha: ringOpacity * 0.9);
      canvas.drawCircle(pos, radius, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IntroCelebrationBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
