import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/stats_service.dart';
import '../widgets/player_seat.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _confirmReset = false;

  static String formatDurationSeconds(int seconds) {
    if (seconds <= 0) return '--';
    if (seconds < 60) return '${seconds}s';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return secs > 0 ? '${mins}m ${secs}s' : '${mins}m';
  }

  static String getRankTitle(int wins, double winPercentage) {
    if (wins >= 15 && winPercentage >= 50) return 'Grand Global Envoy';
    if (wins >= 8) return 'Senior Ambassador';
    if (wins >= 3) return 'Skilled Diplomat';
    if (wins >= 1) return 'Rising Envoy';
    return 'New Challenger';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF0F3B2C),
              Color(0xFF09251B),
              Color(0xFF03140E),
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: StatsService.instance,
            builder: (context, _) {
              final stats = StatsService.instance;
              final humanRecord = stats.humanRecord;
              final totalGames = stats.humanGamesPlayed;
              final totalWins = stats.humanWins;
              final totalLosses = math.max(0, totalGames - totalWins);
              final winPercentage = stats.humanWinPercentage;
              final avgWinSec = stats.averageWinTimeSeconds;
              final fastestWinSec = stats.fastestWinTimeSeconds;
              final winTimes = stats.humanWinTimesSeconds;
              final rankTitle = getRankTitle(totalWins, winPercentage);

              final hasWinTimeData = winTimes.isNotEmpty;
              final displayedWinTimes = hasWinTimeData
                  ? (winTimes.length > 8
                      ? winTimes.sublist(winTimes.length - 8)
                      : winTimes)
                  : const <int>[25, 34, 42, 52, 62];

              final chartLabels = hasWinTimeData
                  ? List<String>.generate(
                      displayedWinTimes.length,
                      (idx) =>
                          'W${math.max(1, winTimes.length - displayedWinTimes.length + idx + 1)}',
                    )
                  : const <String>[
                      '3P Par',
                      '4P Par',
                      '5P Par',
                      '6P Par',
                      '7P Par'
                    ];

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Header Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.42),
                                shape: CircleBorder(
                                  side: BorderSide(
                                    color: const Color(0xFFFFD54F)
                                        .withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                ),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    AudioService.instance.playButtonClick();
                                    HapticService.instance.uiTap();
                                    Navigator.pop(context);
                                  },
                                  child: const Center(
                                    child: Icon(
                                      Icons.arrow_back_rounded,
                                      color: Color(0xFFFFD54F),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFFD700),
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: CustomPaint(
                                      size: const Size(36, 36),
                                      painter: HtmlAvatarPainter(
                                        avatarIndex: humanRecord.avatarIndex,
                                        isMe: true,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'Player Profile',
                                          style: TextStyle(
                                            color: Color(0xFFFFD700),
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '· ${humanRecord.name}',
                                          style: const TextStyle(
                                            color: Color(0xFFFFE082),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '$rankTitle · ${humanRecord.totalPoints} pts',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!_confirmReset)
                              OutlinedButton.icon(
                                onPressed: () {
                                  AudioService.instance.playButtonClick();
                                  HapticService.instance.uiTap();
                                  setState(() => _confirmReset = true);
                                },
                                icon: const Icon(Icons.refresh, size: 14),
                                label: const Text(
                                  'Reset Stats',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              )
                            else
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      AudioService.instance.playButtonClick();
                                      HapticService.instance.uiTap();
                                      StatsService.instance.resetStats();
                                      setState(() => _confirmReset = false);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                    ),
                                    child: const Text(
                                      'Confirm',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _confirmReset = false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 2. Three Primary Aggregate Stat Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildKpiCard(
                                title: 'Total Games Played',
                                value: '$totalGames',
                                valueColor: Colors.white,
                                subtitle: '$totalWins Won · $totalLosses Lost',
                                icon: Icons.sports_esports_rounded,
                                iconColor: const Color(0xFFFFD54F),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildKpiCard(
                                title: 'Win Percentage',
                                value: '${winPercentage.toStringAsFixed(1)}%',
                                valueColor: const Color(0xFF10B981),
                                subtitle: '$totalWins / $totalGames Victories',
                                icon: Icons.emoji_events_rounded,
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildKpiCard(
                                title: 'Average Win Time',
                                value: formatDurationSeconds(avgWinSec),
                                valueColor: const Color(0xFFFFD54F),
                                subtitle:
                                    'Best: ${formatDurationSeconds(fastestWinSec)} · ${winTimes.length} Timed',
                                icon: Icons.timer_outlined,
                                iconColor: const Color(0xFFFFD54F),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 3. Simple Chart & Career Breakdown Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left: Win Time Bar Chart
                            Expanded(
                              flex: 7,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.bar_chart_rounded,
                                              color: Color(0xFFFFD54F),
                                              size: 17,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              hasWinTimeData
                                                  ? 'Win Time History & Average (Seconds)'
                                                  : 'Target Win Time Benchmarks',
                                              style: const TextStyle(
                                                color: Color(0xFFFFE082),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          hasWinTimeData
                                              ? 'Avg: ${formatDurationSeconds(avgWinSec)}'
                                              : 'Win a match to plot times',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 132,
                                      child: CustomPaint(
                                        size: const Size(double.infinity, 132),
                                        painter: _WinTimeBarChartPainter(
                                          winTimes: displayedWinTimes,
                                          labels: chartLabels,
                                          avgSec: avgWinSec,
                                          fastestSec: fastestWinSec,
                                          hasActualData: hasWinTimeData,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Right: Career Summary
                            Expanded(
                              flex: 5,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A)
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37)
                                        .withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.workspace_premium_rounded,
                                          color: Color(0xFFFFD54F),
                                          size: 17,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Win Rate & Career Summary',
                                          style: TextStyle(
                                            color: Color(0xFFFFE082),
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildSummaryRow(
                                      'Sets United',
                                      '$totalWins',
                                      const Color(0xFFFFD54F),
                                    ),
                                    const Divider(
                                        color: Colors.white12, height: 14),
                                    _buildSummaryRow(
                                      'Total Score',
                                      '${humanRecord.totalPoints} pts',
                                      const Color(0xFF10B981),
                                    ),
                                    const Divider(
                                        color: Colors.white12, height: 14),
                                    _buildSummaryRow(
                                      'Fastest Victory',
                                      formatDurationSeconds(fastestWinSec),
                                      Colors.white,
                                    ),
                                    const Divider(
                                        color: Colors.white12, height: 14),
                                    _buildSummaryRow(
                                      'Last United',
                                      humanRecord.lastCompletedCountry != null
                                          ? humanRecord.lastCompletedCountry!
                                              .displayName
                                          : 'None Yet',
                                      const Color(0xFFFFE082),
                                    ),
                                  ],
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
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color valueColor,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _WinTimeBarChartPainter extends CustomPainter {
  final List<int> winTimes;
  final List<String> labels;
  final int avgSec;
  final int fastestSec;
  final bool hasActualData;

  const _WinTimeBarChartPainter({
    required this.winTimes,
    required this.labels,
    required this.avgSec,
    required this.fastestSec,
    required this.hasActualData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (winTimes.isEmpty) return;

    int maxVal = 60;
    for (final v in winTimes) {
      if (v > maxVal) maxVal = v;
    }
    if (avgSec + 10 > maxVal) maxVal = avgSec + 10;

    const double chartTop = 16.0;
    final double chartBottom = size.height - 22.0;
    final double chartHeight = math.max(20.0, chartBottom - chartTop);
    const double chartLeft = 8.0;
    final double chartRight = size.width - 8.0;
    final double chartWidth = math.max(40.0, chartRight - chartLeft);

    final Paint baselinePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(chartLeft, chartBottom),
      Offset(chartRight, chartBottom),
      baselinePaint,
    );

    final int count = winTimes.length;
    final double slotWidth = chartWidth / count;
    final double barWidth = (slotWidth * 0.52).clamp(16.0, 34.0);

    for (int i = 0; i < count; i++) {
      final int sec = winTimes[i];
      final double barHeight =
          ((sec / maxVal) * chartHeight).clamp(6.0, chartHeight);
      final double x = chartLeft + i * slotWidth + (slotWidth - barWidth) / 2;
      final double y = chartBottom - barHeight;
      final bool isFastest = hasActualData && sec == fastestSec;

      final Paint barPaint = Paint()
        ..color = !hasActualData
            ? const Color(0xFFFFD54F).withValues(alpha: 0.28)
            : isFastest
                ? const Color(0xFF10B981)
                : const Color(0xFFD97706);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(5),
        ),
        barPaint,
      );

      final TextPainter valPainter = TextPainter(
        text: TextSpan(
          text: '${sec}s',
          style: TextStyle(
            color: isFastest
                ? const Color(0xFF6EE7B7)
                : const Color(0xFFFFE082),
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valPainter.paint(
        canvas,
        Offset(x + (barWidth - valPainter.width) / 2, y - 13),
      );

      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(x + (barWidth - labelPainter.width) / 2, chartBottom + 4),
      );
    }

    if (hasActualData && avgSec > 0) {
      final double avgY = chartBottom -
          ((avgSec / maxVal) * chartHeight).clamp(0.0, chartHeight);
      final Paint avgPaint = Paint()
        ..color = const Color(0xFFFFD700)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(chartLeft, avgY),
        Offset(chartRight, avgY),
        avgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WinTimeBarChartPainter oldDelegate) {
    return oldDelegate.winTimes != winTimes ||
        oldDelegate.avgSec != avgSec ||
        oldDelegate.hasActualData != hasActualData;
  }
}
