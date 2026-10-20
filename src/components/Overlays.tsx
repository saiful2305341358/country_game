import React, { useEffect, useRef, useState } from 'react';
import {
  Award,
  BookOpen,
  Check,
  CheckCircle2,
  Globe,
  HelpCircle,
  Home,
  Lightbulb,
  LogOut,
  PauseCircle,
  Play,
  RefreshCw,
  RotateCcw,
  Sparkles,
  Trophy,
  Users,
  Vibrate,
  Volume2,
  VolumeX,
  X,
  ArrowLeftRight,
  Layers,
  Gamepad2,
} from 'lucide-react';
import {
  COUNTRY_METADATA,
  CountryType,
  GamePlayer,
  getPlayerOrdinaryTypeCounts,
} from '../models/types';
import { AudioService, HapticService } from '../services/soundSynthesizer';
import {
  computeRoundPoints,
  PlayerStatsRecord,
  StatsService,
} from '../services/statsService';
import { CountryCardView } from './CountryCardView';
import { AvatarSvg } from './PlayerSeat';

// 1. Bilingual How to Play & Rules Dialog
export const BilingualRulesDialog: React.FC<{ onClose: () => void }> = ({ onClose }) => {
  const [isBangla, setIsBangla] = useState(false);

  const englishRules = [
    {
      icon: <Trophy size={18} className="text-[#FFD54F] shrink-0" />,
      title: '1. Core Goal — Unite One Country',
      body: 'Your mission is to collect a complete set of cards belonging to a single country. As soon as any player holds all cards of a single country, they are declared the sole winner and the game immediately ends!',
    },
    {
      icon: <Users size={18} className="text-[#FFD54F] shrink-0" />,
      title: '2. Dynamic Difficulty (Player-Based Set Size)',
      body: 'The number of cards required to win matches the total number of players at the table (N):\n• 3 Players → Collect 3 cards of the same country (9 country cards total)\n• 4 Players → Collect 4 cards of the same country (16 country cards total)\n• 5 Players → Collect 5 cards of the same country (25 country cards total)\n• 6 Players → Collect 6 cards of the same country (36 country cards total)\n• 7 Players → Collect 7 cards of the same country (49 country cards total)',
    },
    {
      icon: <Globe size={18} className="text-[#FFD54F] shrink-0" />,
      title: "3. Balanced Deal & 'Global' Starter Card",
      body: "At the start of every round, cards are shuffled and dealt so every player begins with a balanced hand containing 1 card of each active country. The special 'Global' card begins on the center table. It acts as a neutral bridge card that can be passed freely, but does not count toward any country's winning set.",
    },
    {
      icon: <ArrowLeftRight size={18} className="text-[#FFD54F] shrink-0" />,
      title: '4. Turn Order & Card Passing Flow',
      body: "• A randomly chosen player starts by taking the 'Global' card from the table and passing 1 card from their hand onto the table.\n• Turns move sequentially around the table. On your turn, you pick up the face-up table card and discard 1 card from your hand.\n• Same-Type Restriction: You cannot discard a card of the exact same country that is currently on the table.",
    },
  ];

  const banglaRules = [
    {
      icon: <Trophy size={18} className="text-[#FFD54F] shrink-0" />,
      title: '১. মূল লক্ষ্য — একটি দেশের সব কার্ড সংগ্রহ',
      body: 'খেলার মূল উদ্দেশ্য হলো যেকোনো একটি দেশের সম্পূর্ণ কার্ড সেট নিজের হাতে মেলানো। যেকোনো একজন খেলোয়াড় একটি দেশের সব কার্ড একত্রিত করামাত্রই একক বিজয়ী ঘোষিত হবেন এবং খেলাটি সাথে সাথেই শেষ হয়ে যাবে।',
    },
    {
      icon: <Users size={18} className="text-[#FFD54F] shrink-0" />,
      title: '২. গতিশীল চ্যালেঞ্জ (খেলোয়াড় সংখ্যা অনুযায়ী জয়ের শর্ত)',
      body: 'জয়ের জন্য কয়টি একই দেশের কার্ড লাগবে তা নির্ভর করে মোট খেলোয়াড় সংখ্যার (N) ওপর:\n• ৩ জন খেলোয়াড় → একই দেশের ৩টি কার্ড মেলাতে হবে (মোট ৯টি দেশ কার্ড)\n• ৪ জন খেলোয়াড় → একই দেশের ৪টি কার্ড মেলাতে হবে (মোট ১৬টি দেশ কার্ড)\n• ৫ জন খেলোয়াড় → একই দেশের ৫টি কার্ড মেলাতে হবে (মোট ২৫টি দেশ কার্ড)\n• ৬ জন খেলোয়াড় → একই দেশের ৬টি কার্ড মেলাতে হবে (মোট ৩৬টি দেশ কার্ড)\n• ৭ জন খেলোয়াড় → একই দেশের ৭টি কার্ড মেলাতে হবে (মোট ৪৯টি দেশ কার্ড)',
    },
    {
      icon: <Globe size={18} className="text-[#FFD54F] shrink-0" />,
      title: "৩. প্রাথমিক সুষম বণ্টন ও 'Global' স্টার্টার কার্ড",
      body: "খেলার শুরুতে কার্ডগুলো এমনভাবে ভাগ করা হয় যাতে প্রত্যেক খেলোয়াড়ের হাতে প্রতিটি সক্রিয় দেশের ১টি করে কার্ড থাকে। টেবিলের মাঝখানে বিশেষ 'Global' স্টার্টার কার্ডটি রাখা হয়। এটি যেকোনো সময় বিনিময় করা যায়, তবে এটি কোনো নির্দিষ্ট দেশের সেট পূরণে গণনা করা হয় না।",
    },
    {
      icon: <ArrowLeftRight size={18} className="text-[#FFD54F] shrink-0" />,
      title: '৪. খেলার ক্রম ও কার্ড আদান-প্রদান নিয়ম',
      body: "• লটারির মাধ্যমে নির্বাচিত প্রথম খেলোয়াড় টেবিল থেকে 'Global' কার্ডটি হাতে নেন এবং নিজের হাত থেকে যেকোনো ১টি কার্ড টেবিলে রাখেন।\n• এরপর পর্যায়ক্রমে প্রত্যেকের চাল আসে। আপনার চালে টেবিলের কার্ডটি হাতে তুলে নেবেন এবং হাত থেকে ১টি বৈধ কার্ড টেবিলে রাখবেন।\n• একই দেশের কার্ড নিষেধাজ্ঞা: টেবিলে যে দেশের কার্ডটি রয়েছে, সেই একই দেশের কার্ড সঙ্গে সঙ্গে টেবিলে ফেলা যাবে না।",
    },
  ];

  const rules = isBangla ? banglaRules : englishRules;

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-2.5 sm:p-4"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-[680px] max-h-[92%] bg-[#0F172A] border-[1.4px] border-[#D4AF37] rounded-[18px] p-3.5 sm:p-5 flex flex-col shadow-2xl"
      >
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2">
            <BookOpen size={22} className="text-[#FFD54F]" />
            <h2 className="text-[#FFD54F] text-base sm:text-lg font-extrabold">
              {isBangla ? 'খেলার নিয়মাবলী' : 'How to Play & Rules'}
            </h2>
          </div>

          <div className="flex items-center p-0.5 rounded-[10px] bg-black/40 border border-[#D4AF37]/50">
            <button
              onClick={() => setIsBangla(false)}
              className={`px-3 py-1 rounded-[7px] text-xs font-bold transition ${
                !isBangla ? 'bg-[#D97706] text-white' : 'text-white/70 hover:text-white'
              }`}
            >
              English
            </button>
            <button
              onClick={() => setIsBangla(true)}
              className={`px-3 py-1 rounded-[7px] text-xs font-bold transition ${
                isBangla ? 'bg-[#D97706] text-white' : 'text-white/70 hover:text-white'
              }`}
            >
              বাংলা
            </button>
          </div>
        </div>

        <div className="my-2.5 border-t border-white/10" />

        <div className="flex-1 overflow-y-auto space-y-2.5 pr-1">
          {rules.map((r, idx) => (
            <div
              key={idx}
              className="p-2.5 rounded-[10px] bg-white/[0.04] border border-white/10"
            >
              <div className="flex items-center gap-2 mb-1">
                {r.icon}
                <div className="text-[#FFE082] text-[13px] font-bold">{r.title}</div>
              </div>
              <div className="text-white/75 text-xs leading-relaxed whitespace-pre-line">
                {r.body}
              </div>
            </div>
          ))}
        </div>

        <div className="mt-3 flex justify-end">
          <button
            onClick={onClose}
            className="px-5 py-2 rounded-[10px] bg-[#D97706] hover:bg-[#B45309] text-white text-sm font-bold transition cursor-pointer"
          >
            {isBangla ? 'বুঝেছি!' : 'Got it!'}
          </button>
        </div>
      </div>
    </div>
  );
};

