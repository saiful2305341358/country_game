export enum CountryType {
  australia = 'australia',
  greatBritain = 'greatBritain',
  saudiArabia = 'saudiArabia',
  iran = 'iran',
  japan = 'japan',
  bangladesh = 'bangladesh',
}

export interface CountryMetadata {
  id: CountryType;
  displayName: string;
  nativeName: string;
  shortCode: string;
  primaryColor: string;
  secondaryColor: string;
  accentColor: string;
}

export const COUNTRY_METADATA: Record<CountryType, CountryMetadata> = {
  [CountryType.australia]: {
    id: CountryType.australia,
    displayName: 'Australia',
    nativeName: 'Australia',
    shortCode: 'AUS',
    primaryColor: '#D97706',
    secondaryColor: '#78350F',
    accentColor: '#FDE68A',
  },
  [CountryType.greatBritain]: {
    id: CountryType.greatBritain,
    displayName: 'Great Britain',
    nativeName: 'United Kingdom',
    shortCode: 'GBR',
    primaryColor: '#2563EB',
    secondaryColor: '#1E1B4B',
    accentColor: '#93C5FD',
  },
  [CountryType.saudiArabia]: {
    id: CountryType.saudiArabia,
    displayName: 'Saudi Arabia',
    nativeName: 'السعودية',
    shortCode: 'SAU',
    primaryColor: '#059669',
    secondaryColor: '#064E3B',
    accentColor: '#6EE7B7',
  },
  [CountryType.iran]: {
    id: CountryType.iran,
    displayName: 'Iran',
    nativeName: 'ایران',
    shortCode: 'IRN',
    primaryColor: '#0891B2',
    secondaryColor: '#164E63',
    accentColor: '#67E8F9',
  },
  [CountryType.japan]: {
    id: CountryType.japan,
    displayName: 'Japan',
    nativeName: '日本 • Nippon',
    shortCode: 'JPN',
    primaryColor: '#E11D48',
    secondaryColor: '#881337',
    accentColor: '#FDA4AF',
  },
  [CountryType.bangladesh]: {
    id: CountryType.bangladesh,
    displayName: 'Bangladesh',
    nativeName: 'বাংলাদেশ',
    shortCode: 'BGD',
    primaryColor: '#7C3AED',
    secondaryColor: '#3B0764',
    accentColor: '#DDD6FE',
  },
};

export const ALL_COUNTRY_TYPES: CountryType[] = [
  CountryType.australia,
  CountryType.greatBritain,
  CountryType.saudiArabia,
  CountryType.iran,
  CountryType.japan,
  CountryType.bangladesh,
];

export interface GameCard {
  id: string;
  type: CountryType | null;
  isStartingCard: boolean;
}

export function getCardDisplayName(card: GameCard): string {
  if (card.isStartingCard) return 'Global';
  return card.type ? COUNTRY_METADATA[card.type].displayName : 'Unknown';
}

export function getCardNativeName(card: GameCard): string {
  if (card.isStartingCard) return 'Global';
  return card.type ? COUNTRY_METADATA[card.type].nativeName : '';
}

export interface GamePlayer {
  id: number;
  name: string;
  isHuman: boolean;
  isFemale: boolean;
  homeType: CountryType;
  hand: GameCard[];
}

export function getPlayerOrdinaryTypeCounts(player: GamePlayer): Partial<Record<CountryType, number>> {
  const counts: Partial<Record<CountryType, number>> = {};
  for (const card of player.hand) {
    if (!card.isStartingCard && card.type !== null) {
      counts[card.type] = (counts[card.type] ?? 0) + 1;
    }
  }
  return counts;
}

export function getPlayerWinningType(player: GamePlayer, requiredSetSize?: number): CountryType | null {
  const target = requiredSetSize && requiredSetSize > 0
    ? requiredSetSize
    : (player.hand.length > 0 ? player.hand.length : 4);
  const counts = getPlayerOrdinaryTypeCounts(player);
  for (const type of ALL_COUNTRY_TYPES) {
    if ((counts[type] ?? 0) >= target) {
      return type;
    }
  }
  return null;
}

export interface GameSettings {
  soundEnabled: boolean;
  hapticsEnabled: boolean;
  animationsEnabled: boolean;
  botDelayMs: number;
  themeName: string;
  totalPlayers: number;
}

export const DEFAULT_GAME_SETTINGS: GameSettings = {
  soundEnabled: true,
  hapticsEnabled: true,
  animationsEnabled: true,
  botDelayMs: 1650,
  themeName: 'emerald',
  totalPlayers: 4,
};

export interface GameState {
  totalPlayers: number;
  activeTypes: CountryType[];
  players: GamePlayer[];
  tableCard: GameCard;
  startingPlayerIndex: number;
  currentTurnPlayerIndex: number;
  turnCount: number;
  isOpeningMove: boolean;
  winner: GamePlayer | null;
  winningType: CountryType | null;
  statusMessage: string;
  moveLog: string[];
  lastMovePlayerIndex: number | null;
  lastMoveHandIndex: number | null;
  lastTakenCard: GameCard | null;
  lastDiscardedCard: GameCard | null;
}

export function isLegalDiscard(state: GameState, candidate: GameCard): boolean {
  if (state.winner !== null) return false;
  const currentPlayer = state.players[state.currentTurnPlayerIndex];
  if (!currentPlayer.hand.some((c) => c.id === candidate.id)) return false;

  if (state.isOpeningMove && state.tableCard.isStartingCard) {
    return true;
  }
  if (state.tableCard.isStartingCard) {
    return true;
  }
  if (candidate.isStartingCard) {
    return true;
  }
  return candidate.type !== state.tableCard.type;
}
