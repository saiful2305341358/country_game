import React, { useEffect, useState } from 'react';
import {
  ArrowLeft,
  Award,
  BarChart3,
  Clock,
  Gamepad2,
  RotateCcw,
  Trophy,
  Zap,
} from 'lucide-react';
import { AvatarSvg } from '../components/PlayerSeat';
import { COUNTRY_METADATA } from '../models/types';
import { AudioService, HapticService } from '../services/soundSynthesizer';
import { StatsService } from '../services/statsService';

interface ProfileScreenProps {
  onBack: () => void;
}

export function formatDurationSeconds(seconds: number): string {
  if (!seconds || seconds <= 0) return '--';
  const rounded = Math.round(seconds);
  if (rounded < 60) {
    return `${rounded}s`;
  }
  const mins = Math.floor(rounded / 60);
  const secs = rounded % 60;
  return secs > 0 ? `${mins}m ${secs}s` : `${mins}m`;
}

function getPlayerRankTitle(wins: number, winPercentage: number): string {
  if (wins >= 15 && winPercentage >= 50) return 'Grand Global Envoy';
  if (wins >= 8) return 'Senior Ambassador';
  if (wins >= 3) return 'Skilled Diplomat';
  if (wins >= 1) return 'Rising Envoy';
  return 'New Challenger';
}

