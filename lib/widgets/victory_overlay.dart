import 'package:flutter/material.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_player.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import 'country_card_view.dart';

class VictoryOverlay extends StatelessWidget {
  final GamePlayer winner;
  final CountryType winningType;
  final int totalPlayers;
  final int turnCount;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;
  final VoidCallback? onViewStats;

  const VictoryOverlay({
    super.key,
    required this.winner,
    required this.winningType,
    required this.totalPlayers,
    required this.turnCount,
    required this.onPlayAgain,
    required this.onMainMenu,
    this.onViewStats,
  });

  @override
  Widget build(BuildContext context) {
    final isHuman = winner.isHuman;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availH = constraints.maxHeight;
          final isCompactH = availH < 420;

          final baseCardWidth =
              totalPlayers >= 6 ? 44.0 : (totalPlayers == 5 ? 48.0 : 52.0);
          final cardWidth = isCompactH ? (baseCardWidth * 0.84) : baseCardWidth;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isCompactH ? 8 : 14,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 580),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactH ? 18 : 24,
                  vertical: isCompactH ? 12 : 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Compact Landscape Trophy + Victory Title Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isCompactH ? 8 : 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Color(0xFFFFD54F),
                                Color(0xFFB45309),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.5),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.emoji_events,
                            color: const Color(0xFF1E1B4B),
                            size: isCompactH ? 24 : 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHuman ? 'VICTORY!' : 'GAME OVER',
                                style: TextStyle(
                                  color: isHuman
                                      ? const Color(0xFFFFD700)
                                      : const Color(0xFFFFB74D),
                                  fontSize: isCompactH ? 20 : 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isHuman
                                    ? 'You were the sole winner to collect all $totalPlayers cards of ${winningType.displayName}!'
                                    : '${winner.name} was the sole winner to collect all $totalPlayers cards of ${winningType.displayName}!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompactH ? 12 : 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isCompactH ? 10 : 14),

                    // 2. Dynamic N Winning Cards Row (strictly 2:1 ratio)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 0; i < totalPlayers; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: CountryCardView(
                                card: GameCard.ordinary(
                                  id: 'win_preview_$i',
                                  type: winningType,
                                ),
                                width: cardWidth,
                                height: cardWidth * 2.0,
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: isCompactH ? 8 : 12),

                    // 3. Dynamic Stats Badge & Leaderboard Button Row
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            'Total Turns: $turnCount  •  Winning Set: $totalPlayers× ${winningType.displayName}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFE082),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (onViewStats != null)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              AudioService.instance.playButtonClick();
                              HapticService.instance.uiTap();
                              onViewStats!();
                            },
                            icon: const Icon(
                              Icons.leaderboard_rounded,
                              size: 15,
                              color: Color(0xFFFFD54F),
                            ),
                            label: const Text(
                              'View Games Played & Sets Completed per Player',
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: isCompactH ? 10 : 14),

                    // 4. Action Buttons: Main Menu & Play Again
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              AudioService.instance.playButtonClick();
                              HapticService.instance.uiTap();
                              onMainMenu();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: EdgeInsets.symmetric(
                                vertical: isCompactH ? 9 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Main Menu'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              AudioService.instance.playButtonClick();
                              HapticService.instance.cardPass();
                              onPlayAgain();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isCompactH ? 9 : 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Play Again',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
