import React, { useState } from 'react';
import { CheckCircle2, Globe, HelpCircle, PlayCircle, Settings, Trophy } from 'lucide-react';
import { BilingualRulesDialog, PlayerStatsOverlay } from '../components/Overlays';

interface MainMenuScreenProps {
  onPlayGame: () => void;
  onOpenSettings: () => void;
}

export const MainMenuScreen: React.FC<MainMenuScreenProps> = ({
  onPlayGame,
  onOpenSettings,
}) => {
  const [showRules, setShowRules] = useState(false);
  const [showStats, setShowStats] = useState(false);

  return (
    <div
      style={{
        background: 'radial-gradient(circle at center, #0F3B2C 0%, #09251B 55%, #03140E 100%)',
      }}
      className="relative w-full h-full flex items-center justify-center p-4 sm:p-8 overflow-y-auto"
    >
      <div className="w-full max-w-[820px] grid grid-cols-1 md:grid-cols-21 gap-6 md:gap-9 items-center">
        {/* Left Column: Brand Crest, Title, Tagline, Offline Badge */}
        <div className="md:col-span-11 flex flex-col items-center text-center">
          {/* App Logo */}
          <div
            style={{
              background: 'radial-gradient(circle, #1E293B 0%, #0F172A 100%)',
              boxShadow: '0 0 20px 2px rgba(255, 215, 0, 0.3)',
            }}
            className="relative w-22 h-22 sm:w-24 sm:h-24 rounded-full border-[2.5px] border-[#FFD700] flex items-center justify-center mb-3.5"
          >
            <div className="absolute w-8 h-12 rounded bg-[#D97706] border border-[#FFD700] -rotate-12" />
            <div className="absolute w-8 h-12 rounded bg-[#2563EB] border border-[#FFD700] rotate-12" />
            <div className="relative w-8.5 h-13.5 rounded bg-[#0F172A] border-[1.5px] border-[#FFD700] shadow-md flex items-center justify-center">
              <Globe size={20} className="text-[#38BDF8]" />
            </div>
          </div>

          <h1
            style={{ textShadow: '0 3px 10px rgba(0,0,0,0.85)' }}
            className="text-[#FFD700] text-2xl sm:text-[28px] font-black tracking-[3px]"
          >
            COUNTRY GAME
          </h1>

          <p className="mt-1.5 text-[#FFE082] text-xs sm:text-[12.5px] font-medium leading-relaxed max-w-sm">
            Unite the Nations: Collect all cards of a country to conquer the round!
          </p>

          <div className="mt-3.5 flex items-center gap-1.5 text-white/60 text-[11px]">
            <CheckCircle2 size={15} className="text-[#10B981]" />
            <span>100% Offline • No Network Required</span>
          </div>
        </div>

        {/* Right Column: Primary Navigation & Overlays */}
        <div className="md:col-span-10 flex flex-col gap-3">
          <button
            onClick={onPlayGame}
            style={{ boxShadow: '0 6px 16px rgba(217, 119, 6, 0.45)' }}
            className="w-full py-3.5 rounded-[14px] bg-[#D97706] hover:bg-[#B45309] text-white font-black text-base tracking-[1.5px] flex items-center justify-center gap-2.5 transition cursor-pointer"
          >
            <PlayCircle size={24} />
            PLAY GAME
          </button>

          <button
            onClick={() => setShowRules(true)}
            className="w-full py-3 rounded-[12px] border-[1.2px] border-[#D4AF37] text-[#FFE082] hover:bg-[#D4AF37]/10 font-bold text-xs tracking-wider flex items-center justify-center gap-2 transition cursor-pointer"
          >
            <HelpCircle size={18} />
            HOW TO PLAY & RULES
          </button>

          <button
            onClick={onOpenSettings}
            className="w-full py-2.5 rounded-[12px] border border-white/25 text-white/75 hover:text-white hover:bg-white/5 font-bold text-xs tracking-wider flex items-center justify-center gap-2 transition cursor-pointer"
          >
            <Settings size={18} />
            SETTINGS
          </button>

          <button
            onClick={() => setShowStats(true)}
            className="w-full py-2 text-[#FFE082] hover:underline font-bold text-xs tracking-wider flex items-center justify-center gap-2 cursor-pointer"
          >
            <Trophy size={18} className="text-[#FFD54F]" />
            PLAYER STATS & SETS
          </button>
        </div>
      </div>

      {showRules && <BilingualRulesDialog onClose={() => setShowRules(false)} />}
      {showStats && <PlayerStatsOverlay onClose={() => setShowStats(false)} />}
    </div>
  );
};
