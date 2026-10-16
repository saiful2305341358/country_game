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

    return Container(
      constraints: BoxConstraints(maxWidth: isCompact ? 130 : 170),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? const Color(0xFF1E293B).withValues(alpha: 0.95)
            : const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner
              ? const Color(0xFFFFD700)
              : isCurrentTurn
                  ? const Color(0xFFFFD54F)
                  : Colors.white.withValues(alpha: 0.15),
          width: isCurrentTurn ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isCurrentTurn)
            BoxShadow(
              color: const Color(0xFFFFD54F).withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Avatar, Name, Thinking pill
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: player.isFemale ? const Color(0xFFBE185D) : avatarColor,
                  border: Border.all(
                    color: isCurrentTurn ? const Color(0xFFFFD700) : Colors.white70,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    player.isFemale ? Icons.face_3 : Icons.face,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Name & Home Country
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrentTurn ? const Color(0xFFFFE082) : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      player.homeType.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Bot hand preview: fanned or overlapping card backs
          SizedBox(
            height: isCompact ? 42 : 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < player.hand.length; i++)
                  Align(
                    widthFactor: 0.45,
                    child: CardBackView(
                      width: isCompact ? 32 : 40,
                      height: isCompact ? 44 : 52,
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24, width: 0.6),
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

          // Status indicator (Thinking or Active Turn)
          if (isThinking)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFFFFD54F).withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Thinking...',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else if (isCurrentTurn)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Active Turn',
                style: TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getAvatarColor(int id) {
    const palette = [
      Color(0xFF2563EB), // Human (Blue)
      Color(0xFFD97706), // Bot 1 (Amber)
      Color(0xFF059669), // Bot 2 (Emerald)
      Color(0xFF7C3AED), // Bot 3 (Violet)
      Color(0xFFDC2626), // Bot 4 (Rose)
      Color(0xFF0891B2), // Bot 5 (Cyan)
    ];
    return palette[id % palette.length];
  }
}
