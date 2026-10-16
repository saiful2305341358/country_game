import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../services/audio_service.dart';
import '../widgets/game_controls_dialog.dart';
import '../widgets/playing_table.dart';
import '../widgets/victory_overlay.dart';

class GameScreen extends StatefulWidget {
  final int totalPlayers;
  final List<CountryType>? predefinedTypes;

  const GameScreen({
    super.key,
    this.totalPlayers = 4,
    this.predefinedTypes,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameEngine _engine;
  bool _showIntroBanner = true;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    _engine.addListener(_onEngineUpdate);
    _startMatch();
  }

  void _startMatch() {
    _engine.startNewGame(
      totalPlayers: widget.totalPlayers,
      predefinedTypes: widget.predefinedTypes,
    );
    AudioService.instance.playExchange();

    // Auto-dismiss the country matchup banner after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() => _showIntroBanner = false);
      }
    });
  }

  void _onEngineUpdate() {
    if (!mounted) return;
    setState(() {});

    final state = _engine.state;
    if (state != null && state.isGameOver) {
      AudioService.instance.playVictory();
    }
  }

  void _onCardSelected(GameCard card) {
    AudioService.instance.playCardTake();
    final success = _engine.makeMove(card);
    if (success) {
      AudioService.instance.playCardPlace();
    }
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameControlsDialog(
        soundEnabled: AudioService.instance.isSoundEnabled,
        onSoundToggle: (val) {
          setState(() {
            AudioService.instance.isSoundEnabled = val;
          });
        },
        onResume: () => Navigator.pop(context),
        onRestart: () {
          Navigator.pop(context);
          _startMatch();
        },
        onMainMenu: () {
          Navigator.pop(context);
          _engine.leaveGame();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngineUpdate);
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _engine.state;
    if (state == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main Table
          PlayingTable(
            state: state,
            isProcessingMove: _engine.isProcessingMove,
            onCardSelected: _onCardSelected,
            onPause: _showPauseDialog,
          ),

          // Intro matchup banner at start
          if (_showIntroBanner)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showIntroBanner ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public, color: Color(0xFFFFD54F), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Match Countries: ${state.activeTypes.map((t) => t.displayName).join(" • ")}',
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Victory Overlay
          if (state.isGameOver && state.winner != null && state.winningType != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: VictoryOverlay(
                  winner: state.winner!,
                  winningType: state.winningType!,
                  turnCount: state.turnCount,
                  onPlayAgain: () {
                    AudioService.instance.playButtonClick();
                    _startMatch();
                  },
                  onMainMenu: () {
                    AudioService.instance.playButtonClick();
                    _engine.leaveGame();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
