// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'audio_service_interface.dart';
import 'sound_synthesizer.dart';

AudioServiceInterface createAudioService() => AudioServiceWeb();

class _SoundPool {
  final List<html.AudioElement> elements;
  int _cursor = 0;

  _SoundPool(String src, {int poolSize = 3})
      : elements = List<html.AudioElement>.generate(poolSize, (_) {
          final el = html.AudioElement(src)
            ..preload = 'auto'
            ..volume = 1.0;
          el.load();
          return el;
        });

  html.AudioElement next() {
    final el = elements[_cursor];
    _cursor = (_cursor + 1) % elements.length;
    return el;
  }
}

class AudioServiceWeb implements AudioServiceInterface {
  bool _soundEnabled = true;
  bool _unlocked = false;

  final Map<String, _SoundPool> _pools = <String, _SoundPool>{};
  final List<StreamSubscription<html.Event>> _unlockSubscriptions =
      <StreamSubscription<html.Event>>[];

  AudioServiceWeb() {
    _loadSavedPreference();
    _initSoundPools();
    _setupUserGestureUnlock();
  }

  void _loadSavedPreference() {
    try {
      final saved = html.window.localStorage['country_game_sound_enabled'];
      if (saved != null) {
        _soundEnabled = saved == 'true';
      }
    } catch (_) {}
  }

  @override
  bool get isSoundEnabled => _soundEnabled;

  @override
  set isSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    try {
      html.window.localStorage['country_game_sound_enabled'] =
          enabled.toString();
    } catch (_) {}
  }

  void _setupUserGestureUnlock() {
    void unlockHandler(html.Event _) {
      if (_unlocked) return;
      _unlocked = true;
      for (final sub in _unlockSubscriptions) {
        sub.cancel();
      }
      _unlockSubscriptions.clear();
    }

    try {
      _unlockSubscriptions.addAll([
        html.window.onMouseDown.listen(unlockHandler),
        html.window.onTouchStart.listen(unlockHandler),
        html.window.onKeyDown.listen(unlockHandler),
      ]);
    } catch (_) {}
  }

  void _initSoundPools() {
    try {
      final wavMap = SoundSynthesizer.generateAllWavBytes();
      for (final entry in wavMap.entries) {
        final isFrequent = entry.key == 'cardTap' ||
            entry.key == 'cardPlace' ||
            entry.key == 'cardTake';
        _pools[entry.key] = _SoundPool(
          SoundSynthesizer.toDataUri(entry.value),
          poolSize: isFrequent ? 4 : 2,
        );
      }
    } catch (_) {}
  }

  void _playSound(String key) {
    if (!_soundEnabled) return;
    final pool = _pools[key];
    if (pool == null) return;

    try {
      final audio = pool.next();
      try {
        audio.currentTime = 0;
      } catch (_) {}
      audio.volume = 1.0;
      audio.play().catchError((_) {});
    } catch (_) {}
  }

  @override
  void playCardTap() => _playSound('cardTap');

  @override
  void playCardTake() => _playSound('cardTake');

  @override
  void playCardPlace() => _playSound('cardPlace');

  @override
  void playExchange() => _playSound('exchange');

  @override
  void playGameStart() => _playSound('gameStart');

  @override
  void playGameEnd() => _playSound('gameEnd');

  @override
  void playVictory() => _playSound('victory');

  @override
  void playButtonClick() => _playSound('buttonClick');

  @override
  void dispose() {
    for (final sub in _unlockSubscriptions) {
      sub.cancel();
    }
    _unlockSubscriptions.clear();
  }
}
