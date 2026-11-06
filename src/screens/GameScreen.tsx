import React, { useCallback, useEffect, useRef, useState } from 'react';
import { CardBackView, CountryCardView } from '../components/CountryCardView';
import {
  CelebrationParticlesCanvas,
  ExitConfirmationDialog,
  GameControlsDialog,
  PlayedCardsHistoryOverlay,
  PlayerStatsOverlay,
  TutorialModalOverlay,
  VictoryOverlay,
} from '../components/Overlays';
import { PlayerSeat } from '../components/PlayerSeat';
import {
  createInitialGameState,
  evaluateBotDecision,
  executeGameMove,
} from '../game/gameLogic';
import {
  CountryType,
  GameCard,
  GameSettings,
  GameState,
  getCardDisplayName,
  isLegalDiscard,
} from '../models/types';
import { AudioService, HapticService } from '../services/soundSynthesizer';
import { StatsService } from '../services/statsService';

interface GameScreenProps {
  totalPlayers: number;
  predefinedTypes?: CountryType[];
  settings: GameSettings;
  onUpdateSettings: (newSettings: GameSettings) => void;
  onNavigateBack: () => void;
  onExitToMainMenu: () => void;
}

const STAGE_WIDTH = 1920;
const STAGE_HEIGHT = 1080;
const CARD_WIDTH = 128;
const CARD_HEIGHT = 188;
const LEFT_TABLE_SLOT = { x: 819, y: 453 };
const RIGHT_TABLE_SLOT = { x: 981, y: 453 };
const DECK_PILE_CENTER = { x: 981 + 64, y: 453 + 94 };
const HAND_CONTAINER_WIDTH = 1100;
const HAND_CONTAINER_HEIGHT = 250;
const HAND_CONTAINER_LEFT = (STAGE_WIDTH - HAND_CONTAINER_WIDTH) / 2;
const HAND_CONTAINER_TOP = STAGE_HEIGHT - HAND_CONTAINER_HEIGHT;
const HUMAN_HAND_CENTER = { x: 960, y: 960 };

const TWO_OPPONENT_SLOTS = [
  { x: 450, y: 380 },
  { x: 1470, y: 380 },
];

const THREE_OPPONENT_SLOTS = [
  { x: 380, y: 540 },
  { x: 960, y: 110 },
  { x: 1540, y: 540 },
];

const FIVE_OPPONENT_SLOTS = [
  { x: 401, y: 762 },
  { x: 548, y: 313 },
  { x: 960, y: 88 },
  { x: 1372, y: 313 },
  { x: 1519, y: 762 },
];

// Dedicated 6-opponent seat layout exclusively for 7-Player Mode (1 Human + 6 Bots)
// Arranged in a symmetric 6-seat elliptical arc around the center table cards
// with generous clearance from the top status bar, corner buttons, and 7-card human hand.
const SIX_OPPONENT_SLOTS = [
  { x: 340, y: 760 }, // Bot 1: Lower-Left
  { x: 430, y: 430 }, // Bot 2: Mid-Upper-Left
  { x: 730, y: 155 }, // Bot 3: Top-Left
  { x: 1190, y: 155 }, // Bot 4: Top-Right
  { x: 1490, y: 430 }, // Bot 5: Mid-Upper-Right
  { x: 1580, y: 760 }, // Bot 6: Lower-Right
];

function getOpponentSeat(opponentIdx: number, totalPlayers: number): { x: number; y: number } {
  if (totalPlayers === 3) {
    return TWO_OPPONENT_SLOTS[opponentIdx % TWO_OPPONENT_SLOTS.length];
  }
  if (totalPlayers === 4) {
    return THREE_OPPONENT_SLOTS[opponentIdx % THREE_OPPONENT_SLOTS.length];
  }
  if (totalPlayers === 5) {
    const indices = [0, 1, 3, 4];
    return FIVE_OPPONENT_SLOTS[indices[opponentIdx % indices.length]];
  }
  if (totalPlayers === 7) {
    return SIX_OPPONENT_SLOTS[opponentIdx % SIX_OPPONENT_SLOTS.length];
  }
  return FIVE_OPPONENT_SLOTS[opponentIdx % FIVE_OPPONENT_SLOTS.length];
}

function getHumanCardStageTopLeft(cardIndex: number, handCount: number): { x: number; y: number } {
  const mid = (handCount - 1) / 2;
  const step = CARD_WIDTH - 2;
  const offsetA = (cardIndex - mid) * step;
  const cardLeft = (HAND_CONTAINER_WIDTH - CARD_WIDTH) / 2 + offsetA;
  const cardTop = 36;
  return {
    x: HAND_CONTAINER_LEFT + cardLeft,
    y: HAND_CONTAINER_TOP + cardTop,
  };
}

function getExchangePlayerCardTopLeft(
  playerIndex: number,
  handIndex: number,
  totalPlayers: number,
  handCount: number
): { x: number; y: number } {
  if (playerIndex === 0) {
    return getHumanCardStageTopLeft(handIndex, handCount);
  }
  const seat = getOpponentSeat(playerIndex - 1, totalPlayers);
  return {
    x: seat.x - CARD_WIDTH / 2,
    y: seat.y - CARD_HEIGHT / 2,
  };
}

