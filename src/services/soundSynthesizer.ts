// Procedural 16-bit 22050Hz PCM WAV synthesizer & Audio/Haptic/Settings services
// Faithfully ported from lib/services/sound_synthesizer.dart, audio_service_web.dart, and haptic_service_web.dart
// Optimized with lazy per-key WAV synthesis, immediate mute/stopAll, and visibilitychange lifecycle handling.

import { DEFAULT_GAME_SETTINGS, GameSettings } from '../models/types';

const SAMPLE_RATE = 22050;

class SeededRandom {
  private seed: number;
  constructor(seed: number) {
    this.seed = seed % 2147483647;
    if (this.seed <= 0) this.seed += 2147483646;
  }
  nextDouble(): number {
    this.seed = (this.seed * 16807) % 2147483647;
    return (this.seed - 1) / 2147483646;
  }
}

function createWavHeader(bytes: Uint8Array, byteCount: number): DataView {
  const view = new DataView(bytes.buffer);
  view.setUint32(0, 0x52494646, false); // "RIFF"
  view.setUint32(4, 36 + byteCount, true);
  view.setUint32(8, 0x57415645, false); // "WAVE"
  view.setUint32(12, 0x666d7420, false); // "fmt "
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true); // PCM
  view.setUint16(22, 1, true); // Mono
  view.setUint32(24, SAMPLE_RATE, true);
  view.setUint32(28, SAMPLE_RATE * 2, true);
  view.setUint16(32, 2, true);
  view.setUint16(34, 16, true);
  view.setUint32(36, 0x64617461, false); // "data"
  view.setUint32(40, byteCount, true);
  return view;
}

function clamp(val: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, val));
}

function generatePhysicalCardFlickWav(durationMs: number, bodyFreq: number, volume: number): Uint8Array {
  const totalSamples = Math.floor(SAMPLE_RATE * (durationMs / 1000.0));
  const byteCount = totalSamples * 2;
  const bytes = new Uint8Array(44 + byteCount);
  const view = createWavHeader(bytes, byteCount);
  const rng = new SeededRandom(101);

  let prevNoise = 0.0;
  for (let i = 0; i < totalSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = i / totalSamples;
    const attack = progress < 0.05 ? progress / 0.05 : 1.0;
    const decay = Math.exp(-progress * 9.5);
    const env = attack * decay;

    const rawNoise = rng.nextDouble() * 2.0 - 1.0;
    const crispPaper = (rawNoise - prevNoise * 0.72) * 0.65;
    prevNoise = rawNoise;

    const body = Math.sin(2 * Math.PI * bodyFreq * t) * Math.exp(-progress * 14.0);
    const wave = (0.62 * crispPaper + 0.38 * body) * env * volume;
    const sample = clamp(Math.round(wave * 32767), -32768, 32767);
    view.setInt16(44 + i * 2, sample, true);
  }
  return bytes;
}

function generatePhysicalCardPlaceWav(durationMs: number, thumpFreq: number, volume: number): Uint8Array {
  const totalSamples = Math.floor(SAMPLE_RATE * (durationMs / 1000.0));
  const byteCount = totalSamples * 2;
  const bytes = new Uint8Array(44 + byteCount);
  const view = createWavHeader(bytes, byteCount);
  const rng = new SeededRandom(202);

  let lpNoise = 0.0;
  for (let i = 0; i < totalSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = i / totalSamples;
    const attack = progress < 0.04 ? progress / 0.04 : 1.0;
    const decay = Math.exp(-progress * 8.2);
    const env = attack * decay;

    const rawNoise = rng.nextDouble() * 2.0 - 1.0;
    lpNoise = lpNoise * 0.65 + rawNoise * 0.35;

    const instantFreq = thumpFreq * (1.0 - 0.32 * progress);
    const thud = Math.sin(2 * Math.PI * instantFreq * t);
    const wave = (0.68 * thud + 0.32 * lpNoise) * env * volume;
    const sample = clamp(Math.round(wave * 32767), -32768, 32767);
    view.setInt16(44 + i * 2, sample, true);
  }
  return bytes;
}

