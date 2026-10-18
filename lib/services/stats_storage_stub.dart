import 'package:flutter/services.dart';

class StatsStorage {
  static const MethodChannel _channel = MethodChannel(
    'com.example.country_game/native_feedback',
  );

  static final Map<String, String> _memory = <String, String>{};
  static bool _initialized = false;

  /// Loads persisted key-value pairs from native SharedPreferences (Android)
  /// or UserDefaults (iOS) into memory on startup.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getAllPrefs')
          .timeout(const Duration(milliseconds: 500));
      if (result != null) {
        for (final entry in result.entries) {
          final val = entry.value;
          if (val is String) {
            _memory[entry.key] = val;
          }
        }
      }
    } catch (_) {
      // Ignore in unit/widget test environments where native channel is absent
    }
  }

  static String? read(String key) => _memory[key];

  static void write(String key, String value) {
    _memory[key] = value;
    try {
      _channel
          .invokeMethod<void>('setPref', <String, dynamic>{
            'key': key,
            'value': value,
          })
          .catchError((_) {});
    } catch (_) {}
  }

  static void remove(String key) {
    _memory.remove(key);
    try {
      _channel
          .invokeMethod<void>('removePref', <String, dynamic>{
            'key': key,
          })
          .catchError((_) {});
    } catch (_) {}
  }
}
