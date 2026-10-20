import 'package:flutter/material.dart';
import '../models/game_card.dart';
import '../models/game_player.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import 'card_back_view.dart';
import 'country_card_view.dart';
import 'player_seat.dart';

/// Opponent seat position on the 1920x1080 horizontal stage from the HTML design (`PP`).
class _StageSeatConfig {
  final Offset avatarPos;

  const _StageSeatConfig({
    required this.avatarPos,
  });
}

/// Fan slot configuration for the human player's hand.
class _FanSlot {
  final double a;
  final double d;
  final double tDeg;

  const _FanSlot({
    required this.a,
    required this.d,
    required this.tDeg,
  });
}

class PlayingTable extends StatefulWidget {
  final GameState state;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onPause;
  final VoidCallback? onShowStats;
  final VoidCallback? onShowTutorial;
  final VoidCallback? onExchangeAnimationComplete;
  final bool isProcessingMove;
  final bool isDealing;
  final double dealingProgress;
  final Animation<double>? dealingAnimation;
  final bool animationsEnabled;

  const PlayingTable({
    super.key,
    required this.state,
    required this.onCardSelected,
    required this.onPause,
    this.onShowStats,
    this.onShowTutorial,
    this.onExchangeAnimationComplete,
    this.isProcessingMove = false,
    this.isDealing = false,
    this.dealingProgress = 1.0,
    this.dealingAnimation,
    this.animationsEnabled = true,
  });

  @override
  State<PlayingTable> createState() => _PlayingTableState();
}

