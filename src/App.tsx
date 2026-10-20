import React, { useCallback, useEffect, useState } from 'react';
import { CountryType, GameSettings } from './models/types';
import { GameScreen } from './screens/GameScreen';
import { IntroVideoScreen } from './screens/IntroVideoScreen';
import { MainMenuScreen } from './screens/MainMenuScreen';
import { PlayerSelectionScreen } from './screens/PlayerSelectionScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { loadPersistedSettings, savePersistedSettings } from './services/soundSynthesizer';

type ScreenRoute = 'intro' | 'menu' | 'playerSelection' | 'settings' | 'game';

export const LandscapeViewportWrapper: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [viewport, setViewport] = useState(() => ({
    width: window.innerWidth,
    height: window.innerHeight,
  }));

  useEffect(() => {
    const onResize = () => {
      const w = window.visualViewport ? Math.round(window.visualViewport.width) : window.innerWidth;
      const h = window.visualViewport
        ? Math.round(window.visualViewport.height)
        : window.innerHeight;
      setViewport((prev) => (prev.width === w && prev.height === h ? prev : { width: w, height: h }));
    };
    window.addEventListener('resize', onResize);
    window.visualViewport?.addEventListener('resize', onResize);
    return () => {
      window.removeEventListener('resize', onResize);
      window.visualViewport?.removeEventListener('resize', onResize);
    };
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
        className="relative shrink-0 overflow-hidden"
      >
        {children}
      </div>
    </div>
  );
};

export function App() {
  const [route, setRoute] = useState<ScreenRoute>('intro');
  const [settings, setSettings] = useState<GameSettings>(() => loadPersistedSettings());
  const [activeMatchConfig, setActiveMatchConfig] = useState<{
    totalPlayers: number;
    predefinedTypes?: CountryType[];
  }>({ totalPlayers: 4 });

  const handleUpdateSettings = useCallback((nextSettings: GameSettings) => {
    setSettings(nextSettings);
    savePersistedSettings(nextSettings);
  }, []);

  const navigateTo = useCallback((nextRoute: ScreenRoute) => {
    setRoute(nextRoute);
    try {
      window.history.pushState({ route: nextRoute }, '');
    } catch {
      // ignore in sandboxed iframes
    }
  }, []);

  // Intercept Android system Back / browser history Back so it follows in-game hierarchy
  useEffect(() => {
    try {
      window.history.replaceState({ route: 'intro' }, '');
    } catch {
      // ignore
    }

    const onPopState = () => {
      if (route === 'game') {
        // Re-push history state and notify GameScreen to open ExitConfirmationDialog
        try {
          window.history.pushState({ route: 'game' }, '');
        } catch {
          // ignore
        }
        window.dispatchEvent(new CustomEvent('ccg-hardware-back'));
      } else if (route === 'playerSelection' || route === 'settings') {
        setRoute('menu');
      } else if (route === 'menu') {
        try {
          window.history.pushState({ route: 'menu' }, '');
        } catch {
          // ignore
        }
      }
    };

    window.addEventListener('popstate', onPopState);
    return () => window.removeEventListener('popstate', onPopState);
  }, [route]);

  return (
    <LandscapeViewportWrapper>
      {route === 'intro' && <IntroVideoScreen onFinished={() => navigateTo('menu')} />}

      {route === 'menu' && (
        <MainMenuScreen
          onPlayGame={() => navigateTo('playerSelection')}
          onOpenSettings={() => navigateTo('settings')}
        />
      )}

      {route === 'playerSelection' && (
        <PlayerSelectionScreen
          onBack={() => navigateTo('menu')}
          onStartGame={(totalPlayers, activeTypes) => {
            setActiveMatchConfig({ totalPlayers, predefinedTypes: activeTypes });
            handleUpdateSettings({ ...settings, totalPlayers });
            navigateTo('game');
          }}
        />
      )}

      {route === 'settings' && (
        <SettingsScreen
          settings={settings}
          onUpdateSettings={handleUpdateSettings}
          onBack={() => navigateTo('menu')}
        />
      )}

      {route === 'game' && (
        <GameScreen
          totalPlayers={activeMatchConfig.totalPlayers}
          predefinedTypes={activeMatchConfig.predefinedTypes}
          settings={settings}
          onUpdateSettings={handleUpdateSettings}
          onExitToMainMenu={() => navigateTo('menu')}
        />
      )}
    </LandscapeViewportWrapper>
  );
}
export default App;
