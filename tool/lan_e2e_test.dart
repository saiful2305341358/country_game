// End-to-end check of nearby rooms on this computer's real network interface
// (not localhost): open a room, find it with discovery, join it by code and
// play a round. Needs a Wi-Fi / LAN connection; run manually:
//   flutter test tool/lan_e2e_test.dart
import 'package:country_game/game/bot_strategy.dart';
import 'package:country_game/models/game_settings.dart';
import 'package:country_game/online/lan/lan_protocol.dart';
import 'package:country_game/online/lan/lan_rooms.dart';
import 'package:country_game/online/room_session.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> waitFor(String what, bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail('Timed out waiting for: $what');
    await Future<void>.delayed(const Duration(milliseconds: 30));
  }
}

void main() {
  test('open, discover, join by code and play on the real network', () async {
    final addresses = await LanRooms.localAddresses();
    // ignore: avoid_print
    print('Local addresses: $addresses');
    expect(addresses, isNotEmpty, reason: 'connect to a Wi-Fi / LAN first');

    final host = await LanRooms.create(myId: 'host-id', myName: 'Host');
    expect(host.code, LanProtocol.codeForAddress(addresses.first));

    // Discovery hears the room's announcement.
    final heard = await LanRooms.discover()
        .firstWhere((rooms) => rooms.any((r) => r.code == host.code))
        .timeout(const Duration(seconds: 6));
    final found = heard.firstWhere((r) => r.code == host.code);
    // ignore: avoid_print
    print(
        'Discovered "${found.hostName}" code ${found.code} at ${found.address}');

    // Friends join with only the code (address worked out from it).
    final bea =
        await LanRooms.join(code: host.code, myId: 'bea-id', myName: 'Bea');
    final cy =
        await LanRooms.join(code: host.code, myId: 'cy-id', myName: 'Cy');
    final all = [host, bea, cy];
    await waitFor('3 players', () => all.every((p) => p.members.length == 3));

    await host.startRound();
    await waitFor('dealt', () => all.every((p) => p.myView != null));
    for (var i = 0; i < 6 && !host.gameState!.isGameOver; i++) {
      final s = host.gameState!;
      final mover = all.firstWhere((p) => p.mySeat == s.currentTurnPlayerIndex);
      await waitFor(
          'mover synced', () => mover.gameState?.turnCount == s.turnCount);
      await mover.playCard(BotStrategy.chooseDiscard(
        state: mover.myView!,
        difficulty: BotDifficulty.hard,
      ));
      await waitFor(
          'applied', () => host.gameState!.turnCount == s.turnCount + 1);
    }
    // ignore: avoid_print
    print('Played ${host.gameState!.turnCount} moves over the network');

    await host.leave();
    await waitFor(
        'closed',
        () =>
            bea.status == RoomStatus.closed && cy.status == RoomStatus.closed);
    for (final p in all) {
      p.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
