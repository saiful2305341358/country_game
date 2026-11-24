import 'dart:math';

import '../game/game_engine.dart';
import '../models/game_settings.dart';
import '../models/game_state.dart';

/// Game logic run on the host's phone, which is the referee of a room.
///
/// It reuses the offline [GameEngine] unchanged, so online rounds follow
/// exactly the same rules. It keeps no state between calls: every move is
/// applied to the latest shared state.
class HostReferee {
  static const int minPlayers = 3;
  static const int maxPlayers = 7;

  /// Deals a new round for [playerNames] (seat order). Every seat is human.
  static GameState startRound(List<String> playerNames, {Random? random}) {
    if (playerNames.length < minPlayers || playerNames.length > maxPlayers) {
      throw ArgumentError(
        'A round needs $minPlayers to $maxPlayers players, '
        'got ${playerNames.length}',
      );
    }
    final engine = _engine();
    try {
      engine.startNewGame(
        totalPlayers: playerNames.length,
        playerNames: playerNames,
        randomSeed: random?.nextInt(1 << 31),
      );
      return engine.state!;
    } finally {
      engine.dispose();
    }
  }

  /// Applies the move "player at [seat] discards card [cardId]" to [state].
  ///
  /// Returns the new state, or null when the move is not allowed: the round is
  /// over, it is not that player's turn, the card is not in their hand, or the
  /// same-country rule forbids it.
  static GameState? applyMove(GameState state, int seat, String cardId) {
    if (state.isGameOver || state.currentTurnPlayerIndex != seat) return null;
    final card =
        state.currentPlayer.hand.where((c) => c.id == cardId).firstOrNull;
    if (card == null || !state.isLegalDiscard(card)) return null;

    final engine = _engine();
    try {
      engine.loadState(state);
      return engine.makeMove(card) ? engine.state : null;
    } finally {
      engine.dispose();
    }
  }

  static GameEngine _engine() => GameEngine(
        initialSettings: const GameSettings(animationsEnabled: false),
      );
}
