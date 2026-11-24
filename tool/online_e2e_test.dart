// End-to-end check of Internet rooms against the real Supabase project.
//
// Run manually (it uses the network and creates a few anonymous test users):
//   flutter test tool/online_e2e_test.dart
//
// Several "phones" are simulated in one process, each with its own
// anonymous sign-in, and they play real rounds through the server.

import 'package:country_game/game/bot_strategy.dart';
import 'package:country_game/models/game_settings.dart';
import 'package:country_game/online/room_session.dart';
import 'package:country_game/online/supabase_config.dart';
import 'package:country_game/online/supabase_room_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<SupabaseClient> newPhone() async {
  final client = SupabaseClient(
    SupabaseConfig.url,
    SupabaseConfig.publishableKey,
  );
  await client.auth.signInAnonymously();
  return client;
}

Future<void> waitFor(
  String what,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

/// Plays the current round to the end; every move is made on the phone whose
/// turn it is, using what that phone sees.
Future<int> playRound(
    SupabaseRoomSession host, List<SupabaseRoomSession> all) async {
  int moves = 0;
  while (!host.gameState!.isGameOver) {
    final s = host.gameState!;
    final mover = all.firstWhere(
      (p) => p.myUserId == host.seats[s.currentTurnPlayerIndex],
    );
    await waitFor('mover sees turn ${s.turnCount}',
        () => mover.gameState?.turnCount == s.turnCount);
    final view = mover.myView!;
    expect(view.isHumanTurn, isTrue, reason: 'mover should see its own turn');
    final card = BotStrategy.chooseDiscard(
      state: view,
      difficulty: BotDifficulty.hard,
    );
    await mover.playCard(card);
    await waitFor('host applies turn ${s.turnCount}',
        () => host.gameState!.turnCount == s.turnCount + 1);
    moves++;
    if (moves > 400) fail('Round did not finish in 400 moves');
  }
  return moves;
}

void main() {
  test('phones create, join and play rounds over Supabase', () async {
    final host =
        await SupabaseRoomSession.create('Host', client: await newPhone());
    expect(host.code, matches(RegExp(r'^\d{3}$')));
    expect(host.isHost, isTrue);

    // Join errors are reported clearly.
    final bPhone = await newPhone();
    await expectLater(
      SupabaseRoomSession.join('000', 'Bea', client: bPhone),
      throwsA(predicate(
          (Object? e) => friendlyRoomError(e!).contains('No open room'))),
    );
    final bea =
        await SupabaseRoomSession.join(host.code, 'Bea', client: bPhone);
    await expectLater(
      SupabaseRoomSession.join(host.code, 'bea', client: await newPhone()),
      throwsA(predicate(
          (Object? e) => friendlyRoomError(e!).contains('already uses'))),
    );

    // Two players are not enough.
    await waitFor('host sees Bea', () => host.members.length == 2);
    expect(host.canStartRound, isFalse);

    final cy = await SupabaseRoomSession.join(host.code, 'Cy',
        client: await newPhone());
    final all = [host, bea, cy];
    await waitFor('everyone sees 3 members',
        () => all.every((p) => p.members.length == 3));
    expect(host.canStartRound, isTrue);
    expect(bea.canStartRound, isFalse, reason: 'only the host starts rounds');
    for (final p in all) {
      expect(p.members.map((m) => m.name), ['Host', 'Bea', 'Cy'],
          reason: 'players are listed in joining order, host first');
    }

    // ---------------- round 1: a full game to a winner
    await host.startRound();
    await waitFor(
        'everyone is dealt in',
        () => all
            .every((p) => p.status == RoomStatus.playing && p.myView != null));
    for (final p in all) {
      expect(p.myView!.players[0].name, 'You');
      expect(p.myView!.players[0].hand.length, 3);
    }

    // Moving out of turn is ignored.
    final s0 = host.gameState!;
    final notMyTurn = all.firstWhere(
      (p) => p.myUserId != host.seats[s0.currentTurnPlayerIndex],
    );
    await notMyTurn.playCard(notMyTurn.myView!.players[0].hand.first);
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(host.gameState!.turnCount, s0.turnCount);

    final moves = await playRound(host, all);
    await waitFor('everyone sees the round end',
        () => all.every((p) => p.status == RoomStatus.roundOver));
    final winnerName = host.gameState!.winner!.name;
    for (final p in all) {
      expect(p.gameState!.winner!.name, winnerName);
      expect(p.gameState!.turnCount, host.gameState!.turnCount);
    }
    // ignore: avoid_print
    print('Round 1: $winnerName won after $moves moves');

    // ---------------- round 2: someone joins mid-round
    await host.startRound();
    await waitFor('round 2 started',
        () => all.every((p) => p.status == RoomStatus.playing && p.round == 2));
    final dee = await SupabaseRoomSession.join(host.code, 'Dee',
        client: await newPhone());
    await waitFor('Dee is waiting', () => host.waitingMembers.length == 1);
    expect(dee.isInCurrentRound, isFalse);
    expect(dee.status, RoomStatus.playing);
    expect(dee.myView, isNull, reason: 'waiting players do not see the table');

    // Next round deals Dee in (4 players -> 4-card set).
    await host.backToLobby();
    await host.startRound();
    final four = [host, bea, cy, dee];
    await waitFor('Dee dealt in',
        () => four.every((p) => p.round == 3 && p.myView?.totalPlayers == 4));

    // ---------------- a player leaves mid-round
    await cy.leave();
    await waitFor(
        'round stops after Cy leaves',
        () =>
            host.status == RoomStatus.lobby && dee.status == RoomStatus.lobby);
    expect(host.notice, contains('Cy'));
    expect(host.members.map((m) => m.name), isNot(contains('Cy')));

    // ---------------- the host closes the room
    await host.leave();
    await waitFor(
        'room closed for everyone',
        () =>
            bea.status == RoomStatus.closed && dee.status == RoomStatus.closed);

    for (final p in [bea, dee, cy, host]) {
      p.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
