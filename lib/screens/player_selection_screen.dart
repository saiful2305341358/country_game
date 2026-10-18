import 'package:flutter/material.dart';
import '../game/card_deck_factory.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../widgets/country_card_view.dart';
import 'game_screen.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  int _selectedPlayers = 4;
  late List<CountryType> _activeTypes;

  @override
  void initState() {
    super.initState();
    _refreshActiveTypes();
  }

  void _refreshActiveTypes() {
    setState(() {
      _activeTypes = CardDeckFactory.selectActiveTypes(_selectedPlayers);
    });
  }

  void _onPlayerCountChanged(int count) {
    if (_selectedPlayers == count) return;
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    setState(() {
      _selectedPlayers = count;
      _activeTypes = CardDeckFactory.selectActiveTypes(count);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD54F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Players',
          style: TextStyle(
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'TOTAL PLAYERS & WINNING SET',
                      style: TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Win by collecting $_selectedPlayers cards of the same country (${_selectedPlayers * _selectedPlayers} country cards in deck)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Player Count Selector Cards (3, 4, 5, 6)
                    Row(
                      children: [
                        _buildPlayerCountOption(
                          3,
                          '3 Players',
                          'Win Set: 3× Cards',
                        ),
                        const SizedBox(width: 8),
                        _buildPlayerCountOption(
                          4,
                          '4 Players',
                          'Win Set: 4× Cards',
                        ),
                        const SizedBox(width: 8),
                        _buildPlayerCountOption(
                          5,
                          '5 Players',
                          'Win Set: 5× Cards',
                        ),
                        const SizedBox(width: 8),
                        _buildPlayerCountOption(
                          6,
                          '6 Players',
                          'Win Set: 6× Cards',
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Active Countries Preview Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.public,
                                color: Color(0xFFFFD54F),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Active Countries (${_activeTypes.length})',
                                style: const TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(
                              Icons.shuffle,
                              size: 14,
                              color: Color(0xFFFFD54F),
                            ),
                            label: const Text(
                              'Reroll Set',
                              style: TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 11,
                              ),
                            ),
                            onPressed: _refreshActiveTypes,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Active Countries Preview Cards with exact 2:1 aspect ratio
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final type in _activeTypes)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CountryCardView(
                                card: GameCard.ordinary(
                                  id: 'preview_${type.id}',
                                  type: type,
                                ),
                                width: 58,
                                height: 116,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.shortCode,
                                style: const TextStyle(
                                  color: Color(0xFFFFE082),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Start Game Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow, size: 24),
                        label: const Text(
                          'START GAME',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          shadowColor:
                              const Color(0xFFD97706).withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          AudioService.instance.playButtonClick();
                          HapticService.instance.uiTap();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameScreen(
                                totalPlayers: _selectedPlayers,
                                predefinedTypes: _activeTypes,
                              ),
                            ),
                          );
                        },
                      ),
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

  Widget _buildPlayerCountOption(int count, String title, String subtitle) {
    final isSelected = _selectedPlayers == count;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onPlayerCountChanged(count),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.15),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFFD700) : Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFFE082) : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
