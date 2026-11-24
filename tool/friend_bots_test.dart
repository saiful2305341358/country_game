// Manual testing helper: two simulated friends join an Internet room and play
// their turns automatically, so one real phone/browser can try a full round.
//
//   ROOM_CODE=482 flutter test tool/friend_bots_test.dart
//
// They leave when the room closes, or after 10 minutes.
import 'dart:io';

import 'package:country_game/game/bot_strategy.dart';
import 'package:country_game/models/game_settings.dart';
import 'package:country_game/online/room_session.dart';
import 'package:country_game/online/supabase_config.dart';
import 'package:country_game/online/supabase_room_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('friend bots play in the room', () async {
    final code = Platform.environment['ROOM_CODE'];
    if (code == null) fail('Set ROOM_CODE to the room to join.');

    final friends = <SupabaseRoomSession>[];
    for (final name in ['Bea', 'Cy']) {
      final client =
          SupabaseClient(SupabaseConfig.url, SupabaseConfig.publishableKey);
      await client.auth.signInAnonymously();
      friends.add(await SupabaseRoomSession.join(code, name, client: client));
    }
    // ignore: avoid_print
    print('Bea and Cy joined room $code');

    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline) &&
        friends.every((f) => f.status != RoomStatus.closed)) {
      for (final f in friends) {
        final view = f.myView;
        if (f.status == RoomStatus.playing &&
            view != null &&
            view.isHumanTurn &&
            !f.isSubmittingMove) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
          await f.playCard(BotStrategy.chooseDiscard(
            state: view,
            difficulty: BotDifficulty.normal,
          ));
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    for (final f in friends) {
      if (f.status != RoomStatus.closed) await f.leave();
      f.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 11)));
}