// 2. Player Stats & Sets Overlay
export const PlayerStatsOverlay: React.FC<{
  activePlayers?: GamePlayer[];
  targetSetSize?: number;
  onClose: () => void;
}> = ({ activePlayers, targetSetSize, onClose }) => {
  const [confirmReset, setConfirmReset] = useState(false);
  const [, setTick] = useState(0);

  useEffect(() => {
    return StatsService.subscribe(() => setTick((t) => t + 1));
  }, []);

  const records: PlayerStatsRecord[] = StatsService.getAllRecords(activePlayers);
  const activeByName = new Map<string, GamePlayer>();
  if (activePlayers) {
    for (const p of activePlayers) {
      activeByName.set(p.name, p);
    }
  }
  const humanRecord = records.find((r) => r.isHuman);
  const setSize = targetSetSize ?? activePlayers?.length ?? 4;

  const getBestHandProgress = (player: GamePlayer): { type: CountryType | null; count: number } => {
    let bestType: CountryType | null = null;
    let bestCount = 0;
    const counts = getPlayerOrdinaryTypeCounts(player);
    for (const [k, v] of Object.entries(counts)) {
      if ((v ?? 0) > bestCount) {
        bestCount = v ?? 0;
        bestType = k as CountryType;
      }
    }
    return { type: bestType, count: bestCount };
  };

  return (
    <div
      onClick={onClose}
      className="fixed inset-0 z-50 bg-black/75 flex items-center justify-center p-2.5 sm:p-5"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-[660px] max-h-[92%] bg-[#0F172A]/95 border-2 border-[#FFD700] rounded-[20px] p-3 sm:p-4 flex flex-col shadow-[0_0_28px_rgba(255,215,0,0.3)]"
      >
        {/* Header */}
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-full bg-gradient-to-br from-[#FFD54F] to-[#B45309] shadow">
              <Trophy size={18} className="text-[#1E1B4B]" />
            </div>
            <div>
              <div className="text-[#FFD700] text-sm sm:text-base font-black tracking-wider">
                PLAYER STATS & SETS COMPLETED
              </div>
              <div className="text-white/70 text-[11px] hidden sm:block">
                Games played and country sets completed per player
              </div>
            </div>
          </div>
          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              onClose();
            }}
            className="p-1.5 rounded-lg text-white/70 hover:text-white hover:bg-white/10 cursor-pointer"
          >
            <X size={20} />
          </button>
        </div>

        {/* Summary Metric Cards */}
        <div className="grid grid-cols-3 gap-2.5 my-3">
          <div className="p-2 rounded-xl bg-white/[0.06] border border-[#38BDF8]/35 text-center">
            <div className="flex items-center justify-center gap-1.5 text-[#38BDF8] font-black text-base">
              <Gamepad2 size={15} />
              <span>{StatsService.totalGamesPlayed}</span>
            </div>
            <div className="text-white/70 text-[9px] font-bold tracking-wider">GAMES PLAYED</div>
          </div>

          <div className="p-2 rounded-xl bg-white/[0.06] border border-[#FFD700]/35 text-center">
            <div className="flex items-center justify-center gap-1.5 text-[#FFD700] font-black text-base">
              <Trophy size={15} />
              <span>{StatsService.totalSetsCompleted}</span>
            </div>
            <div className="text-white/70 text-[9px] font-bold tracking-wider">
              TOTAL SETS COMPLETED
            </div>
          </div>

          <div className="p-2 rounded-xl bg-white/[0.06] border border-[#69F0AE]/35 text-center">
            <div className="flex items-center justify-center gap-1.5 text-[#69F0AE] font-black text-base">
              <Sparkles size={15} />
              <span>{humanRecord?.setsCompleted ?? 0}</span>
            </div>
            <div className="text-white/70 text-[9px] font-bold tracking-wider">YOUR SETS WON</div>
          </div>
        </div>

        {/* Column Headers */}
        <div className="grid grid-cols-12 px-3 text-[#FFE082] text-[10px] font-extrabold tracking-wider mb-1">
          <div className="col-span-5">PLAYER</div>
          <div className="col-span-2 text-center">GAMES</div>
          <div className="col-span-2 text-center">SETS WON</div>
          <div className="col-span-3 text-right">TOTAL POINTS</div>
        </div>

        {/* Player Rows */}
        <div className="flex-1 overflow-y-auto space-y-1.5 pr-1">
          {records.map((record) => {
            const livePlayer = activeByName.get(record.name);
            const progress = livePlayer ? getBestHandProgress(livePlayer) : { type: null, count: 0 };
            return (
              <div
                key={record.name}
                className={`grid grid-cols-12 items-center px-3 py-1.5 rounded-xl border ${
                  record.isHuman
                    ? 'bg-[#1E293B]/95 border-[#FFD700]/60'
                    : 'bg-white/[0.05] border-white/10'
                }`}
              >
                <div className="col-span-5 flex items-center gap-2.5 min-w-0">
                  <div
                    className={`w-8 h-8 rounded-full overflow-hidden border-2 shrink-0 ${
                      record.isHuman ? 'border-[#FFD700]' : 'border-[#BFE3A5]'
                    }`}
                  >
                    <AvatarSvg avatarIndex={record.avatarIndex} isMe={record.isHuman} size={30} />
                  </div>
                  <div className="min-w-0">
                    <div className="flex items-center gap-1.5">
                      <span
                        className={`text-xs sm:text-[13.5px] font-extrabold truncate ${
                          record.isHuman ? 'text-[#FFF176]' : 'text-white'
                        }`}
                      >
                        {record.name}
                      </span>
                      {record.isHuman && (
                        <span className="px-1.5 py-0.5 rounded bg-[#FFD700]/20 text-[#FFD700] text-[8.5px] font-black">
                          YOU
                        </span>
                      )}
                    </div>
                    {progress.type ? (
                      <div className="text-white/65 text-[10px] truncate">
                        In Hand: {progress.count}/{setSize}{' '}
                        {COUNTRY_METADATA[progress.type].displayName}
                      </div>
                    ) : record.lastCompletedCountry ? (
                      <div className="text-white/65 text-[10px] truncate">
                        Last Set: {COUNTRY_METADATA[record.lastCompletedCountry].displayName}
                      </div>
                    ) : null}
                  </div>
                </div>

                <div className="col-span-2 flex justify-center">
                  <span className="px-2.5 py-0.5 rounded-lg bg-white/[0.08] text-white text-xs font-bold">
                    {record.gamesPlayed}
                  </span>
                </div>

                <div className="col-span-2 flex justify-center">
                  <span
                    className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-lg border text-xs font-black ${
                      record.setsCompleted > 0
                        ? 'bg-[#FFD700]/20 border-[#FFD700]/65 text-[#FFF176]'
                        : 'bg-white/[0.06] border-white/10 text-white/70'
                    }`}
                  >
                    <Award
                      size={13}
                      className={record.setsCompleted > 0 ? 'text-[#FFD700]' : 'text-white/40'}
                    />
                    {record.setsCompleted}
                  </span>
                </div>

                <div className="col-span-3 flex justify-end">
                  <span
                    className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-lg border text-xs font-black ${
                      record.totalPoints > 0
                        ? 'bg-[#10B981]/20 border-[#34D399]/60 text-[#6EE7B7]'
                        : 'bg-white/[0.06] border-white/10 text-white/60'
                    }`}
                  >
                    <Sparkles
                      size={12}
                      className={record.totalPoints > 0 ? 'text-[#34D399]' : 'text-white/35'}
                    />
                    {record.totalPoints.toLocaleString()} pts
                  </span>
                </div>
              </div>
            );
          })}
        </div>

        {/* Footer Buttons */}
        <div className="mt-3 flex items-center gap-3">
          {!confirmReset ? (
            <button
              onClick={() => {
                AudioService.playButtonClick();
                HapticService.uiTap();
                setConfirmReset(true);
              }}
              className="flex items-center gap-1.5 px-3.5 py-2 rounded-[10px] border border-white/25 text-white/75 hover:text-white text-xs font-semibold cursor-pointer"
            >
              <RotateCcw size={15} />
              Reset Stats
            </button>
          ) : (
            <button
              onClick={() => {
                AudioService.playButtonClick();
                HapticService.uiTap();
                StatsService.resetStats(activePlayers);
                setConfirmReset(false);
              }}
              className="flex items-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-red-500 text-white text-xs font-bold cursor-pointer"
            >
              <Check size={15} />
              Confirm Reset
            </button>
          )}

          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              onClose();
            }}
            className="flex-1 py-2 rounded-[10px] bg-[#D97706] hover:bg-[#B45309] text-white text-xs sm:text-sm font-bold cursor-pointer"
          >
            Close Overlay
          </button>
        </div>
      </div>
    </div>
  );
};

