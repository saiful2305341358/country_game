import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class StatsStorage {
  static const MethodChannel _channel = MethodChannel(
    'com.example.country_game/native_feedback',
  );

  /// Keys that must only live for the current app process (mirrors web
  /// `sessionStorage`). They are never written to native storage.
  static const Set<String> _sessionOnlyKeys = <String>{
    '__session_intro_played__',
  };

  static final Map<String, String> _memory = <String, String>{};
  static bool _initialized = false;

  /// True only when persisted prefs were actually loaded from native storage.
  /// If loading failed or timed out, writes stay in memory so a partial
  /// in-memory state can never overwrite the player's saved data.
  static bool _nativeLoaded = false;

  /// Loads persisted key-value pairs from native SharedPreferences (Android)
  /// or UserDefaults (iOS) into memory on startup.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getAllPrefs')
          .timeout(const Duration(seconds: 3));
      if (result != null) {
        for (final entry in result.entries) {
          final val = entry.value;
          if (val is String && !_sessionOnlyKeys.contains(entry.key)) {
            _memory[entry.key] = val;
          }
        }
      }
      _nativeLoaded = true;
      // Clean up session keys that older builds persisted by mistake.
      for (final key in _sessionOnlyKeys) {
        if (result?.containsKey(key) ?? false) {
          _removeNative(key);
        }
      }
    } catch (e) {
      // Native channel is absent in unit/widget tests; on a device this means
      // saved data could not be read, so keep this session in memory only.
      debugPrint('StatsStorage: native prefs unavailable ($e)');
    }
  }

  static String? read(String key) => _memory[key];

  static void write(String key, String value) {
    _memory[key] = value;
    if (!_nativeLoaded || _sessionOnlyKeys.contains(key)) return;
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
    if (!_nativeLoaded || _sessionOnlyKeys.contains(key)) return;
    _removeNative(key);
  }

  static void _removeNative(String key) {
    try {
      _channel
          .invokeMethod<void>('removePref', <String, dynamic>{
            'key': key,
          })
          .catchError((_) {});
    } catch (_) {}
  }
}
