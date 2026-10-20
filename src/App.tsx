import React, { useCallback, useEffect, useState } from 'react';
import { CountryType, GameSettings } from './models/types';
import { GameScreen } from './screens/GameScreen';
import { IntroVideoScreen } from './screens/IntroVideoScreen';
import { MainMenuScreen } from './screens/MainMenuScreen';
import { PlayerSelectionScreen } from './screens/PlayerSelectionScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { loadPersistedSettings, savePersistedSettings } from './services/soundSynthesizer';

type ScreenRoute = 'intro' | 'menu' | 'playerSelection' | 'settings' | 'game';

const SESSION_INTRO_KEY = 'ccg_intro_played_session';
let hasPlayedIntroInMemory = false;

export function hasPlayedIntroThisSession(): boolean {
  if (hasPlayedIntroInMemory) return true;
  try {
    return window.sessionStorage.getItem(SESSION_INTRO_KEY) === '1';
  } catch {
    return false;
  }
}

export function markIntroPlayedThisSession(): void {
  hasPlayedIntroInMemory = true;
  try {
    window.sessionStorage.setItem(SESSION_INTRO_KEY, '1');
  } catch {
    // ignore in restricted storage contexts
  }
}

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

  // Keep a single consistent DOM tree structure across portrait and landscape
  // so React never unmounts or restarts active screens on mobile orientation changes.
  return (
    <div className="w-full h-full overflow-hidden flex items-center justify-center bg-[#04140E]">
      <div
        style={
          isPortrait
            ? {
                width: `${viewport.height}px`,
                height: `${viewport.width}px`,
                transform: 'rotate(90deg)',
                transformOrigin: 'center center',
              }
            : {
                width: '100%',
                height: '100%',
              }
        }
        className="relative shrink-0 overflow-hidden"
      >
        {children}
      </div>
    </div>
  );
};

export function App() {
  const [route, setRoute] = useState<ScreenRoute>(() =>
    hasPlayedIntroThisSession() ? 'menu' : 'intro'
  );
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
    if (nextRoute !== 'intro') {
      markIntroPlayedThisSession();
    }
    setRoute(nextRoute);
    try {
      window.history.pushState({ route: nextRoute }, '');
    } catch {
      // ignore in sandboxed iframes
    }
  }, []);

  useEffect(() => {
    try {
      window.history.replaceState({ route }, '');
    } catch {
      // ignore
    }
    // Only initialize history state once on mount
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Intercept Android system Back / browser history Back so it follows in-game hierarchy
  useEffect(() => {
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
      } else if (route === 'menu' || route === 'intro') {
        try {
          window.history.pushState({ route }, '');
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
      {route === 'intro' && (
        <IntroVideoScreen
          onFinished={() => {
            markIntroPlayedThisSession();
            navigateTo('menu');
          }}
        />
      )}

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
