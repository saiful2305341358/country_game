import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/stats_storage_stub.dart'
    if (dart.library.html) '../services/stats_storage_web.dart';

/// A simple, non-intrusive modal overlay that acts as a quick interactive tutorial
/// for new players, explaining how to swap cards with the table and complete a country set to win.
class TutorialModalOverlay extends StatelessWidget {
  static const String _storageKey = 'country_game_tutorial_seen_v1';

  final int targetSetSize;
  final VoidCallback onClose;

  const TutorialModalOverlay({
    super.key,
    this.targetSetSize = 4,
    required this.onClose,
  });

  /// Returns whether the player has already seen and dismissed the tutorial.
  static bool get hasSeenTutorial {
    try {
      return StatsStorage.read(_storageKey) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Marks the tutorial as seen in persistent storage.
  static void markTutorialSeen() {
    try {
      StatsStorage.write(_storageKey, 'true');
    } catch (_) {}
  }

  /// Resets the tutorial seen flag (useful for testing or re-onboarding).
  static void resetTutorialSeen() {
    try {
      StatsStorage.remove(_storageKey);
    } catch (_) {}
  }

  void _handleDismiss() {
    markTutorialSeen();
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    onClose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.54),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: GestureDetector(
          onTap: () {}, // Prevent taps inside the modal card from closing
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xF50F291E),
                    Color(0xF8091B14),
                    Color(0xFA07130E),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xFFFFD54F).withValues(alpha: 0.16),
                          border: Border.all(
                            color:
                                const Color(0xFFFFD54F).withValues(alpha: 0.6),
                          ),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFFFFD54F),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUICK TUTORIAL • HOW TO PLAY',
                              style: TextStyle(
                                color: Color(0xFFFFE082),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              'Swap cards with the table & collect a full country set to win',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        tooltip: 'Close Tutorial',
                        onPressed: _handleDismiss,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 8),

                  // Step 1: How to Swap Cards
                  _buildTutorialStep(
                    stepNumber: '1',
                    icon: Icons.swap_horiz_rounded,
                    accentColor: const Color(0xFF34D399),
                    title: 'Tap a Card to Swap with the Table',
                    description:
                        'On your turn (golden glow), tap any legal card in your hand. Your card slides onto the table first, then the previous table card slides into your hand.',
                  ),
                  const SizedBox(height: 6),

                  // Step 2: Legal Swap Rule
                  _buildTutorialStep(
                    stepNumber: '2',
                    icon: Icons.style_rounded,
                    accentColor: const Color(0xFF60A5FA),
                    title: 'Different Country Swap Rule',
                    description:
                        'You must play a different country than the card currently on the table. The special Starting Card can always be swapped.',
                  ),
                  const SizedBox(height: 6),

                  // Step 3: How to Win
                  _buildTutorialStep(
                    stepNumber: '3',
                    icon: Icons.emoji_events_rounded,
                    accentColor: const Color(0xFFFFD54F),
                    title: 'Collect $targetSetSize Matching Country Cards to Win',
                    description:
                        'Collect all $targetSetSize cards of the same country in your hand (excluding the Starting Card) to immediately win the round!',
                  ),

                  const SizedBox(height: 10),

                  // Footer row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.help_outline_rounded,
                              color: Colors.white54,
                              size: 14,
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Tap "?" anytime to reopen this guide',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _handleDismiss,
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'Got It, Let\'s Play!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialStep({
    required String stepNumber,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.65),
              ),
            ),
            child: Text(
              stepNumber,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: accentColor, size: 14),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.2,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
