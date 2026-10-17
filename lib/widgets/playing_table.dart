import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/game_card.dart';
import '../models/game_player.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import 'card_back_view.dart';
import 'card_dimensions.dart';
import 'country_card_view.dart';
import 'player_seat.dart';

class PlayingTable extends StatefulWidget {
  final GameState state;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onPause;
  final bool isProcessingMove;
  final bool isDealing;
  final double dealingProgress;
  final Animation<double>? dealingAnimation;
  final bool soundEnabled;
  final VoidCallback onToggleSound;
  final bool animationsEnabled;

  const PlayingTable({
    super.key,
    required this.state,
    required this.onCardSelected,
    required this.onPause,
    this.isProcessingMove = false,
    this.isDealing = false,
    this.dealingProgress = 1.0,
    this.dealingAnimation,
    required this.soundEnabled,
    required this.onToggleSound,
    this.animationsEnabled = true,
  });

  @override
  State<PlayingTable> createState() => _PlayingTableState();
}

class _PlayingTableState extends State<PlayingTable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _passController;
  late final Animation<double> _passCurve;

  int _lastAnimatedTurnCount = 0;
  int? _animatingPlayerIndex;
  GameCard? _animatingDiscardedCard;
  GameCard? _animatingTakenCard;

  // Cached moving card widgets for the active pass animation to avoid per-frame widget allocation
  Size? _cachedMovingSize;
  Widget? _cachedTakenWidget;
  Widget? _cachedDiscardedWidget;

  @override
  void initState() {
    super.initState();
    _passController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _passCurve = CurvedAnimation(
      parent: _passController,
      curve: Curves.easeInOutCubic,
    );
    _lastAnimatedTurnCount = widget.state.turnCount;
  }

  @override
  void didUpdateWidget(covariant PlayingTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.state.turnCount == 0) {
      _lastAnimatedTurnCount = 0;
      _animatingPlayerIndex = null;
      _cachedTakenWidget = null;
      _cachedDiscardedWidget = null;
      _passController.reset();
      return;
    }

    // Trigger 2D card passing animation when a new move occurs
    if (widget.animationsEnabled &&
        widget.state.turnCount > _lastAnimatedTurnCount &&
        widget.state.lastMovePlayerIndex != null) {
      _lastAnimatedTurnCount = widget.state.turnCount;
      _animatingPlayerIndex = widget.state.lastMovePlayerIndex;
      _animatingDiscardedCard = widget.state.lastDiscardedCard;
      _animatingTakenCard = widget.state.lastTakenCard;
      _cachedMovingSize = null; // Re-cache once for new card pair
      _passController.forward(from: 0.0);
    }
  }

  void _ensurePassingWidgetsCached(Size movingSize) {
    if (_cachedMovingSize == movingSize &&
        (_cachedTakenWidget != null || _cachedDiscardedWidget != null)) {
      return;
    }
    _cachedMovingSize = movingSize;
    final playerIdx = _animatingPlayerIndex ?? 0;

    if (_animatingTakenCard != null) {
      _cachedTakenWidget = RepaintBoundary(
        child: playerIdx == 0
            ? CountryCardView(
                card: _animatingTakenCard!,
                width: movingSize.width,
                height: movingSize.height,
              )
            : CardBackView(
                width: movingSize.width * 0.78,
              ),
      );
    } else {
      _cachedTakenWidget = null;
    }

    if (_animatingDiscardedCard != null) {
      _cachedDiscardedWidget = RepaintBoundary(
        child: CountryCardView(
          card: _animatingDiscardedCard!,
          width: movingSize.width,
          height: movingSize.height,
        ),
      );
    } else {
      _cachedDiscardedWidget = null;
    }
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  /// Computes the 2D center anchor position for any player index (0 = bottom human, 1..N-1 = bots).
  Offset _getPlayerAnchor({
    required int playerIndex,
    required int totalPlayers,
    required double screenWidth,
    required double screenHeight,
  }) {
    final topOffset = screenHeight < 600 ? 80.0 : 96.0;

    if (playerIndex == 0) {
      return Offset(screenWidth * 0.5, screenHeight - 90);
    }

    if (totalPlayers == 4) {
      switch (playerIndex) {
        case 1:
          return Offset(85, screenHeight * 0.43);
        case 2:
          return Offset(screenWidth * 0.5, topOffset);
        case 3:
          return Offset(screenWidth - 85, screenHeight * 0.43);
      }
    } else if (totalPlayers == 5) {
      switch (playerIndex) {
        case 1:
          return Offset(80, screenHeight * 0.45);
        case 2:
          return Offset(screenWidth * 0.28, topOffset);
        case 3:
          return Offset(screenWidth * 0.72, topOffset);
        case 4:
          return Offset(screenWidth - 80, screenHeight * 0.45);
      }
    } else {
      switch (playerIndex) {
        case 1:
          return Offset(80, screenHeight * 0.66);
        case 2:
          return Offset(85, topOffset);
        case 3:
          return Offset(screenWidth * 0.5, topOffset);
        case 4:
          return Offset(screenWidth - 85, topOffset);
        case 5:
          return Offset(screenWidth - 80, screenHeight * 0.66);
      }
    }
    return Offset(screenWidth * 0.5, screenHeight * 0.5);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        final tableCenter = Offset(screenWidth * 0.5, screenHeight * 0.46);

        // Card sizing strictly following 2:1 ratio
        final handCardSize = CardDimensions.getHumanHandCardSize(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          totalPlayers: state.totalPlayers,
        );

        final tableCardSize = CardDimensions.getTableCardSize(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );

        final humanPlayer = state.players[0];
        final opponentPlayers = state.players.sublist(1);

        return Container(
          width: screenWidth,
          height: screenHeight,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Color(0xFF0F3B2C),
                Color(0xFF09251B),
                Color(0xFF04140E),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Static decorative table felt border and center rings isolated in GPU layer
              const Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: TableFeltPainter(),
                    isComplex: true,
                    willChange: false,
                  ),
                ),
              ),

              // Top HUD Bar: Turn badge ("Your Turn" for human), goal badge, status, Sound toggle, and Pause
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: _buildTopHud(context),
                ),
              ),

              // Central Table Card Area (Classic single upright centered style)
              Positioned(
                left: tableCenter.dx - (tableCardSize.width + 32) / 2,
                top: tableCenter.dy - (tableCardSize.height + 54) / 2,
                width: tableCardSize.width + 32,
                height: tableCardSize.height + 54,
                child: RepaintBoundary(
                  child: _buildCentralTableArea(context, tableCardSize),
                ),
              ),

              // Opponent Seats arranged responsively around edges (each seat has its own RepaintBoundary)
              ..._buildOpponentSeats(
                opponentPlayers: opponentPlayers,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              // 2D Card Passing Animation Overlay isolated in its own RepaintBoundary
              if (_animatingPlayerIndex != null)
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _passCurve,
                    builder: (context, _) {
                      if (!_passController.isAnimating) {
                        return const SizedBox.shrink();
                      }
                      return _buildPassingCardsOverlay(
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        tableCenter: tableCenter,
                        tableCardSize: tableCardSize,
                      );
                    },
                  ),
                ),

              // Initial Shuffling & Dealing Animation Overlay isolated in its own RepaintBoundary
              if (widget.isDealing)
                RepaintBoundary(
                  child: _buildDealingOverlay(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    tableCenter: tableCenter,
                  ),
                ),

              // Human Player Hand Area at Bottom
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: _buildHumanHandArea(
                    context: context,
                    humanPlayer: humanPlayer,
                    cardSize: handCardSize,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHud(BuildContext context) {
    final state = widget.state;
    final activePlayer = state.currentPlayer;
    final isHuman = activePlayer.isHuman;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Turn Badge: "Your Turn" for human player, "<Bot Name>'s Turn" for bots
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isHuman
                    ? const Color(0xFF059669).withValues(alpha: 0.9)
                    : const Color(0xFF1E293B).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isHuman ? const Color(0xFFFFD54F) : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHuman ? Icons.person : Icons.sync_alt,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isHuman ? 'Your Turn' : '${activePlayer.name}\'s Turn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Dynamic Winning Set Size Indicator Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'Goal: ${state.totalPlayers}×',
                style: const TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Status message
            Expanded(
              child: Text(
                widget.isDealing
                    ? 'Shuffling & dealing balanced hands (1 of each country)...'
                    : state.statusMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFFFE082).withValues(alpha: 0.95),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Dedicated HUD Sound On/Off Toggle Button
            IconButton(
              icon: Icon(
                widget.soundEnabled
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: widget.soundEnabled
                    ? const Color(0xFFFFD54F)
                    : Colors.white54,
                size: 22,
              ),
              tooltip: widget.soundEnabled ? 'Mute Sound' : 'Enable Sound',
              onPressed: widget.onToggleSound,
            ),

            // Pause / Menu button
            IconButton(
              icon: const Icon(
                Icons.pause_rounded,
                color: Color(0xFFFFD54F),
                size: 22,
              ),
              tooltip: 'Game Menu',
              onPressed: widget.onPause,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralTableArea(BuildContext context, Size cardSize) {
    final state = widget.state;
    final tableCard = state.tableCard;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.32),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.14),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tableCard.isStartingCard
                      ? Icons.public
                      : Icons.table_restaurant,
                  color: const Color(0xFFFFD54F),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  state.isOpeningMove ? 'STARTER CARD' : 'TABLE CARD',
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: CountryCardView(
                key: ValueKey<String>(tableCard.id),
                card: tableCard,
                width: cardSize.width,
                height: cardSize.height,
                isLegal: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Renders smooth 2D arc trajectories for cards moving between players and the center table
  /// using pre-built cached card widgets so zero card artwork rebuilds occur during the 60fps animation.
  Widget _buildPassingCardsOverlay({
    required double screenWidth,
    required double screenHeight,
    required Offset tableCenter,
    required Size tableCardSize,
  }) {
    final t = _passCurve.value;
    final playerIdx = _animatingPlayerIndex!;
    final playerAnchor = _getPlayerAnchor(
      playerIndex: playerIdx,
      totalPlayers: widget.state.totalPlayers,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );

    final movingWidth = tableCardSize.width * 0.85;
    final movingHeight = movingWidth * 2.0;
    _ensurePassingWidgetsCached(Size(movingWidth, movingHeight));

    // 2D parabolic arc offset perpendicular to the path
    final arcLift = math.sin(math.pi * t) * 34.0;

    // 1. Discarded card: moves from playerAnchor -> tableCenter
    final discardPos = Offset.lerp(playerAnchor, tableCenter, t)! +
        Offset(arcLift * 0.6, -arcLift);

    // 2. Taken card: moves from tableCenter -> playerAnchor
    final takePos = Offset.lerp(tableCenter, playerAnchor, t)! +
        Offset(-arcLift * 0.6, arcLift * 0.5);

    return IgnorePointer(
      child: Stack(
        children: [
          // Taken card moving from table to player's hand
          if (_cachedTakenWidget != null)
            Positioned(
              left: takePos.dx - movingWidth / 2,
              top: takePos.dy - movingHeight / 2,
              child: Opacity(
                opacity: (1.0 - t * 0.35).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: (1.0 - t) * 0.14,
                  child: _cachedTakenWidget!,
                ),
              ),
            ),

          // Discarded card moving from player's hand to center table
          if (_cachedDiscardedWidget != null)
            Positioned(
              left: discardPos.dx - movingWidth / 2,
              top: discardPos.dy - movingHeight / 2,
              child: Opacity(
                opacity: (0.3 + t * 0.7).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: math.sin(math.pi * t) * -0.16,
                  child: _cachedDiscardedWidget!,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Renders the initial shuffling and balanced hand dealing animation from center deck to all seats.
  /// Driven by a localized AnimatedBuilder so the rest of PlayingTable does not rebuild on ticks.
  Widget _buildDealingOverlay({
    required double screenWidth,
    required double screenHeight,
    required Offset tableCenter,
  }) {
    final state = widget.state;
    final n = state.totalPlayers;
    const sharedFlyingCard = CardBackView(width: 36);

    // Precompute player seat anchors once per layout rather than inside the inner loop
    final seatTargets = List<Offset>.generate(
      n,
      (playerIdx) => _getPlayerAnchor(
        playerIndex: playerIdx,
        totalPlayers: n,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
      ),
      growable: false,
    );

    final dealingBanner = Positioned(
      top: 56,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.style,
                color: Color(0xFFFFD54F),
                size: 16,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Dealing Balanced Hands • 1 Card of Each Country (${state.totalPlayers} Cards/Player)',
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget buildFrame(double progress, Widget? bannerChild) {
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
          final pos = Offset.lerp(tableCenter, seatTarget, curvedT)!;

          flyingCards.add(
            Positioned(
              left: pos.dx - 18,
              top: pos.dy - 36,
              child: Transform.rotate(
                angle: (1.0 - curvedT) * 0.4,
                child: sharedFlyingCard,
              ),
            ),
          );
        }
      }

      return IgnorePointer(
        child: Stack(
          children: [
            ...flyingCards,
            ?bannerChild,
          ],
        ),
      );
    }

    if (widget.dealingAnimation != null) {
      return AnimatedBuilder(
        animation: widget.dealingAnimation!,
        child: dealingBanner,
        builder: (context, bannerChild) =>
            buildFrame(widget.dealingAnimation!.value, bannerChild),
      );
    }

    return buildFrame(widget.dealingProgress, dealingBanner);
  }

  List<Widget> _buildOpponentSeats({
    required List<GamePlayer> opponentPlayers,
    required double screenWidth,
    required double screenHeight,
  }) {
    final widgets = <Widget>[];
    final totalPlayers = widget.state.totalPlayers;
    final topOffset = screenHeight < 600 ? 48.0 : 56.0;

    if (totalPlayers == 4) {
      widgets.add(
        Positioned(
          left: 14,
          top: screenHeight * 0.36,
          child: _seatWidget(opponentPlayers[0]),
        ),
      );
      widgets.add(
        Positioned(
          top: topOffset,
          left: screenWidth * 0.5 - 75,
          child: _seatWidget(opponentPlayers[1]),
        ),
      );
      widgets.add(
        Positioned(
          right: 14,
          top: screenHeight * 0.36,
          child: _seatWidget(opponentPlayers[2]),
        ),
      );
    } else if (totalPlayers == 5) {
      widgets.add(
        Positioned(
          left: 12,
          top: screenHeight * 0.38,
          child: _seatWidget(opponentPlayers[0], isCompact: true),
        ),
      );
      widgets.add(
        Positioned(
          top: topOffset,
          left: screenWidth * 0.20,
          child: _seatWidget(opponentPlayers[1], isCompact: true),
        ),
      );
      widgets.add(
        Positioned(
          top: topOffset,
          right: screenWidth * 0.20,
          child: _seatWidget(opponentPlayers[2], isCompact: true),
        ),
      );
      widgets.add(
        Positioned(
          right: 12,
          top: screenHeight * 0.38,
          child: _seatWidget(opponentPlayers[3], isCompact: true),
        ),
      );
    } else {
      widgets.add(
        Positioned(
          left: 12,
          bottom: screenHeight * 0.26,
          child: _seatWidget(opponentPlayers[0], isCompact: true),
        ),
      );
      widgets.add(
        Positioned(
          left: 14,
          top: topOffset,
          child: _seatWidget(opponentPlayers[1], isCompact: true),
        ),
      );
      widgets.add(
        Positioned(
          top: topOffset,
          left: screenWidth * 0.5 - 66,
          child: _seatWidget(opponentPlayers[2], isCompact: true),
        ),
      );
      widgets.add(
        Positioned(
          right: 14,
          top: topOffset,
          child: _seatWidget(opponentPlayers[3], isCompact: true),
        ),
      );
      widgets.add(
        Positioned(
          right: 12,
          bottom: screenHeight * 0.26,
          child: _seatWidget(opponentPlayers[4], isCompact: true),
        ),
      );
    }

    return widgets;
  }

  Widget _seatWidget(GamePlayer player, {bool isCompact = false}) {
    final state = widget.state;
    final isCurrentTurn =
        !widget.isDealing && state.currentTurnPlayerIndex == player.id;
    final isThinking = isCurrentTurn && !player.isHuman && !state.isGameOver;

    return PlayerSeat(
      key: ValueKey<int>(player.id),
      player: player,
      isCurrentTurn: isCurrentTurn,
      isThinking: isThinking,
      isCompact: isCompact,
    );
  }

  Widget _buildHumanHandArea({
    required BuildContext context,
    required GamePlayer humanPlayer,
    required Size cardSize,
  }) {
    final state = widget.state;
    final isHumanTurn = !widget.isDealing && state.isHumanTurn;

    // Build the row of cards ONCE per state update; passed as static child during deal animation
    final cardsScrollRow = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final card in humanPlayer.hand)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildHumanCard(
                card: card,
                isHumanTurn: isHumanTurn,
                cardSize: cardSize,
              ),
            ),
        ],
      ),
    );

    Widget animatedHandRow;
    if (widget.isDealing && widget.dealingAnimation != null) {
      animatedHandRow = AnimatedBuilder(
        animation: widget.dealingAnimation!,
        child: cardsScrollRow,
        builder: (context, child) {
          final reveal =
              ((widget.dealingAnimation!.value - 0.25) / 0.75).clamp(0.0, 1.0);
          return Opacity(
            opacity: reveal,
            child: Transform.translate(
              offset: Offset(0, (1.0 - reveal) * 28),
              child: child,
            ),
          );
        },
      );
    } else if (widget.isDealing) {
      final reveal = ((widget.dealingProgress - 0.25) / 0.75).clamp(0.0, 1.0);
      animatedHandRow = Opacity(
        opacity: reveal,
        child: Transform.translate(
          offset: Offset(0, (1.0 - reveal) * 28),
          child: cardsScrollRow,
        ),
      );
    } else {
      animatedHandRow = cardsScrollRow;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Helper hint when it's human's turn
        if (isHumanTurn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white70, width: 0.8),
            ),
            child: Text(
              state.isOpeningMove
                  ? 'Opening Move: Tap any card to place on the table and take Global'
                  : 'Tap a legal card to pass to the table and take ${state.tableCard.displayName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        animatedHandRow,
      ],
    );
  }

  Widget _buildHumanCard({
    required GameCard card,
    required bool isHumanTurn,
    required Size cardSize,
  }) {
    final isLegal = isHumanTurn && widget.state.isLegalDiscard(card);

    return CountryCardView(
      key: ValueKey<String>(card.id),
      card: card,
      width: cardSize.width,
      height: cardSize.height,
      isLegal: !isHumanTurn || isLegal,
      isSelected: false,
      onTap: isLegal && !widget.isProcessingMove
          ? () {
              HapticService.instance.cardTap();
              AudioService.instance.playCardTap();
              widget.onCardSelected(card);
            }
          : null,
      onIllegalTap: isHumanTurn && !isLegal && !widget.isProcessingMove
          ? () {
              HapticService.instance.invalidMove();
            }
          : null,
    );
  }
}

class TableFeltPainter extends CustomPainter {
  const TableFeltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(10), const Radius.circular(20)),
      borderPaint,
    );

    final center = Offset(size.width / 2, size.height * 0.46);
    final ringPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 110, ringPaint);
    canvas.drawCircle(center, 85, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
