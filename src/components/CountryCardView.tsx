import React, { useState } from 'react';
import { Globe } from 'lucide-react';
import { COUNTRY_METADATA, CountryType, GameCard } from '../models/types';

interface CountryCardViewProps {
  card: GameCard;
  isSelected?: boolean;
  isLegal?: boolean;
  width?: number;
  height?: number;
  onTap?: () => void;
  onIllegalTap?: () => void;
}

export const CountryCardView: React.FC<CountryCardViewProps> = React.memo(({
  card,
  isSelected = false,
  isLegal = true,
  width = 90,
  height,
  onTap,
  onIllegalTap,
}) => {
  const [isPressed, setIsPressed] = useState(false);
  const [isHovered, setIsHovered] = useState(false);
  const [shaking, setShaking] = useState(false);

  const effectiveHeight = height ?? width * 2.0;
  const activeSelected = isSelected || isPressed;
  const isLifted = activeSelected || isHovered;

  const radius = Math.max(7, Math.min(18, width * (14 / 128)));
  const borderWidth = Math.max(2.2, Math.min(5.5, width * (5 / 128)));
  const scale = Math.max(0.48, Math.min(1.45, width / 90.0));

  const handleClick = () => {
    if (isLegal && onTap) {
      onTap();
    } else if (!isLegal && onIllegalTap) {
      setShaking(true);
      onIllegalTap();
      setTimeout(() => setShaking(false), 280);
    }
  };

  const liftY = onTap && isLegal && isLifted ? -18 * (width / 128) : 0;

  const renderEmblemSvg = (type: CountryType, accent: string) => {
    switch (type) {
      case CountryType.australia: {
        // 7-pointed Federation Star & circle
        const points = 7;
        const rOuter = 28;
        const rInner = 13;
        const pts: string[] = [];
        for (let i = 0; i < points * 2; i++) {
          const r = i % 2 === 0 ? rOuter : rInner;
          const angle = (i * Math.PI) / points - Math.PI / 2;
          const x = 50 + Math.cos(angle) * r;
          const y = 44 + Math.sin(angle) * r;
          pts.push(`${x.toFixed(1)},${y.toFixed(1)}`);
        }
        return (
          <svg viewBox="0 0 100 100" className="w-full h-full">
            <polygon
              points={pts.join(' ')}
              fill="none"
              stroke={accent}
              strokeOpacity={0.55}
              strokeWidth={1.6}
            />
            <circle
              cx="50"
              cy="44"
              r="33"
              fill="none"
              stroke={accent}
              strokeOpacity={0.45}
              strokeWidth={1.1}
            />
          </svg>
        );
      }
      case CountryType.greatBritain: {
        // Regal Union compass rose & concentric shield rings
        const lines = Array.from({ length: 8 }, (_, i) => {
          const angle = (i * Math.PI) / 4;
          return (
            <line
              key={i}
              x1={50 + Math.cos(angle) * 7}
              y1={44 + Math.sin(angle) * 7}
              x2={50 + Math.cos(angle) * 28}
              y2={44 + Math.sin(angle) * 28}
              stroke={accent}
              strokeOpacity={0.52}
              strokeWidth={1.5}
            />
          );
        });
        return (
          <svg viewBox="0 0 100 100" className="w-full h-full">
            <circle cx="50" cy="44" r="28" fill="none" stroke={accent} strokeOpacity={0.52} strokeWidth={1.5} />
            <circle cx="50" cy="44" r="19" fill="none" stroke={accent} strokeOpacity={0.52} strokeWidth={1.5} />
            {lines}
          </svg>
        );
      }
      case CountryType.saudiArabia:
        // Rub el Hizb (two overlapping squares forming an 8-pointed star)
        return (
          <svg viewBox="0 0 100 100" className="w-full h-full">
            <rect
              x="29"
              y="23"
              width="42"
              height="42"
              fill="none"
              stroke={accent}
              strokeOpacity={0.55}
              strokeWidth={1.5}
            />
            <rect
              x="29"
              y="23"
              width="42"
              height="42"
              transform="rotate(45 50 44)"
              fill="none"
              stroke={accent}
              strokeOpacity={0.55}
              strokeWidth={1.5}
            />
            <circle cx="50" cy="44" r="9.5" fill="none" stroke={accent} strokeOpacity={0.55} strokeWidth={1.5} />
          </svg>
        );
      case CountryType.iran: {
        // Symmetric Persian turquoise geometric rosette
        const petals = Array.from({ length: 6 }, (_, i) => {
          const angle = (i * Math.PI) / 3;
          return (
            <circle
              key={i}
              cx={50 + Math.cos(angle) * 13.6}
              cy={44 + Math.sin(angle) * 13.6}
              r="12.5"
              fill="none"
              stroke={accent}
              strokeOpacity={0.52}
              strokeWidth={1.4}
            />
          );
        });
        return (
          <svg viewBox="0 0 100 100" className="w-full h-full">
            {petals}
            <circle cx="50" cy="44" r="31" fill="none" stroke={accent} strokeOpacity={0.52} strokeWidth={1.4} />
          </svg>
        );
      }
      case CountryType.japan: {
        // Rising Sun disc & surrounding Seigaiha wave ring
        const rays = Array.from({ length: 12 }, (_, i) => {
          const angle = (i * Math.PI) / 6;
          return (
            <line
              key={i}
              x1={50 + Math.cos(angle) * 20}
              y1={44 + Math.sin(angle) * 20}
              x2={50 + Math.cos(angle) * 30}
              y2={44 + Math.sin(angle) * 30}
              stroke={accent}
              strokeOpacity={0.6}
              strokeWidth={1.3}
            />
          );
        });
        return (
          <svg viewBox="0 0 100 100" className="w-full h-full">
            <circle cx="50" cy="44" r="18" fill={accent} fillOpacity={0.35} stroke={accent} strokeOpacity={0.6} strokeWidth={1.5} />
            <circle cx="50" cy="44" r="30" fill="none" stroke={accent} strokeOpacity={0.6} strokeWidth={1.1} />
            {rays}
          </svg>
        );
      }
      case CountryType.bangladesh: {
        // Traditional Alpona lotus mandala
        const petals = Array.from({ length: 10 }, (_, i) => {
          const angle = (i * Math.PI) / 5;
          return (
            <circle
              key={i}
              cx={50 + Math.cos(angle) * 24}
              cy={44 + Math.sin(angle) * 24}
              r="5.5"
              fill="none"
              stroke={accent}
              strokeOpacity={0.55}
              strokeWidth={1.4}
            />
          );
        });
        return (
          <svg viewBox="0 0 100 100" className="w-full h-full">
            <circle cx="50" cy="44" r="30" fill="none" stroke={accent} strokeOpacity={0.55} strokeWidth={1.4} />
            <circle cx="50" cy="44" r="18" fill="none" stroke={accent} strokeOpacity={0.55} strokeWidth={1.4} />
            {petals}
          </svg>
        );
      }
      case CountryType.brazil: {
        // Iconic Brazilian Losango (Diamond Rhombus) & Celestial Sphere
        return (
          <svg viewBox="0 0 100 100" className="w-full h-full">
            <polygon
              points="50,14 82,44 50,74 18,44"
              fill="none"
              stroke={accent}
              strokeOpacity={0.58}
              strokeWidth={1.5}
            />
            <circle
              cx="50"
              cy="44"
              r="14.5"
              fill={accent}
              fillOpacity={0.22}
              stroke={accent}
              strokeOpacity={0.62}
              strokeWidth={1.4}
            />
            <path
              d="M36 41 Q50 35 64 46"
              fill="none"
              stroke={accent}
              strokeOpacity={0.65}
              strokeWidth={1.3}
            />
          </svg>
        );
      }
    }
  };

  const meta = card.type ? COUNTRY_METADATA[card.type] : null;

  return (
    <div
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => {
        setIsHovered(false);
        setIsPressed(false);
      }}
      onMouseDown={() => {
        if (onTap && isLegal) setIsPressed(true);
      }}
      onMouseUp={() => setIsPressed(false)}
      onClick={handleClick}
      style={{
        width: `${width}px`,
        height: `${effectiveHeight}px`,
        transform: `translate(${shaking ? '5px' : '0px'}, ${liftY}px) scale(${isPressed ? 0.95 : 1})`,
        transition: 'transform 150ms cubic-bezier(0.22, 1, 0.36, 1)',
        cursor: onTap && isLegal ? 'pointer' : !isLegal && onIllegalTap ? 'not-allowed' : 'default',
      }}
      className="relative select-none"
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          borderRadius: `${radius}px`,
          border: `${borderWidth}px solid ${activeSelected ? '#FFC83D' : '#FFFFFF'}`,
          boxShadow: activeSelected
            ? '0 4px 22px rgba(255, 200, 61, 0.45)'
            : '0 10px 24px rgba(20, 10, 50, 0.25)',
          background: card.isStartingCard
            ? 'linear-gradient(135deg, #0F172A 0%, #1E1B4B 55%, #042F2E 100%)'
            : `linear-gradient(135deg, ${meta?.primaryColor} 0%, ${meta?.secondaryColor} 100%)`,
        }}
        className="relative w-full h-full overflow-hidden flex flex-col justify-between"
      >
        {/* Background Artwork Layer */}
        <div className="absolute inset-0 pointer-events-none">
          {card.isStartingCard ? (
            <svg viewBox="0 0 100 100" className="w-full h-full">
              <circle cx="50" cy="43" r="42" fill="none" stroke="#38BDF8" strokeOpacity={0.14} strokeWidth={1} />
              <circle cx="50" cy="43" r="48" fill="none" stroke="#38BDF8" strokeOpacity={0.14} strokeWidth={1} />
              <circle cx="50" cy="43" r="33" fill="none" stroke="#38BDF8" strokeOpacity={0.65} strokeWidth={1.4} />
              <ellipse cx="50" cy="43" rx="18" ry="33" fill="none" stroke="#7DD3FC" strokeOpacity={0.42} strokeWidth={1} />
              <ellipse cx="50" cy="43" rx="7.5" ry="33" fill="none" stroke="#7DD3FC" strokeOpacity={0.42} strokeWidth={1} />
              <line x1="17" y1="43" x2="83" y2="43" stroke="#38BDF8" strokeOpacity={0.65} strokeWidth={1.4} />
              <ellipse
                cx="50"
                cy="43"
                rx="38"
                ry="12"
                transform="rotate(-20 50 43)"
                fill="none"
                stroke="#FFD700"
                strokeOpacity={0.6}
                strokeWidth={1.2}
              />
            </svg>
          ) : (
            meta && renderEmblemSvg(meta.id, meta.accentColor)
          )}
        </div>

        {/* Inner Frame */}
        <div
          style={{
            inset: '3px',
            borderRadius: `${Math.max(2, radius - borderWidth - 2)}px`,
            border: `1px solid ${card.isStartingCard ? 'rgba(56,189,248,0.28)' : `${meta?.accentColor}52`}`,
          }}
          className="absolute pointer-events-none"
        />

        {/* Card Foreground Content */}
        {card.isStartingCard ? (
          <div
            style={{
              padding: `${7 * scale}px ${5 * scale}px`,
            }}
            className="relative z-10 w-full h-full flex flex-col items-center justify-between"
          >
            <div
              style={{
                padding: `${1.8 * scale}px ${5 * scale}px`,
                backgroundColor: 'rgba(2, 132, 199, 0.35)',
                border: '0.8px solid rgba(125, 211, 252, 0.7)',
                borderRadius: '4px',
                fontSize: `${Math.max(5.5, Math.min(10, 7.5 * scale))}px`,
              }}
              className="text-[#E0F2FE] font-extrabold tracking-wider whitespace-nowrap"
            >
              WILD • STARTER
            </div>

            <Globe
              size={Math.round(22 * scale)}
              className="text-[#38BDF8] drop-shadow"
            />

            <div
              style={{
                fontSize: `${Math.max(6, Math.min(10.5, 8 * scale))}px`,
              }}
              className="text-[#FDE68A] font-extrabold tracking-widest"
            >
              GLOBAL
            </div>
          </div>
        ) : (
          meta && (
            <div
              style={{
                padding: `${6.5 * scale}px ${5.5 * scale}px`,
              }}
              className="relative z-10 w-full h-full flex flex-col justify-between"
            >
              {/* Top ISO code + Native name */}
              <div className="flex items-center justify-between gap-1">
                <span
                  style={{
                    padding: `${1.5 * scale}px ${4.5 * scale}px`,
                    backgroundColor: 'rgba(0,0,0,0.42)',
                    border: `0.8px solid ${meta.accentColor}CC`,
                    borderRadius: '4px',
                    fontSize: `${Math.max(6, Math.min(10.5, 8 * scale))}px`,
                  }}
                  className="text-white font-black tracking-wider leading-none"
                >
                  {meta.shortCode}
                </span>
                <span
                  style={{
                    color: meta.accentColor,
                    fontSize: `${Math.max(6.5, Math.min(11, 8.5 * scale))}px`,
                  }}
                  className="font-bold truncate text-right leading-tight"
                >
                  {meta.nativeName}
                </span>
              </div>

              {/* Bottom Country Name Banner */}
              <div
                style={{
                  padding: `${4.5 * scale}px ${5 * scale}px`,
                  backgroundColor: 'rgba(0,0,0,0.58)',
                  borderRadius: `${6 * scale}px`,
                  border: `1px solid ${meta.accentColor}BF`,
                }}
                className="w-full text-center"
              >
                <div
                  style={{
                    fontSize: `${Math.max(8.5, Math.min(16, 12.5 * scale))}px`,
                    textShadow: '0 1px 4px rgba(0,0,0,0.85)',
                  }}
                  className="text-white font-black tracking-wide truncate leading-tight"
                >
                  {meta.displayName}
                </div>
              </div>
            </div>
          )
        )}

        {/* Illegal Move Overlay */}
        {!isLegal && (
          <div className="absolute inset-0 z-20 bg-black/70 flex items-center justify-center">
            <div className="px-1.5 py-0.5 rounded bg-[#DC2626]/95 border border-white/70 text-white text-[7.5px] font-extrabold tracking-wider">
              SAME TYPE
            </div>
          </div>
        )}
      </div>
    </div>
  );
});

