import 'dart:math';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_player.dart';

class InitialExchangeService {
  static const List<String> westernFemaleNames = [
    'Sophia',
    'Eleanor',
    'Charlotte',
    'Amelia',
    'Genevieve',
    'Clara',
    'Victoria',
    'Isla',
  ];

  static const List<String> westernMaleNames = [
    'Arthur',
    'Julian',
    'Oliver',
    'Sebastian',
    'Lucas',
    'Felix',
    'Henry',
    'Alexander',
  ];

  /// Executes the logically simultaneous initial card exchange.
  static List<GamePlayer> performInitialExchange({
    required List<CountryType> activeTypes,
    required Map<CountryType, List<GameCard>> initialDeckByType,
    Random? random,
  }) {
    final n = activeTypes.length;
    final rng = random ?? Random();

    // Phase 1: Give each player N cards of their home type
    final initialHands = <int, List<GameCard>>{};
    for (int i = 0; i < n; i++) {
      final type = activeTypes[i];
      final cardsForType = initialDeckByType[type]!;
      if (cardsForType.length != n) {
        throw StateError(
          'Expected $n cards for type ${type.id}, but found ${cardsForType.length}',
        );
      }
      initialHands[i] = List<GameCard>.from(cardsForType);
    }

    // Phase 2: Compute outgoing distribution simultaneously
    final outgoing = List.generate(
      n,
      (_) => List<GameCard?>.filled(n, null),
    );

    for (int sender = 0; sender < n; sender++) {
      final senderCards = initialHands[sender]!;
      for (int receiver = 0; receiver < n; receiver++) {
        outgoing[sender][receiver] = senderCards[receiver];
      }
    }

    // Phase 3: Clean realistic Western names with 50% Female and 50% Male balance
    final shuffledFemale = List<String>.from(westernFemaleNames)..shuffle(rng);
    final shuffledMale = List<String>.from(westernMaleNames)..shuffle(rng);

    final botProfiles = <({String name, bool isFemale})>[];
    int fIndex = 0;
    int mIndex = 0;

    for (int b = 1; b < n; b++) {
      final bool giveFemale = (b % 2 == 1);
      if (giveFemale) {
        botProfiles.add((
          name: shuffledFemale[fIndex++ % shuffledFemale.length],
          isFemale: true,
        ));
      } else {
        botProfiles.add((
          name: shuffledMale[mIndex++ % shuffledMale.length],
          isFemale: false,
        ));
      }
    }

    // Phase 4: Assemble new hand for each player
    final players = <GamePlayer>[];
    for (int p = 0; p < n; p++) {
      final newHand = <GameCard>[];
      for (int sender = 0; sender < n; sender++) {
        final card = outgoing[sender][p];
        if (card == null) {
          throw StateError('Missing card transfer from $sender to $p');
        }
        newHand.add(card);
      }

      final isHuman = (p == 0);
      final playerName = isHuman ? 'You' : botProfiles[p - 1].name;
      final isFemale = isHuman ? false : botProfiles[p - 1].isFemale;

      players.add(
        GamePlayer(
          id: p,
          name: playerName,
          isHuman: isHuman,
          isFemale: isFemale,
          homeType: activeTypes[p],
          hand: List.unmodifiable(newHand),
        ),
      );
    }

    return players;
  }
}
