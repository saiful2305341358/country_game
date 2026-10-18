import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_engine.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/stats_service.dart';
import '../widgets/celebration_particles_overlay.dart';
import '../widgets/game_controls_dialog.dart';
import '../widgets/player_stats_overlay.dart';
import '../widgets/playing_table.dart';
import '../widgets/tutorial_modal_overlay.dart';
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
  bool _showStatsOverlay = false;
  bool _showTutorialOverlay = false;
  bool _tutorialPausedEngine = false;
  bool _hasRecordedWinningSetForMatch = false;
  int _lastTurnCount = 0;

  // Celebration particle state triggered strictly when a player completes a winning set
  bool _showCelebrationParticles = false;
  int _celebrationTriggerKey = 0;
  CountryType? _celebrationCountryType;
  Offset _celebrationOriginNormalized = const Offset(0.5, 0.52);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Ensure GameSettings reflects saved AudioService preference
    GameSettings.current = GameSettings.current.copyWith(
      soundEnabled: AudioService.instance.isSoundEnabled,
    );

    _engine = GameEngine(
      initialSettings: GameSettings.current,
      waitForExchangeAnimation: true,
    );
    _engine.addListener(_onEngineUpdate);

    _dealingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _isDealing = false);
          if (_engine.state?.isHumanTurn == true) {
            HapticService.instance.yourTurnNotice();
          }
          if (!_showStatsOverlay && !_tutorialPausedEngine) {
            _engine.resumeActivePlay();
          }
        }
      });

    // Show non-intrusive tutorial overlay automatically for first-time players
    if (!TutorialModalOverlay.hasSeenTutorial) {
      _showTutorialOverlay = true;
      _tutorialPausedEngine = false;
      TutorialModalOverlay.markTutorialSeen();
    }

    _startMatch();
  }

  void _startMatch() {
    final animateDeal = GameSettings.current.animationsEnabled;
    _lastTurnCount = 0;
    _showStatsOverlay = false;
    _hasRecordedWinningSetForMatch = false;
    _showCelebrationParticles = false;

    _engine.updateSettings(GameSettings.current);
    _engine.startNewGame(
      totalPlayers: widget.totalPlayers,
      predefinedTypes: widget.predefinedTypes,
      deferBotStart: animateDeal,
    );

    if (_engine.state != null) {
      StatsService.instance.recordGameStarted(_engine.state!.players);
    }

    // Physical card dealing riffle + shuffle haptic pulse on Game Start
    if (animateDeal) {
      AudioService.instance.playExchange();
    } else {
      AudioService.instance.playGameStart();
    }
    HapticService.instance.dealShuffle();

    if (animateDeal) {
      setState(() => _isDealing = true);
      _dealingController.forward(from: 0.0);
    } else {
      setState(() => _isDealing = false);
      if (_engine.state?.isHumanTurn == true) {
        HapticService.instance.yourTurnNotice();
      }
    }
  }

  void _onEngineUpdate() {
    if (!mounted) return;
    final state = _engine.state;

    if (state != null && state.turnCount > _lastTurnCount) {
      final wasBotMove = state.lastMovePlayerIndex != null &&
          state.lastMovePlayerIndex != 0;
      _lastTurnCount = state.turnCount;

      if (wasBotMove) {
        // Physical card flick when bot initiates an exchange (Phase 2 launch)
        AudioService.instance.playCardTap();
      }

      // If animations are disabled, trigger landing + post-exchange cues immediately
      if (!_engine.isExchangeAnimating) {
        AudioService.instance.playCardPlace();
        _triggerPostExchangeCues(state, wasBotMove: wasBotMove);
      }
    }

    setState(() {});
  }

  void _onExchangeAnimationComplete() {
    if (!mounted) return;
    final state = _engine.state;
    final wasBotMove = state?.lastMovePlayerIndex != null &&
        state?.lastMovePlayerIndex != 0;

    _engine.completeExchangeAnimation();

    if (state != null) {
      _triggerPostExchangeCues(state, wasBotMove: wasBotMove);
    }
  }

  /// Computes the normalized (0..1) stage coordinate for a player's seat so celebration
  /// particles burst directly from the player who completed the set.
  Offset _getNormalizedSeatOrigin(int playerIndex, int totalPlayers) {
    if (playerIndex == 0) {
      return const Offset(0.50, 0.76);
    }
    final opponentIdx = playerIndex - 1;
    if (totalPlayers == 3) {
      const seats = [
        Offset(450 / 1920, 380 / 1080),
        Offset(1470 / 1920, 380 / 1080),
      ];
      return seats[opponentIdx % seats.length];
    } else if (totalPlayers == 4) {
      const seats = [
        Offset(380 / 1920, 540 / 1080),
        Offset(960 / 1920, 110 / 1080),
        Offset(1540 / 1920, 540 / 1080),
      ];
      return seats[opponentIdx % seats.length];
    } else if (totalPlayers == 5) {
      const seats = [
        Offset(401 / 1920, 762 / 1080),
        Offset(548 / 1920, 313 / 1080),
        Offset(1372 / 1920, 313 / 1080),
        Offset(1519 / 1920, 762 / 1080),
      ];
      return seats[opponentIdx % seats.length];
    } else {
      const seats = [
        Offset(401 / 1920, 762 / 1080),
        Offset(548 / 1920, 313 / 1080),
        Offset(960 / 1920, 88 / 1080),
        Offset(1372 / 1920, 313 / 1080),
        Offset(1519 / 1920, 762 / 1080),
      ];
      return seats[opponentIdx % seats.length];
    }
  }

  void _triggerPostExchangeCues(
    GameState state, {
    required bool wasBotMove,
  }) {
    // Strictly trigger Victory / Game Over audio and particle celebration ONLY when the game actually ends
    if (state.isGameOver && state.winner != null && state.winningType != null) {
      final winner = state.winner!;
      final winningType = state.winningType!;

      if (!_hasRecordedWinningSetForMatch) {
        _hasRecordedWinningSetForMatch = true;
        StatsService.instance.recordSetCompleted(winner, winningType);
      }

      setState(() {
        _showCelebrationParticles = true;
        _celebrationTriggerKey++;
        _celebrationCountryType = winningType;
        _celebrationOriginNormalized = _getNormalizedSeatOrigin(
          winner.id,
          state.totalPlayers,
        );
      });

      if (winner.isHuman) {
        AudioService.instance.playVictory();
        HapticService.instance.victory();
      } else {
        AudioService.instance.playGameEnd();
        HapticService.instance.roundEnd();
      }
      return;
    }

    if (wasBotMove) {
      if (state.isHumanTurn) {
        HapticService.instance.yourTurnNotice();
      } else {
        HapticService.instance.botTurnTick();
      }
    }
  }

  void _onCardSelected(GameCard card) {
    if (_isDealing || _engine.isProcessingMove) return;
    final success = _engine.makeMove(card);
    if (success) {
      HapticService.instance.cardPass();
    } else {
      HapticService.instance.invalidMove();
    }
  }

  void _openStatsOverlay() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    _engine.pauseActivePlay();
    setState(() {
      _showTutorialOverlay = false;
      _showStatsOverlay = true;
    });
  }

  void _closeStatsOverlay() {
    setState(() => _showStatsOverlay = false);
    if (!_isDealing &&
        !_showTutorialOverlay &&
        _engine.state?.isGameOver != true) {
      _engine.resumeActivePlay();
    }
  }

  void _openTutorialOverlay() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    _engine.pauseActivePlay();
    setState(() {
      _showStatsOverlay = false;
      _showTutorialOverlay = true;
      _tutorialPausedEngine = true;
    });
  }

  void _closeTutorialOverlay() {
    final wasPausedByTutorial = _tutorialPausedEngine;
    setState(() {
      _showTutorialOverlay = false;
      _tutorialPausedEngine = false;
    });
    if (wasPausedByTutorial &&
        !_isDealing &&
        !_showStatsOverlay &&
        _engine.state?.isGameOver != true) {
      _engine.resumeActivePlay();
    }
  }

  void _showPauseDialog() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    _engine.pauseActivePlay();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameControlsDialog(
        soundEnabled: AudioService.instance.isSoundEnabled,
        hapticsEnabled: HapticService.instance.isHapticsEnabled,
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
        onHapticsToggle: (val) {
          setState(() {
            HapticService.instance.isHapticsEnabled = val;
            GameSettings.current = GameSettings.current.copyWith(
              hapticsEnabled: val,
            );
          });
        },
        onShowStats: () {
          Navigator.pop(context);
          setState(() {
            _showTutorialOverlay = false;
            _showStatsOverlay = true;
          });
        },
        onShowTutorial: () {
          Navigator.pop(context);
          setState(() {
            _showStatsOverlay = false;
            _showTutorialOverlay = true;
            _tutorialPausedEngine = true;
          });
        },
        onResume: () {
          Navigator.pop(context);
          if (!_isDealing && !_showStatsOverlay && !_tutorialPausedEngine) {
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
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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

    final showVictoryModal = state.isGameOver &&
        !_engine.isExchangeAnimating &&
        state.winner != null &&
        state.winningType != null;

    return Scaffold(
      backgroundColor: const Color(0xFFBFE3A5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPortraitViewport =
              constraints.maxWidth < constraints.maxHeight;

          final tableStack = Stack(
            children: [
              // 1. Main Horizontal Playing Table with localized Dealing & Sequential Exchange Animation layers
              PlayingTable(
                state: state,
                isProcessingMove: _engine.isProcessingMove,
                isDealing: _isDealing,
                dealingProgress: _dealingController.value,
                dealingAnimation: _dealingController,
                animationsEnabled: GameSettings.current.animationsEnabled,
                onCardSelected: _onCardSelected,
                onExchangeAnimationComplete: _onExchangeAnimationComplete,
                onPause: _showPauseDialog,
                onShowStats: _openStatsOverlay,
                onShowTutorial: _openTutorialOverlay,
              ),

              // 2. Victory Overlay (shown once the winning exchange animation finishes)
              if (showVictoryModal && !_showStatsOverlay && !_showTutorialOverlay)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.72),
                    child: VictoryOverlay(
                      winner: state.winner!,
                      winningType: state.winningType!,
                      totalPlayers: state.totalPlayers,
                      turnCount: state.turnCount,
                      onPlayAgain: _startMatch,
                      onViewStats: () => setState(() => _showStatsOverlay = true),
                      onMainMenu: () {
                        _engine.leaveGame();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),

              // 3. Player Stats & Sets Completed Overlay
              if (_showStatsOverlay)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.76),
                    child: PlayerStatsOverlay(
                      activePlayers: state.players,
                      targetSetSize: state.totalPlayers,
                      onClose: _closeStatsOverlay,
                    ),
                  ),
                ),

              // 4. Non-Intrusive Tutorial Modal Overlay for New Players
              if (_showTutorialOverlay)
                Positioned.fill(
                  child: TutorialModalOverlay(
                    targetSetSize: state.totalPlayers,
                    onClose: _closeTutorialOverlay,
                  ),
                ),

              // 5. Particle-Based Celebration Overlay (triggers strictly when a winning set completes)
              if (_showCelebrationParticles && showVictoryModal)
                Positioned.fill(
                  child: CelebrationParticlesOverlay(
                    completedType: _celebrationCountryType ?? state.winningType,
                    burstOriginNormalized: _celebrationOriginNormalized,
                    triggerKey: _celebrationTriggerKey,
                  ),
                ),
            ],
          );

          if (isPortraitViewport) {
            return RotatedBox(
              quarterTurns: 1,
              child: tableStack,
            );
          }

          return tableStack;
        },
      ),
    );
  }
}
