import 'package:flutter/material.dart';
import '../services/audio_service.dart';

class GameControlsDialog extends StatefulWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  final bool soundEnabled;
  final ValueChanged<bool> onSoundToggle;

  const GameControlsDialog({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onMainMenu,
    required this.soundEnabled,
    required this.onSoundToggle,
  });

  @override
  State<GameControlsDialog> createState() => _GameControlsDialogState();
}

class _GameControlsDialogState extends State<GameControlsDialog> {
  bool _confirmRestart = false;
  bool _confirmMainMenu = false;
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _soundEnabled = widget.soundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.all(22),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.pause_circle_filled,
                  color: Color(0xFFFFD54F),
                  size: 26,
                ),
                SizedBox(width: 8),
                Text(
                  'GAME PAUSED',
                  style: TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Sound Toggle Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _soundEnabled ? Icons.volume_up : Icons.volume_off,
                        color: const Color(0xFFFFD54F),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Sound Effects',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                  Switch(
                    value: _soundEnabled,
                    activeTrackColor: const Color(0xFFFFD54F),
                    onChanged: (val) {
                      setState(() => _soundEnabled = val);
                      widget.onSoundToggle(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Resume button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Resume Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  AudioService.instance.playButtonClick();
                  widget.onResume();
                },
              ),
            ),
            const SizedBox(height: 10),

            // Restart button or confirm
            if (!_confirmRestart)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Restart Match'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD54F),
                    side: const BorderSide(color: Color(0xFFFFD54F), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    AudioService.instance.playButtonClick();
                    setState(() {
                      _confirmRestart = true;
                      _confirmMainMenu = false;
                    });
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Restart current game?',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            onPressed: () => setState(() => _confirmRestart = false),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text('Yes, Restart'),
                            onPressed: () {
                              AudioService.instance.playButtonClick();
                              widget.onRestart();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),

            // Main Menu button or confirm
            if (!_confirmMainMenu)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.home, size: 18),
                  label: const Text('Exit to Main Menu'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: () {
                    AudioService.instance.playButtonClick();
                    setState(() {
                      _confirmMainMenu = true;
                      _confirmRestart = false;
                    });
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Leave game and return to menu?',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                            onPressed: () => setState(() => _confirmMainMenu = false),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706),
                            ),
                            child: const Text('Exit'),
                            onPressed: () {
                              AudioService.instance.playButtonClick();
                              widget.onMainMenu();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
