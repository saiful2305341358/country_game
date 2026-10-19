import 'package:flutter/material.dart';
import '../models/card_type.dart';
import '../models/game_player.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/stats_service.dart';
import 'player_seat.dart';

/// Overlay that displays the number of games played and sets completed per player.
class PlayerStatsOverlay extends StatefulWidget {
  final List<GamePlayer>? activePlayers;
  final int? targetSetSize;
  final VoidCallback onClose;

  const PlayerStatsOverlay({
    super.key,
    this.activePlayers,
    this.targetSetSize,
    required this.onClose,
  });

  @override
  State<PlayerStatsOverlay> createState() => _PlayerStatsOverlayState();
}

class _PlayerStatsOverlayState extends State<PlayerStatsOverlay> {
  bool _confirmReset = false;

  ({CountryType? type, int count}) _getBestHandProgress(GamePlayer player) {
    CountryType? bestType;
    int bestCount = 0;
    for (final entry in player.ordinaryTypeCounts.entries) {
      if (entry.value > bestCount) {
        bestCount = entry.value;
        bestType = entry.key;
      }
    }
    return (type: bestType, count: bestCount);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StatsService.instance,
      builder: (context, _) {
        final statsService = StatsService.instance;
        final records = statsService.getAllRecords(
          activePlayers: widget.activePlayers,
        );
        final activeByName = <String, GamePlayer>{
          if (widget.activePlayers != null)
            for (final p in widget.activePlayers!) p.name: p,
        };
        final humanRecord = records.where((r) => r.isHuman).firstOrNull;
        final setSize =
            widget.targetSetSize ?? widget.activePlayers?.length ?? 4;

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availH = constraints.maxHeight;
              final isCompactH = availH < 420;

              return Center(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isCompactH ? 8 : 14,
                  ),
                  constraints: const BoxConstraints(
                    maxWidth: 660,
                    maxHeight: 500,
                  ),
                  padding: EdgeInsets.all(isCompactH ? 12 : 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.30),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.82),
                        blurRadius: 36,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Header Bar
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isCompactH ? 6 : 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFFFD54F), Color(0xFFB45309)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.leaderboard_rounded,
                              color: const Color(0xFF1E1B4B),
                              size: isCompactH ? 17 : 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PLAYER STATS & SETS COMPLETED',
                                  style: TextStyle(
                                    color: const Color(0xFFFFD700),
                                    fontSize: isCompactH ? 14 : 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                if (!isCompactH) ...[
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Games played and country sets completed per player',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Close Stats',
                            onPressed: () {
                              AudioService.instance.playButtonClick();
                              HapticService.instance.uiTap();
                              widget.onClose();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isCompactH ? 8 : 12),

                      // 2. Top Summary Metric Cards
                      Row(
                        children: [
                          _buildSummaryStatCard(
                            icon: Icons.sports_esports_rounded,
                            label: 'GAMES PLAYED',
                            value: '${statsService.totalGamesPlayed}',
                            accent: const Color(0xFF38BDF8),
                            isCompactH: isCompactH,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryStatCard(
                            icon: Icons.emoji_events_rounded,
                            label: 'TOTAL SETS COMPLETED',
                            value: '${statsService.totalSetsCompleted}',
                            accent: const Color(0xFFFFD700),
                            isCompactH: isCompactH,
                          ),
                          const SizedBox(width: 10),
                          _buildSummaryStatCard(
                            icon: Icons.auto_awesome_rounded,
                            label: 'YOUR SETS WON',
                            value: '${humanRecord?.setsCompleted ?? 0}',
                            accent: const Color(0xFF69F0AE),
                            isCompactH: isCompactH,
                          ),
                        ],
                      ),

                      SizedBox(height: isCompactH ? 8 : 12),

                      // 3. Column Headers
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                'PLAYER',
                                style: TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'GAMES PLAYED',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'SETS COMPLETED',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 5),

                      // 4. Per-Player Rows
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: records.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 5),
                          itemBuilder: (context, index) {
                            final record = records[index];
                            final livePlayer = activeByName[record.name];
                            final progress = livePlayer != null
                                ? _getBestHandProgress(livePlayer)
                                : (type: null, count: 0);

                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: isCompactH ? 5 : 7,
                              ),
                              decoration: BoxDecoration(
                                color: record.isHuman
                                    ? const Color(0xFF1E293B)
                                        .withValues(alpha: 0.95)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: record.isHuman
                                      ? const Color(0xFFFFD700)
                                          .withValues(alpha: 0.6)
                                      : Colors.white12,
                                  width: record.isHuman ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Player Avatar + Name + Current Hand Progress
                                  Expanded(
                                    flex: 5,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: isCompactH ? 30 : 34,
                                          height: isCompactH ? 30 : 34,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: record.isHuman
                                                  ? const Color(0xFFFFD700)
                                                  : const Color(0xFFBFE3A5),
                                              width: 2,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: CustomPaint(
                                              size: Size(
                                                isCompactH ? 26 : 30,
                                                isCompactH ? 26 : 30,
                                              ),
                                              painter: HtmlAvatarPainter(
                                                avatarIndex: record.avatarIndex,
                                                isMe: record.isHuman,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      record.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: record.isHuman
                                                            ? const Color(
                                                                0xFFFFF176,
                                                              )
                                                            : Colors.white,
                                                        fontSize: isCompactH
                                                            ? 12.5
                                                            : 13.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                  if (record.isHuman) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 6,
                                                        vertical: 1,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFFFD700,
                                                        ).withValues(
                                                          alpha: 0.2,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: const Text(
                                                        'YOU',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFFFFD700,
                                                          ),
                                                          fontSize: 8.5,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (progress.type != null)
                                                Text(
                                                  'In Hand: ${progress.count}/$setSize ${progress.type!.displayName}',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.65,
                                                        ),
                                                    fontSize: 10,
                                                  ),
                                                )
                                              else if (record
                                                      .lastCompletedCountry !=
                                                  null)
                                                Text(
                                                  'Last Set: ${record.lastCompletedCountry!.displayName}',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.65,
                                                        ),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Games Played per player
                                  Expanded(
                                    flex: 3,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${record.gamesPlayed}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Sets Completed per player
                                  Expanded(
                                    flex: 3,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: record.setsCompleted > 0
                                              ? const Color(0xFFFFD700)
                                                  .withValues(alpha: 0.18)
                                              : Colors.white
                                                  .withValues(alpha: 0.06),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: record.setsCompleted > 0
                                                ? const Color(0xFFFFD700)
                                                    .withValues(alpha: 0.65)
                                                : Colors.white12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.workspace_premium_rounded,
                                              size: 14,
                                              color: record.setsCompleted > 0
                                                  ? const Color(0xFFFFD700)
                                                  : Colors.white38,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${record.setsCompleted}',
                                              style: TextStyle(
                                                color: record.setsCompleted > 0
                                                    ? const Color(0xFFFFF176)
                                                    : Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      SizedBox(height: isCompactH ? 8 : 12),

                      // 5. Footer Buttons (Reset Stats & Close)
                      Row(
                        children: [
                          if (!_confirmReset)
                            OutlinedButton.icon(
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 16,
                              ),
                              label: const Text('Reset Stats'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: isCompactH ? 8 : 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                AudioService.instance.playButtonClick();
                                HapticService.instance.uiTap();
                                setState(() => _confirmReset = true);
                              },
                            )
                          else
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: const Text('Confirm Reset'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: isCompactH ? 8 : 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                AudioService.instance.playButtonClick();
                                HapticService.instance.uiTap();
                                StatsService.instance.resetStats(
                                  currentPlayers: widget.activePlayers,
                                );
                                setState(() => _confirmReset = false);
                              },
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isCompactH ? 8 : 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                AudioService.instance.playButtonClick();
                                HapticService.instance.uiTap();
                                widget.onClose();
                              },
                              child: const Text(
                                'Close Overlay',
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
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required bool isCompactH,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: isCompactH ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: accent, size: isCompactH ? 13 : 15),
                const SizedBox(width: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: accent,
                    fontSize: isCompactH ? 14.5 : 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
