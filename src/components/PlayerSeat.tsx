import React from 'react';
import { GamePlayer } from '../models/types';

const SKINS = ['#F7C9A0', '#F2B48A', '#FBD9BD', '#E8A87C'];
const BGS = ['#8CC5B7', '#90CAF9', '#FDE7C8', '#7FD3CF', '#C9B8F5', '#F7B2BD'];
const HAIRS = ['#4A2C1D', '#2B1B12', '#F2C14E', '#6E2C00'];
const SHIRTS = ['#2A2160', '#14909A', '#FFB000', '#C0392B'];

export const AvatarSvg: React.FC<{ avatarIndex: number; isMe?: boolean; size?: number }> = React.memo(({
  avatarIndex,
  isMe = false,
  size = 102,
}) => {
  const isSixthBot = avatarIndex === 6;
  const bg = isMe ? '#BBD7F7' : isSixthBot ? BGS[5] : BGS[avatarIndex % 5];
  const shirt = isMe ? '#0B47C9' : isSixthBot ? SHIRTS[3] : SHIRTS[avatarIndex % 3];
  const skin = isMe ? '#0B47C9' : isSixthBot ? SKINS[3] : SKINS[avatarIndex % 3];
  const hair = isSixthBot ? HAIRS[3] : HAIRS[avatarIndex % 3];

  return (
    <svg width={size} height={size} viewBox="0 0 100 100" className="block">
      <rect width="100" height="100" fill={bg} />
      <path d="M18 100c2-22 16-30 32-30s30 8 32 30z" fill={shirt} />
      <circle cx="50" cy="44" r="19" fill={skin} />
      {!isMe && (
        <>
          <path
            d="M30 44c-2-20 12-28 22-26 12 1 20 10 18 26-4-9-10-13-20-13s-16 5-20 13z"
            fill={hair}
          />
          <circle cx="43" cy="46" r="2" fill="#2A2160" />
          <circle cx="57" cy="46" r="2" fill="#2A2160" />
          <path
            d="M44 54q6 5 12 0"
            stroke="#2A2160"
            strokeWidth="2"
            fill="none"
            strokeLinecap="round"
          />
        </>
      )}
    </svg>
  );
});

interface PlayerSeatProps {
  player: GamePlayer;
  isCurrentTurn: boolean;
  isThinking?: boolean;
  isExchanging?: boolean;
  isWinner?: boolean;
  isSevenPlayerMode?: boolean;
}

