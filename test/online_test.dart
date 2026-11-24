import 'dart:convert';
import 'dart:math';

import 'package:country_game/game/bot_strategy.dart';
import 'package:country_game/models/game_settings.dart';
import 'package:country_game/models/game_state.dart';
import 'package:country_game/online/game_state_codec.dart';
import 'package:country_game/online/host_referee.dart';
import 'package:country_game/online/seat_view.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays one move for whoever's turn it is (a bot picks the card).
GameState playOne(GameState s) {
  final card = BotStrategy.chooseDiscard(
    state: s,
    difficulty: BotDifficulty.hard,
  );
  final next = HostReferee.applyMove(s, s.currentTurnPlayerIndex, card.id);
  expect(next, isNotNull, reason: 'legal bot move was rejected');
  return next!;
}

void main() {
  const names = ['Ana', 'Ben', 'Cara', 'Dev', 'Eli'];

  group('HostReferee', () {
    test('deals a round where every seat is a named human', () {
      final s =
          HostReferee.startRound(names.take(4).toList(), random: Random(1));
      expect(s.totalPlayers, 4);
      expect(s.players.map((p) => p.name), names.take(4));
      expect(s.players.every((p) => p.isHuman), isTrue);
      expect(s.players.every((p) => p.hand.length == 4), isTrue);
    });

    test('rejects fewer than 3 or more than 7 players', () {
      expect(() => HostReferee.startRound(['A', 'B']), throwsArgumentError);
      expect(
        () => HostReferee.startRound(List.generate(8, (i) => 'P$i')),
        throwsArgumentError,
      );
    });

    test('only accepts the current player, own cards and legal cards', () {
      var s = HostReferee.startRound(names.take(3).toList(), random: Random(2));
      final turn = s.currentTurnPlayerIndex;
      final other = (turn + 1) % 3;
      final myCard = s.players[turn].hand.first;

      expect(HostReferee.applyMove(s, other, s.players[other].hand.first.id),
          isNull,
          reason: 'not their turn');
      expect(HostReferee.applyMove(s, turn, s.players[other].hand.first.id),
          isNull,
          reason: 'card not in hand');
      expect(HostReferee.applyMove(s, turn, 'no-such-card'), isNull);

      s = HostReferee.applyMove(s, turn, myCard.id)!;
      expect(s.turnCount, 1);
      expect(s.tableCard, myCard);

      // Same-country rule: the next player may not put down the table's country.
      final next = s.currentPlayer;
      final sameType = next.hand
          .where((c) => !c.isStartingCard && c.type == s.tableCard.type)
          .firstOrNull;
      if (sameType != null) {
        expect(
          HostReferee.applyMove(s, s.currentTurnPlayerIndex, sameType.id),
          isNull,
        );
      }
    });

    test('a full round can be played to a winner', () {
      var s = HostReferee.startRound(names.take(3).toList(), random: Random(3));
      for (int i = 0; i < 3000 && !s.isGameOver; i++) {
        s = playOne(s);
      }
      expect(s.isGameOver, isTrue);
      expect(s.winner, isNotNull);
      expect(
          HostReferee.applyMove(
              s, s.currentTurnPlayerIndex, s.currentPlayer.hand.first.id),
          isNull,
          reason: 'no moves after the round is over');
    });
  });

  group('GameStateCodec', () {
    test('round-trips a state through JSON text unchanged', () {
      var s = HostReferee.startRound(names, random: Random(4));
      for (int i = 0; i < 12 && !s.isGameOver; i++) {
        s = playOne(s);
      }
      final json = GameStateCodec.encode(s);
      final decoded = GameStateCodec.decode(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(GameStateCodec.encode(decoded), equals(json));
      expect(decoded.players[2].hand, s.players[2].hand);
      expect(decoded.tableCard, s.tableCard);
      expect(decoded.recentPlayedCards.length, s.recentPlayedCards.length);
    });

    test('rejects damaged data with a FormatException', () {
      expect(() => GameStateCodec.decode({'players': 'oops'}),
          throwsFormatException);
    });
  });

  group('SeatView', () {
    test('every phone sees itself at seat 0 with only its own hand playable',
        () {
      var s = HostReferee.startRound(names, random: Random(5));
      s = playOne(playOne(s));
      for (int seat = 0; seat < s.totalPlayers; seat++) {
        final v = SeatView.forSeat(s, seat);
        expect(v.players[0].hand, s.players[seat].hand);
        expect(v.players[0].name, 'You');
        expect(v.players.where((p) => p.isHuman).length, 1);
        expect(v.players.map((p) => p.id),
            List.generate(s.totalPlayers, (i) => i));
        // Seat order is kept: the next player clockwise stays next.
        expect(v.players[1].name, s.players[(seat + 1) % s.totalPlayers].name);
        expect(
          v.players[v.currentTurnPlayerIndex].hand,
          s.players[s.currentTurnPlayerIndex].hand,
        );
        expect(v.isHumanTurn, seat == s.currentTurnPlayerIndex);
        expect(
          v.players[v.lastMovePlayerIndex!].hand,
          s.players[s.lastMovePlayerIndex!].hand,
        );
      }
    });

    test('status line is written from each player\'s point of view', () {
      final s =
          HostReferee.startRound(names.take(3).toList(), random: Random(6));
      final turn = s.currentTurnPlayerIndex;
      expect(SeatView.forSeat(s, turn).statusMessage, contains('Your'));
      final other = (turn + 1) % 3;
      expect(SeatView.forSeat(s, other).statusMessage,
          contains('Waiting for ${s.players[turn].name}'));
    });

    test('the winner is shown from each point of view', () {
      var s = HostReferee.startRound(names.take(3).toList(), random: Random(7));
      for (int i = 0; i < 3000 && !s.isGameOver; i++) {
        s = playOne(s);
      }
      final w = s.winner!.id;
      expect(SeatView.forSeat(s, w).winner!.id, 0);
      expect(SeatView.forSeat(s, w).statusMessage, contains('You collected'));
      final other = (w + 1) % 3;
      expect(SeatView.forSeat(s, other).winner!.name, s.players[w].name);
    });
  });

  test('a seat outside the table is rejected', () {
    final s = HostReferee.startRound(names.take(3).toList());
    expect(() => SeatView.forSeat(s, 3), throwsRangeError);
  });
}
