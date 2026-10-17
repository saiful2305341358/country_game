import 'package:flutter/material.dart';
import '../models/game_player.dart';
import 'card_back_view.dart';

class PlayerSeat extends StatelessWidget {
  final GamePlayer player;
  final bool isCurrentTurn;
  final bool isThinking;
  final bool isWinner;
  final bool isCompact;

  const PlayerSeat({
    super.key,
    required this.player,
    required this.isCurrentTurn,
    this.isThinking = false,
    this.isWinner = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = _getAvatarColor(player.id);
    final showTurnRing = isCurrentTurn || isThinking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      constraints: BoxConstraints(maxWidth: isCompact ? 132 : 165),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? const Color(0xFF1E293B).withValues(alpha: 0.96)
            : const Color(0xFF0F172A).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFFFD700)
              : isCurrentTurn
                  ? const Color(0xFFFFD54F)
                  : Colors.white.withValues(alpha: 0.16),
          width: isCurrentTurn ? 1.8 : 1.0,
        ),
        boxShadow: [
          if (isCurrentTurn)
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.30),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Sleek circular loading ring around Bot Avatar during their turn + Realistic Name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated circular loading ring around the avatar border during active turn
                    if (showTurnRing)
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFFD700),
                          ),
                          backgroundColor:
                              const Color(0xFFFFD54F).withValues(alpha: 0.2),
                        ),
                      ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: player.isFemale
                            ? const Color(0xFFBE185D)
                            : avatarColor,
                        border: Border.all(
                          color: showTurnRing
                              ? Colors.transparent
                              : Colors.white70,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          player.isFemale ? Icons.face_3 : Icons.face,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrentTurn
                        ? const Color(0xFFFFE082)
                        : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Hand preview: fanned card backs + card count badge (no floating Passing card text below)
          SizedBox(
            height: isCompact ? 40 : 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < player.hand.length; i++)
                  Align(
                    widthFactor: 0.44,
                    child: CardBackView(
                      width: isCompact ? 21 : 24,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white24, width: 0.7),
                  ),
                  child: Text(
                    '${player.cardCount}',
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Color _getAvatarColor(int id) {
    const palette = [
      Color(0xFF2563EB),
      Color(0xFFD97706),
      Color(0xFF059669),
      Color(0xFF7C3AED),
      Color(0xFFDC2626),
      Color(0xFF0891B2),
    ];
    return palette[id % palette.length];
  }
}
