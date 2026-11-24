import 'package:material_ui/material_ui.dart';

/// Background shared by the menu screens (same colours as the original home screen).
const BoxDecoration menuBackgroundDecoration = BoxDecoration(
  gradient: RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [
      Color(0xFF0F3B2C),
      Color(0xFF09251B),
      Color(0xFF03140E),
    ],
  ),
);

/// Brand colours used by the menu screens.
abstract final class MenuColors {
  static const Color gold = Color(0xFFFFD700);
  static const Color goldBorder = Color(0xFFD4AF37);
  static const Color goldText = Color(0xFFFFE082);
  static const Color amber = Color(0xFFD97706);
  static const Color emerald = Color(0xFF10B981);
}

/// A large, tappable option tile used for choosing a game mode.
///
/// [primary] tiles are filled with the brand amber; others are outlined with
/// [accent]. A [badge] (e.g. "Coming soon") is shown in the top-right corner,
/// and [dimmed] tiles are drawn faded but stay tappable so they can explain why.
///
/// Place tiles in a `ModeCardRow` so they share the height of the tallest one.
class ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;
  final bool primary;
  final bool dimmed;
  final String? badge;
  final bool compact;
  final VoidCallback onTap;

  const ModeCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent = MenuColors.goldBorder,
    this.primary = false,
    this.dimmed = false,
    this.badge,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final foreground = primary ? Colors.white : MenuColors.goldText;

    final card = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: primary ? MenuColors.amber : accent.withValues(alpha: 0.08),
          border: Border.all(
            color: primary ? MenuColors.gold.withValues(alpha: 0.55) : accent,
            width: 1.3,
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: MenuColors.amber.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: compact ? 10 : 14,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 36 : 44,
                  height: compact ? 36 : 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary
                        ? Colors.white.withValues(alpha: 0.18)
                        : accent.withValues(alpha: 0.16),
                  ),
                  child: Icon(
                    icon,
                    color: primary ? Colors.white : accent,
                    size: compact ? 20 : 24,
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: compact ? 11.5 : 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground.withValues(alpha: 0.72),
                      fontSize: compact ? 9.5 : 10.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        // The card sizes the tile (so it grows to fit its text); the badge floats on top.
        Opacity(opacity: dimmed ? 0.55 : 1.0, child: card),
        if (badge != null)
          Positioned(
            top: -8,
            right: 8,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: MenuColors.goldBorder),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: MenuColors.goldText,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A row of [ModeCard]s that all take the height of the tallest card (never less
/// than [minHeight]), so wrapped titles grow the row instead of overflowing.
class ModeCardRow extends StatelessWidget {
  final List<Widget> children;
  final double minHeight;
  final double gap;

  const ModeCardRow({
    super.key,
    required this.children,
    this.minHeight = 0,
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: children[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small outlined button for secondary menu actions (rules, settings, stats).
class MenuUtilityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const MenuUtilityButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: MenuColors.goldText,
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.22),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: onPressed,
    );
  }
}

/// Shows a short "coming soon"-style message at the bottom of the screen.
void showMenuNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}