function generatePhysicalCardSlideWav(durationMs: number, volume: number): Uint8Array {
  const totalSamples = Math.floor(SAMPLE_RATE * (durationMs / 1000.0));
  const byteCount = totalSamples * 2;
  const bytes = new Uint8Array(44 + byteCount);
  const view = createWavHeader(bytes, byteCount);
  const rng = new SeededRandom(303);

  let bandState = 0.0;
  let prevRaw = 0.0;
  for (let i = 0; i < totalSamples; i++) {
    const progress = i / totalSamples;
    const env = Math.sin(Math.PI * progress) * Math.exp(-progress * 1.8);

    const raw = rng.nextDouble() * 2.0 - 1.0;
    const hp = raw - prevRaw * 0.82;
    prevRaw = raw;
    bandState = bandState * 0.58 + hp * 0.42;

    const wave = bandState * env * volume * 1.35;
    const sample = clamp(Math.round(wave * 32767), -32768, 32767);
    view.setInt16(44 + i * 2, sample, true);
  }
  return bytes;
}

function generatePhysicalDealRiffleWav(cardCount: number, stepMs: number, volume: number): Uint8Array {
  const stepSamples = Math.floor(SAMPLE_RATE * (stepMs / 1000.0));
  const singleFlick = generatePhysicalCardFlickWav(28, 185.0, volume);
  const flickSamples = Math.floor((singleFlick.length - 44) / 2);
  const totalSamples = stepSamples * (cardCount - 1) + flickSamples;
  const byteCount = totalSamples * 2;
  const bytes = new Uint8Array(44 + byteCount);
  const view = createWavHeader(bytes, byteCount);
  const singleView = new DataView(singleFlick.buffer);

  for (let c = 0; c < cardCount; c++) {
    const offset = c * stepSamples;
    for (let i = 0; i < flickSamples && offset + i < totalSamples; i++) {
      const existing = view.getInt16(44 + (offset + i) * 2, true);
      const add = singleView.getInt16(44 + i * 2, true);
      const sum = clamp(existing + add, -32768, 32767);
      view.setInt16(44 + (offset + i) * 2, sum, true);
    }
  }
  return bytes;
}

function generateUiClickWav(durationMs: number, volume: number): Uint8Array {
  const totalSamples = Math.floor(SAMPLE_RATE * (durationMs / 1000.0));
  const byteCount = totalSamples * 2;
  const bytes = new Uint8Array(44 + byteCount);
  const view = createWavHeader(bytes, byteCount);

  for (let i = 0; i < totalSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = i / totalSamples;
    const env = Math.exp(-progress * 11.0);
    const wave =
      (0.7 * Math.sin(2 * Math.PI * 380.0 * t) + 0.3 * Math.sin(2 * Math.PI * 760.0 * t)) *
      env *
      volume;
    const sample = clamp(Math.round(wave * 32767), -32768, 32767);
    view.setInt16(44 + i * 2, sample, true);
  }
  return bytes;
}

function generateChimeWav(freqs: number[], stepDurationMs: number, volume: number): Uint8Array {
  const samplesPerNote = Math.floor(SAMPLE_RATE * (stepDurationMs / 1000.0));
  const tailSamples = Math.floor(SAMPLE_RATE * 0.16);
  const totalSamples = samplesPerNote * freqs.length + tailSamples;
  const byteCount = totalSamples * 2;
  const bytes = new Uint8Array(44 + byteCount);
  const view = createWavHeader(bytes, byteCount);
  const mixBuffer = new Float64Array(totalSamples);

  for (let n = 0; n < freqs.length; n++) {
    const freq = freqs[n];
    const isLastNote = n === freqs.length - 1;
    const noteStart = n * samplesPerNote;
    const noteLength = isLastNote ? samplesPerNote + tailSamples : Math.floor(samplesPerNote * 1.35);

    for (let i = 0; i < noteLength && noteStart + i < totalSamples; i++) {
      const t = i / SAMPLE_RATE;
      const progress = i / noteLength;
      const attack = progress < 0.06 ? progress / 0.06 : 1.0;
      const decay = Math.exp(-progress * (isLastNote ? 2.6 : 3.4));
      const env = attack * decay;

      const wave =
        0.68 * Math.sin(2 * Math.PI * freq * t) +
        0.22 * Math.sin(2 * Math.PI * (freq * 2.0) * t) +
        0.1 * Math.sin(2 * Math.PI * (freq * 3.0) * t);
      mixBuffer[noteStart + i] += wave * env * volume;
    }
  }

  for (let i = 0; i < totalSamples; i++) {
    const clamped = clamp(mixBuffer[i], -0.98, 0.98);
    const sample = clamp(Math.round(clamped * 32767), -32768, 32767);
    view.setInt16(44 + i * 2, sample, true);
  }

  return bytes;
}

