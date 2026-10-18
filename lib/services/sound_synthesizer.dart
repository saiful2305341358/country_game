import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Shared procedural 16-bit 22050Hz PCM WAV synthesizer used by both Web and Mobile (Android/iOS).
///
/// Gameplay card actions (`cardTap`, `cardPlace`, `cardTake`, `exchange`) use realistic
/// physical paper/felt friction and damped wooden table acoustics (no musical pitch sweeps
/// during normal turns), while musical chimes are reserved strictly for Game Start and Game Over.
class SoundSynthesizer {
  static const int sampleRate = 22050;

  static Map<String, Uint8List> generateAllWavBytes() {
    return <String, Uint8List>{
      'cardTap': _generatePhysicalCardFlickWav(
        durationMs: 30,
        bodyFreq: 175.0,
        volume: 0.52,
      ),
      'cardPlace': _generatePhysicalCardPlaceWav(
        durationMs: 44,
        thumpFreq: 138.0,
        volume: 0.58,
      ),
      'cardTake': _generatePhysicalCardSlideWav(
        durationMs: 56,
        volume: 0.48,
      ),
      'exchange': _generatePhysicalDealRiffleWav(
        cardCount: 4,
        stepMs: 55,
        volume: 0.46,
      ),
      'buttonClick': _generateUiClickWav(
        durationMs: 22,
        volume: 0.45,
      ),
      'gameStart': _generateChimeWav(
        freqs: const [523.25, 659.25, 783.99],
        stepDurationMs: 70,
        volume: 0.48,
      ),
      'gameEnd': _generateChimeWav(
        freqs: const [392.00, 329.63, 261.63],
        stepDurationMs: 95,
        volume: 0.50,
      ),
      'victory': _generateChimeWav(
        freqs: const [523.25, 659.25, 783.99, 1046.50],
        stepDurationMs: 85,
        volume: 0.56,
      ),
    };
  }

  static String toDataUri(Uint8List wavBytes) =>
      'data:audio/wav;base64,${base64Encode(wavBytes)}';

