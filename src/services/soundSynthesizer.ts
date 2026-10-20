// Procedural 22050Hz PCM Audio & Haptic Engine optimized for Mobile Phones, Android WebView APKs, and Browsers.
// Uses Web Audio API (AudioContext + in-memory AudioBuffer) as primary zero-latency engine
// (eliminating Android WebView MediaPlayer data-URI failures and mobile autoplay blocks),
// with automatic first-gesture unlock and HTMLAudioElement fallback.

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

function clamp(val: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, val));
}

function floatSamplesToWavBytes(samples: Float32Array): Uint8Array {
  const totalSamples = samples.length;
  const byteCount = totalSamples * 2;
  const bytes = new Uint8Array(44 + byteCount);
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

  for (let i = 0; i < totalSamples; i++) {
    const s = clamp(Math.round(samples[i] * 32767), -32768, 32767);
    view.setInt16(44 + i * 2, s, true);
  }
  return bytes;
}

/// Crisp physical card-edge flick with mid-range body + upper-mid snap for phone speakers.
function generatePhysicalCardFlickSamples(
  durationMs: number,
  bodyFreq: number,
  volume: number
): Float32Array {
  const totalSamples = Math.floor(SAMPLE_RATE * (durationMs / 1000.0));
  const out = new Float32Array(totalSamples);
  const rng = new SeededRandom(101);

  let prevNoise = 0.0;
  for (let i = 0; i < totalSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = i / totalSamples;
    const attack = progress < 0.04 ? progress / 0.04 : 1.0;
    const decay = Math.exp(-progress * 5.2);
    const env = attack * decay;

    const rawNoise = rng.nextDouble() * 2.0 - 1.0;
    const crispPaper = (rawNoise - prevNoise * 0.68) * 0.72;
    prevNoise = rawNoise;

    const body =
      (0.55 * Math.sin(2 * Math.PI * bodyFreq * t) +
        0.3 * Math.sin(2 * Math.PI * (bodyFreq * 2.0) * t) +
        0.15 * Math.sin(2 * Math.PI * (bodyFreq * 3.2) * t)) *
      Math.exp(-progress * 7.5);
    out[i] = clamp((0.52 * crispPaper + 0.58 * body) * env * volume, -0.98, 0.98);
  }
  return out;
}

/// Tactile physical card placement on table (warm mid-range wood/felt impact + paper settle).
function generatePhysicalCardPlaceSamples(
  durationMs: number,
  thumpFreq: number,
  volume: number
): Float32Array {
  const totalSamples = Math.floor(SAMPLE_RATE * (durationMs / 1000.0));
  const out = new Float32Array(totalSamples);
  const rng = new SeededRandom(202);

  let lpNoise = 0.0;
  for (let i = 0; i < totalSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = i / totalSamples;
    const attack = progress < 0.03 ? progress / 0.03 : 1.0;
    const decay = Math.exp(-progress * 4.8);
    const env = attack * decay;

    const rawNoise = rng.nextDouble() * 2.0 - 1.0;
    lpNoise = lpNoise * 0.55 + rawNoise * 0.45;

    const instantFreq = thumpFreq * (1.0 - 0.3 * progress);
    const thud =
      0.52 * Math.sin(2 * Math.PI * instantFreq * t) +
      0.32 * Math.sin(2 * Math.PI * (instantFreq * 2.0) * t) +
      0.16 * Math.sin(2 * Math.PI * (instantFreq * 3.0) * t);
    out[i] = clamp((0.68 * thud + 0.38 * lpNoise) * env * volume, -0.98, 0.98);
  }
  return out;
}