function uint8ToDataUri(bytes: Uint8Array): string {
  const chunkSize = 0x8000;
  const chunks: string[] = [];
  for (let i = 0; i < bytes.byteLength; i += chunkSize) {
    const sub = bytes.subarray(i, Math.min(i + chunkSize, bytes.byteLength));
    chunks.push(String.fromCharCode.apply(null, Array.from(sub)));
  }
  return `data:audio/wav;base64,${btoa(chunks.join(''))}`;
}

class SoundPool {
  private elements: HTMLAudioElement[];
  private cursor = 0;

  constructor(src: string, poolSize = 3) {
    this.elements = Array.from({ length: poolSize }, () => {
      const el = new Audio(src);
      el.preload = 'auto';
      el.volume = 1.0;
      return el;
    });
  }

  next(): HTMLAudioElement {
    const el = this.elements[this.cursor];
    this.cursor = (this.cursor + 1) % this.elements.length;
    return el;
  }

  stopAll(): void {
    for (const el of this.elements) {
      try {
        if (!el.paused) {
          el.pause();
          el.currentTime = 0;
        }
      } catch {
        // ignore
      }
    }
  }
}

type SoundKey =
  | 'cardTap'
  | 'cardPlace'
  | 'cardTake'
  | 'exchange'
  | 'buttonClick'
  | 'gameStart'
  | 'gameEnd'
  | 'victory';

class AudioServiceImpl {
  private _soundEnabled = true;
  private pools: Partial<Record<SoundKey, SoundPool>> = {};

  constructor() {
    try {
      const saved = window.localStorage.getItem('country_game_sound_enabled');
      if (saved !== null) {
        this._soundEnabled = saved === 'true';
      }
    } catch {
      // ignore
    }

    // Warm up sound pools during browser idle time after initial paint
    if (typeof window !== 'undefined') {
      const warmup = () => {
        try {
          this.getOrCreatePool('buttonClick');
          this.getOrCreatePool('cardTap');
          this.getOrCreatePool('cardPlace');
          this.getOrCreatePool('cardTake');
        } catch {
          // ignore
        }
      };
      if ('requestIdleCallback' in window) {
        (window as unknown as { requestIdleCallback: (cb: () => void) => void }).requestIdleCallback(warmup);
      } else {
        setTimeout(warmup, 250);
      }

      document.addEventListener('visibilitychange', () => {
        if (document.hidden) {
          this.stopAll();
        }
      });
    }
  }

  private synthesizeBytes(key: SoundKey): Uint8Array {
    switch (key) {
      case 'cardTap':
        return generatePhysicalCardFlickWav(30, 175.0, 0.52);
      case 'cardPlace':
        return generatePhysicalCardPlaceWav(44, 138.0, 0.58);
      case 'cardTake':
        return generatePhysicalCardSlideWav(56, 0.48);
      case 'exchange':
        return generatePhysicalDealRiffleWav(4, 55, 0.46);
      case 'buttonClick':
        return generateUiClickWav(22, 0.45);
      case 'gameStart':
        return generateChimeWav([523.25, 659.25, 783.99], 70, 0.48);
      case 'gameEnd':
        return generateChimeWav([392.0, 329.63, 261.63], 95, 0.5);
      case 'victory':
        return generateChimeWav([523.25, 659.25, 783.99, 1046.5], 85, 0.56);
    }
  }

  private getOrCreatePool(key: SoundKey): SoundPool | null {
    const existing = this.pools[key];
    if (existing) return existing;
    try {
      const bytes = this.synthesizeBytes(key);
      const isFrequent = key === 'cardTap' || key === 'cardPlace' || key === 'cardTake';
      const pool = new SoundPool(uint8ToDataUri(bytes), isFrequent ? 3 : 2);
      this.pools[key] = pool;
      return pool;
    } catch {
      return null;
    }
  }

  get isSoundEnabled(): boolean {
    return this._soundEnabled;
  }

  set isSoundEnabled(enabled: boolean) {
    this._soundEnabled = enabled;
    if (!enabled) {
      this.stopAll();
    }
    try {
      window.localStorage.setItem('country_game_sound_enabled', String(enabled));
    } catch {
      // ignore
    }
  }

