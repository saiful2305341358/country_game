import 'dart:math';
import '../models/card_type.dart';
import '../models/game_card.dart';

class CardDeckFactory {
  static const List<CountryType> allAvailableTypes = [
    CountryType.australia,
    CountryType.greatBritain,
    CountryType.saudiArabia,
    CountryType.iran,
    CountryType.japan,
    CountryType.bangladesh,
  ];

  /// Stores the most recent selection of types to avoid immediate repetition.
  static List<CountryType>? _previousSelection;

  static const List<CountryType> allSevenTypes = [
    CountryType.australia,
    CountryType.greatBritain,
    CountryType.saudiArabia,
    CountryType.iran,
    CountryType.japan,
    CountryType.bangladesh,
    CountryType.brazil,
  ];

  /// Deterministically or randomly select [totalPlayers] distinct country types
  /// without immediately repeating the previous combination.
  static List<CountryType> selectActiveTypes(
    int totalPlayers, {
    Random? random,
    bool allowRepeat = false,
  }) {
    if (totalPlayers < 3 || totalPlayers > 7) {
      throw ArgumentError(
        'Supported player counts are 3, 4, 5, 6, or 7. Received: $totalPlayers',
      );
    }

    final rng = random ?? Random();

    if (totalPlayers == 7) {
      final shuffled = List<CountryType>.from(allSevenTypes)..shuffle(rng);
      _previousSelection = List.unmodifiable(shuffled);
      return shuffled;
    }

    if (totalPlayers == 6) {
      // Use all 6 types, but randomly permute their assignment
      final shuffled = List<CountryType>.from(allAvailableTypes)..shuffle(rng);
      _previousSelection = List.unmodifiable(shuffled);
      return shuffled;
    }

    // Generate all combinations of totalPlayers from 6
    final allCombinations = _getCombinations(allAvailableTypes, totalPlayers);

    // Filter out previous selection if possible to avoid immediate repetition
    List<List<CountryType>> candidates = allCombinations;
    if (!allowRepeat && _previousSelection != null) {
      final prevSet = _previousSelection!.toSet();
      final filtered = allCombinations.where((combo) {
        final comboSet = combo.toSet();
        return comboSet.length != prevSet.length ||
            !comboSet.containsAll(prevSet);
      }).toList();

      if (filtered.isNotEmpty) {
        candidates = filtered;
      }
    }

    // Pick one combination randomly
    final chosenCombination = candidates[rng.nextInt(candidates.length)];

    // Shuffle the assignment order so players get different countries
    final shuffled = List<CountryType>.from(chosenCombination)..shuffle(rng);
    _previousSelection = List.unmodifiable(chosenCombination);

    return shuffled;
  }

  /// Helper to compute all mathematical combinations of choosing k items from list.
  static List<List<CountryType>> _getCombinations(
    List<CountryType> list,
    int k,
  ) {
    final result = <List<CountryType>>[];

    void helper(int start, List<CountryType> current) {
      if (current.length == k) {
        result.add(List<CountryType>.from(current));
        return;
      }
      for (int i = start; i < list.length; i++) {
        current.add(list[i]);
        helper(i + 1, current);
        current.removeLast();
      }
    }

    helper(0, []);
    return result;
  }

  /// Creates N * N ordinary cards (N cards per active type) + 1 Starting Card.
  /// Total cards: N * N + 1.
  /// Every card has a strictly unique ID.
  static DeckCreationResult createDeck(
    int totalPlayers, {
    List<CountryType>? predefinedTypes,
    Random? random,
  }) {
    final activeTypes = predefinedTypes ??
        selectActiveTypes(totalPlayers, random: random);

    final ordinaryCards = <CountryType, List<GameCard>>{};

    for (final type in activeTypes) {
      final list = <GameCard>[];
      for (int i = 0; i < totalPlayers; i++) {
        final card = GameCard.ordinary(
          id: 'card_${type.id}_$i',
          type: type,
        );
        list.add(card);
      }
      ordinaryCards[type] = list;
    }

    final startingCard = GameCard.starting(id: 'starting_card_0');

    return DeckCreationResult(
      activeTypes: activeTypes,
      ordinaryCardsByType: ordinaryCards,
      startingCard: startingCard,
    );
  }
}

class DeckCreationResult {
  final List<CountryType> activeTypes;
  final Map<CountryType, List<GameCard>> ordinaryCardsByType;
  final GameCard startingCard;

  const DeckCreationResult({
    required this.activeTypes,
    required this.ordinaryCardsByType,
    required this.startingCard,
  });

  int get totalOrdinaryCards =>
      ordinaryCardsByType.values.fold(0, (sum, list) => sum + list.length);

  int get totalCards => totalOrdinaryCards + 1;
}
