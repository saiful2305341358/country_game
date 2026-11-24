import '../models/game_player.dart';
import '../models/game_state.dart';

/// Turns the shared game state into what one phone should draw.
///
/// The table always draws `players[0]` as the local player at the bottom and
/// opponents in seats 1..N-1, and only `players[0]` is marked human (so only
/// that hand is face-up and tappable). This rotates the state so [mySeat] comes
/// first, renumbers every seat index accordingly, and rewrites the status line
/// from this player's point of view.
class SeatView {
  static GameState forSeat(GameState s, int mySeat) {
    final n = s.totalPlayers;
    if (mySeat < 0 || mySeat >= n) {
      throw RangeError.range(mySeat, 0, n - 1, 'mySeat');
    }
    int view(int seat) => (seat - mySeat + n) % n;
    int? viewOrNull(int? seat) => seat == null ? null : view(seat);

    GamePlayer rotated(GamePlayer p) {
      final v = view(p.id);
      return GamePlayer(
        id: v,
        name: v == 0 ? 'You' : p.name,
        isHuman: v == 0,
        isFemale: p.isFemale,
        homeType: p.homeType,
        hand: p.hand,
      );
    }

    final players = List<GamePlayer>.generate(
      n,
      (v) => rotated(s.players[(v + mySeat) % n]),
    );
    final winner = s.winner == null ? null : players[view(s.winner!.id)];

    final history = s.recentPlayedCards.map((e) {
      final v = view(e.playerId);
      return PlayedCardHistoryEntry(
        turnNumber: e.turnNumber,
        playerId: v,
        playerName: v == 0 ? 'You' : e.playerName,
        isHuman: v == 0,
        isFemale: e.isFemale,
        playedCard: e.playedCard,
        takenCard: e.takenCard,
      );
    }).toList();

    final current = players[view(s.currentTurnPlayerIndex)];
    final String status;
    if (winner != null) {
      final set = '${s.totalPlayers} ${s.winningType?.displayName ?? ''} cards';
      status = winner.id == 0
          ? '🏆 You collected all $set and won the round!'
          : '🏆 ${winner.name} collected all $set and won the round!';
    } else if (current.id == 0) {
      status = s.isOpeningMove
          ? 'Your opening move: choose a card to trade for Global.'
          : 'Your turn: choose a card to trade with the table.';
    } else {
      status = 'Waiting for ${current.name}…';
    }

    return GameState(
      totalPlayers: n,
      activeTypes: s.activeTypes,
      players: players,
      tableCard: s.tableCard,
      startingPlayerIndex: view(s.startingPlayerIndex),
      currentTurnPlayerIndex: view(s.currentTurnPlayerIndex),
      turnCount: s.turnCount,
      isOpeningMove: s.isOpeningMove,
      winner: winner,
      winningType: s.winningType,
      statusMessage: status,
      moveLog: s.moveLog,
      recentPlayedCards: history,
      lastMovePlayerIndex: viewOrNull(s.lastMovePlayerIndex),
      lastMoveHandIndex: s.lastMoveHandIndex,
      lastTakenCard: s.lastTakenCard,
      lastDiscardedCard: s.lastDiscardedCard,
    );
  }
}
