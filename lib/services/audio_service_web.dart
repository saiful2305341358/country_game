// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'audio_service_interface.dart';

AudioServiceInterface createAudioService() => AudioServiceWeb();

class AudioServiceWeb implements AudioServiceInterface {
  bool _soundEnabled = true;

  // Cached data URIs for instant zero-latency playback
  String? _cardTapUri;
  String? _cardTakeUri;
  String? _cardPlaceUri;
  String? _exchangeUri;
  String? _gameStartUri;
  String? _gameEndUri;
  String? _victoryUri;
  String? _buttonClickUri;

  AudioServiceWeb() {
    _loadSavedPreference();
    _initSoundBuffers();
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

  void _initSoundBuffers() {
    try {
      // Soft wooden haptic tap
      _cardTapUri = _generateWoodenTapWav(
        baseFreq: 195,
        overtoneFreq: 390,
        durationMs: 36,
        volume: 0.08,
      );

      // Subtle card slide (Hann-windowed warm sweep)
      _cardTakeUri = _generateSoftSlideWav(
        startFreq: 210,
        endFreq: 325,
        durationMs: 65,
        volume: 0.075,
      );

      // Soft wooden table placement tap
      _cardPlaceUri = _generateWoodenTapWav(
        baseFreq: 162,
        overtoneFreq: 272,
        durationMs: 46,
        volume: 0.10,
      );

      // Gentle dealing cascade
      _exchangeUri = _generateCascadeWav(
        freqs: [240.0, 290.0, 340.0],
        stepDurationMs: 52,
        volume: 0.075,
      );

      // Game Start: subtle, crisp startup chime (clean ascending fifth + octave bell)
      _gameStartUri = _generateCascadeWav(
        freqs: [392.00, 587.33, 783.99],
        stepDurationMs: 68,
        volume: 0.09,
      );

      // Game End: distinct audio cue signaling the round has concluded (warm descending cadence)
      _gameEndUri = _generateCascadeWav(
        freqs: [440.00, 349.23, 293.66],
        stepDurationMs: 95,
        volume: 0.10,
      );

      // Victory SFX: charming, rewarding, and uplifting sound when the user wins
      _victoryUri = _generateCascadeWav(
        freqs: [329.63, 392.00, 523.25, 659.25, 783.99],
        stepDurationMs: 92,
        volume: 0.115,
      );

      // Minimal haptic tick for toggle confirmation
      _buttonClickUri = _generateWoodenTapWav(
        baseFreq: 240,
        overtoneFreq: 420,
        durationMs: 24,
        volume: 0.07,
      );
    } catch (_) {}
  }

  void _playSound(String? dataUri) {
    if (!_soundEnabled || dataUri == null) return;
    try {
      final audio = html.AudioElement(dataUri);
      audio.play();
    } catch (_) {}
  }

  @override
  void playCardTap() => _playSound(_cardTapUri);

  @override
  void playCardTake() => _playSound(_cardTakeUri);

  @override
  void playCardPlace() => _playSound(_cardPlaceUri);

  @override
  void playExchange() => _playSound(_exchangeUri);

  @override
  void playGameStart() => _playSound(_gameStartUri);

  @override
  void playGameEnd() => _playSound(_gameEndUri);

  @override
  void playVictory() => _playSound(_victoryUri);

  @override
  void playButtonClick() => _playSound(_buttonClickUri);

  @override
  void dispose() {}

  static ByteData _createWavHeader(
    Uint8List bytes,
    int sampleRate,
    int byteCount,
  ) {
    final view = ByteData.view(bytes.buffer);
    view.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    view.setUint32(4, 36 + byteCount, Endian.little);
    view.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    view.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little); // PCM
    view.setUint16(22, 1, Endian.little); // Mono
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, sampleRate * 2, Endian.little);
    view.setUint16(32, 2, Endian.little);
    view.setUint16(34, 16, Endian.little);
    view.setUint32(36, 0x64617461, Endian.big); // "data"
    view.setUint32(40, byteCount, Endian.little);
    return view;
  }

  /// Generates a soft wooden haptic tap with smooth attack and rapid exponential decay.
  static String _generateWoodenTapWav({
    required double baseFreq,
    required double overtoneFreq,
    required int durationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, sampleRate, byteCount);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final attack = (progress < 0.08) ? (progress / 0.08) : 1.0;
      final decay = math.exp(-progress * 6.5);
      final env = attack * decay;

      final wave = 0.75 * math.sin(2 * math.pi * baseFreq * t) +
          0.25 * math.sin(2 * math.pi * overtoneFreq * t);
      final sample = (wave * env * volume * 32767).toInt();
      view.setInt16(44 + i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }

  /// Generates a gentle felt card-slide sound using a smooth Hann window.
  static String _generateSoftSlideWav({
    required double startFreq,
    required double endFreq,
    required int durationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, sampleRate, byteCount);

    double phase = 0.0;
    for (int i = 0; i < totalSamples; i++) {
      final progress = i / totalSamples;
      final freq = startFreq + (endFreq - startFreq) * progress;
      phase += 2 * math.pi * freq / sampleRate;
      final env = math.sin(math.pi * progress);
      final sample = (math.sin(phase) * env * volume * 32767).toInt();
      view.setInt16(44 + i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }

  /// Generates a clean warm chime / cascade with soft attack and decay per note.
  static String _generateCascadeWav({
    required List<double> freqs,
    required int stepDurationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final samplesPerNote = (sampleRate * (stepDurationMs / 1000.0)).toInt();
    final totalSamples = samplesPerNote * freqs.length;
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, sampleRate, byteCount);

    int sampleOffset = 0;
    for (final freq in freqs) {
      for (int i = 0; i < samplesPerNote; i++) {
        final t = i / sampleRate;
        final progress = i / samplesPerNote;
        final attack = (progress < 0.1) ? (progress / 0.1) : 1.0;
        final decay = math.exp(-progress * 3.8);
        final env = attack * decay;

        final wave = 0.8 * math.sin(2 * math.pi * freq * t) +
            0.2 * math.sin(2 * math.pi * (freq * 2) * t);
        final sample = (wave * env * volume * 32767).toInt();
        view.setInt16(
          44 + (sampleOffset + i) * 2,
          sample.clamp(-32768, 32767),
          Endian.little,
        );
      }
      sampleOffset += samplesPerNote;
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }
}