function getNormalizedSeatOrigin(playerIndex: number, totalPlayers: number): { x: number; y: number } {
  if (playerIndex === 0) {
    return { x: 0.5, y: 0.76 };
  }
  const seat = getOpponentSeat(playerIndex - 1, totalPlayers);
  return {
    x: seat.x / STAGE_WIDTH,
    y: seat.y / STAGE_HEIGHT,
  };
}

function cubicEase(t: number): number {
  const c = Math.max(0, Math.min(1, t));
  return 1 - Math.pow(1 - c, 3);
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

export const GameScreen: React.FC<GameScreenProps> = ({
  totalPlayers,
  predefinedTypes,
  settings,
  onUpdateSettings,
  onNavigateBack,
  onExitToMainMenu,
}) => {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [stageScale, setStageScale] = useState(0.5);
  const [state, setState] = useState<GameState>(() =>
    createInitialGameState(totalPlayers, predefinedTypes)
  );

  const [isAnimatingExchange, setIsAnimatingExchange] = useState(false);
  const [exchangeProgress, setExchangeProgress] = useState(0);
  const [animatingPlayerIndex, setAnimatingPlayerIndex] = useState<number | null>(null);
  const [animatingHandIndex, setAnimatingHandIndex] = useState<number | null>(null);
  const [animatingDiscardedCard, setAnimatingDiscardedCard] = useState<GameCard | null>(null);
  const [animatingTakenCard, setAnimatingTakenCard] = useState<GameCard | null>(null);
  const [lockedPlayerCardPos, setLockedPlayerCardPos] = useState({ x: 0, y: 0 });
  const [lockedOldTableSlotPos, setLockedOldTableSlotPos] = useState(LEFT_TABLE_SLOT);
  const [lockedIncomingTableSlotPos, setLockedIncomingTableSlotPos] = useState(RIGHT_TABLE_SLOT);
  const [showExitConfirmDialog, setShowExitConfirmDialog] = useState(false);
  const [showPauseDialog, setShowPauseDialog] = useState(false);
  const [showHistoryOverlay, setShowHistoryOverlay] = useState(false);
  const [showStatsOverlay, setShowStatsOverlay] = useState(false);
  const [showTutorialOverlay, setShowTutorialOverlay] = useState<boolean>(
    () => !StatsService.hasSeenTutorial()
  );
  // If the first-time tutorial is open on mount, have cards already dealt on the table
  // so that closing the tutorial resumes gameplay with zero dealing delay
  const [isDealing, setIsDealing] = useState<boolean>(
    () => settings.animationsEnabled && StatsService.hasSeenTutorial()
  );
  const [dealingProgress, setDealingProgress] = useState<number>(() =>
    StatsService.hasSeenTutorial() ? 0 : 1
  );
  const [isDocumentHidden, setIsDocumentHidden] = useState<boolean>(
    () => typeof document !== 'undefined' && document.hidden
  );
  const [celebrationOrigin, setCelebrationOrigin] = useState<{ x: number; y: number }>({
    x: 0.5,
    y: 0.52,
  });

  const recordedWinRef = useRef(false);
  const isProcessingMoveRef = useRef(false);
  const dealingProgressRef = useRef(StatsService.hasSeenTutorial() ? 0 : 1);
  const playedDealSoundRef = useRef(false);
  const exchangeProgressRef = useRef(0);
  const playedExchangeLandingRef = useRef(false);
  const playedExchangeOutgoingRef = useRef(false);
  const isGamePausedRef = useRef(false);
  const immediateResumeFromTutorialRef = useRef(false);
  const matchStartTimeRef = useRef<number>(performance.now());
  const pausedAccumulatedMsRef = useRef<number>(0);
  const pauseStartedAtRef = useRef<number | null>(null);
  const botTurnTimerStateRef = useRef<{
    turnCount: number;
    remainingMs: number;
    startedAt: number;
    chosenCard: GameCard | null;
  }>({
    turnCount: -1,
    remainingMs: 0,
    startedAt: 0,
    chosenCard: null,
  });

  const isGamePaused =
    isDocumentHidden ||
    showTutorialOverlay ||
    showPauseDialog ||
    showExitConfirmDialog ||
    showHistoryOverlay ||
    showStatsOverlay;

  isGamePausedRef.current = isGamePaused;

  useEffect(() => {
    if (isGamePaused) {
      if (pauseStartedAtRef.current === null) {
        pauseStartedAtRef.current = performance.now();
      }
    } else if (pauseStartedAtRef.current !== null) {
      pausedAccumulatedMsRef.current += Math.max(0, performance.now() - pauseStartedAtRef.current);
      pauseStartedAtRef.current = null;
    }
  }, [isGamePaused]);

  // Measure viewport to scale 1920x1080 stage cleanly on all mobile orientations
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const updateScale = () => {
      const w = el.clientWidth;
      const h = el.clientHeight;
      if (w > 0 && h > 0) {
        const scale = Math.min(w / STAGE_WIDTH, h / STAGE_HEIGHT);
        setStageScale(Math.max(0.15, scale));
      }
    };
    updateScale();
    let ro: ResizeObserver | null = null;
    if (typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(updateScale);
      ro.observe(el);
    }
    window.addEventListener('resize', updateScale);
    window.visualViewport?.addEventListener('resize', updateScale);
    return () => {
      ro?.disconnect();
      window.removeEventListener('resize', updateScale);
      window.visualViewport?.removeEventListener('resize', updateScale);
    };
  }, []);

  // Pause bot progression on screen sleep / backgrounding and intercept Android hardware Back
  useEffect(() => {
    const onVisibilityChange = () => {
      setIsDocumentHidden(document.hidden);
    };
    const onHardwareBack = () => {
      if (showHistoryOverlay) {
        setShowHistoryOverlay(false);
      } else if (showStatsOverlay) {
        setShowStatsOverlay(false);
      } else if (showTutorialOverlay) {
        StatsService.markTutorialSeen();
        immediateResumeFromTutorialRef.current = true;
        isGamePausedRef.current = false;
        if (isDealing && dealingProgressRef.current <= 0) {
          dealingProgressRef.current = 1;
          setDealingProgress(1);
          setIsDealing(false);
        }
        setShowTutorialOverlay(false);
      } else if (showPauseDialog) {
        setShowPauseDialog(false);
      } else if (!showExitConfirmDialog) {
        AudioService.playButtonClick();
        HapticService.uiTap();
        setShowExitConfirmDialog(true);
      }
    };
    document.addEventListener('visibilitychange', onVisibilityChange);
    window.addEventListener('ccg-hardware-back', onHardwareBack);
    return () => {
      document.removeEventListener('visibilitychange', onVisibilityChange);
      window.removeEventListener('ccg-hardware-back', onHardwareBack);
    };
  }, [
    showHistoryOverlay,
    showStatsOverlay,
    showTutorialOverlay,
    showPauseDialog,
    showExitConfirmDialog,
  ]);

  // Record initial game started
  useEffect(() => {
    StatsService.recordGameStarted(state.players);
    if (!settings.animationsEnabled && !showTutorialOverlay) {
      playedDealSoundRef.current = true;
      AudioService.playGameStart();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Dealing animation loop (pauses cleanly while Tutorial or any modal is open and resumes from exact progress)
  useEffect(() => {
    if (isGamePaused) return;
    if (!isDealing) {
      if (!playedDealSoundRef.current) {
        playedDealSoundRef.current = true;
        AudioService.playGameStart();
      }
      return;
    }

    if (!playedDealSoundRef.current) {
      playedDealSoundRef.current = true;
      AudioService.playExchange();
    }

    let animId = 0;
    const duration = 1350;
    const start = performance.now() - dealingProgressRef.current * duration;

    const tick = (now: number) => {
      const p = Math.min(1, Math.max(0, (now - start) / duration));
      dealingProgressRef.current = p;
      setDealingProgress(p);
      if (p >= 1) {
        setIsDealing(false);
      } else {
        animId = requestAnimationFrame(tick);
      }
    };
    animId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(animId);
  }, [isDealing, isGamePaused]);

  // Exchange animation loop (pauses cleanly while Tutorial or any modal is open and resumes from exact progress)
  useEffect(() => {
    if (!isAnimatingExchange || isGamePaused) return;
    let animId = 0;
    const duration = 1020;
    const start = performance.now() - exchangeProgressRef.current * duration;

    const tick = (now: number) => {
      const p = Math.min(1, Math.max(0, (now - start) / duration));
      exchangeProgressRef.current = p;
      setExchangeProgress(p);

      if (!playedExchangeLandingRef.current && p >= 0.44) {
        playedExchangeLandingRef.current = true;
        AudioService.playCardPlace();
      }
      if (!playedExchangeOutgoingRef.current && p >= 0.56) {
        playedExchangeOutgoingRef.current = true;
        AudioService.playCardTake();
      }

      if (p >= 1) {
        isProcessingMoveRef.current = false;
        exchangeProgressRef.current = 0;
        playedExchangeLandingRef.current = false;
        playedExchangeOutgoingRef.current = false;
        setIsAnimatingExchange(false);
        setAnimatingPlayerIndex(null);
        setAnimatingHandIndex(null);
        setAnimatingDiscardedCard(null);
        setAnimatingTakenCard(null);
      } else {
        animId = requestAnimationFrame(tick);
      }
    };
    animId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(animId);
  }, [isAnimatingExchange, isGamePaused]);

  // Post-exchange victory / turn cues
  useEffect(() => {
    if (isAnimatingExchange || isDealing) return;
    if (state.winner && state.winningType) {
      if (!recordedWinRef.current) {
        recordedWinRef.current = true;
        const activeElapsedMs = Math.max(
          5000,
          performance.now() - matchStartTimeRef.current - pausedAccumulatedMsRef.current
        );
        const durationSeconds = Math.round(activeElapsedMs / 1000);
        StatsService.recordSetCompleted(
          state.winner,
          state.winningType,
          state.totalPlayers,
          state.turnCount,
          durationSeconds
        );
        setCelebrationOrigin(getNormalizedSeatOrigin(state.winner.id, state.totalPlayers));
        if (state.winner.isHuman) {
          AudioService.playVictory();
          HapticService.victory();
        } else {
          AudioService.playGameEnd();
          HapticService.roundEnd();
        }
      }
    }
  }, [isAnimatingExchange, isDealing, state]);

  const performMove = useCallback(
    (card: GameCard) => {
      if (
        isProcessingMoveRef.current ||
        isDealing ||
        isAnimatingExchange ||
        isGamePausedRef.current
      ) {
        return false;
      }
      const { nextState, isValid } = executeGameMove(state, card);
      if (!isValid) {
        setState(nextState);
        return false;
      }

      isProcessingMoveRef.current = true;

      const wasBot = state.currentTurnPlayerIndex !== 0;
      if (wasBot) {
        AudioService.playCardTap();
      }

      if (
        settings.animationsEnabled &&
        nextState.lastMovePlayerIndex !== null &&
        nextState.lastDiscardedCard &&
        nextState.lastTakenCard
      ) {
        const oldSlot = (nextState.turnCount - 1) % 2;
        const incomingSlot = nextState.turnCount % 2;
        const pIdx = nextState.lastMovePlayerIndex;
        const hIdx = nextState.lastMoveHandIndex ?? 0;

        exchangeProgressRef.current = 0;
        playedExchangeLandingRef.current = false;
        playedExchangeOutgoingRef.current = false;
        setAnimatingPlayerIndex(pIdx);
        setAnimatingHandIndex(hIdx);
        setAnimatingDiscardedCard(nextState.lastDiscardedCard);
        setAnimatingTakenCard(nextState.lastTakenCard);
        setLockedPlayerCardPos(
          getExchangePlayerCardTopLeft(
            pIdx,
            hIdx,
            nextState.totalPlayers,
            nextState.players[0].hand.length
          )
        );
        setLockedOldTableSlotPos(oldSlot === 0 ? LEFT_TABLE_SLOT : RIGHT_TABLE_SLOT);
        setLockedIncomingTableSlotPos(incomingSlot === 0 ? LEFT_TABLE_SLOT : RIGHT_TABLE_SLOT);
        setExchangeProgress(0);
        setIsAnimatingExchange(true);
      } else {
        isProcessingMoveRef.current = false;
        AudioService.playCardPlace();
      }

      setState(nextState);
      return true;
    },
    [isDealing, isAnimatingExchange, isGamePaused, settings.animationsEnabled, state]
  );

  // Bot turn scheduler (tracks elapsed/remaining time across tutorial/modal pauses and resumes immediately)
  useEffect(() => {
    if (
      isDealing ||
      isAnimatingExchange ||
      isGamePaused ||
      state.winner !== null ||
      state.players[state.currentTurnPlayerIndex].isHuman
    ) {
      return;
    }

    const timerState = botTurnTimerStateRef.current;
    let delayMs = 650;
    let chosenCard: GameCard | null = null;

    if (timerState.turnCount === state.turnCount && timerState.chosenCard) {
      // Resuming a bot turn that was paused while the tutorial or another overlay was open
      chosenCard = timerState.chosenCard;
      delayMs = immediateResumeFromTutorialRef.current
        ? Math.min(timerState.remainingMs, 40)
        : Math.max(16, timerState.remainingMs);
    } else {
      try {
        const decision = evaluateBotDecision(state, settings.botDelayMs);
        chosenCard = decision.discardCard;
        delayMs = settings.animationsEnabled ? decision.thinkDelayMs : 120;
        if (immediateResumeFromTutorialRef.current) {
          delayMs = Math.min(delayMs, 60);
        }
      } catch {
        // fallback
      }
      timerState.turnCount = state.turnCount;
      timerState.chosenCard = chosenCard;
      timerState.remainingMs = delayMs;
    }

    immediateResumeFromTutorialRef.current = false;
    timerState.startedAt = performance.now();

    const timer = window.setTimeout(() => {
      timerState.turnCount = -1;
      timerState.remainingMs = 0;
      if (chosenCard) {
        performMove(chosenCard);
      }
    }, delayMs);

    return () => {
      clearTimeout(timer);
      if (timerState.turnCount === state.turnCount && timerState.startedAt > 0) {
        const elapsed = performance.now() - timerState.startedAt;
        timerState.remainingMs = Math.max(0, timerState.remainingMs - elapsed);
      }
    };
  }, [
    isDealing,
    isAnimatingExchange,
    isGamePaused,
    state,
    settings.botDelayMs,
    settings.animationsEnabled,
    performMove,
  ]);

  const handleCloseTutorialOverlay = useCallback(() => {
    StatsService.markTutorialSeen();
    immediateResumeFromTutorialRef.current = true;
    isGamePausedRef.current = false;
    if (isDealing && dealingProgressRef.current <= 0) {
      dealingProgressRef.current = 1;
      setDealingProgress(1);
      setIsDealing(false);
    }
    setShowTutorialOverlay(false);
  }, [isDealing]);

  const handleRestartMatch = () => {
    recordedWinRef.current = false;
    isProcessingMoveRef.current = false;
    dealingProgressRef.current = 0;
    playedDealSoundRef.current = false;
    exchangeProgressRef.current = 0;
    playedExchangeLandingRef.current = false;
    playedExchangeOutgoingRef.current = false;
    matchStartTimeRef.current = performance.now();
    pausedAccumulatedMsRef.current = 0;
    pauseStartedAtRef.current = null;
    const fresh = createInitialGameState(totalPlayers, predefinedTypes);
    setState(fresh);
    setIsAnimatingExchange(false);
    StatsService.recordGameStarted(fresh.players);
    if (settings.animationsEnabled) {
      setDealingProgress(0);
      setIsDealing(true);
    } else {
      setIsDealing(false);
    }
  };

  const humanPlayer = state.players[0];
  const opponentPlayers = state.players.slice(1);
  const activeIdleSlotIndex = state.turnCount % 2;
  const activeIdleSlotTopLeft =
    activeIdleSlotIndex === 0 ? LEFT_TABLE_SLOT : RIGHT_TABLE_SLOT;

  const activePlayerId =
    isAnimatingExchange && animatingPlayerIndex !== null
      ? animatingPlayerIndex
      : state.currentTurnPlayerIndex;
  const isHumanTurnActive = !isDealing && activePlayerId === 0;
  const canHumanAct =
    !isDealing &&
    !isAnimatingExchange &&
    !showExitConfirmDialog &&
    !showPauseDialog &&
    !showHistoryOverlay &&
    !showStatsOverlay &&
    !showTutorialOverlay &&
    state.winner === null &&
    state.players[state.currentTurnPlayerIndex].isHuman;

  const showVictoryModal =
    state.winner !== null && state.winningType !== null && !isAnimatingExchange;

  // Compute exchange animation card positions
  const phase2End = 0.44;
  const phase4Start = 0.56;
  let incomingPos = lockedIncomingTableSlotPos;
  let outgoingPos = lockedOldTableSlotPos;

  if (isAnimatingExchange) {
    if (exchangeProgress < phase2End) {
      const rawIn = Math.min(1, Math.max(0, exchangeProgress / phase2End));
      const tIn = cubicEase(rawIn);
      incomingPos = {
        x: lerp(lockedPlayerCardPos.x, lockedIncomingTableSlotPos.x, tIn),
        y: lerp(lockedPlayerCardPos.y, lockedIncomingTableSlotPos.y, tIn),
      };
      outgoingPos = lockedOldTableSlotPos;
    } else if (exchangeProgress < phase4Start) {
      incomingPos = lockedIncomingTableSlotPos;
      outgoingPos = lockedOldTableSlotPos;
    } else {
      const rawOut = Math.min(
        1,
        Math.max(0, (exchangeProgress - phase4Start) / (1 - phase4Start))
      );
      const tOut = cubicEase(rawOut);
      incomingPos = lockedIncomingTableSlotPos;
      outgoingPos = {
        x: lerp(lockedOldTableSlotPos.x, lockedPlayerCardPos.x, tOut),
        y: lerp(lockedOldTableSlotPos.y, lockedPlayerCardPos.y, tOut),
      };
    }
  }

  return (
    <div
      ref={containerRef}
      style={{
        background:
          'repeating-linear-gradient(90deg, rgba(255,255,255,0.14) 0 80px, rgba(255,255,255,0) 80px 160px), radial-gradient(ellipse at 50% 45%, rgba(255,255,255,0.28), rgba(255,255,255,0) 70%), #BFE3A5',
      }}
      className="relative w-full h-full overflow-hidden select-none"
    >
      {/* Scaled 1920x1080 Stage */}
      <div
        style={{
          width: `${STAGE_WIDTH}px`,
          height: `${STAGE_HEIGHT}px`,
          left: '50%',
          top: '50%',
          transform: `translate(-50%, -50%) scale(${stageScale})`,
          transformOrigin: 'center center',
        }}
        className="absolute"
      >
        {/* Top-Left Back Button (opens dedicated Exit Confirmation Dialog) */}
        <button
          type="button"
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            setShowPauseDialog(false);
            setShowExitConfirmDialog(true);
          }}
          style={{
            left: '66px',
            top: '44px',
            width: '92px',
            height: '92px',
            boxShadow: '0 6px 0 #1E1745, 0 12px 22px rgba(15, 23, 42, 0.28)',
            touchAction: 'manipulation',
          }}
          className="group absolute rounded-full bg-gradient-to-b from-white to-[#F4F1FF] border-[3.5px] border-[#2A2160] flex items-center justify-center hover:scale-105 active:scale-95 active:translate-y-0.5 transition-transform cursor-pointer"
          title="Leave Game"
          aria-label="Leave Game"
        >
          {/* Expanded 108x108 invisible mobile touch target */}
          <span className="absolute -inset-2 rounded-full" aria-hidden="true" />
          <span className="w-[74px] h-[74px] rounded-full bg-[#F3F0FF] border-[1.5px] border-[#DAD3F5] flex items-center justify-center group-hover:bg-[#EAE4FF] transition-colors">
            <svg width="46" height="46" viewBox="0 0 24 24" fill="none">
              <path
                d="M11 6L5 12L11 18"
                stroke="#2A2160"
                strokeWidth="3.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M6 12H19"
                stroke="#2A2160"
                strokeWidth="3.2"
                strokeLinecap="round"
              />
            </svg>
          </span>
        </button>

        {/* Top-Left Quick Tutorial (?) Button */}
        <button
          type="button"
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            setShowTutorialOverlay(true);
          }}
          style={{
            left: '180px',
            top: '44px',
            width: '92px',
            height: '92px',
            boxShadow: '0 6px 0 #1E1745, 0 12px 22px rgba(15, 23, 42, 0.28)',
            touchAction: 'manipulation',
          }}
          className="group absolute rounded-full bg-gradient-to-b from-white to-[#FFFBEB] border-[3.5px] border-[#2A2160] flex items-center justify-center hover:scale-105 active:scale-95 active:translate-y-0.5 transition-transform cursor-pointer"
          title="Quick Tutorial"
          aria-label="Quick Tutorial"
        >
          {/* Expanded 108x108 invisible mobile touch target */}
          <span className="absolute -inset-2 rounded-full" aria-hidden="true" />
          <span className="w-[74px] h-[74px] rounded-full bg-[#FEF3C7] border-[1.5px] border-[#FDE68A] flex items-center justify-center group-hover:bg-[#FDE68A]/75 transition-colors">
            <svg width="46" height="46" viewBox="0 0 24 24" fill="none">
              <path
                d="M8.8 8.6C9.2 5.5 14.8 5.5 15.2 8.9C15.5 11.3 12 11.9 12 14.3"
                stroke="#2A2160"
                strokeWidth="3.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <circle cx="12" cy="18.5" r="1.9" fill="#D97706" />
              <circle cx="12" cy="18.5" r="1.9" stroke="#2A2160" strokeWidth="1.2" />
            </svg>
          </span>
        </button>

        {/* Top-Right Recent Cards History Button (replaces Player Stats & Sets on play screen) */}
        <button
          type="button"
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            setShowHistoryOverlay((prev) => !prev);
          }}
          style={{
            left: '1648px',
            top: '44px',
            width: '92px',
            height: '92px',
            boxShadow: '0 6px 0 #1E1745, 0 12px 22px rgba(15, 23, 42, 0.28)',
            touchAction: 'manipulation',
          }}
          className="group absolute rounded-full bg-gradient-to-b from-white to-[#ECFDF5] border-[3.5px] border-[#2A2160] flex items-center justify-center hover:scale-105 active:scale-95 active:translate-y-0.5 transition-transform cursor-pointer"
          title="Last 5 Cards Played"
          aria-label="Last 5 Cards Played"
        >
          {/* Expanded 108x108 invisible mobile touch target */}
          <span className="absolute -inset-2 rounded-full" aria-hidden="true" />
          <span className="w-[74px] h-[74px] rounded-full bg-[#ECFDF5] border-[1.5px] border-[#A7F3D0] flex items-center justify-center group-hover:bg-[#D1FAE5] transition-colors">
            <svg width="46" height="46" viewBox="0 0 24 24" fill="none">
              <path
                d="M3.2 12a8.8 8.8 0 1 0 2.7-6.4L3.2 8.2"
                stroke="#2A2160"
                strokeWidth="3.0"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M3.2 3.4v4.8H8"
                stroke="#2A2160"
                strokeWidth="3.0"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <rect
                x="9.2"
                y="7.2"
                width="6.4"
                height="9.2"
                rx="1.5"
                fill="#D97706"
                fillOpacity="0.18"
                stroke="#2A2160"
                strokeWidth="2.4"
              />
              <path
                d="M12.4 9.6v2.6l1.8 1.2"
                stroke="#2A2160"
                strokeWidth="2.4"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </span>
          {state.recentPlayedCards.length > 0 && (
            <span className="absolute -top-1.5 -right-1.5 min-w-[32px] h-[32px] px-1.5 rounded-full bg-[#D97706] border-[3px] border-white text-white text-[15px] font-black flex items-center justify-center tabular-nums shadow-md">
              {state.recentPlayedCards.length}
            </span>
          )}
        </button>

        {/* Top-Right Settings Button (opens GAME PAUSED panel) */}
        <button
          type="button"
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            setShowExitConfirmDialog(false);
            setShowPauseDialog(true);
          }}
          style={{
            left: '1762px',
            top: '44px',
            width: '92px',
            height: '92px',
            boxShadow: '0 6px 0 #1E1745, 0 12px 22px rgba(15, 23, 42, 0.28)',
            touchAction: 'manipulation',
          }}
          className="group absolute rounded-full bg-gradient-to-b from-white to-[#EEF2FF] border-[3.5px] border-[#2A2160] flex items-center justify-center hover:scale-105 active:scale-95 active:translate-y-0.5 transition-transform cursor-pointer"
          title="Settings & Controls"
          aria-label="Settings & Controls"
        >
          {/* Expanded 108x108 invisible mobile touch target */}
          <span className="absolute -inset-2 rounded-full" aria-hidden="true" />
          <span className="w-[74px] h-[74px] rounded-full bg-[#EEF2FF] border-[1.5px] border-[#C7D2FE] flex items-center justify-center group-hover:bg-[#E0E7FF] transition-colors">
            <svg width="46" height="46" viewBox="0 0 24 24" fill="none">
              <path
                d="M12 15.5A3.5 3.5 0 1 0 12 8.5a3.5 3.5 0 0 0 0 7Z"
                fill="#2A2160"
                fillOpacity="0.16"
                stroke="#2A2160"
                strokeWidth="2.8"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              <path
                d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 1 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 1 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 1 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 1 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z"
                stroke="#2A2160"
                strokeWidth="2.4"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          </span>
        </button>

        {/* Dealing Stack (shown during initial deal) */}
        {isDealing && (
          <div style={{ left: '989px', top: '453px' }} className="absolute">
            <CardBackView width={112} height={164} showStackShadow />
          </div>
        )}

        {/* Stationary Current Table Card */}
        {!isAnimatingExchange && (
          <div
            style={{
              left: `${activeIdleSlotTopLeft.x}px`,
              top: `${activeIdleSlotTopLeft.y}px`,
            }}
            className="absolute"
          >
            <CountryCardView
              card={state.tableCard}
              width={CARD_WIDTH}
              height={CARD_HEIGHT}
              isLegal
            />
          </div>
        )}

        {/* Opponent Avatars */}
        {opponentPlayers.map((opp, idx) => {
          const seat = getOpponentSeat(idx, state.totalPlayers);
          const isCurrentTurn = !isDealing && activePlayerId === opp.id;
          const isPlayerExchanging = isAnimatingExchange && animatingPlayerIndex === opp.id;
          const isThinking = isCurrentTurn && !opp.isHuman && state.winner === null;
          const isWinner = state.winner?.id === opp.id;
          const isSevenPlayer = state.totalPlayers === 7;

          return (
            <div
              key={opp.id}
              style={{
                left: `${seat.x - 78}px`,
                top: `${seat.y - (isSevenPlayer ? 52 : 56)}px`,
              }}
              className="absolute"
            >
              <PlayerSeat
                player={opp}
                isCurrentTurn={isCurrentTurn}
                isThinking={isThinking}
                isExchanging={isPlayerExchanging}
                isWinner={isWinner}
                isSevenPlayerMode={isSevenPlayer}
              />
            </div>
          );
        })}

        {/* Human Player Bottom Hand */}
        <div
          style={{
            left: `${HAND_CONTAINER_LEFT}px`,
            top: `${HAND_CONTAINER_TOP}px`,
            width: `${HAND_CONTAINER_WIDTH}px`,
            height: `${HAND_CONTAINER_HEIGHT}px`,
            opacity: isDealing ? Math.min(1, Math.max(0, (dealingProgress - 0.25) / 0.75)) : 1,
          }}
          className="absolute"
        >
          {/* Golden Turn Glow Behind Human Hand */}
          {isHumanTurnActive && (
            <div
              style={{
                left: `${(HAND_CONTAINER_WIDTH - (humanPlayer.hand.length * (CARD_WIDTH - 2) + 44)) / 2}px`,
                top: '22px',
                width: `${humanPlayer.hand.length * (CARD_WIDTH - 2) + 44}px`,
                height: `${CARD_HEIGHT + 28}px`,
                borderRadius: '28px',
                border: '3px solid rgba(255, 224, 130, 0.85)',
                boxShadow:
                  '0 0 28px 6px rgba(255, 200, 61, 0.55), 0 0 42px 10px rgba(255, 152, 0, 0.32)',
              }}
              className="absolute pointer-events-none"
            />
          )}

          {humanPlayer.hand.map((card, i) => {
            if (isAnimatingExchange && animatingPlayerIndex === 0 && animatingHandIndex === i) {
              return null;
            }
            const count = humanPlayer.hand.length;
            const mid = (count - 1) / 2;
            const cardLeft = (HAND_CONTAINER_WIDTH - CARD_WIDTH) / 2 + (i - mid) * (CARD_WIDTH - 2);
            const legal = canHumanAct && isLegalDiscard(state, card);

            return (
              <div
                key={card.id}
                style={{
                  left: `${cardLeft}px`,
                  top: '36px',
                }}
                className="absolute"
              >
                <CountryCardView
                  card={card}
                  width={CARD_WIDTH}
                  height={CARD_HEIGHT}
                  isLegal={!canHumanAct || legal}
                  onTap={
                    legal
                      ? () => {
                          AudioService.playCardTap();
                          performMove(card);
                        }
                      : undefined
                  }
                  onIllegalTap={undefined}
                />
              </div>
            );
          })}
        </div>

        {/* Sequential Card Exchange Layer (GPU-composited translate3d) */}
        {isAnimatingExchange && animatingDiscardedCard && animatingTakenCard && (
          <div className="absolute inset-0 pointer-events-none">
            <div
              style={{
                left: '0px',
                top: '0px',
                transform: `translate3d(${outgoingPos.x}px, ${outgoingPos.y}px, 0)`,
                willChange: 'transform',
                zIndex: exchangeProgress >= phase4Start ? 30 : 20,
              }}
              className="absolute"
            >
              <CountryCardView
                card={animatingTakenCard}
                width={CARD_WIDTH}
                height={CARD_HEIGHT}
                isLegal
              />
            </div>

            <div
              style={{
                left: '0px',
                top: '0px',
                transform: `translate3d(${incomingPos.x}px, ${incomingPos.y}px, 0)`,
                willChange: 'transform',
                zIndex: exchangeProgress < phase4Start ? 30 : 20,
              }}
              className="absolute"
            >
              <CountryCardView
                card={animatingDiscardedCard}
                width={CARD_WIDTH}
                height={CARD_HEIGHT}
                isLegal
              />
            </div>
          </div>
        )}

        {/* Initial Dealing Flying Cards (GPU-composited translate3d) */}
        {isDealing && (
          <div className="absolute inset-0 pointer-events-none">
            {Array.from({ length: state.totalPlayers }).flatMap((_, playerIdx) => {
              const target =
                playerIdx === 0
                  ? HUMAN_HAND_CENTER
                  : getOpponentSeat(playerIdx - 1, state.totalPlayers);
              const n = state.totalPlayers;
              const denom = n * n * 1.4;

              return Array.from({ length: n }, (__, c) => {
                const delay = (c * n + playerIdx) / denom;
                const localT = (dealingProgress - delay) / 0.45;
                if (localT <= 0 || localT >= 1) return null;
                const curvedT = cubicEase(localT);
                const x = lerp(DECK_PILE_CENTER.x, target.x, curvedT);
                const y = lerp(DECK_PILE_CENTER.y, target.y, curvedT);

                return (
                  <div
                    key={`${playerIdx}_${c}`}
                    style={{
                      left: '0px',
                      top: '0px',
                      transform: `translate3d(${x - 34}px, ${y - 50}px, 0) rotate(${(1 - curvedT) * 22}deg)`,
                      willChange: 'transform',
                    }}
                    className="absolute"
                  >
                    <CardBackView width={68} height={100} />
                  </div>
                );
              });
            })}
          </div>
        )}
      </div>

      {/* Overlays */}
      {showExitConfirmDialog && (
        <ExitConfirmationDialog
          onStayInGame={() => setShowExitConfirmDialog(false)}
          onExitGame={() => {
            setShowExitConfirmDialog(false);
            onNavigateBack();
          }}
        />
      )}

      {showPauseDialog && (
        <GameControlsDialog
          soundEnabled={settings.soundEnabled}
          hapticsEnabled={settings.hapticsEnabled}
          onSoundToggle={(val) => {
            AudioService.isSoundEnabled = val;
            onUpdateSettings({ ...settings, soundEnabled: val });
            if (val) AudioService.playButtonClick();
          }}
          onHapticsToggle={(val) => {
            HapticService.isHapticsEnabled = val;
            onUpdateSettings({ ...settings, hapticsEnabled: val });
          }}
          onResume={() => setShowPauseDialog(false)}
          onRestart={() => {
            setShowPauseDialog(false);
            handleRestartMatch();
          }}
          onMainMenu={() => {
            setShowPauseDialog(false);
            onExitToMainMenu();
          }}
        />
      )}

      {showVictoryModal &&
        !showHistoryOverlay &&
        !showStatsOverlay &&
        !showTutorialOverlay &&
        state.winner &&
        state.winningType && (
          <>
            <VictoryOverlay
              winner={state.winner}
              winningType={state.winningType}
              totalPlayers={state.totalPlayers}
              turnCount={state.turnCount}
              onPlayAgain={handleRestartMatch}
              onViewStats={() => setShowStatsOverlay(true)}
              onMainMenu={onExitToMainMenu}
            />
            <CelebrationParticlesCanvas
              completedType={state.winningType}
              originNormalized={celebrationOrigin}
            />
          </>
        )}

      {showHistoryOverlay && (
        <PlayedCardsHistoryOverlay
          recentPlayedCards={state.recentPlayedCards}
          currentTableCardName={getCardDisplayName(state.tableCard)}
          onClose={() => setShowHistoryOverlay(false)}
        />
      )}

      {showStatsOverlay && (
        <PlayerStatsOverlay
          activePlayers={state.players}
          targetSetSize={state.totalPlayers}
          onClose={() => setShowStatsOverlay(false)}
        />
      )}

      {showTutorialOverlay && (
        <TutorialModalOverlay
          targetSetSize={state.totalPlayers}
          onResumeGame={handleCloseTutorialOverlay}
          onClose={handleCloseTutorialOverlay}
        />
      )}
    </div>
  );
};
