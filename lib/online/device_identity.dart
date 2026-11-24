import 'dart:math';

import '../services/stats_storage_stub.dart'
    if (dart.library.html) '../services/stats_storage_web.dart';

/// A random id for this app install, kept across launches. Nearby rooms use it
/// to recognise a phone that reconnects, so it gets its seat back.
abstract final class DeviceIdentity {
  static const String _key = 'country_game_device_id';

  static String get id {
    final saved = StatsStorage.read(_key);
    if (saved != null && saved.isNotEmpty) return saved;
    final rng = Random.secure();
    final id = List.generate(16, (_) => rng.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    StatsStorage.write(_key, id);
    return id;
  }
}
