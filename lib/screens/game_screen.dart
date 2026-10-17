import 'package:flutter/material.dart';
import '../game/game_engine.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_settings.dart';
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

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final GameEngine _engine;
  late final AnimationController _dealingController;

  bool _isDealing = false;
  int _lastTurnCount = 0;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(initialSettings: GameSettings.current);
    _engine.addListener(_onEngineUpdate);

    _dealingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _isDealing = false);
          _engine.resumeActivePlay();
        }
      });

    _startMatch();
  }

  void _startMatch() {
    final animateDeal = GameSettings.current.animationsEnabled;
    _lastTurnCount = 0;

    _engine.updateSettings(GameSettings.current);
    _engine.startNewGame(
      totalPlayers: widget.totalPlayers,
      predefinedTypes: widget.predefinedTypes,
      deferBotStart: animateDeal,
    );

    // Subtle, crisp startup chime on Game Start
    AudioService.instance.playGameStart();

    if (animateDeal) {
      setState(() => _isDealing = true);
      _dealingController.forward(from: 0.0);
    } else {
      setState(() => _isDealing = false);
    }
  }

  void _onEngineUpdate() {
    if (!mounted) return;
    final state = _engine.state;

    if (state != null && state.turnCount > _lastTurnCount) {
      final wasBotMove = state.lastMovePlayerIndex != null &&
          state.lastMovePlayerIndex != 0;
      _lastTurnCount = state.turnCount;

      if (state.isGameOver) {
        if (state.winner?.isHuman == true) {
          // Charming, rewarding, uplifting sound when user wins
          AudioService.instance.playVictory();
        } else {
          // Distinct audio cue signaling the round has concluded
          AudioService.instance.playGameEnd();
        }
      } else if (wasBotMove) {
        // Subtle wooden tap + slide feedback for bot card passing
        AudioService.instance.playCardPlace();
      }
    }

    setState(() {});
  }

  void _onCardSelected(GameCard card) {
    if (_isDealing) return;
    AudioService.instance.playCardTake();
    final success = _engine.makeMove(card);
    if (success) {
      AudioService.instance.playCardPlace();
    }
  }

  void _toggleSoundFromHud() {
    final nextVal = !AudioService.instance.isSoundEnabled;
    setState(() {
      AudioService.instance.isSoundEnabled = nextVal;
      GameSettings.current = GameSettings.current.copyWith(
        soundEnabled: nextVal,
      );
    });
    if (nextVal) {
      AudioService.instance.playButtonClick();
    }
  }

  void _showPauseDialog() {
    _engine.pauseActivePlay();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameControlsDialog(
        soundEnabled: AudioService.instance.isSoundEnabled,
        onSoundToggle: (val) {
          setState(() {
            AudioService.instance.isSoundEnabled = val;
            GameSettings.current = GameSettings.current.copyWith(
              soundEnabled: val,
            );
          });
          if (val) {
            AudioService.instance.playButtonClick();
          }
        },
        onResume: () {
          Navigator.pop(context);
          if (!_isDealing) {
            _engine.resumeActivePlay();
          }
        },
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
    _dealingController.dispose();
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
          // Main Playing Table with Dealing & Passing Animations
          AnimatedBuilder(
            animation: _dealingController,
            builder: (context, _) {
              return PlayingTable(
                state: state,
                isProcessingMove: _engine.isProcessingMove,
                isDealing: _isDealing,
                dealingProgress: _dealingController.value,
                soundEnabled: AudioService.instance.isSoundEnabled,
                onToggleSound: _toggleSoundFromHud,
                animationsEnabled: GameSettings.current.animationsEnabled,
                onCardSelected: _onCardSelected,
                onPause: _showPauseDialog,
              );
            },
          ),

          // Victory Overlay
          if (state.isGameOver &&
              state.winner != null &&
              state.winningType != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: VictoryOverlay(
                  winner: state.winner!,
                  winningType: state.winningType!,
                  totalPlayers: state.totalPlayers,
                  turnCount: state.turnCount,
                  onPlayAgain: _startMatch,
                  onMainMenu: () {
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
