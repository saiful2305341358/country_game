import 'package:flutter/foundation.dart';
import 'card_type.dart';
import 'game_card.dart';

@immutable
class GamePlayer {
  final int id;
  final String name;
  final bool isHuman;
  final bool isFemale;
  final CountryType homeType;
  final List<GameCard> hand;

  const GamePlayer({
    required this.id,
    required this.name,
    required this.isHuman,
    this.isFemale = false,
    required this.homeType,
    required this.hand,
  });

  int get cardCount => hand.length;

  bool get hasStartingCard => hand.any((c) => c.isStartingCard);

  int countOfType(CountryType type) {
    return hand.where((c) => !c.isStartingCard && c.type == type).length;
  }

  Map<CountryType, int> get ordinaryTypeCounts {
    final counts = <CountryType, int>{};
    for (final card in hand) {
      if (!card.isStartingCard && card.type != null) {
        counts[card.type!] = (counts[card.type!] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Dynamic Winning Rule:
  /// Winning Set Size = Total Number of Players (N), which matches [requiredSetSize]
  /// (or the player's full hand size N when not explicitly passed).
  CountryType? getWinningType({int? requiredSetSize}) {
    final target = (requiredSetSize != null && requiredSetSize > 0)
        ? requiredSetSize
        : (hand.isNotEmpty ? hand.length : 4);
    final counts = ordinaryTypeCounts;
    for (final entry in counts.entries) {
      if (entry.value >= target) {
        return entry.key;
      }
    }
    return null;
  }

  CountryType? get winningType => getWinningType();

  bool hasWon({int? requiredSetSize}) =>
      getWinningType(requiredSetSize: requiredSetSize) != null;

  GamePlayer copyWith({
    int? id,
    String? name,
    bool? isHuman,
    bool? isFemale,
    CountryType? homeType,
    List<GameCard>? hand,
  }) {
    return GamePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isHuman: isHuman ?? this.isHuman,
      isFemale: isFemale ?? this.isFemale,
      homeType: homeType ?? this.homeType,
      hand: hand != null ? List.unmodifiable(hand) : this.hand,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GamePlayer && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