// 3. Quick Tutorial Modal Overlay
export const TutorialModalOverlay: React.FC<{
  targetSetSize: number;
  onClose: () => void;
}> = ({ targetSetSize, onClose }) => {
  const handleDismiss = () => {
    StatsService.markTutorialSeen();
    AudioService.playButtonClick();
    HapticService.uiTap();
    onClose();
  };

  const steps = [
    {
      num: '1',
      icon: <ArrowLeftRight size={14} className="text-[#34D399]" />,
      accent: '#34D399',
      title: 'Tap a Card to Swap with the Table',
      desc: 'On your turn (golden glow), tap any legal card in your hand. Your card slides onto the table first, then the previous table card slides into your hand.',
    },
    {
      num: '2',
      icon: <Layers size={14} className="text-[#60A5FA]" />,
      accent: '#60A5FA',
      title: 'Different Country Swap Rule',
      desc: "You must play a different country than the card currently on the table. The special 'GLOBAL' Starting Card can always be swapped.",
    },
    {
      num: '3',
      icon: <Trophy size={14} className="text-[#FFD54F]" />,
      accent: '#FFD54F',
      title: `Collect ${targetSetSize} Matching Country Cards to Win`,
      desc: `Collect all ${targetSetSize} cards of the same country in your hand (excluding the 'GLOBAL' Starting Card) to immediately win the round!`,
    },
  ];

  return (
    <div
      onClick={handleDismiss}
      className="fixed inset-0 z-50 bg-black/55 flex items-center justify-center p-2.5 sm:p-3"
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: 'linear-gradient(135deg, rgba(15,41,30,0.96), rgba(9,27,20,0.97), rgba(7,19,14,0.98))',
        }}
        className="w-full max-w-[560px] max-h-[92%] overflow-y-auto rounded-[18px] border-[1.5px] border-[#FFD54F]/80 p-3 sm:p-4 shadow-2xl"
      >
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-[#FFD54F]/15 border border-[#FFD54F]/60 flex items-center justify-center">
              <Lightbulb size={17} className="text-[#FFD54F]" />
            </div>
            <div>
              <div className="text-[#FFE082] text-[13px] font-black tracking-wider">
                QUICK TUTORIAL • HOW TO PLAY
              </div>
              <div className="text-white/70 text-[10.5px]">
                Swap cards with the table & collect a full country set to win
              </div>
            </div>
          </div>
          <button
            onClick={handleDismiss}
            className="p-1 text-white/70 hover:text-white cursor-pointer"
          >
            <X size={19} />
          </button>
        </div>

        <div className="my-2 border-t border-white/10" />

        <div className="space-y-1.5">
          {steps.map((s) => (
            <div
              key={s.num}
              style={{ borderColor: `${s.accent}47` }}
              className="p-2 rounded-[10px] bg-white/[0.05] border flex items-start gap-2.5"
            >
              <div
                style={{
                  backgroundColor: `${s.accent}2E`,
                  borderColor: `${s.accent}A6`,
                  color: s.accent,
                }}
                className="w-6 h-6 rounded-md border flex items-center justify-center text-xs font-black shrink-0"
              >
                {s.num}
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  {s.icon}
                  <span className="text-white text-[11.5px] font-extrabold">{s.title}</span>
                </div>
                <div className="text-white/70 text-[10.5px] leading-snug mt-0.5">{s.desc}</div>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-3 flex items-center justify-between gap-2">
          <div className="flex items-center gap-1.5 text-white/55 text-[10px]">
            <HelpCircle size={14} />
            <span>Tap "?" anytime to reopen this guide</span>
          </div>
          <button
            onClick={handleDismiss}
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-[#D97706] hover:bg-[#B45309] text-white text-xs font-extrabold cursor-pointer"
          >
            <CheckCircle2 size={15} />
            {"Got It, Let's Play!"}
          </button>
        </div>
      </div>
    </div>
  );
};

// 4. Pause / Game Controls Dialog
export const GameControlsDialog: React.FC<{
  soundEnabled: boolean;
  hapticsEnabled: boolean;
  onSoundToggle: (val: boolean) => void;
  onHapticsToggle: (val: boolean) => void;
  onResume: () => void;
  onRestart: () => void;
  onMainMenu: () => void;
}> = ({
  soundEnabled,
  hapticsEnabled,
  onSoundToggle,
  onHapticsToggle,
  onResume,
  onRestart,
  onMainMenu,
}) => {
  const [confirmRestart, setConfirmRestart] = useState(false);
  const [confirmMainMenu, setConfirmMainMenu] = useState(false);

  return (
    <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-2.5 sm:p-4">
      <div className="w-full max-w-[540px] max-h-[92%] overflow-y-auto bg-[#0F172A]/96 border-[1.5px] border-[#D4AF37] rounded-[18px] p-4 sm:p-5 shadow-2xl">
        <div className="flex items-center justify-center gap-2 mb-3">
          <PauseCircle size={25} className="text-[#FFD54F]" />
          <span className="text-[#FFE082] text-lg font-black tracking-widest">GAME PAUSED</span>
        </div>

        <div className="grid grid-cols-2 gap-2.5 mb-3">
          <button
            onClick={() => {
              const next = !soundEnabled;
              HapticService.uiTap();
              onSoundToggle(next);
            }}
            className="flex items-center justify-between px-3 py-2.5 rounded-[10px] bg-white/[0.06] hover:bg-white/[0.1] cursor-pointer"
          >
            <div className="flex items-center gap-2 text-white text-xs font-semibold">
              {soundEnabled ? (
                <Volume2 size={18} className="text-[#FFD54F]" />
              ) : (
                <VolumeX size={18} className="text-[#FFD54F]" />
              )}
              <span>Sound Effects</span>
            </div>
            <span
              className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                soundEnabled ? 'bg-[#FFD54F] text-[#0F172A]' : 'bg-white/15 text-white/60'
              }`}
            >
              {soundEnabled ? 'ON' : 'OFF'}
            </span>
          </button>

          <button
            onClick={() => {
              const next = !hapticsEnabled;
              AudioService.playButtonClick();
              onHapticsToggle(next);
              if (next) {
                HapticService.cardTap();
              }
            }}
            className="flex items-center justify-between px-3 py-2.5 rounded-[10px] bg-white/[0.06] hover:bg-white/[0.1] cursor-pointer"
          >
            <div className="flex items-center gap-2 text-white text-xs font-semibold">
              <Vibrate size={18} className="text-[#FFD54F]" />
              <span>Haptic Feedback</span>
            </div>
            <span
              className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                hapticsEnabled ? 'bg-[#FFD54F] text-[#0F172A]' : 'bg-white/15 text-white/60'
              }`}
            >
              {hapticsEnabled ? 'ON' : 'OFF'}
            </span>
          </button>
        </div>

        <button
          onClick={() => {
            AudioService.playButtonClick();
            HapticService.uiTap();
            onResume();
          }}
          className="w-full py-2.5 rounded-[10px] bg-[#059669] hover:bg-[#047857] text-white font-bold flex items-center justify-center gap-2 mb-2.5 cursor-pointer"
        >
          <Play size={18} />
          Resume Game
        </button>

        {!confirmRestart && !confirmMainMenu && (
          <div className="grid grid-cols-2 gap-2.5">
            <button
              onClick={() => {
                AudioService.playButtonClick();
                HapticService.uiTap();
                setConfirmRestart(true);
              }}
              className="py-2 rounded-[10px] border border-[#FFD54F] text-[#FFD54F] text-xs font-bold flex items-center justify-center gap-1.5 hover:bg-[#FFD54F]/10 cursor-pointer"
            >
              <RefreshCw size={15} />
              Restart Match
            </button>
            <button
              onClick={() => {
                AudioService.playButtonClick();
                HapticService.uiTap();
                setConfirmMainMenu(true);
              }}
              className="py-2 rounded-[10px] text-white/75 hover:text-white text-xs font-bold flex items-center justify-center gap-1.5 hover:bg-white/5 cursor-pointer"
            >
              <Home size={15} />
              Exit to Main Menu
            </button>
          </div>
        )}

        {confirmRestart && (
          <div className="flex items-center justify-between px-3 py-2 rounded-[10px] bg-red-500/15 border border-red-400/50">
            <span className="text-white text-xs">Restart current game?</span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setConfirmRestart(false)}
                className="px-2.5 py-1 text-xs text-white/70 hover:text-white cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  AudioService.playButtonClick();
                  HapticService.cardPass();
                  onRestart();
                }}
                className="px-3 py-1 rounded bg-red-500 text-white text-xs font-bold cursor-pointer"
              >
                Yes, Restart
              </button>
            </div>
          </div>
        )}

        {confirmMainMenu && (
          <div className="flex items-center justify-between px-3 py-2 rounded-[10px] bg-amber-500/15 border border-amber-400/50">
            <span className="text-white text-xs">Leave game and return to menu?</span>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setConfirmMainMenu(false)}
                className="px-2.5 py-1 text-xs text-white/70 hover:text-white cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  AudioService.playButtonClick();
                  HapticService.uiTap();
                  onMainMenu();
                }}
                className="px-3 py-1 rounded bg-[#D97706] text-white text-xs font-bold cursor-pointer"
              >
                Exit
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// 4b. Dedicated Lightweight Exit Confirmation Dialog (Back Button Only)
export const ExitConfirmationDialog: React.FC<{
  onStayInGame: () => void;
  onExitGame: () => void;
}> = ({ onStayInGame, onExitGame }) => {
  const [entered, setEntered] = useState(false);
  const [isClosing, setIsClosing] = useState(false);
  const [isExiting, setIsExiting] = useState(false);

  useEffect(() => {
    const raf = requestAnimationFrame(() => setEntered(true));
    return () => cancelAnimationFrame(raf);
  }, []);

  const handleStay = () => {
    if (isExiting || isClosing) return;
    AudioService.playButtonClick();
    HapticService.uiTap();
    setIsClosing(true);
    window.setTimeout(() => {
      onStayInGame();
    }, 180);
  };

  const handleExit = () => {
    if (isExiting || isClosing) return;
    setIsExiting(true);
    AudioService.playButtonClick();
    HapticService.uiTap();
    setIsClosing(true);
    window.setTimeout(() => {
      onExitGame();
    }, 150);
  };

  useEffect(() => {
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && !isExiting && !isClosing) {
        e.preventDefault();
        handleStay();
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isExiting, isClosing]);

  const isVisible = entered && !isClosing;

  return (
    <div
      role="alertdialog"
      aria-modal="true"
      aria-labelledby="exit-dialog-title"
      aria-describedby="exit-dialog-desc"
      onClick={handleStay}
      className={`fixed inset-0 z-50 bg-black/65 backdrop-blur-[2px] flex items-center justify-center p-4 transition-opacity duration-200 ${
        isVisible ? 'opacity-100' : 'opacity-0'
      }`}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          transform: isVisible ? 'scale(1) translateY(0px)' : 'scale(0.92) translateY(10px)',
          transition: 'transform 200ms cubic-bezier(0.22, 1, 0.36, 1), opacity 180ms ease-out',
          boxShadow:
            '0 18px 40px rgba(0, 0, 0, 0.72), 0 0 24px rgba(212, 175, 55, 0.18)',
        }}
        className="w-full max-w-[400px] max-h-[92%] overflow-y-auto bg-[#0F172A]/96 border-[1.5px] border-[#D4AF37]/85 rounded-[18px] p-4 sm:p-5"
      >
        {/* Header with tasteful Exit icon */}
        <div className="flex items-center gap-3 mb-2.5">
          <div className="w-10 h-10 rounded-full bg-[#D97706]/15 border border-[#FFD54F]/50 flex items-center justify-center shrink-0">
            <LogOut size={19} className="text-[#FFD54F] -scale-x-100" />
          </div>
          <div>
            <h2
              id="exit-dialog-title"
              className="text-[#FFE082] text-base sm:text-[17px] font-black tracking-wide leading-tight"
            >
              Leave Game?
            </h2>
            <span className="text-white/55 text-[10.5px] font-semibold">
              Match in Progress
            </span>
          </div>
        </div>

        {/* Concise Confirmation Message */}
        <p
          id="exit-dialog-desc"
          className="text-white/85 text-xs sm:text-[13px] leading-relaxed mb-4"
        >
          Are you sure you want to leave this match? Your current game progress may be lost.
        </p>

        {/* Two Clear Actions: Stay in Game (Primary Safe) & Exit Game (Cautionary Secondary) */}
        <div className="grid grid-cols-2 gap-2.5">
          <button
            type="button"
            disabled={isExiting || isClosing}
            onClick={handleStay}
            className="py-2.5 px-3 rounded-[10px] bg-[#059669] hover:bg-[#047857] disabled:opacity-60 text-white text-xs sm:text-[13px] font-bold flex items-center justify-center gap-1.5 shadow transition cursor-pointer"
          >
            <Play size={15} />
            Stay in Game
          </button>

          <button
            type="button"
            disabled={isExiting || isClosing}
            onClick={handleExit}
            className="py-2.5 px-3 rounded-[10px] border border-[#F59E0B]/65 bg-[#D97706]/15 hover:bg-[#D97706]/28 disabled:opacity-60 text-[#FFE082] text-xs sm:text-[13px] font-bold flex items-center justify-center gap-1.5 transition cursor-pointer"
          >
            <LogOut size={15} className="-scale-x-100" />
            Exit Game
          </button>
        </div>
      </div>
    </div>
  );
};

