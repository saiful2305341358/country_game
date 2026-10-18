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
    final cardWidth = totalPlayers >= 6 ? 46.0 : (totalPlayers == 5 ? 52.0 : 58.0);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
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
            // Trophy icon with glow
            Container(
              padding: const EdgeInsets.all(14),
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
                    color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFF1E1B4B),
                size: 38,
              ),
            ),

            const SizedBox(height: 14),

            // Victory Title
            Text(
              isHuman ? 'VICTORY!' : 'GAME OVER',
              style: TextStyle(
                color: isHuman
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFFFB74D),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            // Dynamic Winner Description
            Text(
              isHuman
                  ? 'You were the sole winner to collect all $totalPlayers cards of ${winningType.displayName}!'
                  : '${winner.name} was the sole winner to collect all $totalPlayers cards of ${winningType.displayName}!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic N Winning Cards Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < totalPlayers; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: CountryCardView(
                        card: GameCard.ordinary(
                          id: 'win_preview_$i',
                          type: winningType,
                        ),
                        width: cardWidth,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dynamic Stats Badge: ${playerCount}× [Country Name]
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                'Total Turns: $turnCount  •  Winning Set: $totalPlayers× ${winningType.displayName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            if (onViewStats != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  AudioService.instance.playButtonClick();
                  HapticService.instance.uiTap();
                  onViewStats!();
                },
                icon: const Icon(
                  Icons.leaderboard_rounded,
                  size: 16,
                  color: Color(0xFFFFD54F),
                ),
                label: const Text(
                  'View Games Played & Sets Completed per Player',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action Buttons: Main Menu & Play Again
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}
