import React, { useCallback, useEffect, useState } from 'react';
import { CountryType, GameSettings } from './models/types';
import { GameScreen } from './screens/GameScreen';
import { IntroVideoScreen } from './screens/IntroVideoScreen';
import { MainMenuScreen } from './screens/MainMenuScreen';
import { PlayerSelectionScreen } from './screens/PlayerSelectionScreen';
import { SettingsScreen } from './screens/SettingsScreen';
import { loadPersistedSettings, savePersistedSettings } from './services/soundSynthesizer';

export type ScreenRoute = 'intro' | 'menu' | 'playerSelection' | 'settings' | 'game';

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

interface NavigationState {
  stack: ScreenRoute[];
  previousByRoute: Partial<Record<ScreenRoute, ScreenRoute>>;
}

export function App() {
  const [navState, setNavState] = useState<NavigationState>(() => ({
    stack: hasPlayedIntroThisSession() ? ['menu'] : ['intro'],
    previousByRoute: {
      playerSelection: 'menu',
      settings: 'menu',
      game: 'playerSelection',
    },
  }));

  const route = navState.stack[navState.stack.length - 1];

  const [settings, setSettings] = useState<GameSettings>(() => loadPersistedSettings());
  const [activeMatchConfig, setActiveMatchConfig] = useState<{
    totalPlayers: number;
    predefinedTypes?: CountryType[];
  }>({ totalPlayers: 4 });

  const handleUpdateSettings = useCallback((nextSettings: GameSettings) => {
    setSettings(nextSettings);
    savePersistedSettings(nextSettings);
  }, []);

  const navigateTo = useCallback((nextRoute: ScreenRoute, fromRoute?: ScreenRoute) => {
    if (nextRoute !== 'intro') {
      markIntroPlayedThisSession();
    }

    setNavState((prev) => {
      const current = prev.stack[prev.stack.length - 1];
      const sourceRoute = fromRoute ?? current;

      const nextPreviousByRoute: Partial<Record<ScreenRoute, ScreenRoute>> =
        sourceRoute && sourceRoute !== 'intro' && sourceRoute !== nextRoute
          ? { ...prev.previousByRoute, [nextRoute]: sourceRoute }
          : prev.previousByRoute;

      if (current === nextRoute) {
        return { stack: prev.stack, previousByRoute: nextPreviousByRoute };
      }

      // When transitioning out of the one-time intro or resetting to menu
      if (current === 'intro' || nextRoute === 'menu') {
        return { stack: [nextRoute], previousByRoute: nextPreviousByRoute };
      }

      // Preserve the source screen in the stack without creating duplicate entries
      const baseStack: ScreenRoute[] = prev.stack.filter((r) => r !== 'intro');
      let nextStack: ScreenRoute[];

      if (
        sourceRoute &&
        sourceRoute !== 'intro' &&
        baseStack[baseStack.length - 1] !== sourceRoute
      ) {
        const existingSourceIdx = baseStack.lastIndexOf(sourceRoute);
        const trimmed =
          existingSourceIdx >= 0
            ? baseStack.slice(0, existingSourceIdx + 1)
            : [...baseStack, sourceRoute];
        nextStack = [...trimmed, nextRoute];
      } else {
        const existingTargetIdx = baseStack.lastIndexOf(nextRoute);
        nextStack =
          existingTargetIdx >= 0
            ? baseStack.slice(0, existingTargetIdx + 1)
            : [...baseStack, nextRoute];
      }

      return {
        stack: nextStack,
        previousByRoute: nextPreviousByRoute,
      };
    });

    try {
      window.history.pushState({ route: nextRoute, fromRoute }, '');
    } catch {
      // ignore in sandboxed iframes
    }
  }, []);

  const navigateBack = useCallback((fromRoute?: ScreenRoute) => {
    setNavState((prev) => {
      const current = fromRoute ?? prev.stack[prev.stack.length - 1];

      // 1. Prefer the explicit previous screen recorded for the active route
      const recordedTarget = current ? prev.previousByRoute[current] : undefined;
      if (recordedTarget && recordedTarget !== 'intro') {
        const nextStack: ScreenRoute[] =
          recordedTarget === 'playerSelection'
            ? ['menu', 'playerSelection']
            : recordedTarget === 'menu'
              ? ['menu']
              : ['menu', recordedTarget];
        try {
          window.history.replaceState({ route: recordedTarget }, '');
        } catch {
          // ignore
        }
        return { ...prev, stack: nextStack };
      }

      // 2. Otherwise pop the navigation stack
      if (prev.stack.length > 1) {
        const nextStack = prev.stack.slice(0, -1).filter((r) => r !== 'intro');
        if (nextStack.length > 0) {
          const targetRoute = nextStack[nextStack.length - 1];
          try {
            window.history.replaceState({ route: targetRoute }, '');
          } catch {
            // ignore
          }
          return { ...prev, stack: nextStack };
        }
      }

      // 3. Safe fallback: GameScreen returns to PlayerSelectionScreen; others return to MainMenuScreen
      const fallbackTarget: ScreenRoute = current === 'game' ? 'playerSelection' : 'menu';
      const nextStack: ScreenRoute[] =
        fallbackTarget === 'playerSelection' ? ['menu', 'playerSelection'] : ['menu'];

      try {
        window.history.replaceState({ route: fallbackTarget }, '');
      } catch {
        // ignore
      }
      return { ...prev, stack: nextStack };
    });
  }, []);

  const navigateToMainMenu = useCallback(() => {
    markIntroPlayedThisSession();
    setNavState((prev) => ({
      ...prev,
      stack: ['menu'],
    }));
    try {
      window.history.replaceState({ route: 'menu' }, '');
    } catch {
      // ignore
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

  // Intercept Android system Back / browser history Back so it follows the navigation stack
  useEffect(() => {
    const onPopState = () => {
      if (route === 'game') {
        // Re-push history state and notify GameScreen to open ExitConfirmationDialog
        try {
          window.history.pushState({ route: 'game', fromRoute: 'playerSelection' }, '');
        } catch {
          // ignore
        }
        window.dispatchEvent(new CustomEvent('ccg-hardware-back'));
      } else if (route !== 'menu' && route !== 'intro') {
        navigateBack(route);
      } else {
        try {
          window.history.pushState({ route }, '');
        } catch {
          // ignore
        }
      }
    };

    window.addEventListener('popstate', onPopState);
    return () => window.removeEventListener('popstate', onPopState);
  }, [route, navigateBack]);

  return (
    <LandscapeViewportWrapper>
      {route === 'intro' && (
        <IntroVideoScreen
          onFinished={() => {
            markIntroPlayedThisSession();
            navigateTo('menu', 'intro');
          }}
        />
      )}

      {route === 'menu' && (
        <MainMenuScreen
          onPlayGame={() => navigateTo('playerSelection', 'menu')}
          onOpenSettings={() => navigateTo('settings', 'menu')}
        />
      )}

      {route === 'playerSelection' && (
        <PlayerSelectionScreen
          initialPlayers={activeMatchConfig.totalPlayers}
          initialActiveTypes={activeMatchConfig.predefinedTypes}
          onBack={() => navigateBack('playerSelection')}
          onStartGame={(totalPlayers, activeTypes) => {
            setActiveMatchConfig({ totalPlayers, predefinedTypes: activeTypes });
            handleUpdateSettings({ ...settings, totalPlayers });
            navigateTo('game', 'playerSelection');
          }}
        />
      )}

      {route === 'settings' && (
        <SettingsScreen
          settings={settings}
          onUpdateSettings={handleUpdateSettings}
          onBack={() => navigateBack('settings')}
        />
      )}

      {route === 'game' && (
        <GameScreen
          totalPlayers={activeMatchConfig.totalPlayers}
          predefinedTypes={activeMatchConfig.predefinedTypes}
          settings={settings}
          onUpdateSettings={handleUpdateSettings}
          onNavigateBack={() => navigateBack('game')}
          onExitToMainMenu={navigateToMainMenu}
        />
      )}
    </LandscapeViewportWrapper>
  );
}
export default App;