// 5. Victory Overlay + Celebration Particles
export const CelebrationParticlesCanvas: React.FC<{
  completedType: CountryType;
  originNormalized: { x: number; y: number };
}> = ({ completedType, originNormalized }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    if (
      typeof window !== 'undefined' &&
      window.matchMedia?.('(prefers-reduced-motion: reduce)').matches
    ) {
      return;
    }
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const meta = COUNTRY_METADATA[completedType];
    const palette = [
      '#FFD700',
      '#FFF176',
      '#FFB300',
      '#FFFFFF',
      '#69F0AE',
      '#FF5252',
      '#40C4FF',
      meta.primaryColor,
      meta.accentColor,
    ];

    interface Particle {
      ox: number;
      oy: number;
      vx: number;
      vy: number;
      color: string;
      size: number;
      angle: number;
      angVel: number;
      delay: number;
      life: number;
      gravity: number;
    }

    // Use a lightweight particle budget (56 particles) for smooth 60fps on low-end Android GPUs
    const particleCount = 56;
    const particles: Particle[] = [];
    for (let i = 0; i < particleCount; i++) {
      const a = Math.random() * Math.PI * 2;
      const speed = 160 + Math.random() * 440;
      particles.push({
        ox: originNormalized.x,
        oy: originNormalized.y,
        vx: Math.cos(a) * speed,
        vy: Math.sin(a) * speed - 130,
        color: palette[Math.floor(Math.random() * palette.length)],
        size: 7 + Math.random() * 7,
        angle: Math.random() * Math.PI * 2,
        angVel: (Math.random() - 0.5) * 12,
        delay: Math.random() * 0.14,
        life: 0.72 + Math.random() * 0.25,
        gravity: 420,
      });
    }

    let animId = 0;
    const start = performance.now();
    const duration = 3100;

    const render = (now: number) => {
      const progress = (now - start) / duration;
      if (progress >= 1) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        return;
      }

      // Only resize canvas backing buffer if dimensions changed to avoid 60Hz GPU buffer reallocation
      const cw = canvas.clientWidth;
      const ch = canvas.clientHeight;
      if (canvas.width !== cw || canvas.height !== ch) {
        canvas.width = cw;
        canvas.height = ch;
      }
      ctx.clearRect(0, 0, cw, ch);

      for (const p of particles) {
        if (progress < p.delay) continue;
        const localT = (progress - p.delay) / p.life;
        if (localT <= 0 || localT >= 1) continue;
        const dt = localT * p.life * 3.1;
        const dragFactor = (1 - Math.exp(-1.6 * dt)) / 1.6;
        const x = p.ox * cw + p.vx * dragFactor;
        const y = p.oy * ch + p.vy * dragFactor + 0.5 * p.gravity * dt * dt;
        const alpha = Math.min(1, localT / 0.1) * Math.min(1, (1 - localT) / 0.28);

        ctx.save();
        ctx.globalAlpha = Math.max(0, alpha);
        ctx.translate(x, y);
        ctx.rotate(p.angle + p.angVel * dt);
        ctx.fillStyle = p.color;
        ctx.fillRect(-p.size * 0.7, -p.size * 0.35, p.size * 1.4, p.size * 0.7);
        ctx.restore();
      }

      animId = requestAnimationFrame(render);
    };

    animId = requestAnimationFrame(render);
    return () => cancelAnimationFrame(animId);
  }, [completedType, originNormalized.x, originNormalized.y]);

  return <canvas ref={canvasRef} className="fixed inset-0 z-50 pointer-events-none w-full h-full" />;
};

