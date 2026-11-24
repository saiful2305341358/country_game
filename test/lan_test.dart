// Nearby (Wi-Fi / hotspot) rooms, tested with real WebSocket connections on
// localhost: the host and every "phone" run in this process.
import 'package:country_game/game/bot_strategy.dart';
import 'package:country_game/models/game_settings.dart';
import 'package:country_game/online/lan/lan_client_session.dart';
import 'package:country_game/online/lan/lan_errors.dart';
import 'package:country_game/online/lan/lan_host_session.dart';
import 'package:country_game/online/lan/lan_protocol.dart';
import 'package:country_game/online/room_session.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> waitFor(
  String what,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for: $what');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  group('LanProtocol', () {
    test('room code is the last number of the host address', () {
      expect(LanProtocol.codeForAddress('192.168.43.1'), '001');
      expect(LanProtocol.codeForAddress('172.20.10.14'), '014');
      expect(LanProtocol.codeForAddress('192.168.1.234'), '234');
    });

    test('a friend works out the host address from the code', () {
      expect(
          LanProtocol.addressForCode('001', '192.168.43.57'), '192.168.43.1');
      expect(LanProtocol.addressForCode('014', '172.20.10.2'), '172.20.10.14');
      expect(LanProtocol.addressForCode('000', '192.168.1.5'), isNull);
      expect(LanProtocol.addressForCode('255', '192.168.1.5'), isNull);
      expect(LanProtocol.addressForCode('12', '192.168.1.5'), isNull);
    });

    test('Wi-Fi / hotspot addresses are preferred over mobile data', () {
      expect(
        LanProtocol.rankLocalAddresses(
          ['10.71.3.9', '8.8.8.8', '172.20.10.2', '192.168.43.57', '127.0.0.1'],
        ),
        ['192.168.43.57', '172.20.10.2', '10.71.3.9'],
      );
    });
  });

  group('Nearby room over localhost', () {
    late LanHostSession host;
    final clients = <LanClientSession>[];

    Future<LanClientSession> join(String name,
        {String code = '001', String? id}) async {
      final c = await LanClientSession.connect(
        host: '127.0.0.1',
        port: host.port,
        code: code,
        myId: id ?? 'id-$name',
        myName: name,
      );
      clients.add(c);
      return c;
    }

    setUp(() async {
      host = await LanHostSession.start(
        hostId: 'id-host',
        hostName: 'Host',
        address: '127.0.0.1',
        port: 0,
        bindAddress: '127.0.0.1',
        announce: false,
      );
    });

    tearDown(() {
      for (final c in clients) {
        c.dispose();
      }
      clients.clear();
      host.dispose();
    });

    test('join errors are reported', () async {
      expect(host.code, '001');
      await expectLater(
        join('Bea', code: '002'),
        throwsA(isA<LanJoinException>()
            .having((e) => e.reason, 'reason', LanProtocol.roomNotFound)),
      );
      await join('Bea');
      await expectLater(
        join('bea', id: 'another-phone'),
        throwsA(isA<LanJoinException>()
            .having((e) => e.reason, 'reason', LanProtocol.nameTaken)),
      );
      for (final name in ['C', 'D', 'E', 'F', 'G']) {
        await join(name);
      }
      expect(host.members.length, 7);
      await expectLater(
        join('H'),
        throwsA(isA<LanJoinException>()
            .having((e) => e.reason, 'reason', LanProtocol.roomFull)),
      );
      expect(friendlyLanError(const LanJoinException(LanProtocol.roomFull)),
          contains('full'));
    });

    test('players play full rounds; joiners wait; leaving and closing',
        () async {
      final bea = await join('Bea');
      final cy = await join('Cy');
      final all = <RoomSession>[host, bea, cy];
      await waitFor('everyone sees 3 players',
          () => all.every((p) => p.members.length == 3));
      for (final p in all) {
        expect(p.members.map((m) => m.name), ['Host', 'Bea', 'Cy']);
      }
      expect(host.canStartRound, isTrue);
      expect(bea.canStartRound, isFalse);

      // ---- round 1 to a winner
      await host.startRound();
      await waitFor(
          'everyone dealt in',
          () => all.every(
              (p) => p.status == RoomStatus.playing && p.myView != null));

      // Out-of-turn moves are ignored.
      final s0 = host.gameState!;
      final idle = all.firstWhere((p) => p.mySeat != s0.currentTurnPlayerIndex);
      await idle.playCard(idle.myView!.players[0].hand.first);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(host.gameState!.turnCount, s0.turnCount);

      var moves = 0;
      while (!host.gameState!.isGameOver) {
        final s = host.gameState!;
        final mover =
            all.firstWhere((p) => p.mySeat == s.currentTurnPlayerIndex);
        await waitFor(
            'mover sees turn', () => mover.gameState?.turnCount == s.turnCount);
        await mover.playCard(BotStrategy.chooseDiscard(
          state: mover.myView!,
          difficulty: BotDifficulty.hard,
        ));
        await waitFor(
            'turn applied', () => host.gameState!.turnCount == s.turnCount + 1);
        if (++moves > 400) fail('round did not finish');
      }
      await waitFor('everyone sees round over',
          () => all.every((p) => p.status == RoomStatus.roundOver));
      for (final p in all) {
        expect(p.gameState!.winner!.name, host.gameState!.winner!.name);
      }

      // ---- round 2: Dee joins mid-round and waits
      await host.startRound();
      await waitFor('round 2', () => all.every((p) => p.round == 2));
      final dee = await join('Dee');
      await waitFor('Dee waiting', () => host.waitingMembers.length == 1);
      await waitFor(
          'Dee sees the room', () => dee.status == RoomStatus.playing);
      expect(dee.isInCurrentRound, isFalse);
      expect(dee.myView, isNull);

      await host.backToLobby();
      await host.startRound();
      await waitFor('Dee dealt in', () => dee.myView?.totalPlayers == 4);

      // ---- a short Wi-Fi drop: the player reconnects and keeps their seat
      bea.debugDropConnection();
      await waitFor('host sees Bea offline',
          () => !host.members.firstWhere((m) => m.name == 'Bea').connected);
      await waitFor('Bea reconnected',
          () => host.members.firstWhere((m) => m.name == 'Bea').connected,
          timeout: const Duration(seconds: 15));
      expect(host.status, RoomStatus.playing);
      expect(bea.myView, isNotNull);

      // ---- leaving mid-round stops the round
      await cy.leave();
      await waitFor(
          'round stopped',
          () =>
              host.status == RoomStatus.lobby &&
              dee.status == RoomStatus.lobby);
      expect(dee.notice, contains('Cy'));
      expect(host.members.map((m) => m.name), ['Host', 'Bea', 'Dee']);

      // ---- the host closes the room
      await host.leave();
      await waitFor(
          'room closed for everyone',
          () =>
              bea.status == RoomStatus.closed &&
              dee.status == RoomStatus.closed);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
