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
import '../widgets/played_cards_history_overlay.dart';
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
  bool _showHistoryOverlay = false;
  bool _showStatsOverlay = false;
  bool _showTutorialOverlay = false;
  bool _tutorialPausedEngine = false;
  bool _hasRecordedWinningSetForMatch = false;
  int _lastTurnCount = 0;
  final Stopwatch _matchStopwatch = Stopwatch();

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
          if (!_showHistoryOverlay &&
              !_showStatsOverlay &&
              !_tutorialPausedEngine) {
            _engine.resumeActivePlay();
          }
        }
      });

    // Show tutorial overlay automatically for first-time players and pause gameplay while open
    if (!TutorialModalOverlay.hasSeenTutorial) {
      _showTutorialOverlay = true;
      _tutorialPausedEngine = true;
    }

    _startMatch();
  }

  void _startMatch() {
    final animateDeal = GameSettings.current.animationsEnabled;
    _lastTurnCount = 0;
    _showStatsOverlay = false;
    _hasRecordedWinningSetForMatch = false;
    _showCelebrationParticles = false;
    _matchStopwatch
      ..reset()
      ..start();

    _engine.updateSettings(GameSettings.current);
    _engine.startNewGame(
      totalPlayers: widget.totalPlayers,
      predefinedTypes: widget.predefinedTypes,
      deferBotStart: animateDeal || _showTutorialOverlay,
    );

    if (_showTutorialOverlay) {
      _tutorialPausedEngine = true;
      _engine.pauseActivePlay();
    }

    if (_engine.state != null) {
      StatsService.instance.recordGameStarted(_engine.state!.players);
    }

    if (animateDeal) {
      setState(() => _isDealing = true);
      if (_showTutorialOverlay) {
        _dealingController.value = 0.0;
      } else {
        AudioService.instance.playExchange();
        _dealingController.forward(from: 0.0);
      }
    } else {
      setState(() => _isDealing = false);
      if (!_showTutorialOverlay) {
        AudioService.instance.playGameStart();
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
    } else if (totalPlayers == 7) {
      const seats = [
        Offset(340 / 1920, 760 / 1080),
        Offset(430 / 1920, 430 / 1080),
        Offset(730 / 1920, 155 / 1080),
        Offset(1190 / 1920, 155 / 1080),
        Offset(1490 / 1920, 430 / 1080),
        Offset(1580 / 1920, 760 / 1080),
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
        _matchStopwatch.stop();
        final elapsedSec = _matchStopwatch.elapsed.inSeconds.clamp(5, 600);
        StatsService.instance.recordSetCompleted(
          winner,
          winningType,
          totalPlayers: state.totalPlayers,
          turnCount: state.turnCount,
          durationSeconds: elapsedSec,
        );
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
  }

  void _onCardSelected(GameCard card) {
    if (_isDealing ||
        _showTutorialOverlay ||
        _showHistoryOverlay ||
        _showStatsOverlay ||
        _engine.isProcessingMove) {
      return;
    }
    _engine.makeMove(card);
  }

  void _openHistoryOverlay() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    _engine.pauseActivePlay();
    if (_isDealing && _dealingController.isAnimating) {
      _dealingController.stop(canceled: false);
    }
    setState(() {
      _showTutorialOverlay = false;
      _tutorialPausedEngine = false;
      _showStatsOverlay = false;
      _showHistoryOverlay = !_showHistoryOverlay;
    });
    if (!_showHistoryOverlay &&
        !_showStatsOverlay &&
        !_showTutorialOverlay) {
      if (_isDealing && _dealingController.value < 1.0) {
        _dealingController.forward();
      } else if (!_isDealing && _engine.state?.isGameOver != true) {
        _engine.resumeActivePlay();
      }
    }
  }

  void _closeHistoryOverlay() {
    setState(() => _showHistoryOverlay = false);
    if (!_showStatsOverlay && !_showTutorialOverlay) {
      if (_isDealing && _dealingController.value < 1.0) {
        _dealingController.forward();
      } else if (!_isDealing && _engine.state?.isGameOver != true) {
        _engine.resumeActivePlay();
      }
    }
  }

  void _closeStatsOverlay() {
    setState(() => _showStatsOverlay = false);
    if (!_showHistoryOverlay && !_showTutorialOverlay) {
      if (_isDealing && _dealingController.value < 1.0) {
        _dealingController.forward();
      } else if (!_isDealing && _engine.state?.isGameOver != true) {
        _engine.resumeActivePlay();
      }
    }
  }

  void _openTutorialOverlay() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    _engine.pauseActivePlay();
    if (_isDealing && _dealingController.isAnimating) {
      _dealingController.stop(canceled: false);
    }
    setState(() {
      _showHistoryOverlay = false;
      _showStatsOverlay = false;
      _showTutorialOverlay = true;
      _tutorialPausedEngine = true;
    });
  }

  void _closeTutorialOverlay() {
    final wasPausedByTutorial = _tutorialPausedEngine;
    TutorialModalOverlay.markTutorialSeen();
    setState(() {
      _showTutorialOverlay = false;
      _tutorialPausedEngine = false;
      // If dealing had not started yet while the initial tutorial was open,
      // mark dealing complete immediately so gameplay starts with zero delay
      if (_isDealing && _dealingController.value <= 0.0) {
        _isDealing = false;
        _dealingController.value = 1.0;
      }
    });
    if (_isDealing && _dealingController.value < 1.0) {
      _dealingController.forward();
      return;
    }
    if (wasPausedByTutorial &&
        !_isDealing &&
        !_showHistoryOverlay &&
        !_showStatsOverlay &&
        _engine.state?.isGameOver != true) {
      _engine.resumeActivePlay(immediate: true);
    }
  }

  void _showExitConfirmationDialog() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    _engine.pauseActivePlay();
    if (_isDealing && _dealingController.isAnimating) {
      _dealingController.stop(canceled: false);
    }
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Leave Game Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, _, __) => ExitConfirmationDialog(
        onStayInGame: () {
          Navigator.pop(dialogContext);
        },
        onExitGame: () {
          Navigator.pop(dialogContext);
          _engine.leaveGame();
          Navigator.pop(context);
        },
      ),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    ).then((_) {
      if (!mounted ||
          _showHistoryOverlay ||
          _showStatsOverlay ||
          _showTutorialOverlay ||
          _tutorialPausedEngine) {
        return;
      }
      if (_isDealing && _dealingController.value < 1.0) {
        _dealingController.forward();
      } else if (!_isDealing && _engine.state?.isGameOver != true) {
        _engine.resumeActivePlay();
      }
    });
  }

  void _showPauseDialog() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    _engine.pauseActivePlay();
    if (_isDealing && _dealingController.isAnimating) {
      _dealingController.stop(canceled: false);
    }
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
        onResume: () {
          Navigator.pop(context);
          if (_showHistoryOverlay ||
              _showStatsOverlay ||
              _showTutorialOverlay ||
              _tutorialPausedEngine) {
            return;
          }
          if (_isDealing && _dealingController.value < 1.0) {
            _dealingController.forward();
          } else if (!_isDealing && _engine.state?.isGameOver != true) {
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
          Navigator.of(context).popUntil((route) => route.isFirst);
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

    final isTablePaused = _showTutorialOverlay ||
        _showHistoryOverlay ||
        _showStatsOverlay ||
        _engine.isPaused;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitConfirmationDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFBFE3A5),
        body: Stack(
          children: [
            // 1. Main Horizontal Playing Table with localized Dealing & Sequential Exchange Animation layers
            PlayingTable(
              state: state,
              isPaused: isTablePaused,
              isProcessingMove: _engine.isProcessingMove,
              isDealing: _isDealing,
              dealingProgress: _dealingController.value,
              dealingAnimation: _dealingController,
              animationsEnabled: GameSettings.current.animationsEnabled,
              onCardSelected: _onCardSelected,
              onExchangeAnimationComplete: _onExchangeAnimationComplete,
              onBack: _showExitConfirmationDialog,
              onPause: _showPauseDialog,
              onShowHistory: _openHistoryOverlay,
              onShowTutorial: _openTutorialOverlay,
            ),

          // 2. Victory Overlay (shown once the winning exchange animation finishes)
          if (showVictoryModal &&
              !_showHistoryOverlay &&
              !_showStatsOverlay &&
              !_showTutorialOverlay)
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
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            ),

          // 3. Small, Scrollable Last 5 Cards Played History Overlay
          if (_showHistoryOverlay)
            Positioned.fill(
              child: PlayedCardsHistoryOverlay(
                recentPlayedCards: state.recentPlayedCards,
                currentTableCardName: state.tableCard.displayName,
                onClose: _closeHistoryOverlay,
              ),
            ),

          // 4. Player Stats & Sets Completed Overlay (accessible from Victory screen)
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

          // 5. Non-Intrusive Tutorial Modal Overlay for New Players
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
        ),
      ),
    );
  }
}
