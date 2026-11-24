import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the screen from turning off while a multiplayer room is open.
///
/// If the host's phone locks, the OS suspends the app and the room stops for
/// everyone; a player's phone locking drops them from the room. Uses the shared
/// native channel (`keepScreenOn` in `MainActivity.kt` and `AppDelegate.swift`).
/// Does nothing on web.
class ScreenAwake {
  ScreenAwake._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.country_game/native_feedback',
  );

  static Future<void> set(bool on) async {
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('keepScreenOn', <String, dynamic>{
        'on': on,
      });
    } catch (_) {
      // Desktop / tests: no native handler. Not critical.
    }
  }
}
