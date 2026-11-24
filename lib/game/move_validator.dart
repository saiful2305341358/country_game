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

    // The legality rules live in one place (GameState.isLegalDiscard); the only
    // remaining way to fail here is the same-type restriction.
    if (!state.isLegalDiscard(discardCard)) {
      final typeName = state.tableCard.type?.displayName ?? 'this country';
      return MoveValidationResult.failure(
        'Same-Type Restriction: You cannot discard a $typeName card when a $typeName card is on the table.',
      );
    }

    return const MoveValidationResult.success();
  }
}