export const VictoryOverlay: React.FC<{
  winner: GamePlayer;
  winningType: CountryType;
  totalPlayers: number;
  turnCount: number;
  onPlayAgain: () => void;
  onViewStats: () => void;
  onMainMenu: () => void;
}> = ({
  winner,
  winningType,
  totalPlayers,
  turnCount,
  onPlayAgain,
  onViewStats,
  onMainMenu,
}) => {
  const isHuman = winner.isHuman;
  const meta = COUNTRY_METADATA[winningType];
  const cardWidth = totalPlayers >= 6 ? 40 : totalPlayers === 5 ? 44 : 48;

  const { setBonus, speedBonus, roundPoints } = computeRoundPoints(totalPlayers, turnCount);
  const winnerRecord = StatsService.getRecordForPlayer(winner);
  const targetTotalPoints =
    winnerRecord.totalPoints >= roundPoints ? winnerRecord.totalPoints : roundPoints;
  const previousTotalPoints = Math.max(0, targetTotalPoints - roundPoints);

  const [entered, setEntered] = useState(false);
  const [displayedTotalPoints, setDisplayedTotalPoints] = useState(previousTotalPoints);
  const [displayedRoundPoints, setDisplayedRoundPoints] = useState(0);

  useEffect(() => {
    const enterRaf = requestAnimationFrame(() => setEntered(true));

    let animId = 0;
    const start = performance.now();
    const duration = 1050;

    const tick = (now: number) => {
      const raw = Math.min(1, Math.max(0, (now - start) / duration));
      const eased = 1 - Math.pow(1 - raw, 3);
      setDisplayedRoundPoints(Math.round(roundPoints * eased));
      setDisplayedTotalPoints(
        Math.round(previousTotalPoints + (targetTotalPoints - previousTotalPoints) * eased)
      );
      if (raw < 1) {
        animId = requestAnimationFrame(tick);
      }
    };

    animId = requestAnimationFrame(tick);
    return () => {
      cancelAnimationFrame(enterRaf);
      cancelAnimationFrame(animId);
    };
  }, [previousTotalPoints, roundPoints, targetTotalPoints]);

  return (
    <div
      className={`fixed inset-0 z-40 bg-black/78 flex items-center justify-center p-2.5 sm:p-4 transition-opacity duration-300 ${
        entered ? 'opacity-100' : 'opacity-0'
      }`}
    >
      <div
        style={{
          transform: entered ? 'scale(1) translateY(0px)' : 'scale(0.84) translateY(22px)',
          transition: 'transform 420ms cubic-bezier(0.22, 1.18, 0.36, 1), opacity 280ms ease-out',
          boxShadow:
            '0 0 38px rgba(255, 215, 0, 0.38), 0 18px 44px rgba(0, 0, 0, 0.85), inset 0 1px 0 rgba(255, 255, 255, 0.2)',
        }}
        className="relative w-full max-w-[610px] max-h-[92%] overflow-y-auto bg-gradient-to-b from-[#0F172A]/98 via-[#111C35]/98 to-[#091022]/98 border-2 border-[#FFD700] rounded-[22px] p-3.5 sm:p-5"
      >
        {/* Lightweight Static Golden Radial Spotlight Glow Behind Winner Header */}
        <div
          style={{
            background:
              'radial-gradient(circle, rgba(255, 215, 0, 0.16) 0%, rgba(16, 185, 129, 0.08) 45%, transparent 72%)',
          }}
          className="absolute -top-24 left-1/2 -translate-x-1/2 w-[360px] h-[240px] rounded-full pointer-events-none"
        />

        {/* 1. Celebratory Winner Banner & Avatar Spotlight */}
        <div className="relative z-10 flex flex-col sm:flex-row items-center justify-between gap-3 pb-3 border-b border-white/10">
          <div className="flex items-center gap-3.5">
            {/* Winner Avatar with Pulsing Champion Ring & Trophy Badge */}
            <div className="relative shrink-0">
              <div
                style={{
                  boxShadow:
                    '0 0 0 3px #1E1B4B, 0 0 0 6px #FFD700, 0 0 24px 6px rgba(255, 213, 79, 0.65)',
                }}
                className="w-16 h-16 rounded-full overflow-hidden bg-[#2A2160] flex items-center justify-center"
              >
                <AvatarSvg avatarIndex={winner.id} isMe={winner.isHuman} size={64} />
              </div>
              <div className="absolute -top-2 -right-2 w-7 h-7 rounded-full bg-gradient-to-br from-[#FFF176] via-[#FFD54F] to-[#D97706] border-2 border-[#1E1B4B] flex items-center justify-center shadow-lg animate-bounce">
                <Trophy size={14} className="text-[#1E1B4B]" />
              </div>
            </div>

            {/* Winner Name & Round Victory Title */}
            <div>
              <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[#FFD700]/20 border border-[#FFD700]/60 text-[#FFE082] text-[10px] font-black tracking-widest uppercase mb-1">
                <Sparkles size={11} className="text-[#FFD700]" />
                {isHuman ? 'ROUND VICTORY!' : 'ROUND COMPLETE'}
              </div>
              <div className="flex items-baseline gap-2 flex-wrap">
                <span className="text-white/75 text-xs font-bold uppercase tracking-wider">
                  Winner:
                </span>
                <span className="text-[#FFD700] text-xl sm:text-2xl font-black tracking-wide drop-shadow-[0_2px_10px_rgba(255,215,0,0.45)]">
                  {winner.name}
                </span>
              </div>
              <div className="text-white/85 text-xs font-medium mt-0.5">
                {isHuman
                  ? `You collected all ${totalPlayers} cards of ${meta.displayName}!`
                  : `${winner.name} collected all ${totalPlayers} cards of ${meta.displayName}!`}
              </div>
            </div>
          </div>

          {/* 2. Animated Total Points & Round Score Counter Card */}
          <div
            style={{
              background:
                'linear-gradient(135deg, rgba(255, 215, 0, 0.16) 0%, rgba(16, 185, 129, 0.16) 100%)',
              boxShadow: '0 0 20px rgba(255, 215, 0, 0.22)',
            }}
            className="shrink-0 px-4 py-2.5 rounded-2xl border border-[#FFD700]/70 flex flex-col items-center sm:items-end justify-center min-w-[168px]"
          >
            <div className="flex items-center gap-1.5 text-[#FFE082] text-[10px] font-extrabold tracking-widest uppercase">
              <Award size={13} className="text-[#FFD700]" />
              <span>WINNER TOTAL POINTS</span>
            </div>
            <div className="flex items-baseline gap-2 mt-0.5">
              <span className="text-white text-2xl sm:text-[26px] font-black tabular-nums tracking-tight drop-shadow">
                {displayedTotalPoints.toLocaleString()}
              </span>
              <span className="text-[#FFD700] text-xs font-black uppercase">PTS</span>
            </div>
            <div className="mt-0.5 px-2 py-0.5 rounded-full bg-[#10B981]/25 border border-[#34D399]/60 text-[#6EE7B7] text-[10.5px] font-black tabular-nums">
              +{displayedRoundPoints} Round Pts
            </div>
          </div>
        </div>

        {/* 3. Score Breakdown Strip */}
        <div className="relative z-10 grid grid-cols-3 gap-2 my-3">
          <div className="px-2.5 py-1.5 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-between">
            <span className="text-white/65 text-[10.5px] font-semibold">Set Bonus ({totalPlayers}×)</span>
            <span className="text-[#FFE082] text-xs font-black">+{setBonus}</span>
          </div>
          <div className="px-2.5 py-1.5 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-between">
            <span className="text-white/65 text-[10.5px] font-semibold">Speed ({turnCount} turns)</span>
            <span className="text-[#69F0AE] text-xs font-black">+{speedBonus}</span>
          </div>
          <div className="px-2.5 py-1.5 rounded-xl bg-white/[0.06] border border-white/10 flex items-center justify-between">
            <span className="text-white/65 text-[10.5px] font-semibold">Sets Won</span>
            <span className="text-[#38BDF8] text-xs font-black">
              {Math.max(1, winnerRecord.setsCompleted)}
            </span>
          </div>
        </div>

        {/* 4. Staggered Winning Set Cards Row */}
        <div className="relative z-10 flex items-center justify-center gap-2 overflow-x-auto py-1.5 mb-3">
          {Array.from({ length: totalPlayers }, (_, i) => (
            <div
              key={i}
              style={{
                transform: entered
                  ? 'translateY(0px) scale(1)'
                  : 'translateY(18px) scale(0.84)',
                opacity: entered ? 1 : 0,
                transition: `transform 380ms cubic-bezier(0.22, 1.2, 0.36, 1) ${
                  110 + i * 65
                }ms, opacity 280ms ease-out ${110 + i * 65}ms`,
              }}
            >
              <CountryCardView
                card={{ id: `win_preview_${i}`, type: winningType, isStartingCard: false }}
                width={cardWidth}
                height={cardWidth * 2}
              />
            </div>
          ))}
        </div>

        {/* 5. Leaderboard Link */}
        <div className="relative z-10 flex flex-wrap items-center justify-center gap-2.5 mb-3">
          <div className="px-3 py-1 rounded-full bg-white/[0.08] border border-white/10 text-[#FFE082] text-[11px] font-bold">
            Completed Set: {totalPlayers}× {meta.displayName} ({meta.shortCode})
          </div>
          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              onViewStats();
            }}
            className="flex items-center gap-1.5 text-[#FFD54F] hover:underline text-xs font-bold cursor-pointer"
          >
            <Trophy size={14} />
            View All Players' Points & Sets Leaderboard
          </button>
        </div>

        {/* 6. Action Buttons */}
        <div className="relative z-10 grid grid-cols-2 gap-3">
          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.uiTap();
              onMainMenu();
            }}
            className="py-2.5 rounded-[10px] border border-white/25 text-white/80 hover:text-white text-sm font-semibold cursor-pointer"
          >
            Main Menu
          </button>
          <button
            onClick={() => {
              AudioService.playButtonClick();
              HapticService.cardPass();
              onPlayAgain();
            }}
            className="py-2.5 rounded-[10px] bg-[#D97706] hover:bg-[#B45309] text-white text-sm font-bold shadow cursor-pointer"
          >
            Play Again
          </button>
        </div>
      </div>
    </div>
  );
};
