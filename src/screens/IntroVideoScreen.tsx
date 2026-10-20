import React, { useEffect, useRef, useState } from 'react';
import { SkipForward } from 'lucide-react';
import { CountryCardView } from '../components/CountryCardView';
import { GameLogo } from '../components/GameLogo';
import { CountryType } from '../models/types';
import { AudioService, HapticService } from '../services/soundSynthesizer';

interface IntroVideoScreenProps {
  onFinished: () => void;
}

function cubicEase(t: number): number {
  const clamped = Math.max(0, Math.min(1, t));
  return 1 - Math.pow(1 - clamped, 3);
}

function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

export const IntroVideoScreen: React.FC<IntroVideoScreenProps> = ({ onFinished }) => {
  const [t, setT] = useState(0);
  const completedRef = useRef(false);
  const playedLaunchRef = useRef(false);
  const playedLandRef = useRef(false);
  const playedChimeRef = useRef(false);

  const finishIntro = () => {
    if (completedRef.current) return;
    completedRef.current = true;
    onFinished();
  };

  useEffect(() => {
    let animId = 0;
    const start = performance.now();
    const duration = 2400;

    const tick = (now: number) => {
      if (completedRef.current) return;
      const raw = (now - start) / duration;
      const clamped = Math.min(1, Math.max(0, raw));
      setT(clamped);

      if (!playedLaunchRef.current && clamped >= 0.28) {
        playedLaunchRef.current = true;
        AudioService.playCardTap();
      }
      if (!playedLandRef.current && clamped >= 0.46) {
        playedLandRef.current = true;
        AudioService.playCardPlace();
      }
      if (!playedChimeRef.current && clamped >= 0.68) {
        playedChimeRef.current = true;
        AudioService.playVictory();
        HapticService.cardPass();
      }

      if (clamped >= 1) {
        finishIntro();
      } else {
        animId = requestAnimationFrame(tick);
      }
    };

    animId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(animId);
  }, []);

  const leftTableSlot = { x: 302, y: 118 };
  const rightTableSlot = { x: 412, y: 118 };
  const handSlots = [
    { x: 224, y: 278 },
    { x: 312, y: 268 },
    { x: 400, y: 268 },
    { x: 488, y: 278 },
  ];
  const handAngles = [-8, -3, 3, 8];

  const dealProgress = Math.min(1, Math.max(0, t / 0.22));
  const dealScale = cubicEase(dealProgress);

  const inRaw = Math.min(1, Math.max(0, (t - 0.26) / 0.2));
  const inT = cubicEase(inRaw);

  const outRaw = Math.min(1, Math.max(0, (t - 0.48) / 0.2));
  const outT = cubicEase(outRaw);

  const celebrateT = Math.min(1, Math.max(0, (t - 0.68) / 0.32));
  const celebratePop = celebrateT > 0 ? Math.max(0, Math.sin(celebrateT * Math.PI)) : 0;

  const discardPos = {
    x: lerp(handSlots[2].x, rightTableSlot.x, inT),
    y: lerp(handSlots[2].y, rightTableSlot.y, inT),
  };
  const discardAngle = handAngles[2] * (1 - inT);

  const tableJapanPos = {
    x: lerp(leftTableSlot.x, handSlots[2].x, outT),
    y: lerp(leftTableSlot.y, handSlots[2].y, outT),
  };
  const tableJapanAngle = handAngles[2] * outT;

  const stepCaption =
    t < 0.26
      ? 'COLLECT MATCHING COUNTRY CARDS...'
      : t < 0.68
        ? 'SWAP ONE CARD WITH THE TABLE...'
        : 'COMPLETE THE COUNTRY SET TO WIN!';

  return (
    <div
      onClick={finishIntro}
      style={{
        background:
          'repeating-linear-gradient(90deg, rgba(255,255,255,0.14) 0 65px, rgba(255,255,255,0) 65px 130px), radial-gradient(ellipse at 50% 45%, rgba(255,255,255,0.28), rgba(255,255,255,0) 70%), #BFE3A5',
      }}
      className="relative w-full h-full flex items-center justify-center overflow-hidden cursor-pointer"
    >
      {/* Vignette */}
      <div
        style={{
          background: 'radial-gradient(circle at center, rgba(0,0,0,0.1) 0%, rgba(0,0,0,0.58) 100%)',
        }}
        className="absolute inset-0 pointer-events-none"
      />

      {/* Skip Intro Button */}
      <button
        onClick={(e) => {
          e.stopPropagation();
          finishIntro();
        }}
        className="absolute top-3 right-4 z-30 flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#0F172A]/80 border border-[#FFD54F]/50 text-[#FFE082] text-xs font-extrabold tracking-wider hover:bg-[#0F172A] cursor-pointer"
      >
        <SkipForward size={15} />
        SKIP INTRO
      </button>

      {/* 800x450 Choreographed Stage */}
      <div className="relative w-[800px] h-[450px] max-w-full max-h-full scale-[0.72] sm:scale-90 md:scale-100 origin-center">
        {/* Top Title Emblem */}
        <div
          style={{ opacity: dealProgress }}
          className="absolute top-[18px] left-0 right-0 flex justify-center z-20"
        >
          <div className="flex items-center gap-2.5 px-4 py-1.5 rounded-full bg-[#0F172A]/90 border-[1.5px] border-[#FFD54F]/85 shadow-lg">
            <GameLogo size={26} withGlow={false} />
            <span className="text-[#FFD700] text-base font-black tracking-[2.2px]">
              COUNTRY GAME
            </span>
            {celebrateT > 0.05 && (
              <span className="ml-1 px-2 py-0.5 rounded-[10px] bg-[#D97706] text-white text-[10.5px] font-black tracking-wider">
                4 OF A KIND!
              </span>
            )}
          </div>
        </div>

        {/* Hand Card 0 (Japan) */}
        <div
          style={{
            left: `${handSlots[0].x}px`,
            top: `${handSlots[0].y - 10 * celebratePop}px`,
            transform: `rotate(${handAngles[0]}deg) scale(${dealScale + 0.05 * celebratePop})`,
          }}
          className="absolute"
        >
          <CountryCardView
            card={{ id: 'intro_jp_0', type: CountryType.japan, isStartingCard: false }}
            width={86}
            height={126}
          />
        </div>

        {/* Hand Card 1 (Japan) */}
        <div
          style={{
            left: `${handSlots[1].x}px`,
            top: `${handSlots[1].y - 12 * celebratePop}px`,
            transform: `rotate(${handAngles[1]}deg) scale(${dealScale + 0.05 * celebratePop})`,
          }}
          className="absolute"
        >
          <CountryCardView
            card={{ id: 'intro_jp_1', type: CountryType.japan, isStartingCard: false }}
            width={86}
            height={126}
          />
        </div>

        {/* Hand Card 3 (Japan) */}
        <div
          style={{
            left: `${handSlots[3].x}px`,
            top: `${handSlots[3].y - 10 * celebratePop}px`,
            transform: `rotate(${handAngles[3]}deg) scale(${dealScale + 0.05 * celebratePop})`,
          }}
          className="absolute"
        >
          <CountryCardView
            card={{ id: 'intro_jp_3', type: CountryType.japan, isStartingCard: false }}
            width={86}
            height={126}
          />
        </div>

        {/* Table Japan Card */}
        <div
          style={{
            left: `${tableJapanPos.x}px`,
            top: `${tableJapanPos.y - (t >= 0.48 ? 12 * celebratePop : 0)}px`,
            transform: `rotate(${tableJapanAngle}deg) scale(${dealScale + (t >= 0.48 ? 0.05 * celebratePop : 0)})`,
            zIndex: t >= 0.48 ? 15 : 10,
          }}
          className="absolute"
        >
          <CountryCardView
            card={{ id: 'intro_jp_table', type: CountryType.japan, isStartingCard: false }}
            width={86}
            height={126}
          />
        </div>

        {/* Outgoing Australia Card */}
        <div
          style={{
            left: `${discardPos.x}px`,
            top: `${discardPos.y}px`,
            transform: `rotate(${discardAngle}deg) scale(${dealScale})`,
            zIndex: t < 0.48 ? 15 : 10,
          }}
          className="absolute"
        >
          <CountryCardView
            card={{ id: 'intro_au_2', type: CountryType.australia, isStartingCard: false }}
            width={86}
            height={126}
          />
        </div>

        {/* Bottom Caption & Progress */}
        <div className="absolute bottom-[14px] left-0 right-0 flex flex-col items-center gap-1.5 z-20">
          <div className="px-3.5 py-1 rounded-[14px] bg-[#0F172A]/85 border border-[#FFD54F]/45 text-[#FFE082] text-[11px] font-extrabold tracking-wider">
            {stepCaption}
          </div>
          <div className="w-[220px] h-1 rounded bg-black/40 overflow-hidden">
            <div
              style={{ width: `${t * 100}%` }}
              className="h-full bg-[#FFD54F]"
            />
          </div>
        </div>
      </div>
    </div>
  );
};