export const ProfileScreen: React.FC<ProfileScreenProps> = ({ onBack }) => {
  const [confirmReset, setConfirmReset] = useState(false);
  const [, setTick] = useState(0);

  useEffect(() => {
    return StatsService.subscribe(() => setTick((t) => t + 1));
  }, []);

  const humanRecord = StatsService.humanRecord;
  const totalGamesPlayed = StatsService.humanGamesPlayed;
  const totalWins = StatsService.humanWins;
  const totalLosses = Math.max(0, totalGamesPlayed - totalWins);
  const winPercentage = StatsService.humanWinPercentage;
  const averageWinTimeSec = StatsService.averageWinTimeSeconds;
  const fastestWinTimeSec = StatsService.fastestWinTimeSeconds;
  const winTimes = StatsService.humanWinTimesSeconds;
  const rankTitle = getPlayerRankTitle(totalWins, winPercentage);

  const lastCountryMeta = humanRecord.lastCompletedCountry
    ? COUNTRY_METADATA[humanRecord.lastCompletedCountry]
    : null;

  // Chart data: show up to last 8 win times, or benchmark targets when 0 wins recorded
  const hasWinTimeData = winTimes.length > 0;
  const displayedWinTimes = hasWinTimeData ? winTimes.slice(-8) : [25, 34, 42, 52, 62];
  const chartLabels = hasWinTimeData
    ? displayedWinTimes.map((_, idx) => {
        const winNum = Math.max(1, winTimes.length - displayedWinTimes.length + idx + 1);
        return `W${winNum}`;
      })
    : ['3P Par', '4P Par', '5P Par', '6P Par', '7P Par'];

  const maxChartSec = Math.max(60, ...displayedWinTimes, averageWinTimeSec + 10);

  // SVG Donut math for Win Percentage
  const donutRadius = 38;
  const donutCircumference = 2 * Math.PI * donutRadius;
  const clampedWinPct = Math.max(0, Math.min(100, winPercentage));
  const winStrokeDash = (clampedWinPct / 100) * donutCircumference;

  return (
    <div
      style={{
        background: 'radial-gradient(circle at center, #0F3B2C 0%, #09251B 55%, #03140E 100%)',
        paddingTop: 'max(0.45rem, env(safe-area-inset-top))',
        paddingBottom: 'max(0.45rem, env(safe-area-inset-bottom))',
        paddingLeft: 'max(0.75rem, env(safe-area-inset-left))',
        paddingRight: 'max(0.75rem, env(safe-area-inset-right))',
      }}
      className="w-full h-full flex items-center justify-center p-2.5 sm:p-5 overflow-y-auto select-none"
    >
      <div className="w-full max-w-[860px] flex flex-col gap-2.5 sm:gap-3.5 my-auto">
        {/* 1. Top Header Bar */}
        <div className="flex items-center justify-between gap-3">
          <button
            type="button"
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              onBack();
            }}
            style={{ touchAction: 'manipulation' }}
            className="w-11 h-11 rounded-full bg-black/40 border border-[#FFD54F]/45 flex items-center justify-center text-[#FFD54F] hover:bg-white/15 active:scale-95 transition cursor-pointer shadow shrink-0"
            aria-label="Back to Main Menu"
            title="Back"
          >
            <ArrowLeft size={22} strokeWidth={2.6} />
          </button>

          {/* Player Identity Summary */}
          <div className="flex items-center gap-2.5 sm:gap-3">
            <div className="w-10 h-10 sm:w-11 sm:h-11 rounded-full border-2 border-[#FFD700] overflow-hidden bg-[#0F172A] shrink-0 shadow-md">
              <AvatarSvg avatarIndex={humanRecord.avatarIndex} isMe size={44} />
            </div>
            <div className="text-left">
              <div className="flex items-center gap-2">
                <h1 className="text-[#FFD700] text-base sm:text-lg font-black tracking-wider leading-tight">
                  Player Profile
                </h1>
                <span className="text-white/40" aria-hidden="true">
                  ·
                </span>
                <span className="text-[#FFE082] text-xs sm:text-sm font-bold whitespace-nowrap">
                  {humanRecord.name}
                </span>
              </div>
              <div className="flex items-center gap-1.5 text-[10.5px] sm:text-xs text-white/70">
                <span>{rankTitle}</span>
                <span aria-hidden="true">·</span>
                <span className="tabular-nums text-[#10B981] font-semibold">
                  {humanRecord.totalPoints.toLocaleString()} pts
                </span>
              </div>
            </div>
          </div>

          {/* Reset Stats Control */}
          <div className="shrink-0">
            {!confirmReset ? (
              <button
                type="button"
                onClick={() => {
                  AudioService.playButtonClick();
                  HapticService.uiTap();
                  setConfirmReset(true);
                }}
                className="px-3 py-2 rounded-lg bg-black/35 border border-white/20 text-white/75 hover:text-white hover:bg-white/10 text-[11px] font-bold flex items-center gap-1.5 transition cursor-pointer whitespace-nowrap"
              >
                <RotateCcw size={13} />
                Reset Stats
              </button>
            ) : (
              <div className="flex items-center gap-1.5">
                <button
                  type="button"
                  onClick={() => {
                    AudioService.playButtonClick();
                    HapticService.uiTap();
                    StatsService.resetStats();
                    setConfirmReset(false);
                  }}
                  className="px-2.5 py-1.5 rounded-lg bg-red-600 hover:bg-red-700 text-white text-[11px] font-bold cursor-pointer whitespace-nowrap"
                >
                  Confirm
                </button>
                <button
                  type="button"
                  onClick={() => setConfirmReset(false)}
                  className="px-2.5 py-1.5 rounded-lg bg-white/15 hover:bg-white/25 text-white/80 text-[11px] font-bold cursor-pointer whitespace-nowrap"
                >
                  Cancel
                </button>
              </div>
            )}
          </div>
        </div>

        {/* 2. Three Primary Aggregate Stat Cards */}
        <div className="grid grid-cols-3 gap-2 sm:gap-3">
          {/* Card 1: Total Games Played */}
          <div className="p-2.5 sm:p-3.5 rounded-[14px] bg-[#0F172A]/90 border border-[#D4AF37]/35 flex flex-col justify-between">
            <div className="flex items-center justify-between gap-2">
              <span className="text-white/70 text-[11px] sm:text-xs font-semibold">
                Total Games Played
              </span>
              <Gamepad2 size={16} className="text-[#FFD54F] shrink-0" />
            </div>
            <div className="my-1 sm:my-1.5 text-white text-xl sm:text-2xl font-black tabular-nums">
              {totalGamesPlayed}
            </div>
            <div className="flex items-center gap-1.5 text-[10px] sm:text-[11px] text-white/65 tabular-nums">
              <span className="text-[#10B981] font-semibold">{totalWins} Won</span>
              <span aria-hidden="true">·</span>
              <span>{totalLosses} Lost</span>
            </div>
          </div>

          {/* Card 2: Win Percentage */}
          <div className="p-2.5 sm:p-3.5 rounded-[14px] bg-[#0F172A]/90 border border-[#D4AF37]/35 flex flex-col justify-between">
            <div className="flex items-center justify-between gap-2">
              <span className="text-white/70 text-[11px] sm:text-xs font-semibold">
                Win Percentage
              </span>
              <Trophy size={16} className="text-[#10B981] shrink-0" />
            </div>
            <div className="my-1 sm:my-1.5 flex items-baseline gap-2">
              <span className="text-[#10B981] text-xl sm:text-2xl font-black tabular-nums">
                {winPercentage.toFixed(1)}%
              </span>
              <span className="text-white/55 text-[10px] sm:text-[11px] tabular-nums">
                ({totalWins}/{totalGamesPlayed})
              </span>
            </div>
            <div className="w-full h-1.5 rounded-full bg-white/10 overflow-hidden">
              <div
                style={{ width: `${clampedWinPct}%` }}
                className="h-full rounded-full bg-[#10B981] transition-all duration-300"
              />
            </div>
          </div>

          {/* Card 3: Average Win Time */}
          <div className="p-2.5 sm:p-3.5 rounded-[14px] bg-[#0F172A]/90 border border-[#D4AF37]/35 flex flex-col justify-between">
            <div className="flex items-center justify-between gap-2">
              <span className="text-white/70 text-[11px] sm:text-xs font-semibold">
                Average Win Time
              </span>
              <Clock size={16} className="text-[#FFD54F] shrink-0" />
            </div>
            <div className="my-1 sm:my-1.5 text-[#FFD54F] text-xl sm:text-2xl font-black tabular-nums">
              {formatDurationSeconds(averageWinTimeSec)}
            </div>
            <div className="flex items-center gap-1.5 text-[10px] sm:text-[11px] text-white/65 tabular-nums">
              <span>Best: {formatDurationSeconds(fastestWinTimeSec)}</span>
              <span aria-hidden="true">·</span>
              <span>{winTimes.length} Timed Wins</span>
            </div>
          </div>
        </div>

        {/* 3. Simple Performance Charts & Career Breakdown */}
        <div className="grid grid-cols-12 gap-2.5 sm:gap-3.5 items-stretch">
          {/* Left Chart (7 Cols): Win Time Bar Chart with Average Line */}
          <div className="col-span-12 sm:col-span-7 p-3 sm:p-4 rounded-[14px] bg-[#0F172A]/90 border border-[#D4AF37]/35 flex flex-col justify-between">
            <div className="flex items-center justify-between gap-2 mb-2">
              <div className="flex items-center gap-2">
                <BarChart3 size={16} className="text-[#FFD54F] shrink-0" />
                <h2 className="text-[#FFE082] text-xs sm:text-sm font-bold">
                  {hasWinTimeData
                    ? 'Win Time History & Average (Seconds)'
                    : 'Target Win Time Benchmarks by Table Size'}
                </h2>
              </div>
              <div className="flex items-center gap-2 text-[10px] sm:text-[11px] text-white/65 tabular-nums">
                {hasWinTimeData ? (
                  <>
                    <span>Avg: {formatDurationSeconds(averageWinTimeSec)}</span>
                    <span aria-hidden="true">·</span>
                    <span className="text-[#10B981]">
                      Fastest: {formatDurationSeconds(fastestWinTimeSec)}
                    </span>
                  </>
                ) : (
                  <span>Complete a victory to plot your win times</span>
                )}
              </div>
            </div>

            {/* SVG Bar Chart */}
            <div className="relative w-full h-[130px] sm:h-[148px] pt-2">
              <svg
                viewBox="0 0 420 130"
                className="w-full h-full overflow-visible"
                role="img"
                aria-label="Player Win Time Chart"
              >
                {/* Horizontal Grid Lines */}
                {[0.25, 0.5, 0.75, 1].map((ratio, idx) => {
                  const y = 102 - ratio * 82;
                  const labelVal = Math.round(maxChartSec * ratio);
                  return (
                    <g key={idx}>
                      <line
                        x1={32}
                        y1={y}
                        x2={408}
                        y2={y}
                        stroke="rgba(255,255,255,0.08)"
                        strokeDasharray="3 3"
                        strokeWidth={1}
                      />
                      <text
                        x={26}
                        y={y + 3}
                        textAnchor="end"
                        fill="rgba(255,255,255,0.45)"
                        fontSize="9"
                        fontFamily="monospace"
                      >
                        {labelVal}s
                      </text>
                    </g>
                  );
                })}

                {/* Baseline */}
                <line
                  x1={32}
                  y1={102}
                  x2={408}
                  y2={102}
                  stroke="rgba(255,255,255,0.2)"
                  strokeWidth={1}
                />

                {/* Bars */}
                {displayedWinTimes.map((sec, idx) => {
                  const count = displayedWinTimes.length;
                  const slotWidth = 368 / Math.max(1, count);
                  const barWidth = Math.min(34, Math.max(18, slotWidth * 0.52));
                  const x = 36 + idx * slotWidth + (slotWidth - barWidth) / 2;
                  const barHeight = Math.max(6, Math.min(82, (sec / maxChartSec) * 82));
                  const y = 102 - barHeight;
                  const isFastest = hasWinTimeData && sec === fastestWinTimeSec;
                  const barColor = !hasWinTimeData
                    ? 'rgba(255, 213, 79, 0.28)'
                    : isFastest
                      ? '#10B981'
                      : '#D97706';

                  return (
                    <g key={idx}>
                      <rect
                        x={x}
                        y={y}
                        width={barWidth}
                        height={barHeight}
                        rx={5}
                        fill={barColor}
                        stroke={
                          isFastest
                            ? '#34D399'
                            : hasWinTimeData
                              ? '#F59E0B'
                              : 'rgba(255, 213, 79, 0.45)'
                        }
                        strokeWidth={1}
                      />
                      <text
                        x={x + barWidth / 2}
                        y={y - 5}
                        textAnchor="middle"
                        fill={isFastest ? '#6EE7B7' : '#FFE082'}
                        fontSize="9.5"
                        fontWeight="bold"
                        fontFamily="monospace"
                      >
                        {sec}s
                      </text>
                      <text
                        x={x + barWidth / 2}
                        y={116}
                        textAnchor="middle"
                        fill="rgba(255,255,255,0.68)"
                        fontSize="9.5"
                        fontWeight="600"
                      >
                        {chartLabels[idx]}
                      </text>
                    </g>
                  );
                })}

                {/* Average Win Time Reference Line (when player has wins) */}
                {hasWinTimeData && averageWinTimeSec > 0 && (
                  <g>
                    <line
                      x1={32}
                      y1={102 - Math.min(82, (averageWinTimeSec / maxChartSec) * 82)}
                      x2={408}
                      y2={102 - Math.min(82, (averageWinTimeSec / maxChartSec) * 82)}
                      stroke="#FFD700"
                      strokeWidth={1.5}
                      strokeDasharray="5 3"
                    />
                  </g>
                )}
              </svg>
            </div>
          </div>

          {/* Right Column (5 Cols): Win Rate Donut & Career Highlights */}
          <div className="col-span-12 sm:col-span-5 p-3 sm:p-4 rounded-[14px] bg-[#0F172A]/90 border border-[#D4AF37]/35 flex flex-col justify-between gap-2.5">
            <div className="flex items-center gap-2">
              <Award size={16} className="text-[#FFD54F] shrink-0" />
              <h2 className="text-[#FFE082] text-xs sm:text-sm font-bold">
                Win Rate & Career Summary
              </h2>
            </div>

            <div className="flex items-center gap-3.5 my-auto">
              {/* SVG Donut Chart */}
              <div className="relative w-[92px] h-[92px] shrink-0 flex items-center justify-center">
                <svg viewBox="0 0 96 96" className="w-full h-full -rotate-90">
                  <circle
                    cx="48"
                    cy="48"
                    r={donutRadius}
                    fill="none"
                    stroke="rgba(255,255,255,0.1)"
                    strokeWidth="9"
                  />
                  <circle
                    cx="48"
                    cy="48"
                    r={donutRadius}
                    fill="none"
                    stroke="#10B981"
                    strokeWidth="9"
                    strokeLinecap="round"
                    strokeDasharray={`${winStrokeDash} ${donutCircumference}`}
                  />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center text-center">
                  <span className="text-white text-sm font-black tabular-nums leading-none">
                    {Math.round(winPercentage)}%
                  </span>
                  <span className="text-white/55 text-[9px] font-semibold mt-0.5">WIN RATE</span>
                </div>
              </div>

              {/* Career Details List */}
              <div className="flex-1 flex flex-col gap-1.5 text-xs">
                <div className="flex items-center justify-between border-b border-white/10 pb-1">
                  <span className="text-white/65">Sets United</span>
                  <span className="text-[#FFD54F] font-bold tabular-nums">{totalWins}</span>
                </div>
                <div className="flex items-center justify-between border-b border-white/10 pb-1">
                  <span className="text-white/65">Total Score</span>
                  <span className="text-[#10B981] font-bold tabular-nums">
                    {humanRecord.totalPoints.toLocaleString()} pts
                  </span>
                </div>
                <div className="flex items-center justify-between border-b border-white/10 pb-1">
                  <span className="text-white/65">Fastest Victory</span>
                  <span className="text-white font-bold tabular-nums">
                    {formatDurationSeconds(fastestWinTimeSec)}
                  </span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-white/65">Last United</span>
                  <span className="text-[#FFE082] font-bold truncate max-w-[110px]">
                    {lastCountryMeta ? lastCountryMeta.displayName : 'None Yet'}
                  </span>
                </div>
              </div>
            </div>

            <div className="pt-1 border-t border-white/10 flex items-center justify-between text-[10.5px] text-white/60">
              <span className="flex items-center gap-1">
                <Zap size={12} className="text-[#FFD54F]" />
                Last Round Bonus
              </span>
              <span className="tabular-nums font-semibold text-white/85">
                +{humanRecord.lastRoundPoints} pts
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
