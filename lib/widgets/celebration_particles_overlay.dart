import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/card_type.dart';

enum _ParticleKind {
  ribbon,
  star,
  spark,
  circle,
}

class _CelebrationParticle {
  final Offset origin;
  final Offset velocity;
  final Color color;
  final double size;
  final double initialAngle;
  final double angularVelocity;
  final double flutterSpeed;
  final double flutterPhase;
  final double startDelay;
  final double lifetime;
  final double gravity;
  final double drag;
  final _ParticleKind kind;

  const _CelebrationParticle({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    required this.initialAngle,
    required this.angularVelocity,
    required this.flutterSpeed,
    required this.flutterPhase,
    required this.startDelay,
    required this.lifetime,
    required this.gravity,
    required this.drag,
    required this.kind,
  });
}

/// A particle-based celebration overlay that triggers on the game screen when a player
/// completes a 'four-of-a-kind' / winning set of country cards.
///
/// Optimized for low-end mobile GPUs (pre-cached unit star path, zero per-frame allocations,
/// and zero offscreen `MaskFilter.blur` passes).
class CelebrationParticlesOverlay extends StatefulWidget {
  final CountryType? completedType;
  final Offset? burstOriginNormalized;
  final int triggerKey;
  final bool showBanner;
  final String? bannerTitle;
  final String? bannerSubtitle;

  const CelebrationParticlesOverlay({
    super.key,
    this.completedType,
    this.burstOriginNormalized,
    this.triggerKey = 0,
    this.showBanner = false,
    this.bannerTitle,
    this.bannerSubtitle,
  });

  @override
  State<CelebrationParticlesOverlay> createState() =>
      _CelebrationParticlesOverlayState();
}

