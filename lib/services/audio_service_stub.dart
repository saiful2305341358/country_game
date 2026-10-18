import 'package:flutter/services.dart';
import 'audio_service_interface.dart';
import 'sound_synthesizer.dart';
import 'stats_storage_stub.dart';

AudioServiceInterface createAudioService() => AudioServiceMobile();

/// Native Mobile (Android APK/AAB & iOS IPA) Audio Service.
/// Generates 16-bit 22050Hz PCM WAV buffers once via [SoundSynthesizer], transmits each
/// buffer at most once to the native layer, and triggers subsequent playback by key only.
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
  }

  void _loadSavedPreference() {
    final saved = StatsStorage.read(_prefKey);
    if (saved != null) {
      _soundEnabled = saved == 'true';
    }
  }

  @override
  bool get isSoundEnabled => _soundEnabled;

  @override
  set isSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    StatsStorage.write(_prefKey, enabled.toString());
  }

  void _playNativeWav(String key) {
    if (!_soundEnabled) return;
    final bytes = _wavBuffers[key];
    if (bytes == null) return;

    // Only transmit the WAV byte payload the first time each sound key is played;
    // native Android (pcmCache) and iOS (wavCache) retain the buffer in memory.
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
  void dispose() {}
}
