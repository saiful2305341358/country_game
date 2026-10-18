import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import 'move_validator.dart';

/// Encapsulates a bot's selected discard card along with a context-aware,
/// human-like deliberation ("think") delay in milliseconds.
class BotDecision {
  final GameCard discardCard;
  final int thinkDelayMs;
  final bool isHesitantChoice;

  const BotDecision({
    required this.discardCard,
    required this.thinkDelayMs,
    this.isHesitantChoice = false,
  });
}

class BotStrategy {
  /// Evaluates legal discards for the active bot and returns both the optimal [GameCard]
  /// and a natural, human-like `thinkDelayMs` scaled to the decision's complexity.
  static BotDecision evaluateDecision({
    required GameState state,
    int baseDelayMs = 1650,
  }) {
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

    // Deterministic per-bot / per-turn micro-variation (-40ms .. +60ms)
    // so consecutive bots feel organic rather than mechanical.
    final cadenceJitterMs =
        (((state.turnCount * 37 + bot.id * 53) % 101) - 40);

    if (legalCards.length == 1) {
      final quickDelay =
          (baseDelayMs * 0.36 + cadenceJitterMs).round().clamp(420, 1100);
      return BotDecision(
        discardCard: legalCards.first,
        thinkDelayMs: quickDelay,
        isHesitantChoice: false,
      );
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

    // Check if picking up tableCard immediately completes a winning set of N cards
    final bool completesWinningSet = !tableCard.isStartingCard &&
        tableCard.type != null &&
        (typeCountsInHand[tableCard.type!] ?? 0) >= (winningSetSize - 1);

    // Score each candidate card for discarding.
    // HIGHER score means MORE desirable to discard.
    GameCard? bestCandidate;
    double bestScore = -999999.0;
    double secondBestScore = -999999.0;

    for (int i = 0; i < legalCards.length; i++) {
      final candidate = legalCards[i];
      double score = 0.0;

      if (candidate.isStartingCard) {
        // Discarding starting card is strongly favored when building a country set,
        // because the starting card cannot contribute to an N-card country victory.
        score += 95.0;
      } else {
        final cType = candidate.type!;
        final count = typeCountsInHand[cType] ?? 0;

        if (completesWinningSet && cType == tableCard.type) {
          // Never discard a card belonging to the set we are about to complete
          score -= 2000.0;
        } else if (cType == targetType) {
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

        // Subtle memory of the last taken card: avoid immediately feeding the exact
        // country the previous player just picked up if another singleton is available.
        if (state.lastTakenCard != null &&
            !state.lastTakenCard!.isStartingCard &&
            state.lastTakenCard!.type == cType) {
          score -= 12.0;
        }

        // Slight preference to keep home type if count is tied
        if (cType == bot.homeType) {
          score -= 5.0;
        }

        // Small deterministic tie-breaker across hand slots
        score += ((i + state.turnCount) % 3) * 0.5;
      }

      if (score > bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestCandidate = candidate;
      } else if (score > secondBestScore) {
        secondBestScore = score;
      }
    }

    final chosen = bestCandidate ?? legalCards.first;
    final scoreGap = (bestScore - secondBestScore).abs();

    // Determine human-like deliberation factor based on decision difficulty:
    // - Winning move or discarding Starting Card -> confident, brisk pause (0.40x)
    // - Forced to break a pair or very close tie between options -> longer deliberation (0.58x)
    // - Standard singleton swap -> balanced, deliberate human pause (0.48x)
    final bool isBreakingPair = !chosen.isStartingCard &&
        chosen.type != null &&
        (typeCountsInHand[chosen.type!] ?? 0) >= 2;
    final bool isCloseCall = scoreGap < 18.0 || isBreakingPair;

    final double complexityFactor;
    if (completesWinningSet || chosen.isStartingCard) {
      complexityFactor = 0.40;
    } else if (isCloseCall) {
      complexityFactor = 0.58;
    } else {
      complexityFactor = 0.48;
    }

    final int thinkDelayMs = (baseDelayMs * complexityFactor + cadenceJitterMs)
        .round()
        .clamp(480, 1450);

    return BotDecision(
      discardCard: chosen,
      thinkDelayMs: thinkDelayMs,
      isHesitantChoice: isCloseCall,
    );
  }

  /// Evaluates legal discards for the active bot and chooses the optimal card.
  ///
  /// Guarantees:
  /// - Only selects strictly legal moves.
  /// - Treats Starting Card ("Total World") as neutral.
  /// - Never accesses hidden opponent hands.
  /// - Targets collecting N cards of the same country (where N = state.totalPlayers).
  static GameCard chooseDiscard({required GameState state}) {
    return evaluateDecision(state: state).discardCard;
  }
}
