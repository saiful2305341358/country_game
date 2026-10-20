import 'package:flutter/services.dart';
import 'audio_service_interface.dart';
import 'sound_synthesizer.dart';
import 'stats_storage_stub.dart';

AudioServiceInterface createAudioService() => AudioServiceMobile();

/// Native Mobile (Android APK/AAB & iOS IPA) Audio Service.
/// Generates 16-bit 22050Hz PCM WAV buffers once via [SoundSynthesizer], preloads all
/// buffers into native Android SoundPool / AudioTrack cache and iOS AVAudioPlayer cache,
/// and supports immediate stopAll when muted.
class AudioServiceMobile implements AudioServiceInterface {
  static const MethodChannel _channel = MethodChannel(
    'com.example.country_game/native_feedback',
  );
  static const String _prefKey = 'country_game_sound_enabled';

  bool _soundEnabled = true;
  late final Map<String, Uint8List> _wavBuffers;
  final Set<String> _syncedKeys = <String>{};

  AudioServiceMobile() {
    _loadSavedPreference();
    _wavBuffers = SoundSynthesizer.generateAllWavBytes();
    _preloadAllToNative();
  }

  void _loadSavedPreference() {
    final saved = StatsStorage.read(_prefKey);
    if (saved != null) {
      _soundEnabled = saved == 'true';
    }
  }

  void _preloadAllToNative() {
    try {
      _channel
          .invokeMethod<void>('preloadAll', <String, dynamic>{
            'sounds': _wavBuffers,
          })
          .then((_) {
            _syncedKeys.addAll(_wavBuffers.keys);
          })
          .catchError((_) {});
    } catch (_) {}
  }

  @override
  bool get isSoundEnabled => _soundEnabled;

  @override
  set isSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    StatsStorage.write(_prefKey, enabled.toString());
    if (!enabled) {
      try {
        _channel.invokeMethod<void>('stopAll').catchError((_) {});
      } catch (_) {}
    }
  }

  void _playNativeWav(String key) {
    if (!_soundEnabled) return;
    final bytes = _wavBuffers[key];
    if (bytes == null) return;

    final bool sendBytes = _syncedKeys.add(key);

    try {
      _channel
          .invokeMethod<void>('playWav', <String, dynamic>{
            'key': key,
            if (sendBytes) 'bytes': bytes,
          })
          .catchError((_) {
            _syncedKeys.remove(key);
          });
    } catch (_) {
      _syncedKeys.remove(key);
    }
  }

  @override
  void playCardTap() => _playNativeWav('cardTap');

  @override
  void playCardTake() => _playNativeWav('cardTake');

  @override
  void playCardPlace() => _playNativeWav('cardPlace');

  @override
  void playExchange() => _playNativeWav('exchange');

  @override
  void playGameStart() => _playNativeWav('gameStart');

  @override
  void playGameEnd() => _playNativeWav('gameEnd');

  @override
  void playVictory() => _playNativeWav('victory');

  @override
  void playButtonClick() => _playNativeWav('buttonClick');

  @override
  void dispose() {
    try {
      _channel.invokeMethod<void>('stopAll').catchError((_) {});
    } catch (_) {}
  }
}