class _CelebrationParticlesOverlayState
    extends State<CelebrationParticlesOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_CelebrationParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
    _particles = _generateParticles();
    _controller.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant CelebrationParticlesOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.triggerKey != widget.triggerKey ||
        oldWidget.completedType != widget.completedType) {
      _particles = _generateParticles();
      _controller.forward(from: 0.0);
    }
  }

  List<_CelebrationParticle> _generateParticles() {
    final rng = math.Random(42 + widget.triggerKey * 97);
    final type = widget.completedType;

    final palette = <Color>[
      const Color(0xFFFFD700), // Championship Gold
      const Color(0xFFFFF176), // Luminous Lemon Gold
      const Color(0xFFFFB300), // Warm Amber
      const Color(0xFFFFFFFF), // Diamond White
      const Color(0xFF69F0AE), // Celebration Mint
      const Color(0xFFFF5252), // Festive Coral Red
      const Color(0xFF40C4FF), // Sky Cyan
      if (type != null) ...[
        type.primaryColor,
        type.accentColor,
      ],
    ];

    final centerOrigin =
        widget.burstOriginNormalized ?? const Offset(0.5, 0.52);
    final list = <_CelebrationParticle>[];

    // Wave 1 (t = 0.00): Primary radial celebration burst from the completing player / center table
    for (int i = 0; i < 56; i++) {
      final angle = rng.nextDouble() * math.pi * 2.0;
      final speed = 180.0 + rng.nextDouble() * 520.0;
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed - 140.0;
      final kind = _pickKind(rng, i);

      list.add(
        _CelebrationParticle(
          origin: centerOrigin,
          velocity: Offset(vx, vy),
          color: palette[rng.nextInt(palette.length)],
          size: kind == _ParticleKind.star
              ? 11.0 + rng.nextDouble() * 9.0
              : 7.0 + rng.nextDouble() * 8.0,
          initialAngle: rng.nextDouble() * math.pi * 2.0,
          angularVelocity: (rng.nextDouble() - 0.5) * 14.0,
          flutterSpeed: 5.0 + rng.nextDouble() * 9.0,
          flutterPhase: rng.nextDouble() * math.pi * 2.0,
          startDelay: rng.nextDouble() * 0.06,
          lifetime: 0.72 + rng.nextDouble() * 0.26,
          gravity: kind == _ParticleKind.spark ? 240.0 : 460.0,
          drag: 1.6 + rng.nextDouble() * 1.1,
          kind: kind,
        ),
      );
    }

    // Wave 2 (t = 0.12): Twin celebratory confetti cannons from bottom-left & bottom-right
    for (int side = 0; side < 2; side++) {
      final isLeft = side == 0;
      final cannonOrigin = Offset(isLeft ? 0.12 : 0.88, 0.88);
      final baseAngle = isLeft ? -math.pi * 0.36 : -math.pi * 0.64;

      for (int i = 0; i < 26; i++) {
        final spread = (rng.nextDouble() - 0.5) * 0.65;
        final angle = baseAngle + spread;
        final speed = 420.0 + rng.nextDouble() * 540.0;
        final vx = math.cos(angle) * speed;
        final vy = math.sin(angle) * speed;
        final kind = _pickKind(rng, i + 20);

        list.add(
          _CelebrationParticle(
            origin: cannonOrigin,
            velocity: Offset(vx, vy),
            color: palette[rng.nextInt(palette.length)],
            size: 8.0 + rng.nextDouble() * 8.5,
            initialAngle: rng.nextDouble() * math.pi * 2.0,
            angularVelocity: (rng.nextDouble() - 0.5) * 16.0,
            flutterSpeed: 6.0 + rng.nextDouble() * 10.0,
            flutterPhase: rng.nextDouble() * math.pi * 2.0,
            startDelay: 0.10 + rng.nextDouble() * 0.08,
            lifetime: 0.75 + rng.nextDouble() * 0.22,
            gravity: 520.0,
            drag: 1.4 + rng.nextDouble() * 1.0,
            kind: kind,
          ),
        );
      }
    }

    // Wave 3 (t = 0.28): Twin upper-stage golden star & firework bursts
    const skyOrigins = [Offset(0.28, 0.26), Offset(0.72, 0.26)];
    for (final skyOrigin in skyOrigins) {
      for (int i = 0; i < 20; i++) {
        final angle = rng.nextDouble() * math.pi * 2.0;
        final speed = 120.0 + rng.nextDouble() * 360.0;
        final kind = i.isEven ? _ParticleKind.star : _ParticleKind.spark;

        list.add(
          _CelebrationParticle(
            origin: skyOrigin,
            velocity: Offset(
              math.cos(angle) * speed,
              math.sin(angle) * speed - 60.0,
            ),
            color: palette[rng.nextInt(palette.length)],
            size: kind == _ParticleKind.star
                ? 10.0 + rng.nextDouble() * 8.0
                : 6.0 + rng.nextDouble() * 5.0,
            initialAngle: rng.nextDouble() * math.pi * 2.0,
            angularVelocity: (rng.nextDouble() - 0.5) * 12.0,
            flutterSpeed: 5.0 + rng.nextDouble() * 7.0,
            flutterPhase: rng.nextDouble() * math.pi * 2.0,
            startDelay: 0.26 + rng.nextDouble() * 0.07,
            lifetime: 0.62 + rng.nextDouble() * 0.24,
            gravity: 310.0,
            drag: 2.0,
            kind: kind,
          ),
        );
      }
    }

    return list;
  }

  static _ParticleKind _pickKind(math.Random rng, int index) {
    final roll = (index + rng.nextInt(10)) % 10;
    if (roll < 5) return _ParticleKind.ribbon;
    if (roll < 7) return _ParticleKind.star;
    if (roll < 9) return _ParticleKind.spark;
    return _ParticleKind.circle;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        widget.completedType?.primaryColor ?? const Color(0xFFFFD700);
    final accentColor =
        widget.completedType?.accentColor ?? const Color(0xFFFFF176);

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            if (t >= 1.0) {
              return const SizedBox.shrink();
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _CelebrationParticlesPainter(
                    progress: t,
                    particles: _particles,
                    burstOriginNormalized: widget.burstOriginNormalized ??
                        const Offset(0.5, 0.52),
                    primaryColor: primaryColor,
                    accentColor: accentColor,
                  ),
                ),
                if (widget.showBanner &&
                    widget.bannerTitle != null &&
                    t < 0.78)
                  _buildCelebrationBanner(t, primaryColor, accentColor),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCelebrationBanner(
    double t,
    Color primaryColor,
    Color accentColor,
  ) {
    final enterT = (t / 0.14).clamp(0.0, 1.0);
    final exitT = ((0.78 - t) / 0.18).clamp(0.0, 1.0);
    final opacity = math.min(enterT, exitT).clamp(0.0, 1.0);
    final scale = 0.82 + 0.18 * Curves.elasticOut.transform(enterT);

    return Align(
      alignment: const Alignment(0.0, -0.58),
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F172A).withValues(alpha: 0.92),
                  primaryColor.withValues(alpha: 0.88),
                  const Color(0xFF0F172A).withValues(alpha: 0.92),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.55),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.bannerTitle!,
                  style: const TextStyle(
                    color: Color(0xFFFFF176),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
                if (widget.bannerSubtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.bannerSubtitle!,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationParticlesPainter extends CustomPainter {
  /// Pre-computed unit-radius 4-point star path so zero Path objects are allocated per frame.
  static final Path _unitStarPath = _createUnitStarPath();

  static Path _createUnitStarPath() {
    const double inner = 0.34 * 0.4;
    return Path()
      ..moveTo(0, -1.0)
      ..quadraticBezierTo(inner, -inner, 1.0, 0)
      ..quadraticBezierTo(inner, inner, 0, 1.0)
      ..quadraticBezierTo(-inner, inner, -1.0, 0)
      ..quadraticBezierTo(-inner, -inner, 0, -1.0)
      ..close();
  }

  final double progress;
  final List<_CelebrationParticle> particles;
  final Offset burstOriginNormalized;
  final Color primaryColor;
  final Color accentColor;

  const _CelebrationParticlesPainter({
    required this.progress,
    required this.particles,
    required this.burstOriginNormalized,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final burstCenter = Offset(
      burstOriginNormalized.dx * size.width,
      burstOriginNormalized.dy * size.height,
    );

    // 1. Expanding celebratory shockwave rings from burst origin during initial 38% of animation
    //    (rendered with layered translucent strokes — zero offscreen MaskFilter.blur passes)
    if (progress < 0.38) {
      final ringT = (progress / 0.38).clamp(0.0, 1.0);
      final easeRing = 1.0 - math.pow(1.0 - ringT, 3).toDouble();
      final maxRadius = math.min(size.width, size.height) * 0.45;
      final ringRadius = 24.0 + maxRadius * easeRing;
      final ringAlpha = (1.0 - ringT) * 0.65;

      final outerGlowRingPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: ringAlpha * 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0 * (1.0 - ringT * 0.6);
      canvas.drawCircle(burstCenter, ringRadius, outerGlowRingPaint);

      final coreRingPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: ringAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 * (1.0 - ringT * 0.6);
      canvas.drawCircle(burstCenter, ringRadius, coreRingPaint);

      final innerRingPaint = Paint()
        ..color = accentColor.withValues(alpha: ringAlpha * 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * (1.0 - ringT * 0.5);
      canvas.drawCircle(burstCenter, ringRadius * 0.78, innerRingPaint);
    }

    // Scale physics coordinates relative to a 1080p reference height
    final scale = (size.shortestSide / 680.0).clamp(0.55, 1.65);
    final paint = Paint()..style = PaintingStyle.fill;

    // 2. Render each particle along its ballistic + drag + flutter trajectory
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      if (progress < p.startDelay) continue;

      final localT = (progress - p.startDelay) / p.lifetime;
      if (localT <= 0.0 || localT >= 1.0) continue;

      // Real-time seconds elapsed for this particle (total duration ~3.4s)
      final dt = localT * p.lifetime * 3.4;

      // Exponential air-drag integration: (1 - e^(-drag * dt)) / drag
      final dragFactor = (1.0 - math.exp(-p.drag * dt)) / p.drag;
      final flutterSway =
          math.sin(dt * p.flutterSpeed + p.flutterPhase) * 18.0 * localT;

      final startX = p.origin.dx * size.width;
      final startY = p.origin.dy * size.height;

      final x = startX + (p.velocity.dx * dragFactor + flutterSway) * scale;
      final y = startY +
          (p.velocity.dy * dragFactor + 0.5 * p.gravity * dt * dt) * scale;

      // Smooth fade-in and fade-out envelope
      final fadeIn = (localT / 0.08).clamp(0.0, 1.0);
      final fadeOut = ((1.0 - localT) / 0.28).clamp(0.0, 1.0);
      final alpha = (fadeIn * fadeOut).clamp(0.0, 1.0);
      if (alpha <= 0.01) continue;

      paint.color = p.color.withValues(alpha: alpha);
      final s = p.size * scale;

      canvas.save();
      canvas.translate(x, y);
      final angle = p.initialAngle + p.angularVelocity * dt;
      canvas.rotate(angle);

      switch (p.kind) {
        case _ParticleKind.ribbon:
          // 3D tumbling ribbon effect by scaling width with cosine of flutter phase
          final tumbleScale = 0.25 +
              0.75 * math.cos(dt * p.flutterSpeed + p.flutterPhase).abs();
          final rect = Rect.fromCenter(
            center: Offset.zero,
            width: s * 1.45 * tumbleScale,
            height: s * 0.72,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(s * 0.18)),
            paint,
          );
          break;

        case _ParticleKind.star:
          canvas.scale(s, s);
          canvas.drawPath(_unitStarPath, paint);
          break;

        case _ParticleKind.spark:
          // Luminous firework spark streak
          final sparkRect = Rect.fromCenter(
            center: Offset.zero,
            width: s * 1.8,
            height: s * 0.38,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(sparkRect, Radius.circular(s * 0.2)),
            paint,
          );
          break;

        case _ParticleKind.circle:
          canvas.drawCircle(Offset.zero, s * 0.48, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.burstOriginNormalized != burstOriginNormalized ||
        oldDelegate.primaryColor != primaryColor;
  }
}
