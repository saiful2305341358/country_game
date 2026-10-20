import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_player.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';
import 'bot_strategy.dart';
import 'card_deck_factory.dart';
import 'initial_exchange.dart';
import 'move_validator.dart';
import 'winner_detector.dart';

class GameEngine extends ChangeNotifier {
  GameState? _state;
  GameSettings _settings;
  Timer? _botTimer;
  int _gameSessionId = 0;
  bool _isProcessingMove = false;
  bool _isExchangeAnimating = false;
  bool _isPaused = false;
  final bool waitForExchangeAnimation;

  GameEngine({
    GameSettings? initialSettings,
    this.waitForExchangeAnimation = false,
  }) : _settings = initialSettings ?? GameSettings.current;

  GameState? get state => _state;
  GameSettings get settings => _settings;
  bool get hasActiveGame => _state != null;
  bool get isProcessingMove => _isProcessingMove || _isExchangeAnimating;
  bool get isExchangeAnimating => _isExchangeAnimating;
  bool get isPaused => _isPaused;

  void updateSettings(GameSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// Starts a new game with [totalPlayers] (3, 4, 5, or 6).
  /// If [deferBotStart] is true, bot turns wait until [resumeActivePlay] is called
  /// (used while the initial card dealing animation plays on screen).
  void startNewGame({
    int? totalPlayers,
    int? randomSeed,
    List<CountryType>? predefinedTypes,
    bool deferBotStart = false,
  }) {
    _cancelBotAction();
    _gameSessionId++;
    final currentSession = _gameSessionId;
    _isProcessingMove = false;
    _isExchangeAnimating = false;
    _isPaused = deferBotStart;

    final n = totalPlayers ?? _settings.totalPlayers;
    if (n < 3 || n > 7) {
      throw ArgumentError('Invalid player count: $n. Must be 3, 4, 5, 6, or 7.');
    }

    final rng = randomSeed != null ? Random(randomSeed) : Random();

    // 1. Create deck & starting card with dynamic selection
    final deckResult = CardDeckFactory.createDeck(
      n,
      predefinedTypes: predefinedTypes,
      random: rng,
    );

    // 2. Perform simultaneous initial exchange with clean Western names
    final players = InitialExchangeService.performInitialExchange(
      activeTypes: deckResult.activeTypes,
      initialDeckByType: deckResult.ordinaryCardsByType,
      random: rng,
    );

    // 3. Random starting player
    final startingIndex = rng.nextInt(n);
    final startingPlayer = players[startingIndex];

    // 4. Construct initial state
    final initialStatus = startingPlayer.isHuman
        ? 'Opening move: Choose a card from your hand to trade for Global.'
        : '${startingPlayer.name} takes the opening turn with Global.';

    _state = GameState(
      totalPlayers: n,
      activeTypes: deckResult.activeTypes,
      players: players,
      tableCard: deckResult.startingCard,
      startingPlayerIndex: startingIndex,
      currentTurnPlayerIndex: startingIndex,
      turnCount: 0,
      isOpeningMove: true,
      statusMessage: initialStatus,
      moveLog: [
        'Game initialized with $n players (Winning Set: $n cards).',
        startingPlayer.isHuman
            ? 'You were selected to open with Global.'
            : '${startingPlayer.name} selected to open with Global.',
      ],
    );

    assert(verifyIntegrity());
    notifyListeners();

    if (!deferBotStart) {
      _triggerBotIfNeeded(currentSession);
    }
  }

  /// Called after initial dealing animation finishes or when unpausing the game.
  void resumeActivePlay() {
    if (_state == null) return;
    _isPaused = false;
    if (!_isExchangeAnimating) {
      _triggerBotIfNeeded(_gameSessionId);
    }
  }

  /// Called by the UI when both phases of the card exchange animation complete.
  void completeExchangeAnimation() {
    if (!_isExchangeAnimating) return;
    _isExchangeAnimating = false;
    notifyListeners();
    if (!_isPaused) {
      _triggerBotIfNeeded(_gameSessionId);
    }
  }

  /// Pauses scheduled bot actions while pause dialog is open.
  void pauseActivePlay() {
    _isPaused = true;
    _cancelBotAction();
  }

  /// Cancels any scheduled bot moves.
  void _cancelBotAction() {
    _botTimer?.cancel();
    _botTimer = null;
  }

  /// Attempts to make a move for the active player.
  /// Discards [discardCard] and takes the current table card.
  bool makeMove(GameCard discardCard) {
    if (_state == null || _isProcessingMove || _isExchangeAnimating) {
      return false;
    }
    final currentSession = _gameSessionId;

    final validation = MoveValidator.validateMove(
      state: _state!,
      discardCard: discardCard,
    );

    if (!validation.isValid) {
      _state = _state!.copyWith(
        statusMessage: validation.errorMessage ?? 'Invalid move',
      );
      notifyListeners();
      return false;
    }

    _isProcessingMove = true;
    final state = _state!;
    final activePlayerIndex = state.currentTurnPlayerIndex;
    final activePlayer = state.currentPlayer;
    final oldTableCard = state.tableCard;

    // 1. Update active player's hand in-place so card slot alignment is preserved
    final updatedHand = List<GameCard>.from(activePlayer.hand);
    final replacedIndex = updatedHand.indexOf(discardCard);
    if (replacedIndex == -1) {
      _isProcessingMove = false;
      return false;
    }
    updatedHand[replacedIndex] = oldTableCard;

    final updatedPlayer = activePlayer.copyWith(hand: updatedHand);

    // 2. Update players list
    final updatedPlayers = List<GamePlayer>.from(state.players);
    updatedPlayers[activePlayerIndex] = updatedPlayer;

    // 3. Check for victory immediately using dynamic set size = state.totalPlayers
    final winningType = WinnerDetector.checkWinner(
      updatedPlayer,
      requiredSetSize: state.totalPlayers,
    );
    final hasWon = winningType != null;

    final logEntry = state.isOpeningMove
        ? '${activePlayer.name} took Global and placed ${discardCard.displayName} on the table.'
        : '${activePlayer.name} traded ${discardCard.displayName} for ${oldTableCard.displayName}.';

    // Cap moveLog at 24 recent entries to avoid unbounded list copying & GC pressure on low-end devices
    final prevLogs = state.moveLog;
    final newMoveLog = prevLogs.length >= 24
        ? <String>[...prevLogs.sublist(prevLogs.length - 23), logEntry]
        : <String>[...prevLogs, logEntry];

    final shouldLockForAnimation =
        waitForExchangeAnimation && _settings.animationsEnabled;

    if (hasWon) {
      _state = state.copyWith(
        players: updatedPlayers,
        tableCard: discardCard,
        turnCount: state.turnCount + 1,
        isOpeningMove: false,
        winner: updatedPlayer,
        winningType: winningType,
        statusMessage: updatedPlayer.isHuman
            ? '🏆 You collected all ${state.totalPlayers} ${winningType.displayName} cards and won the game!'
            : '🏆 ${updatedPlayer.name} collected all ${state.totalPlayers} ${winningType.displayName} cards and won the game!',
        moveLog: newMoveLog,
        lastMovePlayerIndex: activePlayerIndex,
        lastMoveHandIndex: replacedIndex,
        lastTakenCard: oldTableCard,
        lastDiscardedCard: discardCard,
      );
      _isProcessingMove = false;
      _isExchangeAnimating = shouldLockForAnimation;
      assert(verifyIntegrity());
      notifyListeners();
      return true;
    }

    // 4. Advance turn to next neighbor
    final nextTurnIndex =
        (state.currentTurnPlayerIndex + 1) % state.totalPlayers;
    final nextPlayer = updatedPlayers[nextTurnIndex];

    final nextStatus = nextPlayer.isHuman
        ? '${activePlayer.name} placed ${discardCard.displayName}. Select a card to trade.'
        : '${activePlayer.name} placed ${discardCard.displayName} • ${nextPlayer.name}\'s turn';

    _state = state.copyWith(
      players: updatedPlayers,
      tableCard: discardCard,
      currentTurnPlayerIndex: nextTurnIndex,
      turnCount: state.turnCount + 1,
      isOpeningMove: false,
      statusMessage: nextStatus,
      moveLog: newMoveLog,
      lastMovePlayerIndex: activePlayerIndex,
      lastMoveHandIndex: replacedIndex,
      lastTakenCard: oldTableCard,
      lastDiscardedCard: discardCard,
    );

    _isProcessingMove = false;
    _isExchangeAnimating = shouldLockForAnimation;
    assert(verifyIntegrity());
    notifyListeners();

    // Trigger next bot move only once exchange animation completes (or immediately if animations disabled)
    if (!_isPaused && !_isExchangeAnimating) {
      _triggerBotIfNeeded(currentSession);
    }
    return true;
  }

  void _triggerBotIfNeeded(int sessionId) {
    if (_state == null ||
        _state!.isGameOver ||
        _isPaused ||
        _isExchangeAnimating) {
      return;
    }
    if (_state!.isHumanTurn) return;

    _cancelBotAction();

    BotDecision? precomputedDecision;
    try {
      precomputedDecision = BotStrategy.evaluateDecision(
        state: _state!,
        baseDelayMs: _settings.botDelayMs,
      );
    } catch (_) {}

    final int computedThinkMs = precomputedDecision?.thinkDelayMs ??
        (_settings.botDelayMs * 0.48).round().clamp(480, 1100);

    final delay = _settings.animationsEnabled
        ? Duration(
            milliseconds: waitForExchangeAnimation
                ? computedThinkMs
                : _settings.botDelayMs,
          )
        : const Duration(milliseconds: 100);

    _botTimer = Timer(delay, () {
      if (_gameSessionId != sessionId || _isPaused || _isExchangeAnimating) {
        return;
      }
      if (_state == null || _state!.isGameOver) return;
      if (_state!.isHumanTurn) return;

      try {
        final botDiscard = precomputedDecision?.discardCard ??
            BotStrategy.chooseDiscard(state: _state!);
        makeMove(botDiscard);
      } catch (e) {
        debugPrint('Error in bot move: $e');
      }
    });
  }

  /// Verifies all invariant rules including dynamic N-card winning set size.
  bool verifyIntegrity() {
    if (_state == null) return true;
    final s = _state!;
    final n = s.totalPlayers;

    // 1. Invariant: Table has exactly 1 card
    assert(s.tableCard.id.isNotEmpty, 'Table card must exist');

    // 2. Invariant: Total cards constant: N * N + 1
    final allCards = <GameCard>[s.tableCard];
    for (final p in s.players) {
      // Invariant: Hand size is exactly N
      assert(
        p.hand.length == n,
        'Player ${p.name} has ${p.hand.length} cards, expected $n',
      );
      allCards.addAll(p.hand);
    }

    final expectedTotal = n * n + 1;
    assert(
      allCards.length == expectedTotal,
      'Total cards count ${allCards.length} != expected $expectedTotal',
    );

    // 3. Invariant: Unique card IDs (no duplicate card exists)
    final ids = allCards.map((c) => c.id).toSet();
    assert(
      ids.length == expectedTotal,
      'Duplicate card IDs found! Found ${ids.length} unique of $expectedTotal cards',
    );

    // 4. Invariant: Starting card exists exactly once
    final startingCards = allCards.where((c) => c.isStartingCard).toList();
    assert(
      startingCards.length == 1,
      'Starting card must exist exactly once, found ${startingCards.length}',
    );

    // 5. Invariant: Starting card cannot count towards victory; winner needs N ordinary cards
    for (final p in s.players) {
      final ordinaryCards = p.hand.where((c) => !c.isStartingCard).toList();
      final winType = p.getWinningType(requiredSetSize: n);
      if (winType != null) {
        final count = ordinaryCards.where((c) => c.type == winType).length;
        assert(
          count >= n,
          'Player ${p.name} declared winner in $n-player game but only has $count of $winType',
        );
      }
    }

    return true;
  }

  void resetCurrentGame({bool deferBotStart = false}) {
    if (_state != null) {
      startNewGame(
        totalPlayers: _state!.totalPlayers,
        deferBotStart: deferBotStart,
      );
    }
  }

  void leaveGame() {
    _cancelBotAction();
    _gameSessionId++;
    _state = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelBotAction();
    super.dispose();
  }
}