/// Smooth physical card slide & pickup across tabletop with audible mid-band friction.
function generatePhysicalCardSlideSamples(durationMs: number, volume: number): Float32Array {
  const totalSamples = Math.floor(SAMPLE_RATE * (durationMs / 1000.0));
  const out = new Float32Array(totalSamples);
  const rng = new SeededRandom(303);

  let bandState = 0.0;
  let prevRaw = 0.0;
  for (let i = 0; i < totalSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = i / totalSamples;
    const env = Math.sin(Math.PI * progress) * Math.exp(-progress * 1.3);

    const raw = rng.nextDouble() * 2.0 - 1.0;
    const hp = raw - prevRaw * 0.76;
    prevRaw = raw;
    bandState = bandState * 0.52 + hp * 0.48;

    const slideResonance = 0.32 * Math.sin(2 * Math.PI * (420.0 + 240.0 * progress) * t);
    out[i] = clamp((0.75 * bandState + slideResonance) * env * volume * 1.35, -0.98, 0.98);
  }
  return out;
}

/// Physical multi-card dealing riffle (series of 4 crisp paper snaps).
function generatePhysicalDealRiffleSamples(
  cardCount: number,
  stepMs: number,
  volume: number
): Float32Array {
  const stepSamples = Math.floor(SAMPLE_RATE * (stepMs / 1000.0));
  const singleFlick = generatePhysicalCardFlickSamples(46, 330.0, volume);
  const flickSamples = singleFlick.length;
  const totalSamples = stepSamples * (cardCount - 1) + flickSamples;
  const out = new Float32Array(totalSamples);

  for (let c = 0; c < cardCount; c++) {
    const offset = c * stepSamples;
    for (let i = 0; i < flickSamples && offset + i < totalSamples; i++) {
      out[offset + i] = clamp(out[offset + i] + singleFlick[i], -0.98, 0.98);
    }
  }
  return out;
}

/// Crisp, clear tactile UI button tap tuned for phone speakers.
function generateUiClickSamples(durationMs: number, volume: number): Float32Array {
  const totalSamples = Math.floor(SAMPLE_RATE * (durationMs / 1000.0));
  const out = new Float32Array(totalSamples);

  for (let i = 0; i < totalSamples; i++) {
    const t = i / SAMPLE_RATE;
    const progress = i / totalSamples;
    const attack = progress < 0.04 ? progress / 0.04 : 1.0;
    const env = attack * Math.exp(-progress * 6.2);
    const wave =
      (0.52 * Math.sin(2 * Math.PI * 520.0 * t) +
        0.33 * Math.sin(2 * Math.PI * 1040.0 * t) +
        0.15 * Math.sin(2 * Math.PI * 1560.0 * t)) *
      env *
      volume;
    out[i] = clamp(wave, -0.98, 0.98);
  }
  return out;
}

