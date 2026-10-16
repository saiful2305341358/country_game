import '../models/game_card.dart';
import '../models/game_state.dart';

class MoveValidationResult {
  final bool isValid;
  final String? errorMessage;

  const MoveValidationResult.success()
      : isValid = true,
        errorMessage = null;

  const MoveValidationResult.failure(this.errorMessage) : isValid = false;
}

class MoveValidator {
  static MoveValidationResult validateMove({
    required GameState state,
    required GameCard discardCard,
  }) {
    if (state.isGameOver) {
      return const MoveValidationResult.failure(
        'The game has already concluded. Please start a new game.',
      );
    }

    final currentPlayer = state.currentPlayer;
    final hasCard = currentPlayer.hand.any((c) => c.id == discardCard.id);
    if (!hasCard) {
      return MoveValidationResult.failure(
        '${discardCard.displayName} is not in ${currentPlayer.name}\'s hand.',
      );
    }

    // Opening move exemption: when table card is Starting Card
    if (state.isOpeningMove && state.tableCard.isStartingCard) {
      return const MoveValidationResult.success();
    }

    // If table card is Starting Card (re-placed later in game)
    if (state.tableCard.isStartingCard) {
      return const MoveValidationResult.success();
    }

    // If candidate card to discard is the Starting Card
    if (discardCard.isStartingCard) {
      return const MoveValidationResult.success();
    }

    // Same-type exchange restriction:
    // "A player cannot discard a card of the same ordinary type as the card currently on the table."
    if (discardCard.type == state.tableCard.type) {
      final typeName = state.tableCard.type?.displayName ?? 'this country';
      return MoveValidationResult.failure(
        'Same-Type Restriction: You cannot discard a $typeName card when a $typeName card is on the table.',
      );
    }

    return const MoveValidationResult.success();
  }
}
