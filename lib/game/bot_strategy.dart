import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import 'move_validator.dart';

class BotStrategy {
  /// Evaluates legal discards for the active bot and chooses the optimal card.
  ///
  /// Guarantees:
  /// - Only selects strictly legal moves.
  /// - Treats Starting Card as neutral.
  /// - Never accesses hidden opponent hands.
  /// - Protects sets of 2 or 3 of the same country.
  static GameCard chooseDiscard({required GameState state}) {
    final bot = state.currentPlayer;
    final hand = bot.hand;

    // Filter strictly legal cards
    final legalCards = hand.where((card) {
      final validation = MoveValidator.validateMove(
        state: state,
        discardCard: card,
      );
      return validation.isValid;
    }).toList();

    if (legalCards.isEmpty) {
      throw StateError(
        'Critical engine state: No legal move found for bot ${bot.name}',
      );
    }

    if (legalCards.length == 1) {
      return legalCards.first;
    }

    // 1. Analyze simulated new hand after taking table card
    // The table card will enter bot's hand, while the discarded card will leave.
    final tableCard = state.tableCard;
    final typeCountsInHand = bot.ordinaryTypeCounts;

    // Determine bot's primary strategic target type
    CountryType? targetType;
    int maxCount = 0;
    for (final entry in typeCountsInHand.entries) {
      int effectiveCount = entry.value;
      if (!tableCard.isStartingCard && tableCard.type == entry.key) {
        effectiveCount += 1;
      }
      if (effectiveCount > maxCount) {
        maxCount = effectiveCount;
        targetType = entry.key;
      }
    }

    // Default target type to homeType if no strong preference
    targetType ??= bot.homeType;

    // Score each candidate card for discarding.
    // HIGHER score means MORE desirable to discard.
    GameCard? bestCandidate;
    double bestScore = -999999.0;

    for (final candidate in legalCards) {
      double score = 0.0;

      if (candidate.isStartingCard) {
        // Discarding starting card is often very good if bot is building a country set,
        // because starting card cannot win.
        score += 50.0;
      } else {
        final cType = candidate.type!;
        final count = typeCountsInHand[cType] ?? 0;

        if (cType == targetType) {
          // Severely penalize discarding our primary target
          score -= 500.0 * count;
        } else {
          // Prefer discarding types where we only have 1 card
          if (count == 1) {
            score += 100.0;
          } else if (count == 2) {
            score += 20.0; // Moderate reluctance to break a pair
          } else if (count >= 3) {
            score -= 200.0; // High reluctance to break a triple
          }
        }

        // Slight preference to keep home type if count is tied
        if (cType == bot.homeType) {
          score -= 5.0;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestCandidate = candidate;
      }
    }

    return bestCandidate ?? legalCards.first;
  }
}
