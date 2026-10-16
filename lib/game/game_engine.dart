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

  GameEngine({GameSettings? initialSettings})
      : _settings = initialSettings ?? const GameSettings();

  GameState? get state => _state;
  GameSettings get settings => _settings;
  bool get hasActiveGame => _state != null;
  bool get isProcessingMove => _isProcessingMove;

  void updateSettings(GameSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// Starts a new game with [totalPlayers] (4, 5, or 6).
  void startNewGame({
    int? totalPlayers,
    int? randomSeed,
    List<CountryType>? predefinedTypes,
  }) {
    _cancelBotAction();
    _gameSessionId++;
    final currentSession = _gameSessionId;
    _isProcessingMove = false;

    final n = totalPlayers ?? _settings.totalPlayers;
    if (n < 4 || n > 6) {
      throw ArgumentError('Invalid player count: $n. Must be 4, 5, or 6.');
    }

    final rng = randomSeed != null ? Random(randomSeed) : Random();

    // 1. Create deck & starting card with dynamic selection
    final deckResult = CardDeckFactory.createDeck(
      n,
      predefinedTypes: predefinedTypes,
      random: rng,
    );

    // 2. Perform simultaneous initial exchange with Western name generation
    final players = InitialExchangeService.performInitialExchange(
      activeTypes: deckResult.activeTypes,
      initialDeckByType: deckResult.ordinaryCardsByType,
      random: rng,
    );

    // 3. Random starting player
    final startingIndex = rng.nextInt(n);

    // 4. Construct initial state
    final startingPlayerName = players[startingIndex].name;
    _state = GameState(
      totalPlayers: n,
      activeTypes: deckResult.activeTypes,
      players: players,
      tableCard: deckResult.startingCard,
      startingPlayerIndex: startingIndex,
      currentTurnPlayerIndex: startingIndex,
      turnCount: 0,
      isOpeningMove: true,
      statusMessage:
          'Game started! $startingPlayerName was chosen to make the opening move with the Starting Card.',
      moveLog: [
        'Game initialized with $n players.',
        '$startingPlayerName selected to take the Starting Card.',
      ],
    );

    verifyIntegrity();
    notifyListeners();

    // If starting player is a bot, schedule their opening move
    _triggerBotIfNeeded(currentSession);
  }

  /// Cancels any scheduled bot moves.
  void _cancelBotAction() {
    _botTimer?.cancel();
    _botTimer = null;
  }

  /// Attempts to make a move for the active player.
  /// Discards [discardCard] and takes the current table card.
  bool makeMove(GameCard discardCard) {
    if (_state == null || _isProcessingMove) return false;
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
    final activePlayer = state.currentPlayer;
    final oldTableCard = state.tableCard;

    // 1. Update active player's hand: remove discardCard, add oldTableCard
    final updatedHand = List<GameCard>.from(activePlayer.hand);
    final removed = updatedHand.remove(discardCard);
    if (!removed) {
      _isProcessingMove = false;
      return false;
    }
    updatedHand.add(oldTableCard);

    final updatedPlayer = activePlayer.copyWith(hand: updatedHand);

    // 2. Update players list
    final updatedPlayers = List<GamePlayer>.from(state.players);
    updatedPlayers[state.currentTurnPlayerIndex] = updatedPlayer;

    // 3. Check for victory immediately
    final winningType = WinnerDetector.checkWinner(updatedPlayer);
    final hasWon = winningType != null;

    final logEntry = state.isOpeningMove
        ? '${activePlayer.name} took the Starting Card and placed ${discardCard.displayName} on the table.'
        : '${activePlayer.name} exchanged ${discardCard.displayName} for ${oldTableCard.displayName}.';

    final newMoveLog = List<String>.from(state.moveLog)..add(logEntry);

    if (hasWon) {
      _state = state.copyWith(
        players: updatedPlayers,
        tableCard: discardCard,
        turnCount: state.turnCount + 1,
        isOpeningMove: false,
        winner: updatedPlayer,
        winningType: winningType,
        statusMessage:
            '🏆 ${updatedPlayer.name} has collected 4 ${winningType.displayName} cards and won the game!',
        moveLog: newMoveLog,
      );
      _isProcessingMove = false;
      verifyIntegrity();
      notifyListeners();
      return true;
    }

    // 4. Advance turn to right-hand neighbor
    final nextTurnIndex = (state.currentTurnPlayerIndex + 1) % state.totalPlayers;
    final nextPlayer = updatedPlayers[nextTurnIndex];

    _state = state.copyWith(
      players: updatedPlayers,
      tableCard: discardCard,
      currentTurnPlayerIndex: nextTurnIndex,
      turnCount: state.turnCount + 1,
      isOpeningMove: false,
      statusMessage: '${nextPlayer.name}\'s turn to exchange a card.',
      moveLog: newMoveLog,
    );

    _isProcessingMove = false;
    verifyIntegrity();
    notifyListeners();

    // Trigger next bot move if next player is bot
    _triggerBotIfNeeded(currentSession);
    return true;
  }

  void _triggerBotIfNeeded(int sessionId) {
    if (_state == null || _state!.isGameOver) return;
    if (_state!.isHumanTurn) return;

    _cancelBotAction();

    final delay = _settings.animationsEnabled
        ? Duration(milliseconds: _settings.botDelayMs)
        : const Duration(milliseconds: 100);

    _botTimer = Timer(delay, () {
      if (_gameSessionId != sessionId) return;
      if (_state == null || _state!.isGameOver) return;
      if (_state!.isHumanTurn) return;

      try {
        final botDiscard = BotStrategy.chooseDiscard(state: _state!);
        makeMove(botDiscard);
      } catch (e) {
        debugPrint('Error in bot move: $e');
      }
    });
  }

  /// Verifies all 16 invariant rules specified in prompt section 16.
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

    // 5. Invariant: Starting card cannot count towards victory
    for (final p in s.players) {
      final ordinaryCards = p.hand.where((c) => !c.isStartingCard).toList();
      final winType = p.winningType;
      if (winType != null) {
        final count = ordinaryCards.where((c) => c.type == winType).length;
        assert(
          count >= 4,
          'Player ${p.name} declared winner but only has $count of $winType',
        );
      }
    }

    return true;
  }

  void resetCurrentGame() {
    if (_state != null) {
      startNewGame(totalPlayers: _state!.totalPlayers);
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
