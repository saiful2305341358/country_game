import 'package:flutter/material.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_player.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/stats_service.dart';
import 'country_card_view.dart';
import 'player_seat.dart';

class VictoryOverlay extends StatefulWidget {
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
  State<VictoryOverlay> createState() => _VictoryOverlayState();
}

class _VictoryOverlayState extends State<VictoryOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scoreProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _scoreProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winner = widget.winner;
    final winningType = widget.winningType;
    final totalPlayers = widget.totalPlayers;
    final turnCount = widget.turnCount;
    final isHuman = winner.isHuman;

    final score = StatsService.computeRoundPoints(
      totalPlayers: totalPlayers,
      turnCount: turnCount,
    );
    final record = StatsService.instance.getRecordForPlayer(winner);
    final targetTotalPoints = record.totalPoints >= score.roundPoints
        ? record.totalPoints
        : score.roundPoints;
    final previousTotalPoints =
        (targetTotalPoints - score.roundPoints).clamp(0, targetTotalPoints);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availH = constraints.maxHeight;
          final isCompactH = availH < 420;

          final baseCardWidth =
              totalPlayers >= 6 ? 42.0 : (totalPlayers == 5 ? 46.0 : 50.0);
          final cardWidth = isCompactH ? (baseCardWidth * 0.84) : baseCardWidth;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: isCompactH ? 8 : 14,
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final currentTotal = (previousTotalPoints +
                          (targetTotalPoints - previousTotalPoints) *
                              _scoreProgress.value)
                      .round();
                  final currentRound =
                      (score.roundPoints * _scoreProgress.value).round();

                  return Opacity(
                    opacity: _fadeAnim.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.82 + 0.18 * _scaleAnim.value,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 610),
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactH ? 18 : 24,
                          vertical: isCompactH ? 12 : 20,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.97),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFFFD700),
                            width: 2.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withValues(alpha: 0.38),
                              blurRadius: 34,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.85),
                              blurRadius: 42,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Winner Spotlight + Animated Total Points Card
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: isCompactH ? 52 : 62,
                                  height: isCompactH ? 52 : 62,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFFD700),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD700)
                                            .withValues(alpha: 0.55),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: CustomPaint(
                                      painter: HtmlAvatarPainter(
                                        avatarIndex: winner.id,
                                        isMe: winner.isHuman,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHuman
                                            ? 'ROUND VICTORY!'
                                            : 'ROUND COMPLETE',
                                        style: TextStyle(
                                          color: const Color(0xFFFFE082),
                                          fontSize: isCompactH ? 10 : 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Winner: ${winner.name}',
                                        style: TextStyle(
                                          color: const Color(0xFFFFD700),
                                          fontSize: isCompactH ? 18 : 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        isHuman
                                            ? 'You collected all $totalPlayers cards of ${winningType.displayName}!'
                                            : '${winner.name} collected all $totalPlayers cards of ${winningType.displayName}!',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.85),
                                          fontSize: isCompactH ? 11.5 : 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isCompactH ? 12 : 14,
                                    vertical: isCompactH ? 8 : 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700)
                                          .withValues(alpha: 0.7),
                                    ),
                                    color: const Color(0xFFFFD700)
                                        .withValues(alpha: 0.14),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'TOTAL POINTS',
                                        style: TextStyle(
                                          color: Color(0xFFFFE082),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Text(
                                        '$currentTotal PTS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isCompactH ? 18 : 22,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '+$currentRound Round Pts',
                                        style: const TextStyle(
                                          color: Color(0xFF69F0AE),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
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
                                    'Turns: $turnCount  •  Set Bonus: +${score.setBonus}  •  Speed Bonus: +${score.speedBonus}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFE082),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (widget.onViewStats != null)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      AudioService.instance.playButtonClick();
                                      HapticService.instance.uiTap();
                                      widget.onViewStats!();
                                    },
                                    icon: const Icon(
                                      Icons.leaderboard_rounded,
                                      size: 15,
                                      color: Color(0xFFFFD54F),
                                    ),
                                    label: const Text(
                                      'View Points & Sets Leaderboard',
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
                                      widget.onMainMenu();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                      side: const BorderSide(
                                        color: Colors.white24,
                                      ),
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
                                      widget.onPlayAgain();
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
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
            ),
          );
        },
      ),
    );
  }
}
