import React, { useCallback, useEffect, useRef, useState } from 'react';
import { CardBackView, CountryCardView } from '../components/CountryCardView';
import {
  CelebrationParticlesCanvas,
  GameControlsDialog,
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
  isLegalDiscard,
} from '../models/types';
import { AudioService, HapticService } from '../services/soundSynthesizer';
import { StatsService } from '../services/statsService';

interface GameScreenProps {
  totalPlayers: number;
  predefinedTypes?: CountryType[];
  settings: GameSettings;
  onUpdateSettings: (newSettings: GameSettings) => void;
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
  onExitToMainMenu,
}) => {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const [stageScale, setStageScale] = useState(0.5);

  const [state, setState] = useState<GameState>(() =>
    createInitialGameState(totalPlayers, predefinedTypes)
  );
  const [isDealing, setIsDealing] = useState<boolean>(settings.animationsEnabled);
  const [dealingProgress, setDealingProgress] = useState<number>(0);

  const [isAnimatingExchange, setIsAnimatingExchange] = useState(false);
  const [exchangeProgress, setExchangeProgress] = useState(0);
  const [animatingPlayerIndex, setAnimatingPlayerIndex] = useState<number | null>(null);
  const [animatingHandIndex, setAnimatingHandIndex] = useState<number | null>(null);
  const [animatingDiscardedCard, setAnimatingDiscardedCard] = useState<GameCard | null>(null);
  const [animatingTakenCard, setAnimatingTakenCard] = useState<GameCard | null>(null);
  const [lockedPlayerCardPos, setLockedPlayerCardPos] = useState({ x: 0, y: 0 });
  const [lockedOldTableSlotPos, setLockedOldTableSlotPos] = useState(LEFT_TABLE_SLOT);
  const [lockedIncomingTableSlotPos, setLockedIncomingTableSlotPos] = useState(RIGHT_TABLE_SLOT);

  const [showPauseDialog, setShowPauseDialog] = useState(false);
  const [showStatsOverlay, setShowStatsOverlay] = useState(false);
  const [showTutorialOverlay, setShowTutorialOverlay] = useState<boolean>(
    () => !StatsService.hasSeenTutorial()
  );
  const [celebrationOrigin, setCelebrationOrigin] = useState<{ x: number; y: number }>({
    x: 0.5,
    y: 0.52,
  });

  const recordedWinRef = useRef(false);

  // Measure viewport to scale 1920x1080 stage cleanly
  useEffect(() => {
    const updateScale = () => {
      const el = containerRef.current;
      if (!el) return;
      const w = el.clientWidth;
      const h = el.clientHeight;
      const scale = Math.min(w / STAGE_WIDTH, h / STAGE_HEIGHT);
      setStageScale(Math.max(0.15, scale));
    };
    updateScale();
    window.addEventListener('resize', updateScale);
    return () => window.removeEventListener('resize', updateScale);
  }, []);

  // Record initial game started
  useEffect(() => {
    StatsService.recordGameStarted(state.players);
    if (!StatsService.hasSeenTutorial()) {
      StatsService.markTutorialSeen();
    }
    if (settings.animationsEnabled) {
      AudioService.playExchange();
    } else {
      AudioService.playGameStart();
    }
    HapticService.dealShuffle();
  }, []);

  // Dealing animation loop
  useEffect(() => {
    if (!isDealing) return;
    let animId = 0;
    const start = performance.now();
    const duration = 1350;

    const tick = (now: number) => {
      const p = Math.min(1, Math.max(0, (now - start) / duration));
      setDealingProgress(p);
      if (p >= 1) {
        setIsDealing(false);
      } else {
        animId = requestAnimationFrame(tick);
      }
    };
    animId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(animId);
  }, [isDealing]);

  // Exchange animation loop
  useEffect(() => {
    if (!isAnimatingExchange) return;
    let animId = 0;
    const start = performance.now();
    const duration = 1020;
    let playedLanding = false;
    let playedOutgoing = false;

    const tick = (now: number) => {
      const p = Math.min(1, Math.max(0, (now - start) / duration));
      setExchangeProgress(p);

      if (!playedLanding && p >= 0.44) {
        playedLanding = true;
        AudioService.playCardPlace();
        HapticService.botTurnTick();
      }
      if (!playedOutgoing && p >= 0.56) {
        playedOutgoing = true;
        AudioService.playCardTake();
      }

      if (p >= 1) {
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
  }, [isAnimatingExchange]);

  // Post-exchange victory / turn cues
  useEffect(() => {
    if (isAnimatingExchange || isDealing) return;
    if (state.winner && state.winningType) {
      if (!recordedWinRef.current) {
        recordedWinRef.current = true;
        StatsService.recordSetCompleted(state.winner, state.winningType);
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
      const { nextState, isValid } = executeGameMove(state, card);
      if (!isValid) {
        HapticService.invalidMove();
        setState(nextState);
        return false;
      }

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
        AudioService.playCardPlace();
      }

      setState(nextState);
      return true;
    },
    [settings.animationsEnabled, state]
  );

  // Bot turn scheduler
  useEffect(() => {
    const isPaused = showPauseDialog || showStatsOverlay || showTutorialOverlay;
    if (
      isDealing ||
      isAnimatingExchange ||
      isPaused ||
      state.winner !== null ||
      state.players[state.currentTurnPlayerIndex].isHuman
    ) {
      return;
    }

    let delayMs = 650;
    let chosenCard: GameCard | null = null;
    try {
      const decision = evaluateBotDecision(state, settings.botDelayMs);
      chosenCard = decision.discardCard;
      delayMs = settings.animationsEnabled ? decision.thinkDelayMs : 120;
    } catch {
      // fallback
    }

    const timer = window.setTimeout(() => {
      if (chosenCard) {
        performMove(chosenCard);
      }
    }, delayMs);

    return () => clearTimeout(timer);
  }, [
    isDealing,
    isAnimatingExchange,
    showPauseDialog,
    showStatsOverlay,
    showTutorialOverlay,
    state,
    settings.botDelayMs,
    settings.animationsEnabled,
    performMove,
  ]);

  const handleRestartMatch = () => {
    recordedWinRef.current = false;
    const fresh = createInitialGameState(totalPlayers, predefinedTypes);
    setState(fresh);
    setIsAnimatingExchange(false);
    StatsService.recordGameStarted(fresh.players);
    if (settings.animationsEnabled) {
      setDealingProgress(0);
      setIsDealing(true);
      AudioService.playExchange();
    } else {
      setIsDealing(false);
      AudioService.playGameStart();
    }
    HapticService.dealShuffle();
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
      className="relative w-full h-full flex items-center justify-center overflow-hidden select-none"
    >
      {/* Scaled 1920x1080 Stage */}
      <div
        style={{
          width: `${STAGE_WIDTH}px`,
          height: `${STAGE_HEIGHT}px`,
          transform: `scale(${stageScale})`,
          transformOrigin: 'center center',
        }}
        className="relative shrink-0"
      >
        {/* Top-Left Back/Menu Button */}
        <button
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            setShowPauseDialog(true);
          }}
          style={{ left: '90px', top: '60px', width: '68px', height: '68px' }}
          className="absolute rounded-full bg-white border-2 border-[#DAD3F5] flex items-center justify-center hover:scale-105 transition cursor-pointer shadow"
          title="Game Menu"
        >
          <svg width="30" height="30" viewBox="0 0 24 24" fill="none">
            <path
              d="M15 5l-7 7 7 7"
              stroke="#2A2160"
              strokeWidth="2.4"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </button>

        {/* Top-Left Quick Tutorial (?) Button */}
        <button
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            setShowTutorialOverlay(true);
          }}
          style={{ left: '176px', top: '60px', width: '68px', height: '68px' }}
          className="absolute rounded-full bg-white border-2 border-[#DAD3F5] flex items-center justify-center hover:scale-105 transition cursor-pointer shadow"
          title="Quick Tutorial"
        >
          <svg width="30" height="30" viewBox="0 0 24 24" fill="none">
            <path
              d="M9.1 9C9.5 6.2 14.5 6.2 14.9 9.2C15.2 11.4 12 12 12 14.2"
              stroke="#2A2160"
              strokeWidth="2.4"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <circle cx="12" cy="18.2" r="1.45" fill="#2A2160" />
          </svg>
        </button>

        {/* Top-Center Status Pill */}
        <div
          style={{ left: '460px', right: '460px', top: '34px' }}
          className="absolute flex justify-center pointer-events-none"
        >
          <div className="px-6 py-2 rounded-full bg-[#2A2160]/90 border-2 border-[#FFD54F]/75 text-[#FFE082] text-[20px] font-bold tracking-wide shadow-lg truncate">
            {state.statusMessage}
          </div>
        </div>

        {/* Top-Right Player Stats Button */}
        <button
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            setShowStatsOverlay(true);
          }}
          style={{ left: '1676px', top: '60px', width: '68px', height: '68px' }}
          className="absolute rounded-full bg-white border-2 border-[#DAD3F5] flex items-center justify-center hover:scale-105 transition cursor-pointer shadow"
          title="Player Stats & Sets"
        >
          <svg width="30" height="30" viewBox="0 0 24 24" fill="none">
            <path
              d="M7 4h10v5.5Q17 14.5 12 14.5Q7 14.5 7 9.5Z"
              stroke="#2A2160"
              strokeWidth="2.2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <path
              d="M7 6H4.2Q4.2 10.5 7 10.5M17 6h2.8Q19.8 10.5 17 10.5M12 14.5v5M8 19.5h8"
              stroke="#2A2160"
              strokeWidth="2.2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          </svg>
        </button>

        {/* Top-Right Settings Button */}
        <button
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            setShowPauseDialog(true);
          }}
          style={{ left: '1762px', top: '60px', width: '68px', height: '68px' }}
          className="absolute rounded-full bg-white border-2 border-[#DAD3F5] flex items-center justify-center hover:scale-105 transition cursor-pointer shadow"
          title="Settings & Controls"
        >
          <svg width="30" height="30" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="3" stroke="#2A2160" strokeWidth="2.4" />
            <path
              d="M12 2.8v3M12 18.2v3M2.8 12h3M18.2 12h3M5.5 5.5l2.1 2.1M16.4 16.4l2.1 2.1M18.5 5.5l-2.1 2.1M7.6 16.4l-2.1 2.1"
              stroke="#2A2160"
              strokeWidth="2.4"
              strokeLinecap="round"
            />
          </svg>
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

          return (
            <div
              key={opp.id}
              style={{
                left: `${seat.x - 78}px`,
                top: `${seat.y - 56}px`,
              }}
              className="absolute"
            >
              <PlayerSeat
                player={opp}
                isCurrentTurn={isCurrentTurn}
                isThinking={isThinking}
                isExchanging={isPlayerExchanging}
                isWinner={isWinner}
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
                          HapticService.cardTap();
                          AudioService.playCardTap();
                          const ok = performMove(card);
                          if (ok) HapticService.cardPass();
                        }
                      : undefined
                  }
                  onIllegalTap={
                    canHumanAct && !legal
                      ? () => {
                          HapticService.invalidMove();
                        }
                      : undefined
                  }
                />
              </div>
            );
          })}
        </div>

        {/* Sequential Card Exchange Layer */}
        {isAnimatingExchange && animatingDiscardedCard && animatingTakenCard && (
          <div className="absolute inset-0 pointer-events-none">
            <div
              style={{
                left: `${outgoingPos.x}px`,
                top: `${outgoingPos.y}px`,
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
                left: `${incomingPos.x}px`,
                top: `${incomingPos.y}px`,
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

        {/* Initial Dealing Flying Cards */}
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
                      left: `${x - 34}px`,
                      top: `${y - 50}px`,
                      transform: `rotate(${(1 - curvedT) * 22}deg)`,
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
          onClose={() => setShowTutorialOverlay(false)}
        />
      )}
    </div>
  );
};
