import { ALL_COUNTRY_TYPES, CountryType, GamePlayer } from '../models/types';

export interface PlayerStatsRecord {
  name: string;
  isHuman: boolean;
  avatarIndex: number;
  gamesPlayed: number;
  setsCompleted: number;
  totalPoints: number;
  lastRoundPoints: number;
  lastCompletedCountry?: CountryType;
}

const STORAGE_KEY = 'country_game_player_stats_v1';
const TUTORIAL_STORAGE_KEY = 'country_game_tutorial_seen_v1';

export function computeRoundPoints(totalPlayers: number, turnCount: number): {
  setBonus: number;
  speedBonus: number;
  roundPoints: number;
} {
  const setBonus = Math.max(3, totalPlayers) * 100;
  const speedBonus = Math.max(50, 250 - Math.max(0, turnCount) * 10);
  return {
    setBonus,
    speedBonus,
    roundPoints: setBonus + speedBonus,
  };
}

class StatsServiceImpl {
  private _totalGamesPlayed = 0;
  private _playerRecords: Map<string, PlayerStatsRecord> = new Map();
  private _listeners: Set<() => void> = new Set();

  constructor() {
    this.loadFromStorage();
  }

  subscribe(listener: () => void): () => void {
    this._listeners.add(listener);
    return () => {
      this._listeners.delete(listener);
    };
  }

  private notify() {
    for (const listener of this._listeners) {
      listener();
    }
  }

  get totalGamesPlayed(): number {
    return this._totalGamesPlayed;
  }

  get totalSetsCompleted(): number {
    let sum = 0;
    for (const r of this._playerRecords.values()) {
      sum += r.setsCompleted;
    }
    return sum;
  }

  getRecordForPlayer(player: GamePlayer): PlayerStatsRecord {
    return (
      this._playerRecords.get(player.name) ?? {
        name: player.name,
        isHuman: player.isHuman,
        avatarIndex: player.id,
        gamesPlayed: 0,
        setsCompleted: 0,
        totalPoints: 0,
        lastRoundPoints: 0,
      }
    );
  }

  getAllRecords(activePlayers?: GamePlayer[]): PlayerStatsRecord[] {
    if (activePlayers && activePlayers.length > 0) {
      return activePlayers.map((p) => this.getRecordForPlayer(p));
    }
    const list = Array.from(this._playerRecords.values());
    if (!list.some((r) => r.isHuman)) {
      list.unshift({
        name: 'You',
        isHuman: true,
        avatarIndex: 0,
        gamesPlayed: 0,
        setsCompleted: 0,
        totalPoints: 0,
        lastRoundPoints: 0,
      });
    }
    list.sort((a, b) => {
      if (a.isHuman !== b.isHuman) return a.isHuman ? -1 : 1;
      const byPoints = b.totalPoints - a.totalPoints;
      if (byPoints !== 0) return byPoints;
      const bySets = b.setsCompleted - a.setsCompleted;
      if (bySets !== 0) return bySets;
      return b.gamesPlayed - a.gamesPlayed;
    });
    return list;
  }

  recordGameStarted(players: GamePlayer[]) {
    this._totalGamesPlayed++;
    for (const p of players) {
      const existing = this.getRecordForPlayer(p);
      this._playerRecords.set(p.name, {
        ...existing,
        isHuman: p.isHuman,
        avatarIndex: p.id,
        gamesPlayed: existing.gamesPlayed + 1,
      });
    }
    this.saveToStorage();
    this.notify();
  }

  recordSetCompleted(
    player: GamePlayer,
    type: CountryType,
    totalPlayers = 4,
    turnCount = 1
  ): PlayerStatsRecord {
    const existing = this.getRecordForPlayer(player);
    const { roundPoints } = computeRoundPoints(totalPlayers, turnCount);
    const updated: PlayerStatsRecord = {
      ...existing,
      isHuman: player.isHuman,
      avatarIndex: player.id,
      setsCompleted: existing.setsCompleted + 1,
      totalPoints: existing.totalPoints + roundPoints,
      lastRoundPoints: roundPoints,
      lastCompletedCountry: type,
    };
    this._playerRecords.set(player.name, updated);
    this.saveToStorage();
    this.notify();
    return updated;
  }

  resetStats(currentPlayers?: GamePlayer[]) {
    this._totalGamesPlayed = 0;
    this._playerRecords.clear();
    if (currentPlayers) {
      for (const p of currentPlayers) {
        this._playerRecords.set(p.name, {
          name: p.name,
          isHuman: p.isHuman,
          avatarIndex: p.id,
          gamesPlayed: 0,
          setsCompleted: 0,
          totalPoints: 0,
          lastRoundPoints: 0,
        });
      }
    }
    try {
      window.localStorage.removeItem(STORAGE_KEY);
    } catch {
      // ignore
    }
    this.notify();
  }

  private loadFromStorage() {
    try {
      const raw = window.localStorage.getItem(STORAGE_KEY);
      if (!raw) return;
      const decoded = JSON.parse(raw);
      this._totalGamesPlayed =
        typeof decoded.totalGamesPlayed === 'number' ? decoded.totalGamesPlayed : 0;
      if (decoded.players && typeof decoded.players === 'object') {
        this._playerRecords.clear();
        for (const [key, val] of Object.entries(decoded.players)) {
          if (val && typeof val === 'object') {
            const v = val as Record<string, unknown>;
            const rawType =
              typeof v.lastCompletedCountry === 'string' ? v.lastCompletedCountry : undefined;
            const parsedType = ALL_COUNTRY_TYPES.find((t) => t === rawType);
            const setsCompleted = typeof v.setsCompleted === 'number' ? v.setsCompleted : 0;
            const totalPoints =
              typeof v.totalPoints === 'number' ? v.totalPoints : setsCompleted * 500;
            const lastRoundPoints =
              typeof v.lastRoundPoints === 'number' ? v.lastRoundPoints : 0;
            this._playerRecords.set(key, {
              name: typeof v.name === 'string' ? v.name : 'Player',
              isHuman: Boolean(v.isHuman),
              avatarIndex: typeof v.avatarIndex === 'number' ? v.avatarIndex : 0,
              gamesPlayed: typeof v.gamesPlayed === 'number' ? v.gamesPlayed : 0,
              setsCompleted,
              totalPoints,
              lastRoundPoints,
              lastCompletedCountry: parsedType,
            });
          }
        }
      }
    } catch {
      // ignore
    }
  }

  private saveToStorage() {
    try {
      const playersObj: Record<string, unknown> = {};
      for (const [k, v] of this._playerRecords.entries()) {
        playersObj[k] = v;
      }
      window.localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          totalGamesPlayed: this._totalGamesPlayed,
          players: playersObj,
        })
      );
    } catch {
      // ignore
    }
  }

  hasSeenTutorial(): boolean {
    try {
      return window.localStorage.getItem(TUTORIAL_STORAGE_KEY) === 'true';
    } catch {
      return false;
    }
  }

  markTutorialSeen() {
    try {
      window.localStorage.setItem(TUTORIAL_STORAGE_KEY, 'true');
    } catch {
      // ignore
    }
  }
}

export const StatsService = new StatsServiceImpl();
