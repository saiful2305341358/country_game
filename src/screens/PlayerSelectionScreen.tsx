import React, { useState } from 'react';
import { ArrowLeft, Globe, Play, Shuffle } from 'lucide-react';
import { CountryCardView } from '../components/CountryCardView';
import { GameLogo } from '../components/GameLogo';
import { selectActiveTypes } from '../game/gameLogic';
import { COUNTRY_METADATA, CountryType } from '../models/types';
import { AudioService, HapticService } from '../services/soundSynthesizer';

interface PlayerSelectionScreenProps {
  onBack: () => void;
  onStartGame: (totalPlayers: number, activeTypes: CountryType[]) => void;
}

export const PlayerSelectionScreen: React.FC<PlayerSelectionScreenProps> = ({
  onBack,
  onStartGame,
}) => {
  const [selectedPlayers, setSelectedPlayers] = useState<number>(4);
  const [activeTypes, setActiveTypes] = useState<CountryType[]>(() => selectActiveTypes(4));

  const handlePlayerCountChange = (count: number) => {
    if (count === selectedPlayers) return;
    AudioService.playButtonClick();
    HapticService.uiTap();
    setSelectedPlayers(count);
    setActiveTypes(selectActiveTypes(count));
  };

  const handleReroll = () => {
    AudioService.playButtonClick();
    HapticService.uiTap();
    setActiveTypes(selectActiveTypes(selectedPlayers));
  };

  const handleStart = () => {
    AudioService.playButtonClick();
    HapticService.uiTap();
    onStartGame(selectedPlayers, activeTypes);
  };

  const playerOptions = [
    { count: 3, title: '3 Players', subtitle: 'Win Set: 3× Cards' },
    { count: 4, title: '4 Players', subtitle: 'Win Set: 4× Cards' },
    { count: 5, title: '5 Players', subtitle: 'Win Set: 5× Cards' },
    { count: 6, title: '6 Players', subtitle: 'Win Set: 6× Cards' },
    { count: 7, title: '7 Players', subtitle: 'Win Set: 7× Cards' },
  ];

  return (
    <div
      style={{
        background: 'radial-gradient(circle at center, #0F3B2C 0%, #09251B 55%, #03140E 100%)',
        paddingTop: 'max(0.45rem, env(safe-area-inset-top))',
        paddingBottom: 'max(0.45rem, env(safe-area-inset-bottom))',
        paddingLeft: 'max(0.75rem, env(safe-area-inset-left))',
        paddingRight: 'max(0.75rem, env(safe-area-inset-right))',
      }}
      className="w-full h-full flex items-center justify-center p-2 sm:p-5 overflow-y-auto select-none"
    >
      <div className="w-full max-w-[780px] flex flex-col justify-between gap-1.5 sm:gap-3 my-auto">
        {/* 1. Top Header */}
        <div className="flex items-center justify-between">
          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              onBack();
            }}
            className="w-9 h-9 sm:w-10 sm:h-10 rounded-full flex items-center justify-center text-[#FFD54F] hover:bg-white/10 cursor-pointer"
          >
            <ArrowLeft size={20} />
          </button>

          <div className="text-center">
            <div className="flex items-center justify-center gap-2 flex-wrap">
              <GameLogo size={24} withGlow={false} />
              <span className="text-[#FFD700] text-sm sm:text-[17px] font-black tracking-wider">
                Select Players
              </span>
              <span className="px-2 py-0.5 rounded bg-[#FFD700]/15 border border-[#FFD700]/45 text-[#FFE082] text-[9px] sm:text-[9.5px] font-black tracking-wider">
                TOTAL PLAYERS & WINNING SET
              </span>
            </div>
            <div className="text-white/80 text-[10.5px] sm:text-[11px] mt-0.5">
              Win by collecting {selectedPlayers} cards of the same country (
              {selectedPlayers * selectedPlayers} country cards in deck)
            </div>
          </div>

          <div className="w-9 h-9 sm:w-10 sm:h-10" />
        </div>

        {/* 2. Player Count Selector Row */}
        <div className="grid grid-cols-5 gap-1.5 sm:gap-2.5">
          {playerOptions.map((opt) => {
            const isSelected = selectedPlayers === opt.count;
            return (
              <button
                key={opt.count}
                onClick={() => handlePlayerCountChange(opt.count)}
                style={{
                  boxShadow: isSelected ? '0 0 12px 1px rgba(255, 215, 0, 0.25)' : 'none',
                }}
                className={`py-1.5 sm:py-2 px-1.5 sm:px-2 rounded-xl border transition flex flex-col items-center justify-center cursor-pointer ${
                  isSelected
                    ? 'bg-[#0F172A]/95 border-2 border-[#FFD700]'
                    : 'bg-black/35 border border-white/15 hover:border-white/30'
                }`}
              >
                <span
                  className={`text-lg sm:text-[22px] font-black leading-none ${
                    isSelected ? 'text-[#FFD700]' : 'text-white'
                  }`}
                >
                  {opt.count}
                </span>
                <span
                  className={`text-[10.5px] sm:text-[11px] font-bold mt-0.5 sm:mt-1 ${
                    isSelected ? 'text-[#FFE082]' : 'text-white/75'
                  }`}
                >
                  {opt.title}
                </span>
                <span className="text-white/60 text-[8.5px] sm:text-[9px]">{opt.subtitle}</span>
              </button>
            );
          })}
        </div>

        {/* 3. Active Countries Header Bar */}
        <div className="px-3 py-1.5 sm:py-2 rounded-[10px] bg-black/35 border border-[#D4AF37]/40 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Globe size={16} className="text-[#FFD54F]" />
            <span className="text-[#FFE082] text-[11.5px] sm:text-xs font-bold">
              Active Countries ({activeTypes.length})
            </span>
          </div>
          <button
            onClick={handleReroll}
            className="flex items-center gap-1.5 px-2.5 py-0.5 sm:py-1 rounded text-[#FFD54F] hover:bg-white/10 text-[11px] font-bold cursor-pointer"
          >
            <Shuffle size={13} />
            Reroll Set
          </button>
        </div>

        {/* 4. Country Card Preview Stage (Fixed height so 3..7 players never shifts START GAME) */}
        <div className="h-[112px] sm:h-[136px] flex items-center justify-center gap-2 sm:gap-3 overflow-x-auto py-0.5">
          {activeTypes.map((type) => (
            <div key={type} className="flex flex-col items-center gap-0.5 shrink-0">
              <CountryCardView
                card={{ id: `preview_${type}`, type, isStartingCard: false }}
                width={44}
                height={88}
              />
              <span className="text-[#FFE082] text-[9px] font-bold">
                {COUNTRY_METADATA[type].shortCode}
              </span>
            </div>
          ))}
        </div>

        {/* 5. Start Game Button */}
        <button
          onClick={handleStart}
          style={{ boxShadow: '0 6px 16px rgba(217, 119, 6, 0.45)' }}
          className="w-full py-2.5 sm:py-3 rounded-xl bg-[#D97706] hover:bg-[#B45309] active:scale-[0.99] text-white font-black text-sm sm:text-[15px] tracking-[1.5px] flex items-center justify-center gap-2 cursor-pointer transition"
        >
          <Play size={19} />
          START GAME
        </button>
      </div>
    </div>
  );
};
