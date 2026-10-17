import '../models/card_type.dart';
import '../models/game_player.dart';

class WinnerDetector {
  /// Checks whether [player] holds [requiredSetSize] (N = totalPlayers)
  /// ordinary cards of the same [CountryType].
  ///
  /// Strict Invariants:
  /// - Winning Set Size = Total Number of Players (N).
  /// - Only ordinary cards count.
  /// - The Starting Card ("Total World") is strictly ignored and NEVER contributes to the set.
  /// - (N - 1) ordinary cards + Starting Card is NOT a win.
  static CountryType? checkWinner(
    GamePlayer player, {
    int? requiredSetSize,
  }) {
    return player.getWinningType(requiredSetSize: requiredSetSize);
  }
}
