import '../models/card_type.dart';
import '../models/game_player.dart';

class WinnerDetector {
  /// Checks whether [player] holds 4 ordinary cards of the same [CountryType].
  ///
  /// Strict Invariants:
  /// - Only ordinary cards count.
  /// - The Starting Card is strictly ignored and NEVER contributes to the set.
  /// - 3 ordinary cards + Starting Card is NOT a win.
  static CountryType? checkWinner(GamePlayer player) {
    return player.winningType;
  }
}
