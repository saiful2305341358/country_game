import {
  ALL_COUNTRY_TYPES,
  COUNTRY_METADATA,
  CountryType,
  GameCard,
  GamePlayer,
  GameState,
  getCardDisplayName,
  getPlayerOrdinaryTypeCounts,
  getPlayerWinningType,
  isLegalDiscard,
} from '../models/types';

const WESTERN_FEMALE_NAMES = [
  'Sophia',
  'Eleanor',
  'Charlotte',
  'Amelia',
  'Genevieve',
  'Clara',
  'Victoria',
  'Isla',
];

const WESTERN_MALE_NAMES = [
  'Arthur',
  'Julian',
  'Oliver',
  'Sebastian',
  'Lucas',
  'Felix',
  'Henry',
  'Alexander',
];

function shuffleArray<T>(list: T[]): T[] {
  const arr = [...list];
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

function getCombinations<T>(list: T[], k: number): T[][] {
  const result: T[][] = [];
  function helper(start: number, current: T[]) {
    if (current.length === k) {
      result.push([...current]);
      return;
    }
    for (let i = start; i < list.length; i++) {
      current.push(list[i]);
      helper(i + 1, current);
      current.pop();
    }
  }
  helper(0, []);
  return result;
}

let previousSelection: CountryType[] | null = null;

export function selectActiveTypes(totalPlayers: number, allowRepeat = false): CountryType[] {
  const clamped = Math.max(3, Math.min(6, totalPlayers));
  if (clamped === 6) {
    const shuffled = shuffleArray(ALL_COUNTRY_TYPES);
    previousSelection = [...shuffled];
    return shuffled;
  }

  const allCombinations = getCombinations(ALL_COUNTRY_TYPES, clamped);
  let candidates = allCombinations;

  if (!allowRepeat && previousSelection !== null) {
    const prevSet = new Set(previousSelection);
    const filtered = allCombinations.filter((combo) => {
      if (combo.length !== prevSet.size) return true;
      return !combo.every((item) => prevSet.has(item));
    });
    if (filtered.length > 0) {
      candidates = filtered;
    }
  }

  const chosen = candidates[Math.floor(Math.random() * candidates.length)];
  const shuffled = shuffleArray(chosen);
  previousSelection = [...chosen];
  return shuffled;
}

export interface DeckCreationResult {
  activeTypes: CountryType[];
  ordinaryCardsByType: Map<CountryType, GameCard[]>;
  startingCard: GameCard;
}

export function createDeck(totalPlayers: number, predefinedTypes?: CountryType[]): DeckCreationResult {
  const activeTypes =
    predefinedTypes && predefinedTypes.length === totalPlayers
      ? predefinedTypes
      : selectActiveTypes(totalPlayers);

  const ordinaryCardsByType = new Map<CountryType, GameCard[]>();
  for (const type of activeTypes) {
    const cards: GameCard[] = [];
    for (let i = 0; i < totalPlayers; i++) {
      cards.push({
        id: `card_${type}_${i}`,
        type,
        isStartingCard: false,
      });
    }
    ordinaryCardsByType.set(type, cards);
  }

  const startingCard: GameCard = {
    id: 'starting_card_0',
    type: null,
    isStartingCard: true,
  };

  return {
    activeTypes,
    ordinaryCardsByType,
    startingCard,
  };
}

export function performInitialExchange(
  activeTypes: CountryType[],
  initialDeckByType: Map<CountryType, GameCard[]>
): GamePlayer[] {
  const n = activeTypes.length;
  const initialHands = new Map<number, GameCard[]>();

  for (let i = 0; i < n; i++) {
    const type = activeTypes[i];
    const cards = initialDeckByType.get(type)!;
    initialHands.set(i, [...cards]);
  }

  const outgoing: GameCard[][] = Array.from({ length: n }, () => []);
  for (let sender = 0; sender < n; sender++) {
    const senderCards = initialHands.get(sender)!;
    for (let receiver = 0; receiver < n; receiver++) {
      outgoing[sender][receiver] = senderCards[receiver];
    }
  }

  const shuffledFemale = shuffleArray(WESTERN_FEMALE_NAMES);
  const shuffledMale = shuffleArray(WESTERN_MALE_NAMES);
  const botProfiles: { name: string; isFemale: boolean }[] = [];
  let fIndex = 0;
  let mIndex = 0;

  for (let b = 1; b < n; b++) {
    const giveFemale = b % 2 === 1;
    if (giveFemale) {
      botProfiles.push({
        name: shuffledFemale[fIndex++ % shuffledFemale.length],
        isFemale: true,
      });
    } else {
      botProfiles.push({
        name: shuffledMale[mIndex++ % shuffledMale.length],
        isFemale: false,
      });
    }
  }

  const players: GamePlayer[] = [];
  for (let p = 0; p < n; p++) {
    const newHand: GameCard[] = [];
    for (let sender = 0; sender < n; sender++) {
      newHand.push(outgoing[sender][p]);
    }
    const isHuman = p === 0;
    players.push({
      id: p,
      name: isHuman ? 'You' : botProfiles[p - 1].name,
      isHuman,
      isFemale: isHuman ? false : botProfiles[p - 1].isFemale,
      homeType: activeTypes[p],
      hand: newHand,
    });
  }

  return players;
}

export interface MoveValidationResult {
  isValid: boolean;
  errorMessage?: string;
}

export function validateMove(state: GameState, discardCard: GameCard): MoveValidationResult {
  if (state.winner !== null) {
    return {
      isValid: false,
      errorMessage: 'The game has already concluded. Please start a new game.',
    };
  }
  const currentPlayer = state.players[state.currentTurnPlayerIndex];
  const hasCard = currentPlayer.hand.some((c) => c.id === discardCard.id);
  if (!hasCard) {
    return {
      isValid: false,
      errorMessage: `${getCardDisplayName(discardCard)} is not in ${currentPlayer.name}'s hand.`,
    };
  }
  if (state.isOpeningMove && state.tableCard.isStartingCard) {
    return { isValid: true };
  }
  if (state.tableCard.isStartingCard) {
    return { isValid: true };
  }
  if (discardCard.isStartingCard) {
    return { isValid: true };
  }
  if (discardCard.type === state.tableCard.type) {
    const typeName = state.tableCard.type
      ? COUNTRY_METADATA[state.tableCard.type].displayName
      : 'this country';
    return {
      isValid: false,
      errorMessage: `Same-Type Restriction: You cannot discard a ${typeName} card when a ${typeName} card is on the table.`,
    };
  }
  return { isValid: true };
}

export interface BotDecision {
  discardCard: GameCard;
  thinkDelayMs: number;
  isHesitantChoice: boolean;
}

export function evaluateBotDecision(state: GameState, baseDelayMs = 1650): BotDecision {
  const bot = state.players[state.currentTurnPlayerIndex];
  const hand = bot.hand;
  const winningSetSize = state.totalPlayers;

  const legalCards = hand.filter((card) => isLegalDiscard(state, card));
  if (legalCards.length === 0) {
    throw new Error(`Critical engine state: No legal move found for bot ${bot.name}`);
  }

  const cadenceJitterMs = ((state.turnCount * 37 + bot.id * 53) % 101) - 40;

  if (legalCards.length === 1) {
    const quickDelay = Math.max(420, Math.min(1100, Math.round(baseDelayMs * 0.36 + cadenceJitterMs)));
    return {
      discardCard: legalCards[0],
      thinkDelayMs: quickDelay,
      isHesitantChoice: false,
    };
  }

  const tableCard = state.tableCard;
  const typeCountsInHand = getPlayerOrdinaryTypeCounts(bot);

  let targetType: CountryType | null = null;
  let maxCount = 0;

  for (const [typeKey, countVal] of Object.entries(typeCountsInHand)) {
    const type = typeKey as CountryType;
    let effectiveCount = countVal ?? 0;
    if (!tableCard.isStartingCard && tableCard.type === type) {
      effectiveCount += 1;
    }
    if (effectiveCount > maxCount) {
      maxCount = effectiveCount;
      targetType = type;
    }
  }

  if (!targetType) {
    targetType = bot.homeType;
  }

  const completesWinningSet =
    !tableCard.isStartingCard &&
    tableCard.type !== null &&
    (typeCountsInHand[tableCard.type] ?? 0) >= winningSetSize - 1;

  let bestCandidate: GameCard | null = null;
  let bestScore = -999999.0;
  let secondBestScore = -999999.0;

  for (let i = 0; i < legalCards.length; i++) {
    const candidate = legalCards[i];
    let score = 0.0;

    if (candidate.isStartingCard) {
      score += 95.0;
    } else {
      const cType = candidate.type!;
      const count = typeCountsInHand[cType] ?? 0;

      if (completesWinningSet && cType === tableCard.type) {
        score -= 2000.0;
      } else if (cType === targetType) {
        score -= 500.0 * count;
      } else {
        if (count === 1) {
          score += 120.0;
        } else if (count === 2) {
          score += 20.0;
        } else if (count >= winningSetSize - 1) {
          score -= 400.0;
        } else if (count >= 3) {
          score -= 220.0;
        }
      }

      if (
        state.lastTakenCard !== null &&
        !state.lastTakenCard.isStartingCard &&
        state.lastTakenCard.type === cType
      ) {
        score -= 12.0;
      }

      if (cType === bot.homeType) {
        score -= 5.0;
      }

      score += ((i + state.turnCount) % 3) * 0.5;
    }

    if (score > bestScore) {
      secondBestScore = bestScore;
      bestScore = score;
      bestCandidate = candidate;
    } else if (score > secondBestScore) {
      secondBestScore = score;
    }
  }

  const chosen = bestCandidate ?? legalCards[0];
  const scoreGap = Math.abs(bestScore - secondBestScore);

  const isBreakingPair =
    !chosen.isStartingCard &&
    chosen.type !== null &&
    (typeCountsInHand[chosen.type] ?? 0) >= 2;
  const isCloseCall = scoreGap < 18.0 || isBreakingPair;

  let complexityFactor = 0.48;
  if (completesWinningSet || chosen.isStartingCard) {
    complexityFactor = 0.4;
  } else if (isCloseCall) {
    complexityFactor = 0.58;
  }

  const thinkDelayMs = Math.max(
    480,
    Math.min(1450, Math.round(baseDelayMs * complexityFactor + cadenceJitterMs))
  );

  return {
    discardCard: chosen,
    thinkDelayMs,
    isHesitantChoice: isCloseCall,
  };
}

export function createInitialGameState(
  totalPlayers: number,
  predefinedTypes?: CountryType[]
): GameState {
  const n = Math.max(3, Math.min(6, totalPlayers));
  const deckResult = createDeck(n, predefinedTypes);
  const players = performInitialExchange(deckResult.activeTypes, deckResult.ordinaryCardsByType);
  const startingIndex = Math.floor(Math.random() * n);
  const startingPlayer = players[startingIndex];

  const initialStatus = startingPlayer.isHuman
    ? 'Opening move: Choose a card from your hand to trade for Global.'
    : `${startingPlayer.name} takes the opening turn with Global.`;

  return {
    totalPlayers: n,
    activeTypes: deckResult.activeTypes,
    players,
    tableCard: deckResult.startingCard,
    startingPlayerIndex: startingIndex,
    currentTurnPlayerIndex: startingIndex,
    turnCount: 0,
    isOpeningMove: true,
    winner: null,
    winningType: null,
    statusMessage: initialStatus,
    moveLog: [
      `Game initialized with ${n} players (Winning Set: ${n} cards).`,
      startingPlayer.isHuman
        ? 'You were selected to open with Global.'
        : `${startingPlayer.name} selected to open with Global.`,
    ],
    lastMovePlayerIndex: null,
    lastMoveHandIndex: null,
    lastTakenCard: null,
    lastDiscardedCard: null,
  };
}

export function executeGameMove(
  state: GameState,
  discardCard: GameCard
): { nextState: GameState; isValid: boolean } {
  const validation = validateMove(state, discardCard);
  if (!validation.isValid) {
    return {
      nextState: {
        ...state,
        statusMessage: validation.errorMessage ?? 'Invalid move',
      },
      isValid: false,
    };
  }

  const activePlayerIndex = state.currentTurnPlayerIndex;
  const activePlayer = state.players[activePlayerIndex];
  const oldTableCard = state.tableCard;

  const updatedHand = [...activePlayer.hand];
  const replacedIndex = updatedHand.findIndex((c) => c.id === discardCard.id);
  if (replacedIndex === -1) {
    return { nextState: state, isValid: false };
  }
  updatedHand[replacedIndex] = oldTableCard;

  const updatedPlayer: GamePlayer = {
    ...activePlayer,
    hand: updatedHand,
  };

  const updatedPlayers = [...state.players];
  updatedPlayers[activePlayerIndex] = updatedPlayer;

  const winningType = getPlayerWinningType(updatedPlayer, state.totalPlayers);
  const hasWon = winningType !== null;

  const logEntry = state.isOpeningMove
    ? `${activePlayer.name} took Global and placed ${getCardDisplayName(discardCard)} on the table.`
    : `${activePlayer.name} traded ${getCardDisplayName(discardCard)} for ${getCardDisplayName(oldTableCard)}.`;

  const prevLogs = state.moveLog;
  const newMoveLog =
    prevLogs.length >= 24 ? [...prevLogs.slice(prevLogs.length - 23), logEntry] : [...prevLogs, logEntry];

  if (hasWon && winningType) {
    const winName = COUNTRY_METADATA[winningType].displayName;
    return {
      isValid: true,
      nextState: {
        ...state,
        players: updatedPlayers,
        tableCard: discardCard,
        turnCount: state.turnCount + 1,
        isOpeningMove: false,
        winner: updatedPlayer,
        winningType,
        statusMessage: updatedPlayer.isHuman
          ? `🏆 You collected all ${state.totalPlayers} ${winName} cards and won the game!`
          : `🏆 ${updatedPlayer.name} collected all ${state.totalPlayers} ${winName} cards and won the game!`,
        moveLog: newMoveLog,
        lastMovePlayerIndex: activePlayerIndex,
        lastMoveHandIndex: replacedIndex,
        lastTakenCard: oldTableCard,
        lastDiscardedCard: discardCard,
      },
    };
  }

  const nextTurnIndex = (state.currentTurnPlayerIndex + 1) % state.totalPlayers;
  const nextPlayer = updatedPlayers[nextTurnIndex];
  const nextStatus = nextPlayer.isHuman
    ? `${activePlayer.name} placed ${getCardDisplayName(discardCard)}. Select a card to trade.`
    : `${activePlayer.name} placed ${getCardDisplayName(discardCard)} • ${nextPlayer.name}'s turn`;

  return {
    isValid: true,
    nextState: {
      ...state,
      players: updatedPlayers,
      tableCard: discardCard,
      currentTurnPlayerIndex: nextTurnIndex,
      turnCount: state.turnCount + 1,
      isOpeningMove: false,
      statusMessage: nextStatus,
      moveLog: newMoveLog,
      lastMovePlayerIndex: activePlayerIndex,
      lastMoveHandIndex: replacedIndex,
      lastTakenCard: oldTableCard,
      lastDiscardedCard: discardCard,
    },
  };
}
