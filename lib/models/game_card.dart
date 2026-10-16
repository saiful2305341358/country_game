import 'package:flutter/foundation.dart';
import 'card_type.dart';

@immutable
class GameCard {
  final String id;
  final CountryType? type;
  final bool isStartingCard;

  const GameCard({
    required this.id,
    required this.type,
    this.isStartingCard = false,
  });

  factory GameCard.ordinary({
    required String id,
    required CountryType type,
  }) {
    return GameCard(
      id: id,
      type: type,
      isStartingCard: false,
    );
  }

  factory GameCard.starting({String id = 'starting_card_0'}) {
    return GameCard(
      id: id,
      type: null,
      isStartingCard: true,
    );
  }

  String get displayName =>
      isStartingCard ? 'Starting Card' : (type?.displayName ?? 'Unknown');

  String get nativeName =>
      isStartingCard ? 'Astrolabe' : (type?.nativeName ?? '');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCard && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      isStartingCard ? 'GameCard(Starting, id=$id)' : 'GameCard(${type?.name}, id=$id)';
}
