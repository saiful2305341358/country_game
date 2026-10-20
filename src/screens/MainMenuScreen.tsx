import React, { useState } from 'react';
import { CheckCircle2, HelpCircle, PlayCircle, Settings, Trophy } from 'lucide-react';
import { GameLogo } from '../components/GameLogo';
import { BilingualRulesDialog, PlayerStatsOverlay } from '../components/Overlays';
import { AudioService, HapticService } from '../services/soundSynthesizer';

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
        paddingTop: 'max(0.65rem, env(safe-area-inset-top))',
        paddingBottom: 'max(0.65rem, env(safe-area-inset-bottom))',
        paddingLeft: 'max(1rem, env(safe-area-inset-left))',
        paddingRight: 'max(1rem, env(safe-area-inset-right))',
      }}
      className="relative w-full h-full flex items-center justify-center p-3 sm:p-6 overflow-y-auto select-none"
    >
      <div className="w-full max-w-[820px] grid grid-cols-12 gap-4 sm:gap-8 items-center my-auto">
        {/* Left Column: Brand Crest, Title, Tagline, Offline Badge */}
        <div className="col-span-6 flex flex-col items-center text-center">
          {/* Responsive Official Game Logo */}
          <div className="mb-2 sm:mb-3.5 flex items-center justify-center">
            <GameLogo
              size={96}
              className="w-[74px] h-[74px] sm:w-[96px] sm:h-[96px]"
              ariaLabel="Country Card Game Emblem"
            />
          </div>

          <h1
            style={{ textShadow: '0 3px 10px rgba(0,0,0,0.85)' }}
            className="text-[#FFD700] text-xl sm:text-[28px] font-black tracking-[2.5px] sm:tracking-[3px] leading-tight"
          >
            COUNTRY GAME
          </h1>

          <p className="mt-1 sm:mt-1.5 text-[#FFE082] text-[11px] sm:text-[12.5px] font-medium leading-snug max-w-sm">
            Unite the Nations: Collect all cards of a country to conquer the round!
          </p>

          <div className="mt-2 sm:mt-3.5 flex items-center gap-1.5 text-white/60 text-[10.5px] sm:text-[11px]">
            <CheckCircle2 size={14} className="text-[#10B981] shrink-0" />
            <span className="truncate">100% Offline • No Network Required</span>
          </div>
        </div>

        {/* Right Column: Primary Navigation & Overlays */}
        <div className="col-span-6 flex flex-col gap-2 sm:gap-3">
          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              onPlayGame();
            }}
            style={{ boxShadow: '0 6px 16px rgba(217, 119, 6, 0.45)' }}
            className="w-full py-2.5 sm:py-3.5 rounded-[14px] bg-[#D97706] hover:bg-[#B45309] active:scale-[0.99] text-white font-black text-sm sm:text-base tracking-[1.5px] flex items-center justify-center gap-2 sm:gap-2.5 transition cursor-pointer"
          >
            <PlayCircle size={22} />
            PLAY GAME
          </button>

          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              setShowRules(true);
            }}
            className="w-full py-2 sm:py-3 rounded-[12px] border-[1.2px] border-[#D4AF37] text-[#FFE082] hover:bg-[#D4AF37]/10 active:scale-[0.99] font-bold text-[11.5px] sm:text-xs tracking-wider flex items-center justify-center gap-2 transition cursor-pointer"
          >
            <HelpCircle size={17} />
            HOW TO PLAY & RULES
          </button>

          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              onOpenSettings();
            }}
            className="w-full py-2 sm:py-2.5 rounded-[12px] border border-white/25 text-white/75 hover:text-white hover:bg-white/5 active:scale-[0.99] font-bold text-[11.5px] sm:text-xs tracking-wider flex items-center justify-center gap-2 transition cursor-pointer"
          >
            <Settings size={17} />
            SETTINGS
          </button>

          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              setShowStats(true);
            }}
            className="w-full py-1.5 sm:py-2 text-[#FFE082] hover:underline font-bold text-[11.5px] sm:text-xs tracking-wider flex items-center justify-center gap-2 cursor-pointer"
          >
            <Trophy size={17} className="text-[#FFD54F]" />
            PLAYER STATS & SETS
          </button>
        </div>
      </div>

      {showRules && <BilingualRulesDialog onClose={() => setShowRules(false)} />}
      {showStats && <PlayerStatsOverlay onClose={() => setShowStats(false)} />}
    </div>
  );
};