  static ByteData _createWavHeader(Uint8List bytes, int byteCount) {
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

  /// Crisp physical card-edge flick (short paper snap + damped low-mid body, no pitch sweep).
  static Uint8List _generatePhysicalCardFlickWav({
    required int durationMs,
    required double bodyFreq,
    required double volume,
  }) {
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, byteCount);
    final rng = math.Random(101);

    double prevNoise = 0.0;
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final attack = (progress < 0.05) ? (progress / 0.05) : 1.0;
      final decay = math.exp(-progress * 9.5);
      final env = attack * decay;

      final rawNoise = rng.nextDouble() * 2.0 - 1.0;
      // High-passed paper snap
      final crispPaper = (rawNoise - prevNoise * 0.72) * 0.65;
      prevNoise = rawNoise;

      // Rapidly damped wooden/cardboard body
      final body = math.sin(2 * math.pi * bodyFreq * t) * math.exp(-progress * 14.0);
      final wave = (0.62 * crispPaper + 0.38 * body) * env * volume;
      final sample = (wave * 32767).round().clamp(-32768, 32767);
      view.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// Soft physical card placement on table/grass (warm damped thump + paper settle).
  static Uint8List _generatePhysicalCardPlaceWav({
    required int durationMs,
    required double thumpFreq,
    required double volume,
  }) {
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, byteCount);
    final rng = math.Random(202);

    double lpNoise = 0.0;
    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final attack = (progress < 0.04) ? (progress / 0.04) : 1.0;
      final decay = math.exp(-progress * 8.2);
      final env = attack * decay;

      final rawNoise = rng.nextDouble() * 2.0 - 1.0;
      lpNoise = lpNoise * 0.65 + rawNoise * 0.35;

      // Pitch drops slightly on impact like a real physical thud (138Hz -> 92Hz)
      final instantFreq = thumpFreq * (1.0 - 0.32 * progress);
      final thud = math.sin(2 * math.pi * instantFreq * t);
      final wave = (0.68 * thud + 0.32 * lpNoise) * env * volume;
      final sample = (wave * 32767).round().clamp(-32768, 32767);
      view.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// Smooth physical card slide across felt/grass (band-filtered paper brush friction, no tone).
  static Uint8List _generatePhysicalCardSlideWav({
    required int durationMs,
    required double volume,
  }) {
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, byteCount);
    final rng = math.Random(303);

    double bandState = 0.0;
    double prevRaw = 0.0;
    for (int i = 0; i < totalSamples; i++) {
      final progress = i / totalSamples;
      final env = math.sin(math.pi * progress) * math.exp(-progress * 1.8);

      final raw = rng.nextDouble() * 2.0 - 1.0;
      final hp = raw - prevRaw * 0.82;
      prevRaw = raw;
      bandState = bandState * 0.58 + hp * 0.42;

      final wave = bandState * env * volume * 1.35;
      final sample = (wave * 32767).round().clamp(-32768, 32767);
      view.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// Physical multi-card dealing riffle (series of 4 crisp paper snaps).
  static Uint8List _generatePhysicalDealRiffleWav({
    required int cardCount,
    required int stepMs,
    required double volume,
  }) {
    final stepSamples = (sampleRate * (stepMs / 1000.0)).toInt();
    final singleFlick = _generatePhysicalCardFlickWav(
      durationMs: 28,
      bodyFreq: 185.0,
      volume: volume,
    );
    final flickSamples = (singleFlick.length - 44) ~/ 2;
    final totalSamples = stepSamples * (cardCount - 1) + flickSamples;
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, byteCount);
    final singleView = ByteData.view(singleFlick.buffer);

    for (int c = 0; c < cardCount; c++) {
      final offset = c * stepSamples;
      for (int i = 0; i < flickSamples && (offset + i) < totalSamples; i++) {
        final existing = view.getInt16(44 + (offset + i) * 2, Endian.little);
        final add = singleView.getInt16(44 + i * 2, Endian.little);
        final sum = (existing + add).clamp(-32768, 32767);
        view.setInt16(44 + (offset + i) * 2, sum, Endian.little);
      }
    }
    return bytes;
  }

  /// Crisp, short tactile UI button tap.
  static Uint8List _generateUiClickWav({
    required int durationMs,
    required double volume,
  }) {
    final totalSamples = (sampleRate * (durationMs / 1000.0)).toInt();
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, byteCount);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final env = math.exp(-progress * 11.0);
      final wave = (0.7 * math.sin(2 * math.pi * 380.0 * t) +
              0.3 * math.sin(2 * math.pi * 760.0 * t)) *
          env *
          volume;
      final sample = (wave * 32767).round().clamp(-32768, 32767);
      view.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// Warm harmonic bell chime reserved strictly for Game Start and Game Over / Victory.
  static Uint8List _generateChimeWav({
    required List<double> freqs,
    required int stepDurationMs,
    required double volume,
  }) {
    final samplesPerNote = (sampleRate * (stepDurationMs / 1000.0)).toInt();
    final tailSamples = (sampleRate * 0.16).toInt();
    final totalSamples = samplesPerNote * freqs.length + tailSamples;
    final byteCount = totalSamples * 2;
    final bytes = Uint8List(44 + byteCount);
    final view = _createWavHeader(bytes, byteCount);
    final mixBuffer = Float64List(totalSamples);

    for (int n = 0; n < freqs.length; n++) {
      final freq = freqs[n];
      final isLastNote = n == freqs.length - 1;
      final noteStart = n * samplesPerNote;
      final noteLength = isLastNote
          ? samplesPerNote + tailSamples
          : (samplesPerNote * 1.35).toInt();

      for (int i = 0; i < noteLength && (noteStart + i) < totalSamples; i++) {
        final t = i / sampleRate;
        final progress = i / noteLength;
        final attack = (progress < 0.06) ? (progress / 0.06) : 1.0;
        final decay = math.exp(-progress * (isLastNote ? 2.6 : 3.4));
        final env = attack * decay;

        final wave = 0.68 * math.sin(2 * math.pi * freq * t) +
            0.22 * math.sin(2 * math.pi * (freq * 2.0) * t) +
            0.10 * math.sin(2 * math.pi * (freq * 3.0) * t);
        mixBuffer[noteStart + i] += wave * env * volume;
      }
    }

    for (int i = 0; i < totalSamples; i++) {
      final clamped = mixBuffer[i].clamp(-0.98, 0.98);
      final sample = (clamped * 32767).round().clamp(-32768, 32767);
      view.setInt16(44 + i * 2, sample, Endian.little);
    }

    return bytes;
  }
}
