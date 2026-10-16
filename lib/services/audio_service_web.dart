// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'audio_service_interface.dart';

AudioServiceInterface createAudioService() => AudioServiceWeb();

class AudioServiceWeb implements AudioServiceInterface {
  bool _soundEnabled = true;

  // Cached data URIs for instant playback
  String? _cardTapUri;
  String? _cardTakeUri;
  String? _cardPlaceUri;
  String? _exchangeUri;
  String? _gameStartUri;
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
      html.window.localStorage['country_game_sound_enabled'] = enabled.toString();
    } catch (_) {}
  }

  void _initSoundBuffers() {
    try {
      _cardTapUri = _generateToneWav(freq: 850, durationMs: 40, volume: 0.15);
      _cardTakeUri = _generateChirpWav(startFreq: 300, endFreq: 600, durationMs: 80, volume: 0.18);
      _cardPlaceUri = _generateToneWav(freq: 260, durationMs: 60, volume: 0.22);
      _exchangeUri = _generateArpeggioWav(freqs: [523.25, 659.25], noteDurationMs: 90, volume: 0.20);
      _gameStartUri = _generateArpeggioWav(freqs: [523.25, 659.25, 783.99], noteDurationMs: 80, volume: 0.22);
      _victoryUri = _generateArpeggioWav(freqs: [523.25, 659.25, 783.99, 1046.50], noteDurationMs: 120, volume: 0.25);
      _buttonClickUri = _generateToneWav(freq: 600, durationMs: 30, volume: 0.12);
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
  void playVictory() => _playSound(_victoryUri);

  @override
  void playButtonClick() => _playSound(_buttonClickUri);

  @override
  void dispose() {}

  /// Generates a standard offline PCM 16-bit WAV data URI with smooth envelope.
  static String _generateToneWav({
    required double freq,
    required int durationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final byteCount = totalSamples * 2;

    final bytes = Uint8List(44 + byteCount);
    final view = ByteData.view(bytes.buffer);

    // RIFF header
    view.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    view.setUint32(4, 36 + byteCount, Endian.little);
    view.setUint32(8, 0x57415645, Endian.big); // "WAVE"

    // "fmt " chunk
    view.setUint32(12, 0x666D7420, Endian.big);
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little); // PCM
    view.setUint16(22, 1, Endian.little); // Mono
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    view.setUint16(32, 2, Endian.little); // block align
    view.setUint16(34, 16, Endian.little); // 16 bits per sample

    // "data" chunk
    view.setUint32(36, 0x64617461, Endian.big);
    view.setUint32(40, byteCount, Endian.little);

    // Audio samples with decay envelope
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final envelope = 1.0 - (i / totalSamples); // Linear decay
      final sample = (math.sin(2 * math.pi * freq * t) * envelope * volume * 32767).toInt();
      view.setInt16(44 + i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }

  static String _generateChirpWav({
    required double startFreq,
    required double endFreq,
    required int durationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final byteCount = totalSamples * 2;

    final bytes = Uint8List(44 + byteCount);
    final view = ByteData.view(bytes.buffer);

    view.setUint32(0, 0x52494646, Endian.big);
    view.setUint32(4, 36 + byteCount, Endian.little);
    view.setUint32(8, 0x57415645, Endian.big);
    view.setUint32(12, 0x666D7420, Endian.big);
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little);
    view.setUint16(22, 1, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, sampleRate * 2, Endian.little);
    view.setUint16(32, 2, Endian.little);
    view.setUint16(34, 16, Endian.little);
    view.setUint32(36, 0x64617461, Endian.big);
    view.setUint32(40, byteCount, Endian.little);

    double phase = 0.0;
    for (int i = 0; i < totalSamples; i++) {
      final progress = i / totalSamples;
      final currentFreq = startFreq + (endFreq - startFreq) * progress;
      phase += 2 * math.pi * currentFreq / sampleRate;
      final envelope = 1.0 - progress;
      final sample = (math.sin(phase) * envelope * volume * 32767).toInt();
      view.setInt16(44 + i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }

  static String _generateArpeggioWav({
    required List<double> freqs,
    required int noteDurationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final samplesPerNote = (sampleRate * (noteDurationMs / 1000.0)).toInt();
    final totalSamples = samplesPerNote * freqs.length;
    final byteCount = totalSamples * 2;

    final bytes = Uint8List(44 + byteCount);
    final view = ByteData.view(bytes.buffer);

    view.setUint32(0, 0x52494646, Endian.big);
    view.setUint32(4, 36 + byteCount, Endian.little);
    view.setUint32(8, 0x57415645, Endian.big);
    view.setUint32(12, 0x666D7420, Endian.big);
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little);
    view.setUint16(22, 1, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, sampleRate * 2, Endian.little);
    view.setUint16(32, 2, Endian.little);
    view.setUint16(34, 16, Endian.little);
    view.setUint32(36, 0x64617461, Endian.big);
    view.setUint32(40, byteCount, Endian.little);

    int sampleOffset = 0;
    for (final freq in freqs) {
      for (int i = 0; i < samplesPerNote; i++) {
        final t = i / sampleRate;
        final envelope = 1.0 - (i / samplesPerNote);
        final sample = (math.sin(2 * math.pi * freq * t) * envelope * volume * 32767).toInt();
        view.setInt16(44 + (sampleOffset + i) * 2, sample.clamp(-32768, 32767), Endian.little);
      }
      sampleOffset += samplesPerNote;
    }

    return 'data:audio/wav;base64,${base64Encode(bytes)}';
  }
}
