import 'package:flutter/foundation.dart';
import 'card_type.dart';
import 'game_card.dart';
import 'game_player.dart';

@immutable
class GameState {
  final int totalPlayers;
  final List<CountryType> activeTypes;
  final List<GamePlayer> players;
  final GameCard tableCard;
  final int startingPlayerIndex;
  final int currentTurnPlayerIndex;
  final int turnCount;
  final bool isOpeningMove;
  final GamePlayer? winner;
  final CountryType? winningType;
  final String statusMessage;
  final List<String> moveLog;

  /// Metadata for the most recent card exchange to drive 2D table animations.
  final int? lastMovePlayerIndex;
  final GameCard? lastTakenCard;
  final GameCard? lastDiscardedCard;

  const GameState({
    required this.totalPlayers,
    required this.activeTypes,
    required this.players,
    required this.tableCard,
    required this.startingPlayerIndex,
    required this.currentTurnPlayerIndex,
    required this.turnCount,
    required this.isOpeningMove,
    this.winner,
    this.winningType,
    required this.statusMessage,
    this.moveLog = const [],
    this.lastMovePlayerIndex,
    this.lastTakenCard,
    this.lastDiscardedCard,
  });

  bool get isGameOver => winner != null;

  GamePlayer get currentPlayer => players[currentTurnPlayerIndex];

  bool get isHumanTurn => !isGameOver && currentPlayer.isHuman;

  /// Dynamic winning set size equals totalPlayers (N).
  int get winningSetSize => totalPlayers;

  bool isLegalDiscard(GameCard candidate) {
    if (isGameOver) return false;
    // Card must be in current player's hand
    if (!currentPlayer.hand.any((c) => c.id == candidate.id)) return false;

    // Rule 1: Starting move exemption
    if (isOpeningMove && tableCard.isStartingCard) {
      return true;
    }

    // Rule 2: If table card is starting card, player can discard any card
    if (tableCard.isStartingCard) {
      return true;
    }

    // Rule 3: Candidate is starting card: always legal because starting card has no ordinary type
    if (candidate.isStartingCard) {
      return true;
    }

    // Rule 4: Same-type restriction: cannot discard card of same ordinary type as table card
    return candidate.type != tableCard.type;
  }

  GameState copyWith({
    int? totalPlayers,
    List<CountryType>? activeTypes,
    List<GamePlayer>? players,
    GameCard? tableCard,
    int? startingPlayerIndex,
    int? currentTurnPlayerIndex,
    int? turnCount,
    bool? isOpeningMove,
    GamePlayer? winner,
    CountryType? winningType,
    String? statusMessage,
    List<String>? moveLog,
    int? lastMovePlayerIndex,
    GameCard? lastTakenCard,
    GameCard? lastDiscardedCard,
  }) {
    return GameState(
      totalPlayers: totalPlayers ?? this.totalPlayers,
      activeTypes: activeTypes ?? this.activeTypes,
      players: players ?? this.players,
      tableCard: tableCard ?? this.tableCard,
      startingPlayerIndex: startingPlayerIndex ?? this.startingPlayerIndex,
      currentTurnPlayerIndex:
          currentTurnPlayerIndex ?? this.currentTurnPlayerIndex,
      turnCount: turnCount ?? this.turnCount,
      isOpeningMove: isOpeningMove ?? this.isOpeningMove,
      winner: winner ?? this.winner,
      winningType: winningType ?? this.winningType,
      statusMessage: statusMessage ?? this.statusMessage,
      moveLog: moveLog ?? this.moveLog,
      lastMovePlayerIndex: lastMovePlayerIndex ?? this.lastMovePlayerIndex,
      lastTakenCard: lastTakenCard ?? this.lastTakenCard,
      lastDiscardedCard: lastDiscardedCard ?? this.lastDiscardedCard,
    );
  }
}
