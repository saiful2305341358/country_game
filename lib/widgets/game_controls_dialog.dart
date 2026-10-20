import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class GameControlsDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final VoidCallback? onShowStats;
  final VoidCallback? onShowTutorial;
  final bool soundEnabled;
  final ValueChanged<bool> onSoundToggle;
  final bool hapticsEnabled;
  final ValueChanged<bool>? onHapticsToggle;

  const GameControlsDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onMainMenu,
    this.onShowStats,
    this.onShowTutorial,
    required this.onSoundToggle,
    required this.soundEnabled,
    this.hapticsEnabled = true,
    this.onHapticsToggle,
  });

  @override
  State<GameControlsDialog> createState() => _GameControlsDialogState();
}

class _GameControlsDialogState extends State<GameControlsDialog> {
  bool _confirmRestart = false;
  bool _confirmMainMenu = false;
  late bool _soundEnabled;
  late bool _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = widget.soundEnabled;
    _hapticsEnabled = widget.hapticsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final isCompactH = screenH < 420;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isCompactH ? 8 : 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: EdgeInsets.all(isCompactH ? 14 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD4AF37),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 25,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pause_circle_filled,
                      color: const Color(0xFFFFD54F),
                      size: isCompactH ? 22 : 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GAME PAUSED',
                      style: TextStyle(
                        color: const Color(0xFFFFE082),
                        fontSize: isCompactH ? 16 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isCompactH ? 10 : 14),

                // 2. Side-by-Side Sound & Haptics Toggles for Landscape
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _soundEnabled
                                        ? Icons.volume_up
                                        : Icons.volume_off,
                                    color: const Color(0xFFFFD54F),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Sound Effects',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _soundEnabled,
                              activeTrackColor: const Color(0xFFFFD54F),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) {
                                setState(() => _soundEnabled = val);
                                HapticService.instance.uiTap();
                                widget.onSoundToggle(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _hapticsEnabled
                                        ? Icons.vibration_rounded
                                        : Icons.phonelink_erase_rounded,
                                    color: const Color(0xFFFFD54F),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  const Flexible(
                                    child: Text(
                                      'Haptic Feedback',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _hapticsEnabled,
                              activeTrackColor: const Color(0xFFFFD54F),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) {
                                setState(() => _hapticsEnabled = val);
                                HapticService.instance.isHapticsEnabled = val;
                                if (val) {
                                  HapticService.instance.cardTap();
                                }
                                widget.onHapticsToggle?.call(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isCompactH ? 10 : 14),

                // 3. Primary Resume Game Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text(
                      'Resume Game',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isCompactH ? 10 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      AudioService.instance.playButtonClick();
                      HapticService.instance.uiTap();
                      widget.onResume();
                    },
                  ),
                ),

                SizedBox(height: isCompactH ? 8 : 10),

                // 4. Restart Match & Exit to Main Menu
                if (!_confirmRestart && !_confirmMainMenu)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 17),
                          label: const Text(
                            'Restart Match',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFFD54F),
                            side: const BorderSide(
                              color: Color(0xFFFFD54F),
                              width: 1,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isCompactH ? 9 : 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            AudioService.instance.playButtonClick();
                            HapticService.instance.uiTap();
                            setState(() {
                              _confirmRestart = true;
                              _confirmMainMenu = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextButton.icon(
                          icon: const Icon(Icons.home, size: 17),
                          label: const Text(
                            'Exit to Main Menu',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                            padding: EdgeInsets.symmetric(
                              vertical: isCompactH ? 9 : 11,
                            ),
                          ),
                          onPressed: () {
                            AudioService.instance.playButtonClick();
                            HapticService.instance.uiTap();
                            setState(() {
                              _confirmMainMenu = true;
                              _confirmRestart = false;
                            });
                          },
                        ),
                      ),
                    ],
                  )
                else if (_confirmRestart)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Restart current game?',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onPressed: () {
                            HapticService.instance.uiTap();
                            setState(() => _confirmRestart = false);
                          },
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Yes, Restart'),
                          onPressed: () {
                            AudioService.instance.playButtonClick();
                            HapticService.instance.cardPass();
                            widget.onRestart();
                          },
                        ),
                      ],
                    ),
                  )
                else if (_confirmMainMenu)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Leave game and return to menu?',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        TextButton(
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white70),
                          ),
                          onPressed: () {
                            HapticService.instance.uiTap();
                            setState(() => _confirmMainMenu = false);
                          },
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Exit'),
                          onPressed: () {
                            AudioService.instance.playButtonClick();
                            HapticService.instance.uiTap();
                            widget.onMainMenu();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dedicated, lightweight Exit Confirmation Dialog shown ONLY when the Back button is pressed.
class ExitConfirmationDialog extends StatefulWidget {
  final VoidCallback onStayInGame;
  final VoidCallback onExitGame;

  const ExitConfirmationDialog({
    super.key,
    required this.onStayInGame,
    required this.onExitGame,
  });

  @override
  State<ExitConfirmationDialog> createState() => _ExitConfirmationDialogState();
}

class _ExitConfirmationDialogState extends State<ExitConfirmationDialog> {
  bool _isProcessingExit = false;

  void _handleStay() {
    if (_isProcessingExit) return;
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    widget.onStayInGame();
  }

  void _handleExit() {
    if (_isProcessingExit) return;
    setState(() => _isProcessingExit = true);
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    widget.onExitGame();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final isCompactH = screenH < 420;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isCompactH ? 8 : 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          padding: EdgeInsets.all(isCompactH ? 16 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.72),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD97706).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFFFFD54F).withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFFFD54F),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leave Game?',
                          style: TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Match in Progress',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to leave this match? Your current game progress may be lost.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text(
                        'Stay in Game',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isCompactH ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isProcessingExit ? null : _handleStay,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text(
                        'Exit Game',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFE082),
                        backgroundColor:
                            const Color(0xFFD97706).withValues(alpha: 0.15),
                        side: BorderSide(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.65),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isCompactH ? 10 : 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isProcessingExit ? null : _handleExit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