export const PlayerSeat: React.FC<PlayerSeatProps> = React.memo(({
  player,
  isCurrentTurn,
  isThinking = false,
  isExchanging = false,
  isWinner = false,
  isSevenPlayerMode = false,
}) => {
  const showTurnGlow = isCurrentTurn || isThinking || isExchanging || isWinner;
  const primaryGlow = isWinner ? '#69F0AE' : '#FFE082';

  // Carefully proportioned player profile specifically for 7-player mode (6 opponents on table)
  if (isSevenPlayerMode) {
    return (
      <div
        style={{ width: '156px', height: '152px' }}
        className="relative select-none flex flex-col items-center"
      >
        {/* Radiant Outer Turn Ring */}
        {showTurnGlow && (
          <div
            style={{
              top: '-22px',
              left: '0px',
              width: '156px',
              height: '156px',
              background: `radial-gradient(circle, ${primaryGlow}99 50%, rgba(255,179,0,0.35) 75%, transparent 100%)`,
            }}
            className="absolute rounded-full pointer-events-none animate-pulse"
          />
        )}

        {/* Avatar Circle (104px for balanced 6-opponent table spacing) */}
        <div
          style={{
            width: '104px',
            height: '104px',
            border: `${showTurnGlow ? 5 : 4.5}px solid ${showTurnGlow ? '#FFF176' : '#BFE3A5'}`,
            boxShadow: showTurnGlow
              ? '0 0 0 3px #2A2160, 0 0 0 9px #FFC83D, 0 0 26px 10px rgba(255, 213, 79, 0.78)'
              : '0 0 0 3px #2A2160',
          }}
          className="relative z-10 rounded-full overflow-hidden flex items-center justify-center bg-[#2A2160]"
        >
          <AvatarSvg avatarIndex={player.id} isMe={player.isHuman} size={95} />
        </div>

        {/* Thinking Bubble */}
        {isThinking && !isExchanging && !isWinner && (
          <div
            style={{
              top: '-6px',
              right: '14px',
              border: '2px solid #FFE082',
            }}
            className="absolute z-20 px-2 py-1 rounded-xl bg-[#2A2160] shadow-md flex items-center gap-1"
          >
            <span className="w-1.5 h-1.5 rounded-full bg-[#FFE082] animate-bounce" />
            <span className="w-1.5 h-1.5 rounded-full bg-[#FFE082]/80 animate-bounce [animation-delay:120ms]" />
            <span className="w-1.5 h-1.5 rounded-full bg-[#FFE082]/60 animate-bounce [animation-delay:240ms]" />
          </div>
        )}

        {/* Name Tag Pill */}
        <div
          style={{
            top: '111px',
            backgroundColor: showTurnGlow ? '#FFC83D' : '#FFFFFF',
            border: `2px solid ${showTurnGlow ? '#2A2160' : '#DAD3F5'}`,
            boxShadow: showTurnGlow ? '0 0 14px 2px rgba(255, 200, 61, 0.72)' : 'none',
          }}
          className="absolute z-20 px-3.5 py-0.5 rounded-[14px] max-w-[148px]"
        >
          <div className="text-[#2A2160] text-[16px] font-semibold leading-tight truncate">
            {player.name}
          </div>
        </div>
      </div>
    );
  }

  // Original 3, 4, 5, and 6 player mode profile (kept 100% as-is)
  return (
    <div style={{ width: '156px', height: '162px' }} className="relative select-none flex flex-col items-center">
      {/* Radiant Outer Turn Ring */}
      {showTurnGlow && (
        <div
          style={{
            top: '-26px',
            left: '-4px',
            width: '164px',
            height: '164px',
            background: `radial-gradient(circle, ${primaryGlow}99 50%, rgba(255,179,0,0.35) 75%, transparent 100%)`,
          }}
          className="absolute rounded-full pointer-events-none animate-pulse"
        />
      )}

      {/* Avatar Circle */}
      <div
        style={{
          width: '112px',
          height: '112px',
          border: `${showTurnGlow ? 5.5 : 5}px solid ${showTurnGlow ? '#FFF176' : '#BFE3A5'}`,
          boxShadow: showTurnGlow
            ? '0 0 0 3px #2A2160, 0 0 0 10px #FFC83D, 0 0 28px 12px rgba(255, 213, 79, 0.78)'
            : '0 0 0 3px #2A2160',
        }}
        className="relative z-10 rounded-full overflow-hidden flex items-center justify-center bg-[#2A2160]"
      >
        <AvatarSvg avatarIndex={player.id} isMe={player.isHuman} size={102} />
      </div>

      {/* Thinking Bubble */}
      {isThinking && !isExchanging && !isWinner && (
        <div
          style={{
            top: '-6px',
            right: '12px',
            border: '2px solid #FFE082',
          }}
          className="absolute z-20 px-2 py-1 rounded-xl bg-[#2A2160] shadow-md flex items-center gap-1"
        >
          <span className="w-1.5 h-1.5 rounded-full bg-[#FFE082] animate-bounce" />
          <span className="w-1.5 h-1.5 rounded-full bg-[#FFE082]/80 animate-bounce [animation-delay:120ms]" />
          <span className="w-1.5 h-1.5 rounded-full bg-[#FFE082]/60 animate-bounce [animation-delay:240ms]" />
        </div>
      )}

      {/* Name Tag Pill */}
      <div
        style={{
          top: '120px',
          backgroundColor: showTurnGlow ? '#FFC83D' : '#FFFFFF',
          border: `2px solid ${showTurnGlow ? '#2A2160' : '#DAD3F5'}`,
          boxShadow: showTurnGlow ? '0 0 14px 2px rgba(255, 200, 61, 0.72)' : 'none',
        }}
        className="absolute z-20 px-3.5 py-0.5 rounded-[14px] max-w-[152px]"
      >
        <div className="text-[#2A2160] text-[17px] font-semibold leading-tight truncate">
          {player.name}
        </div>
      </div>
    </div>
  );
});
