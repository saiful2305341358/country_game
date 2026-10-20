import React, { useEffect, useState } from 'react';
import { CountryType, DEFAULT_GAME_SETTINGS, GameSettings } from './models/types';
import { GameScreen } from './screens/GameScreen';
import { IntroVideoScreen } from './screens/IntroVideoScreen';
import { MainMenuScreen } from './screens/MainMenuScreen';
import { PlayerSelectionScreen } from './screens/PlayerSelectionScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { AudioService, HapticService } from './services/soundSynthesizer';

type ScreenRoute = 'intro' | 'menu' | 'playerSelection' | 'settings' | 'game';

export const LandscapeViewportWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [viewport, setViewport] = useState({ width: window.innerWidth, height: window.innerHeight });

  useEffect(() => {
    const onResize = () => {
      setViewport({ width: window.innerWidth, height: window.innerHeight });
    };
    window.addEventListener('resize', onResize);
    return () => window.removeEventListener('resize', onResize);
  }, []);

  const isPortrait = viewport.width > 0 && viewport.height > 0 && viewport.width < viewport.height;

  if (!isPortrait) {
    return <div className="w-full h-full overflow-hidden">{children}</div>;
  }

  return (
    <div className="w-full h-full overflow-hidden flex items-center justify-center bg-[#04140E]">
      <div
        style={{
          width: `${viewport.height}px`,
          height: `${viewport.width}px`,
          transform: 'rotate(90deg)',
          transformOrigin: 'center center',
        }}
        className="shrink-0 overflow-hidden"
      >
        {children}
      </div>
    </div>
  );
};

export function App() {
  const [route, setRoute] = useState<ScreenRoute>('intro');
  const [settings, setSettings] = useState<GameSettings>(() => ({
    ...DEFAULT_GAME_SETTINGS,
    soundEnabled: AudioService.isSoundEnabled,
    hapticsEnabled: HapticService.isHapticsEnabled,
  }));
  const [activeMatchConfig, setActiveMatchConfig] = useState<{
    totalPlayers: number;
    predefinedTypes?: CountryType[];
  }>({ totalPlayers: 4 });

  return (
    <LandscapeViewportWrapper>
      {route === 'intro' && <IntroVideoScreen onFinished={() => setRoute('menu')} />}

      {route === 'menu' && (
        <MainMenuScreen
          onPlayGame={() => setRoute('playerSelection')}
          onOpenSettings={() => setRoute('settings')}
        />
      )}

      {route === 'playerSelection' && (
        <PlayerSelectionScreen
          onBack={() => setRoute('menu')}
          onStartGame={(totalPlayers, activeTypes) => {
            setActiveMatchConfig({ totalPlayers, predefinedTypes: activeTypes });
            setSettings((prev) => ({ ...prev, totalPlayers }));
            setRoute('game');
          }}
        />
      )}

      {route === 'settings' && (
        <SettingsScreen
          settings={settings}
          onUpdateSettings={setSettings}
          onBack={() => setRoute('menu')}
        />
      )}

      {route === 'game' && (
        <GameScreen
          totalPlayers={activeMatchConfig.totalPlayers}
          predefinedTypes={activeMatchConfig.predefinedTypes}
          settings={settings}
          onUpdateSettings={setSettings}
          onExitToMainMenu={() => setRoute('menu')}
        />
      )}
    </LandscapeViewportWrapper>
  );
}
export default App;
