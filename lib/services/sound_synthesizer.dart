import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Shared procedural 16-bit 22050Hz PCM WAV synthesizer used by both Web and Mobile (Android/iOS).
///
/// Specifically tuned for real mobile phone micro-speakers (300Hz–2200Hz mid-range harmonics,
/// clear 45ms–90ms transient sustain, and 0.85–0.94 normalized peak amplitude) so card taps,
/// tabletop placements, slides, dealing riffles, UI clicks, and chimes are loud, crisp, and
/// unmistakable on every Android & iOS phone without external headphones.
class SoundSynthesizer {
  static const int sampleRate = 22050;

  static Map<String, Uint8List> generateAllWavBytes() {
    return <String, Uint8List>{
      'cardTap': _generatePhysicalCardFlickWav(
        durationMs: 55,
        bodyFreq: 310.0,
        volume: 0.88,
      ),
      'cardPlace': _generatePhysicalCardPlaceWav(
        durationMs: 75,
        thumpFreq: 260.0,
        volume: 0.92,
      ),
      'cardTake': _generatePhysicalCardSlideWav(
        durationMs: 85,
        volume: 0.86,
      ),
      'exchange': _generatePhysicalDealRiffleWav(
        cardCount: 4,
        stepMs: 60,
        volume: 0.88,
      ),
      'buttonClick': _generateUiClickWav(
        durationMs: 42,
        volume: 0.86,
      ),
      'gameStart': _generateChimeWav(
        freqs: const [523.25, 659.25, 783.99],
        stepDurationMs: 80,
        volume: 0.90,
      ),
      'gameEnd': _generateChimeWav(
        freqs: const [392.00, 329.63, 261.63],
        stepDurationMs: 105,
        volume: 0.90,
      ),
      'victory': _generateChimeWav(
        freqs: const [523.25, 659.25, 783.99, 1046.50],
        stepDurationMs: 95,
        volume: 0.94,
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

  /// Crisp physical card-edge flick with mid-range body + upper-mid snap for phone speakers.
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
      final attack = (progress < 0.04) ? (progress / 0.04) : 1.0;
      final decay = math.exp(-progress * 5.2);
      final env = attack * decay;

      final rawNoise = rng.nextDouble() * 2.0 - 1.0;
      final crispPaper = (rawNoise - prevNoise * 0.68) * 0.72;
      prevNoise = rawNoise;

      // Fundamental + 2nd & 3rd overtones so small phone speakers reproduce the card snap clearly
      final body = (0.55 * math.sin(2 * math.pi * bodyFreq * t) +
              0.30 * math.sin(2 * math.pi * (bodyFreq * 2.0) * t) +
              0.15 * math.sin(2 * math.pi * (bodyFreq * 3.2) * t)) *
          math.exp(-progress * 7.5);
      final wave = ((0.52 * crispPaper + 0.58 * body) * env * volume)
          .clamp(-0.98, 0.98);
      final sample = (wave * 32767).round().clamp(-32768, 32767);
      view.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// Tactile physical card placement on table (warm mid-range wood/felt impact + paper settle).
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
      final attack = (progress < 0.03) ? (progress / 0.03) : 1.0;
      final decay = math.exp(-progress * 4.8);
      final env = attack * decay;

      final rawNoise = rng.nextDouble() * 2.0 - 1.0;
      lpNoise = lpNoise * 0.55 + rawNoise * 0.45;

      // Audible mid-range pitch drop (260Hz -> 175Hz + 520Hz/780Hz overtones)
      final instantFreq = thumpFreq * (1.0 - 0.30 * progress);
      final thud = 0.52 * math.sin(2 * math.pi * instantFreq * t) +
          0.32 * math.sin(2 * math.pi * (instantFreq * 2.0) * t) +
          0.16 * math.sin(2 * math.pi * (instantFreq * 3.0) * t);
      final wave = ((0.68 * thud + 0.38 * lpNoise) * env * volume)
          .clamp(-0.98, 0.98);
      final sample = (wave * 32767).round().clamp(-32768, 32767);
      view.setInt16(44 + i * 2, sample, Endian.little);
    }
    return bytes;
  }

  /// Smooth physical card slide & pickup across tabletop with audible mid-band friction.
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
      final t = i / sampleRate;
      final progress = i / totalSamples;
      final env = math.sin(math.pi * progress) * math.exp(-progress * 1.3);

      final raw = rng.nextDouble() * 2.0 - 1.0;
      final hp = raw - prevRaw * 0.76;
      prevRaw = raw;
      bandState = bandState * 0.52 + hp * 0.48;

      final slideResonance =
          0.32 * math.sin(2 * math.pi * (420.0 + 240.0 * progress) * t);
      final wave = ((0.75 * bandState + slideResonance) * env * volume * 1.35)
          .clamp(-0.98, 0.98);
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
      durationMs: 46,
      bodyFreq: 330.0,
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

  /// Crisp, clear tactile UI button tap tuned for phone speakers.
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
      final attack = (progress < 0.04) ? (progress / 0.04) : 1.0;
      final env = attack * math.exp(-progress * 6.2);
      final wave = (0.52 * math.sin(2 * math.pi * 520.0 * t) +
              0.33 * math.sin(2 * math.pi * 1040.0 * t) +
              0.15 * math.sin(2 * math.pi * 1560.0 * t)) *
          env *
          volume;
      final sample = (wave.clamp(-0.98, 0.98) * 32767).round().clamp(-32768, 32767);
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
    final tailSamples = (sampleRate * 0.22).toInt();
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
          : (samplesPerNote * 1.45).toInt();

      for (int i = 0; i < noteLength && (noteStart + i) < totalSamples; i++) {
        final t = i / sampleRate;
        final progress = i / noteLength;
        final attack = (progress < 0.05) ? (progress / 0.05) : 1.0;
        final decay = math.exp(-progress * (isLastNote ? 2.2 : 3.0));
        final env = attack * decay;

        final wave = 0.58 * math.sin(2 * math.pi * freq * t) +
            0.26 * math.sin(2 * math.pi * (freq * 2.0) * t) +
            0.12 * math.sin(2 * math.pi * (freq * 3.0) * t) +
            0.04 * math.sin(2 * math.pi * (freq * 4.0) * t);
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
