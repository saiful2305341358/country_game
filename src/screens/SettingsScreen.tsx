import React from 'react';
import {
  ArrowLeft,
  Gauge,
  RotateCcw,
  Sparkles,
  Vibrate,
  Volume2,
  VolumeX,
} from 'lucide-react';
import { DEFAULT_GAME_SETTINGS, GameSettings } from '../models/types';
import { AudioService, HapticService } from '../services/soundSynthesizer';

interface SettingsScreenProps {
  settings: GameSettings;
  onUpdateSettings: (newSettings: GameSettings) => void;
  onBack: () => void;
}

export const SettingsScreen: React.FC<SettingsScreenProps> = ({
  settings,
  onUpdateSettings,
  onBack,
}) => {
  const toggleSound = () => {
    const next = !settings.soundEnabled;
    AudioService.isSoundEnabled = next;
    onUpdateSettings({ ...settings, soundEnabled: next });
    HapticService.uiTap();
    if (next) {
      AudioService.playCardTap();
    }
  };

  const toggleHaptics = () => {
    const next = !settings.hapticsEnabled;
    HapticService.isHapticsEnabled = next;
    onUpdateSettings({ ...settings, hapticsEnabled: next });
    if (next) {
      HapticService.cardPass();
    }
  };

  const toggleAnimations = () => {
    const next = !settings.animationsEnabled;
    onUpdateSettings({ ...settings, animationsEnabled: next });
    AudioService.playButtonClick();
    HapticService.uiTap();
  };

  const setBotDelay = (ms: number) => {
    AudioService.playButtonClick();
    HapticService.uiTap();
    onUpdateSettings({ ...settings, botDelayMs: ms });
  };

  const resetDefaults = () => {
    AudioService.isSoundEnabled = true;
    HapticService.isHapticsEnabled = true;
    onUpdateSettings({ ...DEFAULT_GAME_SETTINGS, totalPlayers: settings.totalPlayers });
    AudioService.playButtonClick();
    HapticService.uiTap();
  };

  const paceOptions = [
    { label: 'Fast', ms: 1100 },
    { label: 'Normal', ms: 1650 },
    { label: 'Relaxed', ms: 2300 },
  ];

  return (
    <div
      style={{
        background: 'radial-gradient(circle at center, #0F3B2C 0%, #09251B 55%, #03140E 100%)',
        paddingTop: 'max(0.5rem, env(safe-area-inset-top))',
        paddingBottom: 'max(0.5rem, env(safe-area-inset-bottom))',
        paddingLeft: 'max(0.75rem, env(safe-area-inset-left))',
        paddingRight: 'max(0.75rem, env(safe-area-inset-right))',
      }}
      className="w-full h-full flex items-center justify-center p-2.5 sm:p-6 overflow-y-auto select-none"
    >
      <div className="w-full max-w-[820px] flex flex-col gap-2.5 sm:gap-3.5 my-auto">
        {/* Top Header */}
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
          <h1 className="text-[#FFD700] text-base sm:text-lg font-bold tracking-wider">Settings</h1>
          <div className="w-9 h-9 sm:w-10 sm:h-10" />
        </div>

        {/* Two-Column Landscape Cards */}
        <div className="grid grid-cols-2 gap-2.5 sm:gap-3.5">
          {/* Left Card: Audio & Haptics */}
          <div className="p-3 sm:p-4 rounded-[14px] bg-[#0F172A]/85 border border-[#D4AF37]/30 flex flex-col gap-2.5 sm:gap-3">
            <div className="text-[#FFE082] text-[11px] font-black tracking-[1.5px]">
              AUDIO & HAPTICS
            </div>

            <div className="flex items-center justify-between gap-3">
              <div className="flex items-start gap-2.5">
                {settings.soundEnabled ? (
                  <Volume2 size={20} className="text-[#FFD54F] shrink-0 mt-0.5" />
                ) : (
                  <VolumeX size={20} className="text-[#FFD54F] shrink-0 mt-0.5" />
                )}
                <div>
                  <div className="text-white text-xs font-semibold">Gameplay Sound Effects</div>
                  <div className="text-white/60 text-[10px]">
                    Soft wooden taps, subtle card slides, and victory chimes during matches
                  </div>
                </div>
              </div>
              <button
                onClick={toggleSound}
                className={`px-3 py-1 rounded-full text-xs font-bold transition cursor-pointer ${
                  settings.soundEnabled
                    ? 'bg-[#FFD54F] text-[#0F172A]'
                    : 'bg-white/15 text-white/60'
                }`}
              >
                {settings.soundEnabled ? 'ON' : 'OFF'}
              </button>
            </div>

            <div className="border-t border-white/10" />

            <div className="flex items-center justify-between gap-3">
              <div className="flex items-start gap-2.5">
                <Vibrate size={20} className="text-[#FFD54F] shrink-0 mt-0.5" />
                <div>
                  <div className="text-white text-xs font-semibold">Tactile Haptic Feedback</div>
                  <div className="text-white/60 text-[10px]">
                    Physical vibration responses for card taps, turn alerts, and victory events
                  </div>
                </div>
              </div>
              <button
                onClick={toggleHaptics}
                className={`px-3 py-1 rounded-full text-xs font-bold transition cursor-pointer ${
                  settings.hapticsEnabled
                    ? 'bg-[#FFD54F] text-[#0F172A]'
                    : 'bg-white/15 text-white/60'
                }`}
              >
                {settings.hapticsEnabled ? 'ON' : 'OFF'}
              </button>
            </div>
          </div>

          {/* Right Card: Display & Gameplay */}
          <div className="p-4 rounded-[14px] bg-[#0F172A]/85 border border-[#D4AF37]/30 flex flex-col gap-3">
            <div className="text-[#FFE082] text-[11px] font-black tracking-[1.5px]">
              DISPLAY & GAMEPLAY
            </div>

            <div className="flex items-center justify-between gap-3">
              <div className="flex items-start gap-2.5">
                <Sparkles size={20} className="text-[#FFD54F] shrink-0 mt-0.5" />
                <div>
                  <div className="text-white text-xs font-semibold">Smooth Animations</div>
                  <div className="text-white/60 text-[10px]">
                    Initial card dealing animation and 2D card passing trajectories
                  </div>
                </div>
              </div>
              <button
                onClick={toggleAnimations}
                className={`px-3 py-1 rounded-full text-xs font-bold transition cursor-pointer ${
                  settings.animationsEnabled
                    ? 'bg-[#FFD54F] text-[#0F172A]'
                    : 'bg-white/15 text-white/60'
                }`}
              >
                {settings.animationsEnabled ? 'ON' : 'OFF'}
              </button>
            </div>

            <div className="border-t border-white/10" />

            <div>
              <div className="flex items-center gap-2.5 mb-2">
                <Gauge size={20} className="text-[#FFD54F]" />
                <div>
                  <div className="text-white text-xs font-semibold">Bot Thinking Pace</div>
                  <div className="text-[#FFD54F] text-[10.5px]">
                    {settings.botDelayMs <= 1100
                      ? 'Fast (1100ms)'
                      : settings.botDelayMs <= 1650
                        ? 'Normal (1650ms)'
                        : 'Relaxed (2300ms)'}
                  </div>
                </div>
              </div>

              <div className="grid grid-cols-3 gap-2">
                {paceOptions.map((opt) => {
                  const isSelected = settings.botDelayMs === opt.ms;
                  return (
                    <button
                      key={opt.ms}
                      onClick={() => setBotDelay(opt.ms)}
                      className={`py-1.5 rounded-lg text-[11px] font-bold border transition cursor-pointer ${
                        isSelected
                          ? 'bg-[#D97706] border-[#FFD700] text-white'
                          : 'bg-white/[0.08] border-white/10 text-white/70 hover:text-white'
                      }`}
                    >
                      {opt.label}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Reset Defaults Button */}
        <button
          onClick={resetDefaults}
          className="w-full py-2.5 rounded-[10px] border border-white/25 text-white/75 hover:text-white hover:bg-white/5 text-xs font-semibold flex items-center justify-center gap-2 cursor-pointer"
        >
          <RotateCcw size={16} />
          Reset All Settings to Default
        </button>
      </div>
    </div>
  );
};
