import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import 'player_selection_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

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
              Color(0xFF0F3B2C), // Deep Emerald Felt
              Color(0xFF09251B),
              Color(0xFF03140E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo: Hand-crafted Vector Card Crest with Compass
                    _buildAppLogo(),

                    const SizedBox(height: 20),

                    // Game Title
                    const Text(
                      'COUNTRY GAME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Offline Four-of-a-Kind Card Strategy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 34),

                    // Play Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_fill, size: 26),
                        label: const Text(
                          'PLAY GAME',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                          shadowColor: const Color(0xFFD97706).withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          AudioService.instance.playButtonClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayerSelectionScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // How to Play button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.help_outline, size: 20),
                        label: const Text(
                          'HOW TO PLAY & RULES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFE082),
                          side: const BorderSide(
                            color: Color(0xFFD4AF37),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          AudioService.instance.playButtonClick();
                          _showRulesDialog(context);
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Settings Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.settings, size: 20),
                        label: const Text(
                          'SETTINGS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          AudioService.instance.playButtonClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Offline status indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.offline_pin,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '100% Offline • No Network Required',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
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
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotated cards behind
            Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 32,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1),
                ),
              ),
            ),
            Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 32,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1),
                ),
              ),
            ),
            // Center Card with Star
            Container(
              width: 34,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF991B1B),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.stars,
                  color: Color(0xFFFFD700),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.menu_book, color: Color(0xFFFFD54F)),
            SizedBox(width: 8),
            Text(
              'Game Rules',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleSection(
                title: '1. Objective',
                body:
                    'Be the first player to collect 4 cards of the same country type! Victory is immediate and automatic.',
              ),
              _RuleSection(
                title: '2. Setup & Initial Exchange',
                body:
                    'Players start with 4, 5, or 6 cards. An automatic simultaneous exchange distributes cards so every player starts with 1 card of each active country.',
              ),
              _RuleSection(
                title: '3. Starting Card (Universal Starter)',
                body:
                    'The Starting Card begins on the table. A randomly selected player takes it and discards any card from their hand. The Starting Card does NOT belong to any country and CANNOT count towards a 4-of-a-kind win.',
              ),
              _RuleSection(
                title: '4. Same-Type Exchange Restriction',
                body:
                    'On regular turns, you take the card on the table and discard a card from your hand. You CANNOT discard a card of the same country type as the card currently on the table.',
              ),
              _RuleSection(
                title: '5. Computer Opponents',
                body:
                    'Play against 3, 4, or 5 smart offline bots that strategically build pairs and sets while respecting all game rules.',
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it!'),
            onPressed: () {
              AudioService.instance.playButtonClick();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  final String title;
  final String body;

  const _RuleSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFE082),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
