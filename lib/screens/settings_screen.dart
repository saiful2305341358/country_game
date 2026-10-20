import 'package:flutter/material.dart';
import '../models/game_settings.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _soundEnabled;
  late bool _hapticsEnabled;
  late bool _animationsEnabled;
  late int _botDelayMs;

  @override
  void initState() {
    super.initState();
    _soundEnabled = AudioService.instance.isSoundEnabled;
    _hapticsEnabled = HapticService.instance.isHapticsEnabled;
    _animationsEnabled = GameSettings.current.animationsEnabled;
    _botDelayMs = GameSettings.current.botDelayMs;
  }

  void _syncSettings() {
    GameSettings.current = GameSettings.current.copyWith(
      soundEnabled: _soundEnabled,
      hapticsEnabled: _hapticsEnabled,
      animationsEnabled: _animationsEnabled,
      botDelayMs: _botDelayMs,
    );
  }

  void _resetToDefaults() {
    setState(() {
      _soundEnabled = true;
      _hapticsEnabled = true;
      AudioService.instance.isSoundEnabled = true;
      HapticService.instance.isHapticsEnabled = true;
      _animationsEnabled = true;
      _botDelayMs = 1650;
      _syncSettings();
    });
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings restored to defaults'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04140E),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availW = constraints.maxWidth;
              final availH = constraints.maxHeight;
              final isCompactH = availH < 390;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: availW < 640 ? 16 : 24,
                    vertical: isCompactH ? 8 : 14,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Anchored Top Header Row
                        Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: 'Back',
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Color(0xFFFFD54F),
                                ),
                                onPressed: () {
                                  AudioService.instance.playButtonClick();
                                  HapticService.instance.uiTap();
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                            const Expanded(
                              child: Text(
                                'Settings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),

                        SizedBox(height: isCompactH ? 8 : 14),

                        // 2. Balanced Two-Column Landscape Cards Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              // Left Card: Audio & Haptics
                              Expanded(
                                child: _buildSettingsCard(
                                  title: 'Audio & Haptics',
                                  isCompactH: isCompactH,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: SwitchListTile(
                                        dense: isCompactH,
                                        visualDensity: isCompactH
                                            ? VisualDensity.compact
                                            : VisualDensity.standard,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Gameplay Sound Effects',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: const Text(
                                          'Soft wooden taps, subtle card slides, and victory chimes during matches',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                        secondary: Icon(
                                          _soundEnabled
                                              ? Icons.volume_up_rounded
                                              : Icons.volume_off_rounded,
                                          color: const Color(0xFFFFD54F),
                                          size: 21,
                                        ),
                                        value: _soundEnabled,
                                        activeTrackColor:
                                            const Color(0xFFFFD54F),
                                        onChanged: (val) {
                                          setState(() {
                                            _soundEnabled = val;
                                            AudioService.instance
                                                .isSoundEnabled = val;
                                            _syncSettings();
                                          });
                                          HapticService.instance.uiTap();
                                          if (val) {
                                            AudioService.instance.playCardTap();
                                          }
                                        },
                                      ),
                                    ),
                                    const Divider(
                                      color: Colors.white12,
                                      height: 12,
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: SwitchListTile(
                                        dense: isCompactH,
                                        visualDensity: isCompactH
                                            ? VisualDensity.compact
                                            : VisualDensity.standard,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Tactile Haptic Feedback',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: const Text(
                                          'Physical vibration responses for card taps, turn alerts, and victory events',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                        secondary: Icon(
                                          _hapticsEnabled
                                              ? Icons.vibration_rounded
                                              : Icons.phonelink_erase_rounded,
                                          color: const Color(0xFFFFD54F),
                                          size: 21,
                                        ),
                                        value: _hapticsEnabled,
                                        activeTrackColor:
                                            const Color(0xFFFFD54F),
                                        onChanged: (val) {
                                          setState(() {
                                            _hapticsEnabled = val;
                                            HapticService.instance
                                                .isHapticsEnabled = val;
                                            _syncSettings();
                                          });
                                          if (val) {
                                            HapticService.instance.cardPass();
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Right Card: Display & Gameplay
                              Expanded(
                                child: _buildSettingsCard(
                                  title: 'Display & Gameplay',
                                  isCompactH: isCompactH,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: SwitchListTile(
                                        dense: isCompactH,
                                        visualDensity: isCompactH
                                            ? VisualDensity.compact
                                            : VisualDensity.standard,
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Smooth Animations',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: const Text(
                                          'Initial card dealing animation and 2D card passing trajectories',
                                          style: TextStyle(
                                            color: Colors.white60,
                                            fontSize: 10,
                                          ),
                                        ),
                                        secondary: const Icon(
                                          Icons.animation,
                                          color: Color(0xFFFFD54F),
                                          size: 21,
                                        ),
                                        value: _animationsEnabled,
                                        activeTrackColor:
                                            const Color(0xFFFFD54F),
                                        onChanged: (val) {
                                          setState(() {
                                            _animationsEnabled = val;
                                            _syncSettings();
                                          });
                                          AudioService.instance.playButtonClick();
                                          HapticService.instance.uiTap();
                                        },
                                      ),
                                    ),
                                    const Divider(
                                      color: Colors.white12,
                                      height: 12,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.speed,
                                          color: Color(0xFFFFD54F),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Bot Thinking Pace',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                _botDelayMs <= 1100
                                                    ? 'Fast (1100ms)'
                                                    : _botDelayMs <= 1650
                                                        ? 'Normal (1650ms)'
                                                        : 'Relaxed (2300ms)',
                                                style: const TextStyle(
                                                  color: Color(0xFFFFD54F),
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _buildPaceButton('Fast', 1100),
                                        const SizedBox(width: 8),
                                        _buildPaceButton('Normal', 1650),
                                        const SizedBox(width: 8),
                                        _buildPaceButton('Relaxed', 2300),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                        SizedBox(height: isCompactH ? 10 : 14),

                        // 3. Reset Defaults Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Reset All Settings to Default'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white24),
                              padding: EdgeInsets.symmetric(
                                vertical: isCompactH ? 9 : 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _resetToDefaults,
                          ),
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

  Widget _buildPaceButton(String label, int ms) {
    final isSelected = _botDelayMs == ms;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AudioService.instance.playButtonClick();
          HapticService.instance.uiTap();
          setState(() {
            _botDelayMs = ms;
            _syncSettings();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFD97706)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFFD700) : Colors.white12,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required bool isCompactH,
    required List<Widget> children,
  }) {
    return Material(
      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompactH ? 12 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: isCompactH ? 6 : 8),
            ...children,
          ],
        ),
      ),
    );
  }
}
