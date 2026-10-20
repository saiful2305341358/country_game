import React, { useId } from 'react';

export interface GameLogoProps {
  /** Pixel size of the square logo mark (width & height). Responsive via CSS if omitted. */
  size?: number;
  /** Optional additional Tailwind classes */
  className?: string;
  /** Whether to show subtle ambient glow behind the medallion */
  withGlow?: boolean;
  /** Accessible label */
  ariaLabel?: string;
}

/**
 * Official responsive vector logo for Country Card Game.
 * Combines the central GLOBAL wild-starter card, a latitude/longitude globe with a tilted
 * golden orbital ring, and three fanned country cards (Saudi Arabia Emerald, Japan Crimson,
 * and Australia Outback Gold) inside a deep navy & gold medallion.
 */
export const GameLogo: React.FC<GameLogoProps> = React.memo(({
  size = 96,
  className = '',
  withGlow = true,
  ariaLabel = 'Country Card Game Logo',
}) => {
  const uid = useId().replace(/:/g, '');
  const idMedallionBg = `ccg_medallion_bg_${uid}`;
  const idGoldRim = `ccg_gold_rim_${uid}`;
  const idCardSau = `ccg_card_sau_${uid}`;
  const idCardAus = `ccg_card_aus_${uid}`;
  const idCardJpn = `ccg_card_jpn_${uid}`;
  const idCardGlobal = `ccg_card_global_${uid}`;
  const idGlobeGlow = `ccg_globe_glow_${uid}`;
  const idCardShadow = `ccg_card_shadow_${uid}`;

  return (
    <div
      role="img"
      aria-label={ariaLabel}
      style={{
        width: `${size}px`,
        height: `${size}px`,
        aspectRatio: '1 / 1',
        filter: withGlow ? 'drop-shadow(0 6px 20px rgba(255, 215, 0, 0.28))' : undefined,
      }}
      className={`relative inline-flex items-center justify-center shrink-0 select-none ${className}`}
    >
      <svg
        viewBox="0 0 256 256"
        width="100%"
        height="100%"
        preserveAspectRatio="xMidYMid meet"
        className="block w-full h-full overflow-visible"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          {/* Outer Medallion Navy Gradient */}
          <radialGradient id={idMedallionBg} cx="50%" cy="38%" r="65%">
            <stop offset="0%" stopColor="#1E293B" />
            <stop offset="58%" stopColor="#0F172A" />
            <stop offset="100%" stopColor="#060D1A" />
          </radialGradient>

          {/* Metallic Gold Rim Gradient */}
          <linearGradient id={idGoldRim} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#FFF59D" />
            <stop offset="35%" stopColor="#FFD700" />
            <stop offset="70%" stopColor="#D97706" />
            <stop offset="100%" stopColor="#F59E0B" />
          </linearGradient>

          {/* Saudi Arabia Card Gradient (Lush Emerald) */}
          <linearGradient id={idCardSau} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#10B981" />
            <stop offset="100%" stopColor="#064E3B" />
          </linearGradient>

          {/* Australia Card Gradient (Outback Gold/Amber) */}
          <linearGradient id={idCardAus} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#F59E0B" />
            <stop offset="100%" stopColor="#78350F" />
          </linearGradient>

          {/* Japan Card Gradient (Imperial Crimson) */}
          <linearGradient id={idCardJpn} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#F43F5E" />
            <stop offset="100%" stopColor="#881337" />
          </linearGradient>

          {/* Central GLOBAL Card Gradient */}
          <linearGradient id={idCardGlobal} x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#0F172A" />
            <stop offset="52%" stopColor="#1E1B4B" />
            <stop offset="100%" stopColor="#042F2E" />
          </linearGradient>

          {/* Luminous Cyan Globe Gradient */}
          <radialGradient id={idGlobeGlow} cx="50%" cy="45%" r="55%">
            <stop offset="0%" stopColor="#38BDF8" stopOpacity="0.42" />
            <stop offset="70%" stopColor="#0284C7" stopOpacity="0.12" />
            <stop offset="100%" stopColor="#0284C7" stopOpacity="0" />
          </radialGradient>

          {/* Soft Drop Shadow for Cards */}
          <filter id={idCardShadow} x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="0" dy="5" stdDeviation="5" floodColor="#000000" floodOpacity="0.55" />
          </filter>
        </defs>

        {/* 1. Outer Gold & Navy Medallion Crest */}
        <circle
          cx="128"
          cy="128"
          r="118"
          fill={`url(#${idMedallionBg})`}
          stroke={`url(#${idGoldRim})`}
          strokeWidth="7"
        />

        {/* Subtle Inner Compass Ring & Cardinal Ticks */}
        <circle
          cx="128"
          cy="128"
          r="105"
          fill="none"
          stroke="#FFD700"
          strokeOpacity="0.32"
          strokeWidth="1.8"
          strokeDasharray="6 6"
        />

        {/* Background Global Latitude/Longitude Arcs inside Medallion */}
        <ellipse
          cx="128"
          cy="128"
          rx="92"
          ry="42"
          fill="none"
          stroke="#38BDF8"
          strokeOpacity="0.14"
          strokeWidth="1.5"
          transform="rotate(-18 128 128)"
        />
        <ellipse
          cx="128"
          cy="128"
          rx="42"
          ry="92"
          fill="none"
          stroke="#38BDF8"
          strokeOpacity="0.14"
          strokeWidth="1.5"
          transform="rotate(-18 128 128)"
        />

        {/* 2. Left Fanned Country Card — Saudi Arabia (Emerald Green) */}
        <g transform="translate(128 148) rotate(-22) translate(-46 -88)" filter={`url(#${idCardShadow})`}>
          <rect
            x="0"
            y="0"
            width="76"
            height="112"
            rx="10"
            fill={`url(#${idCardSau})`}
            stroke="#FFFFFF"
            strokeWidth="3"
          />
          <rect
            x="5"
            y="5"
            width="66"
            height="102"
            rx="7"
            fill="none"
            stroke="#6EE7B7"
            strokeOpacity="0.55"
            strokeWidth="1.2"
          />
          {/* Octagonal Rub el Hizb Motif */}
          <rect
            x="24"
            y="34"
            width="28"
            height="28"
            fill="none"
            stroke="#6EE7B7"
            strokeOpacity="0.85"
            strokeWidth="2"
          />
          <rect
            x="24"
            y="34"
            width="28"
            height="28"
            fill="none"
            stroke="#6EE7B7"
            strokeOpacity="0.85"
            strokeWidth="2"
            transform="rotate(45 38 48)"
          />
        </g>

        {/* 3. Right Fanned Country Card — Australia (Outback Gold) */}
        <g transform="translate(128 148) rotate(22) translate(-30 -88)" filter={`url(#${idCardShadow})`}>
          <rect
            x="0"
            y="0"
            width="76"
            height="112"
            rx="10"
            fill={`url(#${idCardAus})`}
            stroke="#FFFFFF"
            strokeWidth="3"
          />
          <rect
            x="5"
            y="5"
            width="66"
            height="102"
            rx="7"
            fill="none"
            stroke="#FDE68A"
            strokeOpacity="0.55"
            strokeWidth="1.2"
          />
          {/* 7-Pointed Star Emblem */}
          <polygon
            points="38,28 43,40 56,38 47,48 53,60 40,55 38,67 36,55 23,60 29,48 20,38 33,40"
            fill="#FDE68A"
            fillOpacity="0.35"
            stroke="#FDE68A"
            strokeWidth="1.8"
            strokeLinejoin="round"
          />
        </g>

        {/* 4. Upper-Right Accent Country Card — Japan (Crimson Sun) */}
        <g transform="translate(128 144) rotate(8) translate(-38 -96)" filter={`url(#${idCardShadow})`}>
          <rect
            x="0"
            y="0"
            width="76"
            height="112"
            rx="10"
            fill={`url(#${idCardJpn})`}
            stroke="#FFFFFF"
            strokeWidth="3"
          />
          <circle
            cx="38"
            cy="46"
            r="16"
            fill="#FDA4AF"
            fillOpacity="0.4"
            stroke="#FFE4E6"
            strokeWidth="2"
          />
        </g>

        {/* 5. Center Hero Card — GLOBAL Wild Starter Card */}
        <g transform="translate(84 54)" filter={`url(#${idCardShadow})`}>
          <rect
            x="0"
            y="0"
            width="88"
            height="132"
            rx="12"
            fill={`url(#${idCardGlobal})`}
            stroke={`url(#${idGoldRim})`}
            strokeWidth="3.5"
          />
          <rect
            x="6"
            y="6"
            width="76"
            height="120"
            rx="8"
            fill="none"
            stroke="#38BDF8"
            strokeOpacity="0.45"
            strokeWidth="1.4"
          />

          {/* Top Mini Header Pill inside Global Card */}
          <rect
            x="14"
            y="12"
            width="60"
            height="12"
            rx="6"
            fill="#0284C7"
            fillOpacity="0.28"
            stroke="#38BDF8"
            strokeOpacity="0.65"
            strokeWidth="1"
          />
          <circle cx="24" cy="18" r="2.2" fill="#FFD700" />
          <circle cx="44" cy="18" r="2.2" fill="#38BDF8" />
          <circle cx="64" cy="18" r="2.2" fill="#FFD700" />

          {/* Central Stylized Globe inside Hero Card */}
          <circle cx="44" cy="64" r="31" fill={`url(#${idGlobeGlow})`} />
          <circle
            cx="44"
            cy="64"
            r="25"
            fill="none"
            stroke="#38BDF8"
            strokeWidth="2.2"
          />
          {/* Globe Meridians */}
          <ellipse
            cx="44"
            cy="64"
            rx="13"
            ry="25"
            fill="none"
            stroke="#7DD3FC"
            strokeOpacity="0.78"
            strokeWidth="1.6"
          />
          <line
            x1="44"
            y1="39"
            x2="44"
            y2="89"
            stroke="#7DD3FC"
            strokeOpacity="0.75"
            strokeWidth="1.5"
          />
          {/* Globe Latitude Lines */}
          <line
            x1="19"
            y1="64"
            x2="69"
            y2="64"
            stroke="#38BDF8"
            strokeWidth="1.8"
          />
          <path
            d="M23 52 Q44 57 65 52"
            fill="none"
            stroke="#7DD3FC"
            strokeOpacity="0.75"
            strokeWidth="1.5"
          />
          <path
            d="M23 76 Q44 71 65 76"
            fill="none"
            stroke="#7DD3FC"
            strokeOpacity="0.75"
            strokeWidth="1.5"
          />

          {/* Tilted Golden Orbital Unity Ring around the Globe */}
          <ellipse
            cx="44"
            cy="64"
            rx="34"
            ry="11"
            fill="none"
            stroke={`url(#${idGoldRim})`}
            strokeWidth="2.6"
            transform="rotate(-22 44 64)"
          />
          {/* Orbiting Gold Node */}
          <circle cx="74" cy="52" r="3.8" fill="#FFF59D" stroke="#D97706" strokeWidth="1.2" />
          <circle cx="14" cy="76" r="3.2" fill="#FFD700" />

          {/* Bottom Gold Accent Bar inside Global Card */}
          <rect
            x="18"
            y="106"
            width="52"
            height="11"
            rx="5.5"
            fill="#FFD700"
            fillOpacity="0.18"
            stroke="#FFD700"
            strokeOpacity="0.75"
            strokeWidth="1.2"
          />
          <line
            x1="28"
            y1="111.5"
            x2="60"
            y2="111.5"
            stroke="#FFE082"
            strokeWidth="2.2"
            strokeLinecap="round"
          />
        </g>

        {/* 6. Forefront Championship 4-Pointed Gold Star Crest at Bottom Pedestal */}
        <g transform="translate(128 206)">
          <circle
            cx="0"
            cy="0"
            r="18"
            fill="#0F172A"
            stroke={`url(#${idGoldRim})`}
            strokeWidth="2.8"
          />
          <polygon
            points="0,-13 3.8,-3.8 13,0 3.8,3.8 0,13 -3.8,3.8 -13,0 -3.8,-3.8"
            fill={`url(#${idGoldRim})`}
          />
          <circle cx="0" cy="0" r="2.8" fill="#FFFFFF" />
        </g>
      </svg>
    </div>
  );
});