/// Warm harmonic bell chime reserved strictly for Game Start and Game Over / Victory.
function generateChimeSamples(
  freqs: number[],
  stepDurationMs: number,
  volume: number
): Float32Array {
  const samplesPerNote = Math.floor(SAMPLE_RATE * (stepDurationMs / 1000.0));
  const tailSamples = Math.floor(SAMPLE_RATE * 0.22);
  const totalSamples = samplesPerNote * freqs.length + tailSamples;
  const out = new Float32Array(totalSamples);

  for (let n = 0; n < freqs.length; n++) {
    const freq = freqs[n];
    const isLastNote = n === freqs.length - 1;
    const noteStart = n * samplesPerNote;
    const noteLength = isLastNote ? samplesPerNote + tailSamples : Math.floor(samplesPerNote * 1.45);

    for (let i = 0; i < noteLength && noteStart + i < totalSamples; i++) {
      const t = i / SAMPLE_RATE;
      const progress = i / noteLength;
      const attack = progress < 0.05 ? progress / 0.05 : 1.0;
      const decay = Math.exp(-progress * (isLastNote ? 2.2 : 3.0));
      const env = attack * decay;

      const wave =
        0.58 * Math.sin(2 * Math.PI * freq * t) +
        0.26 * Math.sin(2 * Math.PI * (freq * 2.0) * t) +
        0.12 * Math.sin(2 * Math.PI * (freq * 3.0) * t) +
        0.04 * Math.sin(2 * Math.PI * (freq * 4.0) * t);
      out[noteStart + i] = clamp(out[noteStart + i] + wave * env * volume, -0.98, 0.98);
    }
  }
  return out;
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

type WebAudioContextConstructor = typeof AudioContext;

function getAudioContextConstructor(): WebAudioContextConstructor | null {
  if (typeof window === 'undefined') return null;
  const w = window as unknown as {
    AudioContext?: WebAudioContextConstructor;
    webkitAudioContext?: WebAudioContextConstructor;
  };
  return w.AudioContext || w.webkitAudioContext || null;
}

class AudioServiceImpl {
  private _soundEnabled = true;
  private audioCtx: AudioContext | null = null;
  private masterGain: GainNode | null = null;
  private floatCache: Partial<Record<SoundKey, Float32Array>> = {};
  private audioBuffers: Partial<Record<SoundKey, AudioBuffer>> = {};
  private activeSources: Set<AudioBufferSourceNode> = new Set();
  private pools: Partial<Record<SoundKey, SoundPool>> = {};
  private unlocked = false;

  constructor() {
    try {
      const saved = window.localStorage.getItem('country_game_sound_enabled');
      if (saved !== null) {
        this._soundEnabled = saved === 'true';
      }
    } catch {
      // ignore
    }

    if (typeof window !== 'undefined') {
      this.setupMobileGestureUnlock();

      const warmup = () => {
        try {
          this.getOrCreateSamples('buttonClick');
          this.getOrCreateSamples('cardTap');
          this.getOrCreateSamples('cardPlace');
          this.getOrCreateSamples('cardTake');
          this.getOrCreateSamples('exchange');
        } catch {
          // ignore
        }
      };

      if ('requestIdleCallback' in window) {
        (window as unknown as { requestIdleCallback: (cb: () => void) => void }).requestIdleCallback(
          warmup
        );
      } else {
        setTimeout(warmup, 120);
      }

      document.addEventListener('visibilitychange', () => {
        if (document.hidden) {
          this.stopAll();
        } else if (this._soundEnabled && this.audioCtx && this.audioCtx.state === 'suspended') {
          this.audioCtx.resume().catch(() => {});
        }
      });
    }
  }

  private setupMobileGestureUnlock(): void {
    const unlockEvents = ['pointerdown', 'touchstart', 'touchend', 'mousedown', 'keydown', 'click'];
    const onGesture = () => {
      try {
        const ctx = this.ensureAudioContext();
        if (ctx) {
          if (ctx.state === 'suspended') {
            ctx.resume().catch(() => {});
          }
          if (!this.unlocked) {
            this.unlocked = true;
            // Play a 1-sample silent buffer to permanently unlock hardware audio on Android WebView & iOS
            const silentBuf = ctx.createBuffer(1, 1, SAMPLE_RATE);
            const src = ctx.createBufferSource();
            src.buffer = silentBuf;
            src.connect(ctx.destination);
            src.start(0);
          }
        }
      } catch {
        // ignore
      }
    };

    for (const evt of unlockEvents) {
      window.addEventListener(evt, onGesture, { capture: true, passive: true });
    }
  }

  private ensureAudioContext(): AudioContext | null {
    if (this.audioCtx) {
      return this.audioCtx;
    }
    const Ctor = getAudioContextConstructor();
    if (!Ctor) return null;
    try {
      this.audioCtx = new Ctor();
      this.masterGain = this.audioCtx.createGain();
      this.masterGain.gain.value = this._soundEnabled ? 1.0 : 0.0;
      this.masterGain.connect(this.audioCtx.destination);
      return this.audioCtx;
    } catch {
      return null;
    }
  }

  private synthesizeSamples(key: SoundKey): Float32Array {
    switch (key) {
      case 'cardTap':
        return generatePhysicalCardFlickSamples(55, 310.0, 0.88);
      case 'cardPlace':
        return generatePhysicalCardPlaceSamples(75, 260.0, 0.92);
      case 'cardTake':
        return generatePhysicalCardSlideSamples(85, 0.86);
      case 'exchange':
        return generatePhysicalDealRiffleSamples(4, 60, 0.88);
      case 'buttonClick':
        return generateUiClickSamples(42, 0.86);
      case 'gameStart':
        return generateChimeSamples([523.25, 659.25, 783.99], 80, 0.9);
      case 'gameEnd':
        return generateChimeSamples([392.0, 329.63, 261.63], 105, 0.9);
      case 'victory':
        return generateChimeSamples([523.25, 659.25, 783.99, 1046.5], 95, 0.94);
    }
  }

  private getOrCreateSamples(key: SoundKey): Float32Array {
    let samples = this.floatCache[key];
    if (!samples) {
      samples = this.synthesizeSamples(key);
      this.floatCache[key] = samples;
    }
    return samples;
  }

  private getOrCreateAudioBuffer(ctx: AudioContext, key: SoundKey): AudioBuffer | null {
    const existing = this.audioBuffers[key];
    if (existing) return existing;
    try {
      const samples = this.getOrCreateSamples(key);
      const buffer = ctx.createBuffer(1, samples.length, SAMPLE_RATE);
      const channel = buffer.getChannelData(0);
      channel.set(samples);
      this.audioBuffers[key] = buffer;
      return buffer;
    } catch {
      return null;
    }
  }

  private getOrCreateFallbackPool(key: SoundKey): SoundPool | null {
    const existing = this.pools[key];
    if (existing) return existing;
    try {
      const samples = this.getOrCreateSamples(key);
      const wavBytes = floatSamplesToWavBytes(samples);
      const isFrequent = key === 'cardTap' || key === 'cardPlace' || key === 'cardTake';
      const pool = new SoundPool(uint8ToDataUri(wavBytes), isFrequent ? 3 : 2);
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
    if (this.masterGain && this.audioCtx) {
      try {
        this.masterGain.gain.setValueAtTime(enabled ? 1.0 : 0.0, this.audioCtx.currentTime);
      } catch {
        this.masterGain.gain.value = enabled ? 1.0 : 0.0;
      }
    }
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
    for (const src of this.activeSources) {
      try {
        src.stop();
        src.disconnect();
      } catch {
        // ignore
      }
    }
    this.activeSources.clear();

    for (const pool of Object.values(this.pools)) {
      pool?.stopAll();
    }
  }

  private playSound(key: SoundKey) {
    if (!this._soundEnabled) return;
    if (typeof document !== 'undefined' && document.hidden) return;

    // 1. Primary Engine: Web Audio API (zero-latency in-memory AudioBuffer, works in all Android WebViews & mobile browsers)
    const ctx = this.ensureAudioContext();
    if (ctx) {
      try {
        if (ctx.state === 'suspended') {
          ctx.resume().catch(() => {});
        }
        const buffer = this.getOrCreateAudioBuffer(ctx, key);
        if (buffer) {
          const source = ctx.createBufferSource();
          source.buffer = buffer;
          source.connect(this.masterGain ?? ctx.destination);
          this.activeSources.add(source);
          source.onended = () => {
            this.activeSources.delete(source);
          };
          source.start(0);
          return;
        }
      } catch {
        // Fallback to HTMLAudioElement pool below
      }
    }

    // 2. Secondary Fallback: HTMLAudioElement pool
    const pool = this.getOrCreateFallbackPool(key);
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
    this.vibrate(14);
  }
  cardPass() {
    this.vibrate(24);
  }
  invalidMove() {
    this.vibrate([20, 45, 28]);
  }
  botTurnTick() {
    this.vibrate(10);
  }
  yourTurnNotice() {
    this.vibrate([16, 35, 24]);
  }
  dealShuffle() {
    this.vibrate([12, 30, 14, 30, 18]);
  }
  victory() {
    this.vibrate([40, 50, 50, 50, 90]);
  }
  roundEnd() {
    this.vibrate([28, 60, 42]);
  }
  uiTap() {
    this.vibrate(12);
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