  stopAll(): void {
    for (const pool of Object.values(this.pools)) {
      pool?.stopAll();
    }
  }

  private playSound(key: SoundKey) {
    if (!this._soundEnabled) return;
    if (typeof document !== 'undefined' && document.hidden) return;
    const pool = this.getOrCreatePool(key);
    if (!pool) return;
    try {
      const audio = pool.next();
      audio.currentTime = 0;
      audio.volume = 1.0;
      audio.play().catch(() => {});
    } catch {
      // ignore
    }
  }

  playCardTap() {
    this.playSound('cardTap');
  }
  playCardTake() {
    this.playSound('cardTake');
  }
  playCardPlace() {
    this.playSound('cardPlace');
  }
  playExchange() {
    this.playSound('exchange');
  }
  playGameStart() {
    this.playSound('gameStart');
  }
  playGameEnd() {
    this.playSound('gameEnd');
  }
  playVictory() {
    this.playSound('victory');
  }
  playButtonClick() {
    this.playSound('buttonClick');
  }
}

class HapticServiceImpl {
  private _hapticsEnabled = true;

  constructor() {
    try {
      const saved = window.localStorage.getItem('country_game_haptics_enabled');
      if (saved !== null) {
        this._hapticsEnabled = saved === 'true';
      }
    } catch {
      // ignore
    }
  }

  get isHapticsEnabled(): boolean {
    return this._hapticsEnabled;
  }

  set isHapticsEnabled(enabled: boolean) {
    this._hapticsEnabled = enabled;
    if (!enabled) {
      try {
        if (typeof navigator !== 'undefined' && navigator.vibrate) {
          navigator.vibrate(0);
        }
      } catch {
        // ignore
      }
    }
    try {
      window.localStorage.setItem('country_game_haptics_enabled', String(enabled));
    } catch {
      // ignore
    }
  }

  private vibrate(pattern: number | number[]) {
    if (!this._hapticsEnabled) return;
    if (typeof document !== 'undefined' && document.hidden) return;
    try {
      if (typeof navigator !== 'undefined' && navigator.vibrate) {
        navigator.vibrate(pattern);
      }
    } catch {
      // ignore
    }
  }

  cardTap() {
    this.vibrate(12);
  }
  cardPass() {
    this.vibrate(22);
  }
  invalidMove() {
    this.vibrate([18, 45, 24]);
  }
  botTurnTick() {
    this.vibrate(8);
  }
  yourTurnNotice() {
    this.vibrate([14, 35, 22]);
  }
  dealShuffle() {
    this.vibrate([10, 30, 12, 30, 16]);
  }
  victory() {
    this.vibrate([35, 50, 45, 50, 85]);
  }
  roundEnd() {
    this.vibrate([25, 60, 40]);
  }
  uiTap() {
    this.vibrate(10);
  }
}

export const AudioService = new AudioServiceImpl();
export const HapticService = new HapticServiceImpl();

export function loadPersistedSettings(): GameSettings {
  let animationsEnabled = DEFAULT_GAME_SETTINGS.animationsEnabled;
  let botDelayMs = DEFAULT_GAME_SETTINGS.botDelayMs;
  try {
    const savedAnim = window.localStorage.getItem('country_game_animations_enabled');
    if (savedAnim !== null) {
      animationsEnabled = savedAnim === 'true';
    }
    const savedDelay = window.localStorage.getItem('country_game_bot_delay_ms');
    if (savedDelay !== null) {
      const parsed = parseInt(savedDelay, 10);
      if (!Number.isNaN(parsed) && parsed >= 500 && parsed <= 5000) {
        botDelayMs = parsed;
      }
    }
  } catch {
    // ignore
  }
  return {
    ...DEFAULT_GAME_SETTINGS,
    soundEnabled: AudioService.isSoundEnabled,
    hapticsEnabled: HapticService.isHapticsEnabled,
    animationsEnabled,
    botDelayMs,
  };
}

export function savePersistedSettings(settings: GameSettings): void {
  try {
    window.localStorage.setItem(
      'country_game_animations_enabled',
      String(settings.animationsEnabled)
    );
    window.localStorage.setItem('country_game_bot_delay_ms', String(settings.botDelayMs));
  } catch {
    // ignore
  }
}