class _PlayingTableState extends State<PlayingTable>
    with SingleTickerProviderStateMixin {
  static const double _stageWidth = 1920.0;
  static const double _stageHeight = 1080.0;

  // Card dimensions from HTML (.card { width: 128px; height: 188px })
  static const double _cardWidth = 128.0;
  static const double _cardHeight = 188.0;

  // Two existing center table card positions aligned side-by-side in the center of the table:
  // Slot 0 (Left table position): left: 819px, top: 453px, upright (0 deg)
  static const Offset _leftTableSlotTopLeft = Offset(819.0, 453.0);

  // Slot 1 (Right table position): left: 981px, top: 453px, upright (0 deg)
  static const Offset _rightTableSlotTopLeft = Offset(981.0, 453.0);

  static const Offset _deckPileCenter = Offset(981.0 + 64.0, 453.0 + 94.0);

  // Human hand container layout at bottom center
  static const double _handContainerWidth = 1100.0;
  static const double _handContainerHeight = 250.0;
  static const double _handContainerLeft =
      (_stageWidth - _handContainerWidth) / 2.0;
  static const double _handContainerTop = _stageHeight - _handContainerHeight;
  static const Offset _humanHandCenter = Offset(960.0, 960.0);

  // Natural medium-speed easing curve: cubic-bezier(0.22, 1, 0.36, 1)
  static const Curve _exchangeCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  // Strict sequential exchange phase boundaries along _passController (0.0 -> 1.0):
  // Phase 2 (0.00 -> 0.44): Incoming card moves directly from player to open table slot.
  //                         Existing table card stays 100% stationary in its slot.
  // Phase 3 (0.44 -> 0.56): Incoming card has arrived completely; both cards rest stably
  //                         for a natural, deliberate beat before the pickup begins.
  // Phase 4 (0.56 -> 1.00): Previous table card moves directly from its table slot to the
  //                         exchanging player, while the new table card stays 100% stationary.
  static const double _phase2End = 0.44;
  static const double _phase4Start = 0.56;

  // Dedicated balanced seat layouts by player count on the 1920x1080 stage:
  // 3 Players (1 Human at bottom + 2 Bots in a balanced triangle around the center cards)
  static const List<_StageSeatConfig> _twoOpponentSlots = [
    // 0: Upper-Left flank
    _StageSeatConfig(avatarPos: Offset(450, 380)),
    // 1: Upper-Right flank
    _StageSeatConfig(avatarPos: Offset(1470, 380)),
  ];

  // 4 Players (1 Human at bottom + 3 Bots at Left-Center, Top-Center, Right-Center)
  static const List<_StageSeatConfig> _threeOpponentSlots = [
    // 0: Left-Center (vertically aligned with center table cards)
    _StageSeatConfig(avatarPos: Offset(380, 540)),
    // 1: Top-Center (directly across from human player)
    _StageSeatConfig(avatarPos: Offset(960, 110)),
    // 2: Right-Center (vertically aligned with center table cards)
    _StageSeatConfig(avatarPos: Offset(1540, 540)),
  ];

  // 5 & 6 Players opponent avatar seats from HTML `PP`
  static const List<_StageSeatConfig> _fiveOpponentSlots = [
    // 0: Bottom-Left
    _StageSeatConfig(avatarPos: Offset(401, 762)),
    // 1: Top-Left
    _StageSeatConfig(avatarPos: Offset(548, 313)),
    // 2: Top-Center
    _StageSeatConfig(avatarPos: Offset(960, 88)),
    // 3: Top-Right
    _StageSeatConfig(avatarPos: Offset(1372, 313)),
    // 4: Bottom-Right
    _StageSeatConfig(avatarPos: Offset(1519, 762)),
  ];

  // Dedicated 6-opponent seat layout exclusively for 7-Player Mode (1 Human + 6 Bots)
  static const List<_StageSeatConfig> _sixOpponentSlots = [
    // 0: Bot 1 (Lower-Left)
    _StageSeatConfig(avatarPos: Offset(340, 760)),
    // 1: Bot 2 (Mid-Upper-Left)
    _StageSeatConfig(avatarPos: Offset(430, 430)),
    // 2: Bot 3 (Top-Left)
    _StageSeatConfig(avatarPos: Offset(730, 155)),
    // 3: Bot 4 (Top-Right)
    _StageSeatConfig(avatarPos: Offset(1190, 155)),
    // 4: Bot 5 (Mid-Upper-Right)
    _StageSeatConfig(avatarPos: Offset(1490, 430)),
    // 5: Bot 6 (Lower-Right)
    _StageSeatConfig(avatarPos: Offset(1580, 760)),
  ];

  late final AnimationController _passController;

  int _lastAnimatedTurnCount = 0;
  bool _isAnimatingExchange = false;
  bool _hasPlayedLandingCue = false;
  bool _hasPlayedOutgoingCue = false;
  int? _animatingPlayerIndex;
  int? _animatingHandIndex;
  int _oldTableSlotIndex = 0;
  int _incomingTableSlotIndex = 1;
  Offset _lockedPlayerCardPos = Offset.zero;
  Offset _lockedOldTableSlotPos = _leftTableSlotTopLeft;
  Offset _lockedIncomingTableSlotPos = _rightTableSlotTopLeft;
  GameCard? _animatingDiscardedCard;
  GameCard? _animatingTakenCard;
  String? _selectedCardId;

  Widget? _cachedTakenWidget;
  Widget? _cachedDiscardedWidget;

  @override
  void initState() {
    super.initState();
    _passController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1020),
    )
      ..addListener(_onPassAnimationTick)
      ..addStatusListener(_onPassAnimationStatus);
    _lastAnimatedTurnCount = widget.state.turnCount;
  }

  void _onPassAnimationTick() {
    final p = _passController.value;
    if (!_hasPlayedLandingCue && p >= _phase2End) {
      _hasPlayedLandingCue = true;
      AudioService.instance.playCardPlace();
      HapticService.instance.botTurnTick();
    }
    if (!_hasPlayedOutgoingCue && p >= _phase4Start) {
      _hasPlayedOutgoingCue = true;
      AudioService.instance.playCardTake();
    }
  }

  void _onPassAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() {
        _isAnimatingExchange = false;
        _hasPlayedLandingCue = false;
        _hasPlayedOutgoingCue = false;
        _animatingPlayerIndex = null;
        _animatingHandIndex = null;
        _animatingDiscardedCard = null;
        _animatingTakenCard = null;
        _cachedTakenWidget = null;
        _cachedDiscardedWidget = null;
      });
      widget.onExchangeAnimationComplete?.call();
    }
  }

  @override
  void didUpdateWidget(covariant PlayingTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.state.turnCount == 0) {
      _lastAnimatedTurnCount = 0;
      _isAnimatingExchange = false;
      _hasPlayedLandingCue = false;
      _hasPlayedOutgoingCue = false;
      _animatingPlayerIndex = null;
      _animatingHandIndex = null;
      _oldTableSlotIndex = 0;
      _incomingTableSlotIndex = 1;
      _lockedOldTableSlotPos = _leftTableSlotTopLeft;
      _lockedIncomingTableSlotPos = _rightTableSlotTopLeft;
      _animatingDiscardedCard = null;
      _animatingTakenCard = null;
      _selectedCardId = null;
      _cachedTakenWidget = null;
      _cachedDiscardedWidget = null;
      _passController.reset();
      return;
    }

    // Prevent overlapping animations or restarting an active exchange mid-flight
    if (_isAnimatingExchange || _passController.isAnimating) {
      return;
    }

    if (widget.state.turnCount > _lastAnimatedTurnCount &&
        widget.state.lastMovePlayerIndex != null) {
      _lastAnimatedTurnCount = widget.state.turnCount;
      _selectedCardId = null;

      // The previous table card was resting in (turnCount - 1) % 2,
      // and the newly placed card lands in the opposite slot (turnCount % 2) and stays there.
      _oldTableSlotIndex = (widget.state.turnCount - 1) % 2;
      _incomingTableSlotIndex = widget.state.turnCount % 2;

      if (widget.animationsEnabled &&
          widget.state.lastDiscardedCard != null &&
          widget.state.lastTakenCard != null) {
        final playerIdx = widget.state.lastMovePlayerIndex!;
        final handIdx = widget.state.lastMoveHandIndex ?? 0;

        _animatingPlayerIndex = playerIdx;
        _animatingHandIndex = handIdx;
        _animatingDiscardedCard = widget.state.lastDiscardedCard;
        _animatingTakenCard = widget.state.lastTakenCard;

        // Lock start and destination coordinates once for the entire exchange duration
        _lockedPlayerCardPos = _getExchangePlayerCardTopLeft(
          playerIdx,
          handIdx,
          widget.state.totalPlayers,
        );
        _lockedOldTableSlotPos = _getTableSlotTopLeft(_oldTableSlotIndex);
        _lockedIncomingTableSlotPos =
            _getTableSlotTopLeft(_incomingTableSlotIndex);

        _isAnimatingExchange = true;
        _hasPlayedLandingCue = false;
        _hasPlayedOutgoingCue = false;
        _buildPassingCache();
        _passController.forward(from: 0.0);
      } else {
        _isAnimatingExchange = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onExchangeAnimationComplete?.call();
          }
        });
      }
    }
  }

  void _buildPassingCache() {
    if (_animatingTakenCard != null) {
      _cachedTakenWidget = RepaintBoundary(
        child: CountryCardView(
          card: _animatingTakenCard!,
          width: _cardWidth,
          height: _cardHeight,
          isLegal: true,
        ),
      );
    } else {
      _cachedTakenWidget = null;
    }

    if (_animatingDiscardedCard != null) {
      _cachedDiscardedWidget = RepaintBoundary(
        child: CountryCardView(
          card: _animatingDiscardedCard!,
          width: _cardWidth,
          height: _cardHeight,
          isLegal: true,
        ),
      );
    } else {
      _cachedDiscardedWidget = null;
    }
  }

  @override
  void dispose() {
    _passController.removeListener(_onPassAnimationTick);
    _passController.removeStatusListener(_onPassAnimationStatus);
    _passController.dispose();
    super.dispose();
  }

  Offset _getTableSlotTopLeft(int slotIndex) =>
      slotIndex == 0 ? _leftTableSlotTopLeft : _rightTableSlotTopLeft;

  /// Maps opponent index (0..totalPlayers-2) to its balanced stage seat for 3, 4, 5, or 6 players.
  _StageSeatConfig _getOpponentStageSeat(int opponentIdx, int totalPlayers) {
    if (totalPlayers == 3) {
      // 2 bots: balanced Upper-Left and Upper-Right triangle seats
      return _twoOpponentSlots[opponentIdx % _twoOpponentSlots.length];
    } else if (totalPlayers == 4) {
      // 3 bots: classic 4-player compass seats (Left-Center, Top-Center, Right-Center)
      return _threeOpponentSlots[opponentIdx % _threeOpponentSlots.length];
    } else if (totalPlayers == 5) {
      // 4 bots: Bottom-Left, Top-Left, Top-Right, Bottom-Right
      const indices = [0, 1, 3, 4];
      return _fiveOpponentSlots[indices[opponentIdx % indices.length]];
    } else if (totalPlayers == 7) {
      // 6 bots: dedicated 6-seat arc around the playing table
      return _sixOpponentSlots[opponentIdx % _sixOpponentSlots.length];
    } else {
      // 5 bots: all 5 slots
      return _fiveOpponentSlots[opponentIdx % _fiveOpponentSlots.length];
    }
  }

  /// Returns the target center position on the 1920x1080 stage for dealing animations.
  Offset _getPlayerTargetAnchor(int playerIndex, int totalPlayers) {
    if (playerIndex == 0) {
      return _humanHandCenter;
    }
    return _getOpponentStageSeat(playerIndex - 1, totalPlayers).avatarPos;
  }

  /// Computes the exact top-left coordinate on the 1920x1080 stage for a card in the human player's hand.
  Offset _getHumanCardStageTopLeft(int cardIndex, int handCount) {
    final safeCount = handCount > 0 ? handCount : widget.state.totalPlayers;
    final clampedIndex = cardIndex.clamp(0, safeCount - 1);
    final slot = _fanSlot(clampedIndex, safeCount);
    final cardLeft = (_handContainerWidth - _cardWidth) / 2.0 + slot.a;
    final cardTop = 36.0 + slot.d;
    return Offset(_handContainerLeft + cardLeft, _handContainerTop + cardTop);
  }

  /// Computes the exact top-left coordinate on the 1920x1080 stage for any player's card during an exchange.
  Offset _getExchangePlayerCardTopLeft(
    int playerIndex,
    int handIndex,
    int totalPlayers,
  ) {
    if (playerIndex == 0) {
      final handCount = widget.state.players[0].hand.length;
      return _getHumanCardStageTopLeft(handIndex, handCount);
    }
    final seatCenter =
        _getOpponentStageSeat(playerIndex - 1, totalPlayers).avatarPos;
    return Offset(
      seatCenter.dx - _cardWidth / 2.0,
      seatCenter.dy - _cardHeight / 2.0,
    );
  }

  /// Computes a gapless slot for card `i` of `n` in the human player's hand.
  _FanSlot _fanSlot(int i, int n) {
    final mid = (n - 1) / 2.0;
    final offsetFromCenter = i - mid;
    // Zero-gap side-by-side layout (edges touch with a 2px overlap so there is no gap)
    const step = _cardWidth - 2.0;
    return _FanSlot(
      a: offsetFromCenter * step,
      d: 0.0,
      tDeg: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final humanPlayer = state.players[0];
    final opponentPlayers = state.players.sublist(1);
    final activeIdleSlotIndex = state.turnCount % 2;
    final activeIdleSlotTopLeft = _getTableSlotTopLeft(activeIdleSlotIndex);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFBFE3A5),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-viewport striped lawn background (--bg with repeating vertical stripes & radial glow)
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: StageLawnBackgroundPainter(),
                isComplex: true,
                willChange: false,
              ),
            ),
          ),

          // Horizontal 1920x1080 stage scaled cleanly via FittedBox inside SafeArea
          SafeArea(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: SizedBox(
                  width: _stageWidth,
                  height: _stageHeight,
                  child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Top-Left Back/Menu Button (.btn at left: 90px, top: 60px)
                    Positioned(
                      left: 90,
                      top: 60,
                      width: 68,
                      height: 68,
                      child: _buildCircleButton(
                        tooltip: 'Game Menu',
                        onTap: widget.onPause,
                        child: const CustomPaint(
                          size: Size(30, 30),
                          painter: _BackChevronIconPainter(),
                        ),
                      ),
                    ),

                    // 1b. Top-Left Quick Tutorial (?) Button (.btn at left: 176px, top: 60px)
                    if (widget.onShowTutorial != null)
                      Positioned(
                        left: 176,
                        top: 60,
                        width: 68,
                        height: 68,
                        child: _buildCircleButton(
                          tooltip: 'Quick Tutorial',
                          onTap: widget.onShowTutorial!,
                          child: const CustomPaint(
                            size: Size(30, 30),
                            painter: _TutorialHelpIconPainter(),
                          ),
                        ),
                      ),

                    // 2. Top-Right Player Stats & Sets Button (.btn at left: 1676px, top: 60px)
                    if (widget.onShowStats != null)
                      Positioned(
                        left: 1676,
                        top: 60,
                        width: 68,
                        height: 68,
                        child: _buildCircleButton(
                          tooltip: 'Player Stats & Sets',
                          onTap: widget.onShowStats!,
                          child: const CustomPaint(
                            size: Size(30, 30),
                            painter: _StatsTrophyIconPainter(),
                          ),
                        ),
                      ),

                    // 3. Top-Right Settings Button (.btn at left: 1762px, top: 60px)
                    Positioned(
                      left: 1762,
                      top: 60,
                      width: 68,
                      height: 68,
                      child: _buildCircleButton(
                        tooltip: 'Settings & Controls',
                        onTap: widget.onPause,
                        child: const CustomPaint(
                          size: Size(30, 30),
                          painter: _SettingsGearIconPainter(),
                        ),
                      ),
                    ),

                    // 4. Dealing stack shown only during the initial deal animation
                    if (widget.isDealing)
                      const Positioned(
                        left: 989,
                        top: 453,
                        width: 112,
                        height: 164,
                        child: CardBackView(
                          width: 112,
                          height: 164,
                          showStackShadow: true,
                        ),
                      ),

                    // 5. Stationary Current Table Card (when not in the middle of an exchange animation)
                    if (!_isAnimatingExchange)
                      Positioned(
                        left: activeIdleSlotTopLeft.dx,
                        top: activeIdleSlotTopLeft.dy,
                        width: _cardWidth,
                        height: _cardHeight,
                        child: RepaintBoundary(
                          child: _buildIdleTableCard(
                            context,
                            slotIndex: activeIdleSlotIndex,
                          ),
                        ),
                      ),

                    // 6. Opponent Avatars & Name Tags (#players — NO cards in front of bots)
                    ..._buildOpponentAvatars(opponentPlayers),

                    // 7. Human Player Bottom Hand (full hit-test box & zero gaps between cards)
                    _buildHumanHandFan(humanPlayer),

                    // 8. Realistic Video-Accurate Sequential Card Exchange Layer
                    if (_isAnimatingExchange && _animatingPlayerIndex != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _passController,
                              builder: (context, _) {
                                if (!_isAnimatingExchange) {
                                  return const SizedBox.shrink();
                                }
                                return _buildRealisticExchangeOverlay();
                              },
                            ),
                          ),
                        ),
                      ),

                    // 9. Initial Shuffling & Dealing Animation Overlay
                    if (widget.isDealing)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: _buildDealingOverlay(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildCircleButton({
    required String tooltip,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFFFFF),
              border: Border.all(
                color: const Color(0xFFDAD3F5),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Renders the single current table card at its active slot (`state.turnCount % 2`) when idle.
  Widget _buildIdleTableCard(BuildContext context, {required int slotIndex}) {
    final state = widget.state;
    final tableCard = state.tableCard;
    final canInteract = !widget.isDealing &&
        !widget.isProcessingMove &&
        !_isAnimatingExchange &&
        state.isHumanTurn;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!canInteract) return;
        if (_selectedCardId != null) {
          final humanHand = state.players[0].hand;
          final match =
              humanHand.where((c) => c.id == _selectedCardId).toList();
          if (match.isNotEmpty && state.isLegalDiscard(match.first)) {
            HapticService.instance.cardTap();
            AudioService.instance.playCardTap();
            widget.onCardSelected(match.first);
          }
        }
      },
      child: CountryCardView(
        key: ValueKey<String>(tableCard.id),
        card: tableCard,
        width: _cardWidth,
        height: _cardHeight,
        isLegal: true,
      ),
    );
  }

  List<Widget> _buildOpponentAvatars(List<GamePlayer> opponentPlayers) {
    final widgets = <Widget>[];
    final totalPlayers = widget.state.totalPlayers;

    // While an exchange animation is in progress, keep the exchanging player highlighted
    // until Phase 5 completes.
    final activePlayerId = _isAnimatingExchange && _animatingPlayerIndex != null
        ? _animatingPlayerIndex!
        : widget.state.currentTurnPlayerIndex;

    for (int i = 0; i < opponentPlayers.length; i++) {
      final player = opponentPlayers[i];
      final seat = _getOpponentStageSeat(i, totalPlayers);
      final isCurrentTurn = !widget.isDealing && activePlayerId == player.id;
      final isPlayerExchanging =
          _isAnimatingExchange && _animatingPlayerIndex == player.id;
      final isThinking =
          isCurrentTurn && !player.isHuman && !widget.state.isGameOver;
      final isWinner =
          widget.state.isGameOver && widget.state.winner?.id == player.id;

      final isSevenPlayer = totalPlayers == 7;
      widgets.add(
        Positioned(
          left: seat.avatarPos.dx - 78,
          top: seat.avatarPos.dy - (isSevenPlayer ? 52 : 56),
          child: PlayerSeat(
            key: ValueKey<int>(player.id),
            player: player,
            isCurrentTurn: isCurrentTurn,
            isThinking: isThinking,
            isExchanging: isPlayerExchanging,
            isWinner: isWinner,
            isSevenPlayerMode: isSevenPlayer,
            exchangeAnimation: isPlayerExchanging ? _passController : null,
          ),
        ),
      );
    }

    return widgets;
  }

  /// Renders the human player's hand at bottom center inside a real 1100x250 hit-test box
  /// so every card is 100% responsive to touch and mouse taps.
  Widget _buildHumanHandFan(GamePlayer humanPlayer) {
    final state = widget.state;
    final activePlayerId = _isAnimatingExchange && _animatingPlayerIndex != null
        ? _animatingPlayerIndex!
        : state.currentTurnPlayerIndex;
    final isHumanTurnActive = !widget.isDealing && activePlayerId == 0;
    final canHumanAct = !widget.isDealing &&
        !widget.isProcessingMove &&
        !_isAnimatingExchange &&
        state.isHumanTurn;
    final cards = humanPlayer.hand;
    final count = cards.length;
    final handSpanWidth = count * (_cardWidth - 2.0) + 44.0;

    final fanStack = SizedBox(
      width: _handContainerWidth,
      height: _handContainerHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Subtle warm golden turn glow behind the human player's hand during their turn/exchange
          if (isHumanTurnActive)
            Positioned(
              left: (_handContainerWidth - handSpanWidth) / 2.0,
              top: 22.0,
              width: handSpanWidth,
              height: _cardHeight + 28.0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFFFE082).withValues(alpha: 0.85),
                      width: 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC83D).withValues(alpha: 0.55),
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.32),
                        blurRadius: 42,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          for (int i = 0; i < count; i++)
            Builder(
              builder: (context) {
                // During a human card exchange (Phases 2–4), the active slot is vacated while
                // the selected card slides onto the table and the previous table card is pulled back.
                if (_isAnimatingExchange &&
                    _animatingPlayerIndex == 0 &&
                    _animatingHandIndex == i) {
                  return const SizedBox.shrink();
                }

                final card = cards[i];
                final slot = _fanSlot(i, count);
                final isLegal = canHumanAct && state.isLegalDiscard(card);
                final isSelected = _selectedCardId == card.id;

                final cardLeft =
                    (_handContainerWidth - _cardWidth) / 2.0 + slot.a;
                final cardTop = 36.0 + slot.d;

                return Positioned(
                  left: cardLeft,
                  top: cardTop,
                  width: _cardWidth,
                  height: _cardHeight,
                  child: CountryCardView(
                    key: ValueKey<String>(card.id),
                    card: card,
                    width: _cardWidth,
                    height: _cardHeight,
                    isLegal: !canHumanAct || isLegal,
                    isSelected: isSelected,
                    onTap: isLegal
                        ? () {
                            HapticService.instance.cardTap();
                            AudioService.instance.playCardTap();
                            widget.onCardSelected(card);
                          }
                        : null,
                    onIllegalTap: canHumanAct && !isLegal
                        ? () {
                            HapticService.instance.invalidMove();
                          }
                        : null,
                  ),
                );
              },
            ),
        ],
      ),
    );

    Widget animatedHand;
    if (widget.isDealing && widget.dealingAnimation != null) {
      animatedHand = AnimatedBuilder(
        animation: widget.dealingAnimation!,
        child: fanStack,
        builder: (context, child) {
          final reveal =
              ((widget.dealingAnimation!.value - 0.25) / 0.75).clamp(0.0, 1.0);
          return Opacity(
            opacity: reveal,
            child: Transform.translate(
              offset: Offset(0, (1.0 - reveal) * 40),
              child: child,
            ),
          );
        },
      );
    } else if (widget.isDealing) {
      final reveal = ((widget.dealingProgress - 0.25) / 0.75).clamp(0.0, 1.0);
      animatedHand = Opacity(
        opacity: reveal,
        child: Transform.translate(
          offset: Offset(0, (1.0 - reveal) * 40),
          child: fanStack,
        ),
      );
    } else {
      animatedHand = fanStack;
    }

    return Positioned(
      left: _handContainerLeft,
      top: _handContainerTop,
      width: _handContainerWidth,
      height: _handContainerHeight,
      child: RepaintBoundary(
        child: animatedHand,
      ),
    );
  }

  /// Renders the smooth, sequential, single-movement card exchange:
  /// 1. Phase 2 (`0.00 -> 0.47`): The incoming card moves directly from `_lockedPlayerCardPos`
  ///    to `_lockedIncomingTableSlotPos` using `Cubic(0.22, 1.0, 0.36, 1.0)`.
  ///    The previous table card remains completely stationary at `_lockedOldTableSlotPos`.
  /// 2. Phase 3 (`0.47 -> 0.53`): Incoming card has arrived completely; both cards rest stably
  ///    at their table positions.
  /// 3. Phase 4 (`0.53 -> 1.00`): Only after the incoming card has reached its final position,
  ///    the previous table card moves directly from `_lockedOldTableSlotPos` to `_lockedPlayerCardPos`
  ///    using `Cubic(0.22, 1.0, 0.36, 1.0)`, while the incoming card stays completely stationary.
  Widget _buildRealisticExchangeOverlay() {
    final p = _passController.value;

    final Offset incomingPos;
    final Offset outgoingPos;

    if (p < _phase2End) {
      final rawIn = (p / _phase2End).clamp(0.0, 1.0);
      final tIn = _exchangeCurve.transform(rawIn);
      incomingPos = Offset.lerp(
        _lockedPlayerCardPos,
        _lockedIncomingTableSlotPos,
        tIn,
      )!;
      outgoingPos = _lockedOldTableSlotPos;
    } else if (p < _phase4Start) {
      incomingPos = _lockedIncomingTableSlotPos;
      outgoingPos = _lockedOldTableSlotPos;
    } else {
      final rawOut =
          ((p - _phase4Start) / (1.0 - _phase4Start)).clamp(0.0, 1.0);
      final tOut = _exchangeCurve.transform(rawOut);
      incomingPos = _lockedIncomingTableSlotPos;
      outgoingPos = Offset.lerp(
        _lockedOldTableSlotPos,
        _lockedPlayerCardPos,
        tOut,
      )!;
    }

    final takenKey =
        ValueKey<String>('exchange_taken_${_animatingTakenCard?.id ?? "old"}');
    final discardedKey = ValueKey<String>(
      'exchange_discarded_${_animatingDiscardedCard?.id ?? "new"}',
    );

    final takenLayer = _cachedTakenWidget != null
        ? Positioned(
            key: takenKey,
            left: 0,
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
            child: Transform.translate(
              offset: outgoingPos,
              child: _cachedTakenWidget!,
            ),
          )
        : null;

    final discardedLayer = _cachedDiscardedWidget != null
        ? Positioned(
            key: discardedKey,
            left: 0,
            top: 0,
            width: _cardWidth,
            height: _cardHeight,
            child: Transform.translate(
              offset: incomingPos,
              child: _cachedDiscardedWidget!,
            ),
          )
        : null;

    // Keep the actively moving card on top while preserving Element identity via ValueKeys
    final children = p < _phase4Start
        ? <Widget>[
            ?takenLayer,
            ?discardedLayer,
          ]
        : <Widget>[
            ?discardedLayer,
            ?takenLayer,
          ];

    return Stack(
      clipBehavior: Clip.none,
      children: children,
    );
  }

  /// Renders the initial dealing sequence from the center deck pile to all players.
  Widget _buildDealingOverlay() {
    final state = widget.state;
    final n = state.totalPlayers;
    const sharedFlyingCard = CardBackView(
      width: 68,
      height: 100,
    );

    final seatTargets = List<Offset>.generate(
      n,
      (playerIdx) => _getPlayerTargetAnchor(playerIdx, n),
      growable: false,
    );

    Widget buildFrame(double progress) {
      final p = progress.clamp(0.0, 1.0);
      final flyingCards = <Widget>[];
      final denom = n * n * 1.4;

      for (int playerIdx = 0; playerIdx < n; playerIdx++) {
        final seatTarget = seatTargets[playerIdx];

        for (int c = 0; c < n; c++) {
          final delay = (c * n + playerIdx) / denom;
          final localT = ((p - delay) / 0.45).clamp(0.0, 1.0);
          if (localT <= 0.0 || localT >= 1.0) continue;

          final curvedT = Curves.easeOutCubic.transform(localT);
          final pos = Offset.lerp(_deckPileCenter, seatTarget, curvedT)!;

          flyingCards.add(
            Positioned(
              left: pos.dx - 34,
              top: pos.dy - 50,
              child: Transform.rotate(
                angle: (1.0 - curvedT) * 0.4,
                child: sharedFlyingCard,
              ),
            ),
          );
        }
      }

      return Stack(
        clipBehavior: Clip.none,
        children: flyingCards,
      );
    }

    if (widget.dealingAnimation != null) {
      return AnimatedBuilder(
        animation: widget.dealingAnimation!,
        builder: (context, _) => buildFrame(widget.dealingAnimation!.value),
      );
    }

    return buildFrame(widget.dealingProgress);
  }
}

