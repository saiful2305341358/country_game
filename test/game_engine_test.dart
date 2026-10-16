import 'package:flutter_test/flutter_test.dart';
import 'package:country_game/models/card_type.dart';
import 'package:country_game/models/game_card.dart';
import 'package:country_game/models/game_player.dart';
import 'package:country_game/models/game_settings.dart';
import 'package:country_game/models/game_state.dart';
import 'package:country_game/game/card_deck_factory.dart';
import 'package:country_game/game/initial_exchange.dart';
import 'package:country_game/game/move_validator.dart';
import 'package:country_game/game/winner_detector.dart';
import 'package:country_game/game/bot_strategy.dart';
import 'package:country_game/game/game_engine.dart';

void main() {
  group('1-3: Initialization for 4, 5, 6 players', () {
    for (final count in [4, 5, 6]) {
      test('Initialization for $count players creates correct structures', () {
        final engine = GameEngine(
          initialSettings: const GameSettings(animationsEnabled: false),
        );
        engine.startNewGame(totalPlayers: count, randomSeed: 42);
        final state = engine.state!;

        expect(state.totalPlayers, equals(count));
        expect(state.players.length, equals(count));
        expect(state.activeTypes.length, equals(count));
        expect(engine.verifyIntegrity(), isTrue);
      });
    }
  });

  group('4-5: Card counts and Starting Card', () {
    test('4 players: 16 ordinary + 1 starting = 17 cards total', () {
      final deck = CardDeckFactory.createDeck(4);
      expect(deck.totalOrdinaryCards, equals(16));
      expect(deck.totalCards, equals(17));
      expect(deck.startingCard.isStartingCard, isTrue);
    });

    test('5 players: 25 ordinary + 1 starting = 26 cards total', () {
      final deck = CardDeckFactory.createDeck(5);
      expect(deck.totalOrdinaryCards, equals(25));
      expect(deck.totalCards, equals(26));
    });

    test('6 players: 36 ordinary + 1 starting = 37 cards total', () {
      final deck = CardDeckFactory.createDeck(6);
      expect(deck.totalOrdinaryCards, equals(36));
      expect(deck.totalCards, equals(37));
    });
  });

  group('6-8: Initial distribution and simultaneous exchange', () {
    test('After initial exchange, every player has exactly 1 of each active type', () {
      for (final n in [4, 5, 6]) {
        final deck = CardDeckFactory.createDeck(n);
        final players = InitialExchangeService.performInitialExchange(
          activeTypes: deck.activeTypes,
          initialDeckByType: deck.ordinaryCardsByType,
        );

        expect(players.length, equals(n));
        for (final player in players) {
          expect(player.hand.length, equals(n));
          for (final type in deck.activeTypes) {
            expect(player.countOfType(type), equals(1));
          }
        }
      }
    });
  });

  group('9-10: Starting card location and starting player', () {
    test('The starting card begins on the table and starting player is valid', () {
      final engine = GameEngine(
        initialSettings: const GameSettings(animationsEnabled: false),
      );
      engine.startNewGame(totalPlayers: 4, randomSeed: 123);
      final state = engine.state!;

      expect(state.tableCard.isStartingCard, isTrue);
      expect(state.startingPlayerIndex, inInclusiveRange(0, 3));
      expect(state.currentTurnPlayerIndex, equals(state.startingPlayerIndex));
      expect(state.isOpeningMove, isTrue);
    });
  });

  group('11-12: Opening move with starting card and card transfers', () {
    test('First player can exchange Starting Card with ANY ordinary card', () {
      final engine = GameEngine(
        initialSettings: const GameSettings(animationsEnabled: false),
      );
      engine.startNewGame(totalPlayers: 4, randomSeed: 10);
      final state = engine.state!;

      final active = state.currentPlayer;
      final anyCardInHand = active.hand.first;

      // Legal check
      final validation = MoveValidator.validateMove(
        state: state,
        discardCard: anyCardInHand,
      );
      expect(validation.isValid, isTrue);

      final success = engine.makeMove(anyCardInHand);
      expect(success, isTrue);

      final updatedState = engine.state!;
      expect(updatedState.isOpeningMove, isFalse);
      expect(updatedState.tableCard.id, equals(anyCardInHand.id));

      // Active player now holds the starting card
      final prevPlayer = updatedState.players[state.currentTurnPlayerIndex];
      expect(prevPlayer.hasStartingCard, isTrue);
      expect(prevPlayer.hand.length, equals(4));
    });
  });

  group('13-14: Same-type exchange restriction', () {
    test('Player CANNOT discard card of same ordinary type as table card', () {
      final player = GamePlayer(
        id: 0,
        name: 'You',
        isHuman: true,
        homeType: CountryType.australia,
        hand: [
          GameCard.ordinary(id: 'c1', type: CountryType.australia),
          GameCard.ordinary(id: 'c2', type: CountryType.greatBritain),
          GameCard.ordinary(id: 'c3', type: CountryType.saudiArabia),
          GameCard.ordinary(id: 'c4', type: CountryType.iran),
        ],
      );

      final state = GameState(
        totalPlayers: 4,
        activeTypes: [
          CountryType.australia,
          CountryType.greatBritain,
          CountryType.saudiArabia,
          CountryType.iran,
        ],
        players: [
          player,
          player.copyWith(id: 1, name: 'Bot 1'),
          player.copyWith(id: 2, name: 'Bot 2'),
          player.copyWith(id: 3, name: 'Bot 3'),
        ],
        tableCard: GameCard.ordinary(id: 'table_aus', type: CountryType.australia),
        startingPlayerIndex: 0,
        currentTurnPlayerIndex: 0,
        turnCount: 2,
        isOpeningMove: false,
        statusMessage: 'Ready',
      );

      // Discarding Australia when Australia is on the table MUST fail
      final ausCard = player.hand[0];
      final invalidValidation = MoveValidator.validateMove(
        state: state,
        discardCard: ausCard,
      );
      expect(invalidValidation.isValid, isFalse);
      expect(invalidValidation.errorMessage, contains('Same-Type Restriction'));

      // Discarding Great Britain MUST succeed
      final gbCard = player.hand[1];
      final validValidation = MoveValidator.validateMove(
        state: state,
        discardCard: gbCard,
      );
      expect(validValidation.isValid, isTrue);
    });

    test('Starting card can always be discarded even if table is any type', () {
      final player = GamePlayer(
        id: 0,
        name: 'You',
        isHuman: true,
        homeType: CountryType.australia,
        hand: [
          GameCard.starting(id: 'start_card'),
          GameCard.ordinary(id: 'c2', type: CountryType.greatBritain),
          GameCard.ordinary(id: 'c3', type: CountryType.saudiArabia),
          GameCard.ordinary(id: 'c4', type: CountryType.iran),
        ],
      );

      final state = GameState(
        totalPlayers: 4,
        activeTypes: [
          CountryType.australia,
          CountryType.greatBritain,
          CountryType.saudiArabia,
          CountryType.iran,
        ],
        players: [player, player.copyWith(id: 1), player.copyWith(id: 2), player.copyWith(id: 3)],
        tableCard: GameCard.ordinary(id: 'table_aus', type: CountryType.australia),
        startingPlayerIndex: 0,
        currentTurnPlayerIndex: 0,
        turnCount: 3,
        isOpeningMove: false,
        statusMessage: 'Ready',
      );

      final validation = MoveValidator.validateMove(
        state: state,
        discardCard: player.hand[0], // starting card
      );
      expect(validation.isValid, isTrue);
    });
  });

  group('16-18: Automatic Victory Detection and Game Over', () {
    test('Player holding 4 cards of same type wins immediately', () {
      final playerWith4 = GamePlayer(
        id: 0,
        name: 'Winner',
        isHuman: true,
        homeType: CountryType.japan,
        hand: [
          GameCard.ordinary(id: 'j1', type: CountryType.japan),
          GameCard.ordinary(id: 'j2', type: CountryType.japan),
          GameCard.ordinary(id: 'j3', type: CountryType.japan),
          GameCard.ordinary(id: 'j4', type: CountryType.japan),
        ],
      );
      expect(WinnerDetector.checkWinner(playerWith4), equals(CountryType.japan));
      expect(playerWith4.hasWon, isTrue);
    });

    test('3 ordinary cards + Starting Card does NOT constitute a win', () {
      final playerWith3PlusStart = GamePlayer(
        id: 0,
        name: 'Almost',
        isHuman: true,
        homeType: CountryType.japan,
        hand: [
          GameCard.ordinary(id: 'j1', type: CountryType.japan),
          GameCard.ordinary(id: 'j2', type: CountryType.japan),
          GameCard.ordinary(id: 'j3', type: CountryType.japan),
          GameCard.starting(id: 'start_1'),
        ],
      );
      expect(WinnerDetector.checkWinner(playerWith3PlusStart), isNull);
      expect(playerWith3PlusStart.hasWon, isFalse);
    });
  });

  group('19: Bot strategy always returns legal move', () {
    test('Bot chooses strictly legal moves in various scenarios', () {
      final engine = GameEngine(
        initialSettings: const GameSettings(animationsEnabled: false),
      );
      engine.startNewGame(totalPlayers: 5, randomSeed: 999);

      // Play 20 moves through engine
      for (int i = 0; i < 20; i++) {
        if (engine.state!.isGameOver) break;
        final bot = engine.state!.currentPlayer;
        final chosen = BotStrategy.chooseDiscard(state: engine.state!);
        final validation = MoveValidator.validateMove(
          state: engine.state!,
          discardCard: chosen,
        );
        expect(validation.isValid, isTrue);
        expect(bot.hand.contains(chosen), isTrue);
        engine.makeMove(chosen);
      }
    });
  });

  group('20-22: Card Conservation & Reset', () {
    test('Conservation of cards and clean reset', () {
      final engine = GameEngine(
        initialSettings: const GameSettings(animationsEnabled: false),
      );
      engine.startNewGame(totalPlayers: 6, randomSeed: 777);

      expect(engine.verifyIntegrity(), isTrue);

      // Make a few moves
      for (int i = 0; i < 6; i++) {
        if (engine.state!.isGameOver) break;
        final card = BotStrategy.chooseDiscard(state: engine.state!);
        engine.makeMove(card);
        expect(engine.verifyIntegrity(), isTrue);
      }

      // Reset
      engine.resetCurrentGame();
      expect(engine.verifyIntegrity(), isTrue);
      expect(engine.state!.turnCount, equals(0));
      expect(engine.state!.isOpeningMove, isTrue);
    });
  });
}
