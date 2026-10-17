import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import 'move_validator.dart';

class BotStrategy {
  /// Evaluates legal discards for the active bot and chooses the optimal card.
  ///
  /// Guarantees:
  /// - Only selects strictly legal moves.
  /// - Treats Starting Card ("Total World") as neutral.
  /// - Never accesses hidden opponent hands.
  /// - Targets collecting N cards of the same country (where N = state.totalPlayers).
  static GameCard chooseDiscard({required GameState state}) {
    final bot = state.currentPlayer;
    final hand = bot.hand;
    final winningSetSize = state.totalPlayers;

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
        // Discarding starting card is strongly favored when building a country set,
        // because the starting card cannot contribute to an N-card country victory.
        score += 80.0;
      } else {
        final cType = candidate.type!;
        final count = typeCountsInHand[cType] ?? 0;

        if (cType == targetType) {
          // Severely penalize discarding our primary target country
          score -= 500.0 * count;
        } else {
          // Prefer discarding singletons over pairs or larger sets
          if (count == 1) {
            score += 120.0;
          } else if (count == 2) {
            score += 20.0;
          } else if (count >= winningSetSize - 1) {
            score -= 400.0; // Never break a set 1 card away from winning
          } else if (count >= 3) {
            score -= 220.0;
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