interface CardBackViewProps {
  width?: number;
  height?: number;
  showStackShadow?: boolean;
}

export const CardBackView: React.FC<CardBackViewProps> = React.memo(({
  width = 112,
  height,
  showStackShadow = false,
}) => {
  const effectiveHeight = height ?? width * (164 / 112);
  const radius = Math.max(5, Math.min(18, width * (14 / 112)));
  const borderWidth = Math.max(1.8, Math.min(6, width * (5 / 112)));

  return (
    <div
      style={{
        width: `${width}px`,
        height: `${effectiveHeight}px`,
        borderRadius: `${radius}px`,
        border: `${borderWidth}px solid #FFFFFF`,
        backgroundColor: '#2A2160',
        boxShadow: showStackShadow
          ? '4px 4px 0 rgba(255,255,255,0.25), 0 6px 14px rgba(20,10,70,0.35)'
          : '0 6px 14px rgba(20,10,70,0.35)',
      }}
      className="relative overflow-hidden select-none"
    >
      <svg viewBox="0 0 112 164" className="w-full h-full">
        <rect width="112" height="164" fill="#2A2160" />
        <ellipse
          cx="56"
          cy="82"
          rx="44"
          ry="48"
          transform="rotate(-20 56 82)"
          fill="#FFC83D"
        />
      </svg>
    </div>
  );
});
