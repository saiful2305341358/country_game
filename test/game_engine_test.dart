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
  group('1-3: Initialization & Dynamic Winning Set Size for 3, 4, 5, 6 players', () {
    for (final count in [3, 4, 5, 6]) {
      test('Initialization for $count players creates correct structures and winningSetSize=$count', () {
        final engine = GameEngine(
          initialSettings: const GameSettings(animationsEnabled: false),
        );
        engine.startNewGame(totalPlayers: count, randomSeed: 42);
        final state = engine.state!;

        expect(state.totalPlayers, equals(count));
        expect(state.winningSetSize, equals(count));
        expect(state.players.length, equals(count));
        expect(state.activeTypes.length, equals(count));
        expect(engine.verifyIntegrity(), isTrue);

        // Verify human player is 'You' and bots have clean names without 'Bot'
        expect(state.players.first.name, equals('You'));
        for (final p in state.players) {
          expect(p.name.contains('Bot'), isFalse);
        }
      });
    }
  });

  group('4-5: Dynamic Deck Generation (N x N + 1)', () {
    test('3 players: 9 ordinary + 1 starting = 10 cards total', () {
      final deck = CardDeckFactory.createDeck(3);
      expect(deck.totalOrdinaryCards, equals(9));
      expect(deck.totalCards, equals(10));
      expect(deck.startingCard.isStartingCard, isTrue);
      expect(deck.startingCard.displayName, equals('Global'));
    });

    test('4 players: 16 ordinary + 1 starting = 17 cards total', () {
      final deck = CardDeckFactory.createDeck(4);
      expect(deck.totalOrdinaryCards, equals(16));
      expect(deck.totalCards, equals(17));
      expect(deck.startingCard.isStartingCard, isTrue);
      expect(deck.startingCard.displayName, equals('Global'));
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
    test('After initial exchange, every player has a balanced hand (1 of each active country)', () {
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
      expect(updatedState.lastMovePlayerIndex, equals(state.currentTurnPlayerIndex));
      expect(updatedState.lastDiscardedCard?.id, equals(anyCardInHand.id));
      expect(updatedState.lastTakenCard?.isStartingCard, isTrue);

      final prevPlayer = updatedState.players[state.currentTurnPlayerIndex];
      expect(prevPlayer.hasStartingCard, isTrue);
      expect(prevPlayer.hand.length, equals(4));
    });
  });

  group('13-14: Same-type exchange restriction', () {
    test('Player CANNOT discard card of same ordinary type as table card', () {
      final player = GamePlayer(
        id: 0,
        name: 'Alex',
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
          player.copyWith(id: 1, name: 'Sophia'),
          player.copyWith(id: 2, name: 'Arthur'),
          player.copyWith(id: 3, name: 'Eleanor'),
        ],
        tableCard: GameCard.ordinary(id: 'table_aus', type: CountryType.australia),
        startingPlayerIndex: 0,
        currentTurnPlayerIndex: 0,
        turnCount: 2,
        isOpeningMove: false,
        statusMessage: 'Ready',
      );

      final ausCard = player.hand[0];
      final invalidValidation = MoveValidator.validateMove(
        state: state,
        discardCard: ausCard,
      );
      expect(invalidValidation.isValid, isFalse);
      expect(invalidValidation.errorMessage, contains('Same-Type Restriction'));

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
        name: 'Alex',
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
        players: [
          player,
          player.copyWith(id: 1),
          player.copyWith(id: 2),
          player.copyWith(id: 3),
        ],
        tableCard: GameCard.ordinary(id: 'table_aus', type: CountryType.australia),
        startingPlayerIndex: 0,
        currentTurnPlayerIndex: 0,
        turnCount: 3,
        isOpeningMove: false,
        statusMessage: 'Ready',
      );

      final validation = MoveValidator.validateMove(
        state: state,
        discardCard: player.hand[0],
      );
      expect(validation.isValid, isTrue);
    });
  });

  group('16-18: Dynamic Player-Based Winning Condition (Set Size = N)', () {
    test('4-Player Game: 4 cards of same country wins immediately', () {
      final playerWith4 = GamePlayer(
        id: 0,
        name: 'Alex',
        isHuman: true,
        homeType: CountryType.japan,
        hand: [
          GameCard.ordinary(id: 'j1', type: CountryType.japan),
          GameCard.ordinary(id: 'j2', type: CountryType.japan),
          GameCard.ordinary(id: 'j3', type: CountryType.japan),
          GameCard.ordinary(id: 'j4', type: CountryType.japan),
        ],
      );
      expect(
        WinnerDetector.checkWinner(playerWith4, requiredSetSize: 4),
        equals(CountryType.japan),
      );
      expect(playerWith4.hasWon(requiredSetSize: 4), isTrue);
    });

    test('5-Player Game: 4 of same country is NOT a win; requires 5 of same country', () {
      final playerWith4In5PlayerGame = GamePlayer(
        id: 0,
        name: 'Sophia',
        isHuman: false,
        homeType: CountryType.japan,
        hand: [
          GameCard.ordinary(id: 'j1', type: CountryType.japan),
          GameCard.ordinary(id: 'j2', type: CountryType.japan),
          GameCard.ordinary(id: 'j3', type: CountryType.japan),
          GameCard.ordinary(id: 'j4', type: CountryType.japan),
          GameCard.ordinary(id: 'a1', type: CountryType.australia),
        ],
      );
      expect(
        WinnerDetector.checkWinner(playerWith4In5PlayerGame, requiredSetSize: 5),
        isNull,
      );
      expect(playerWith4In5PlayerGame.hasWon(requiredSetSize: 5), isFalse);

      final playerWith5In5PlayerGame = GamePlayer(
        id: 0,
        name: 'Sophia',
        isHuman: false,
        homeType: CountryType.japan,
        hand: [
          GameCard.ordinary(id: 'j1', type: CountryType.japan),
          GameCard.ordinary(id: 'j2', type: CountryType.japan),
          GameCard.ordinary(id: 'j3', type: CountryType.japan),
          GameCard.ordinary(id: 'j4', type: CountryType.japan),
          GameCard.ordinary(id: 'j5', type: CountryType.japan),
        ],
      );
      expect(
        WinnerDetector.checkWinner(playerWith5In5PlayerGame, requiredSetSize: 5),
        equals(CountryType.japan),
      );
      expect(playerWith5In5PlayerGame.hasWon(requiredSetSize: 5), isTrue);
    });

    test('6-Player Game: 5 of same country is NOT a win; requires 6 of same country', () {
      final playerWith5In6PlayerGame = GamePlayer(
        id: 0,
        name: 'Arthur',
        isHuman: false,
        homeType: CountryType.bangladesh,
        hand: [
          GameCard.ordinary(id: 'b1', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b2', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b3', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b4', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b5', type: CountryType.bangladesh),
          GameCard.starting(id: 'start_0'),
        ],
      );
      expect(
        WinnerDetector.checkWinner(playerWith5In6PlayerGame, requiredSetSize: 6),
        isNull,
      );

      final playerWith6In6PlayerGame = GamePlayer(
        id: 0,
        name: 'Arthur',
        isHuman: false,
        homeType: CountryType.bangladesh,
        hand: [
          GameCard.ordinary(id: 'b1', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b2', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b3', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b4', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b5', type: CountryType.bangladesh),
          GameCard.ordinary(id: 'b6', type: CountryType.bangladesh),
        ],
      );
      expect(
        WinnerDetector.checkWinner(playerWith6In6PlayerGame, requiredSetSize: 6),
        equals(CountryType.bangladesh),
      );
    });

    test('(N-1) ordinary cards + Starting Card NEVER constitutes a win', () {
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
      expect(WinnerDetector.checkWinner(playerWith3PlusStart, requiredSetSize: 4), isNull);
      expect(playerWith3PlusStart.hasWon(requiredSetSize: 4), isFalse);
    });
  });

  group('19: Bot strategy always returns legal move', () {
    test('Bot chooses strictly legal moves in various scenarios', () {
      final engine = GameEngine(
        initialSettings: const GameSettings(animationsEnabled: false),
      );
      engine.startNewGame(totalPlayers: 5, randomSeed: 999);

      for (int i = 0; i < 20; i++) {
        if (engine.state!.isGameOver) break;
        final bot = engine.state!.currentPlayer;
        final decision = BotStrategy.evaluateDecision(
          state: engine.state!,
          baseDelayMs: 1650,
        );
        final chosen = decision.discardCard;
        final validation = MoveValidator.validateMove(
          state: engine.state!,
          discardCard: chosen,
        );
        expect(validation.isValid, isTrue);
        expect(bot.hand.contains(chosen), isTrue);
        expect(decision.thinkDelayMs, inInclusiveRange(420, 1450));
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

      for (int i = 0; i < 6; i++) {
        if (engine.state!.isGameOver) break;
        final card = BotStrategy.chooseDiscard(state: engine.state!);
        engine.makeMove(card);
        expect(engine.verifyIntegrity(), isTrue);
      }

      engine.resetCurrentGame();
      expect(engine.verifyIntegrity(), isTrue);
      expect(engine.state!.turnCount, equals(0));
      expect(engine.state!.isOpeningMove, isTrue);
    });
  });
}