/// Paints the HTML `#stage` background:
/// `background: repeating-linear-gradient(90deg,rgba(255,255,255,.14) 0 130px,rgba(255,255,255,0) 130px 260px), radial-gradient(ellipse at 50% 45%,rgba(255,255,255,.28),rgba(255,255,255,0) 70%), #BFE3A5`
class StageLawnBackgroundPainter extends CustomPainter {
  const StageLawnBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFBFE3A5));

    // Repeating vertical stripes (scaled proportionally to viewport width)
    final stripeWidth = size.width * (130.0 / 1920.0);
    final period = stripeWidth * 2.0;
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += period) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, stripeWidth, size.height),
        stripePaint,
      );
    }

    // Soft radial highlight at (50%, 45%)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.1),
        radius: 0.7,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints `<svg viewBox="0 0 24 24"><path d="M15 5l-7 7 7 7"/></svg>` from the HTML Back button.
class _BackChevronIconPainter extends CustomPainter {
  const _BackChevronIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final path = Path()
      ..moveTo(15 * s, 5 * s)
      ..lineTo(8 * s, 12 * s)
      ..lineTo(15 * s, 19 * s);
    final paint = Paint()
      ..color = const Color(0xFF2A2160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints `<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="3"/><path d="M12 2.8v3M12 18.2v3M2.8 12h3M18.2 12h3M5.5 5.5l2.1 2.1M16.4 16.4l2.1 2.1M18.5 5.5l-2.1 2.1M7.6 16.4l-2.1 2.1"/></svg>`
class _SettingsGearIconPainter extends CustomPainter {
  const _SettingsGearIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final paint = Paint()
      ..color = const Color(0xFF2A2160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(Offset(12 * s, 12 * s), 3 * s, paint);

    final rays = Path()
      ..moveTo(12 * s, 2.8 * s)
      ..lineTo(12 * s, 5.8 * s)
      ..moveTo(12 * s, 18.2 * s)
      ..lineTo(12 * s, 21.2 * s)
      ..moveTo(2.8 * s, 12 * s)
      ..lineTo(5.8 * s, 12 * s)
      ..moveTo(18.2 * s, 12 * s)
      ..lineTo(21.2 * s, 12 * s)
      ..moveTo(5.5 * s, 5.5 * s)
      ..lineTo(7.6 * s, 7.6 * s)
      ..moveTo(16.4 * s, 16.4 * s)
      ..lineTo(18.5 * s, 18.5 * s)
      ..moveTo(18.5 * s, 5.5 * s)
      ..lineTo(16.4 * s, 7.6 * s)
      ..moveTo(7.6 * s, 16.4 * s)
      ..lineTo(5.5 * s, 18.5 * s);
    canvas.drawPath(rays, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints a clean vector Trophy / Leaderboard icon matching the #2A2160 stroke style of the table buttons.
class _StatsTrophyIconPainter extends CustomPainter {
  const _StatsTrophyIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final paint = Paint()
      ..color = const Color(0xFF2A2160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Trophy cup body
    final cup = Path()
      ..moveTo(7 * s, 4 * s)
      ..lineTo(17 * s, 4 * s)
      ..lineTo(17 * s, 9.5 * s)
      ..quadraticBezierTo(17 * s, 14.5 * s, 12 * s, 14.5 * s)
      ..quadraticBezierTo(7 * s, 14.5 * s, 7 * s, 9.5 * s)
      ..close();
    canvas.drawPath(cup, paint);

    // Left & right handles
    final handles = Path()
      ..moveTo(7 * s, 6 * s)
      ..lineTo(4.2 * s, 6 * s)
      ..quadraticBezierTo(4.2 * s, 10.5 * s, 7 * s, 10.5 * s)
      ..moveTo(17 * s, 6 * s)
      ..lineTo(19.8 * s, 6 * s)
      ..quadraticBezierTo(19.8 * s, 10.5 * s, 17 * s, 10.5 * s);
    canvas.drawPath(handles, paint);

    // Stem & pedestal base
    final base = Path()
      ..moveTo(12 * s, 14.5 * s)
      ..lineTo(12 * s, 19.5 * s)
      ..moveTo(8 * s, 19.5 * s)
      ..lineTo(16 * s, 19.5 * s);
    canvas.drawPath(base, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints a crisp Question Mark / Tutorial Help icon matching the #2A2160 stroke style of the table buttons.
class _TutorialHelpIconPainter extends CustomPainter {
  const _TutorialHelpIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final strokePaint = Paint()
      ..color = const Color(0xFF2A2160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final curve = Path()
      ..moveTo(9.1 * s, 9.0 * s)
      ..cubicTo(9.5 * s, 6.2 * s, 14.5 * s, 6.2 * s, 14.9 * s, 9.2 * s)
      ..cubicTo(15.2 * s, 11.4 * s, 12.0 * s, 12.0 * s, 12.0 * s, 14.2 * s);
    canvas.drawPath(curve, strokePaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF2A2160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(12.0 * s, 18.2 * s), 1.45 * s, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

