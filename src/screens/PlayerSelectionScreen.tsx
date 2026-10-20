import React, { useState } from 'react';
import { ArrowLeft, Globe, Play, Shuffle } from 'lucide-react';
import { CountryCardView } from '../components/CountryCardView';
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
  ];

  return (
    <div
      style={{
        background: 'radial-gradient(circle at center, #0F3B2C 0%, #09251B 55%, #03140E 100%)',
      }}
      className="w-full h-full flex items-center justify-center p-3 sm:p-5 overflow-y-auto"
    >
      <div className="w-full max-w-[780px] flex flex-col justify-between gap-2.5 sm:gap-3.5">
        {/* 1. Top Header */}
        <div className="flex items-center justify-between">
          <button
            onClick={onBack}
            className="w-10 h-10 rounded-full flex items-center justify-center text-[#FFD54F] hover:bg-white/10 cursor-pointer"
          >
            <ArrowLeft size={22} />
          </button>

          <div className="text-center">
            <div className="flex items-center justify-center gap-2.5 flex-wrap">
              <span className="text-[#FFD700] text-base sm:text-[17px] font-black tracking-wider">
                Select Players
              </span>
              <span className="px-2 py-0.5 rounded bg-[#FFD700]/15 border border-[#FFD700]/45 text-[#FFE082] text-[9.5px] font-black tracking-wider">
                TOTAL PLAYERS & WINNING SET
              </span>
            </div>
            <div className="text-white/80 text-[11px] mt-0.5">
              Win by collecting {selectedPlayers} cards of the same country (
              {selectedPlayers * selectedPlayers} country cards in deck)
            </div>
          </div>

          <div className="w-10 h-10" />
        </div>

        {/* 2. Player Count Selector Row */}
        <div className="grid grid-cols-4 gap-2 sm:gap-2.5">
          {playerOptions.map((opt) => {
            const isSelected = selectedPlayers === opt.count;
            return (
              <button
                key={opt.count}
                onClick={() => handlePlayerCountChange(opt.count)}
                style={{
                  boxShadow: isSelected ? '0 0 12px 1px rgba(255, 215, 0, 0.25)' : 'none',
                }}
                className={`py-2 px-2 rounded-xl border transition flex flex-col items-center justify-center cursor-pointer ${
                  isSelected
                    ? 'bg-[#0F172A]/95 border-2 border-[#FFD700]'
                    : 'bg-black/35 border border-white/15 hover:border-white/30'
                }`}
              >
                <span
                  className={`text-xl sm:text-[22px] font-black leading-none ${
                    isSelected ? 'text-[#FFD700]' : 'text-white'
                  }`}
                >
                  {opt.count}
                </span>
                <span
                  className={`text-[11px] font-bold mt-1 ${
                    isSelected ? 'text-[#FFE082]' : 'text-white/75'
                  }`}
                >
                  {opt.title}
                </span>
                <span className="text-white/60 text-[9px]">{opt.subtitle}</span>
              </button>
            );
          })}
        </div>

        {/* 3. Active Countries Header Bar */}
        <div className="px-3.5 py-2 rounded-[10px] bg-black/35 border border-[#D4AF37]/40 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Globe size={17} className="text-[#FFD54F]" />
            <span className="text-[#FFE082] text-xs font-bold">
              Active Countries ({activeTypes.length})
            </span>
          </div>
          <button
            onClick={handleReroll}
            className="flex items-center gap-1.5 px-2.5 py-1 rounded text-[#FFD54F] hover:bg-white/10 text-[11px] font-bold cursor-pointer"
          >
            <Shuffle size={14} />
            Reroll Set
          </button>
        </div>

        {/* 4. Country Card Preview Stage */}
        <div className="min-h-[132px] sm:min-h-[148px] flex items-center justify-center gap-3 overflow-x-auto py-1">
          {activeTypes.map((type) => (
            <div key={type} className="flex flex-col items-center gap-1 shrink-0">
              <CountryCardView
                card={{ id: `preview_${type}`, type, isStartingCard: false }}
                width={52}
                height={104}
              />
              <span className="text-[#FFE082] text-[9.5px] font-bold">
                {COUNTRY_METADATA[type].shortCode}
              </span>
            </div>
          ))}
        </div>

        {/* 5. Start Game Button */}
        <button
          onClick={handleStart}
          style={{ boxShadow: '0 6px 16px rgba(217, 119, 6, 0.45)' }}
          className="w-full py-3 rounded-xl bg-[#D97706] hover:bg-[#B45309] text-white font-black text-sm sm:text-[15px] tracking-[1.5px] flex items-center justify-center gap-2 cursor-pointer"
        >
          <Play size={20} />
          START GAME
        </button>
      </div>
    </div>
  );
};
