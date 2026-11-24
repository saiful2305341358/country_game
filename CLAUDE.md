# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An offline, landscape-only card-trading game for 3–7 players (one human + bots), written in Flutter. With N players there are N countries × N cards plus one neutral "Global" starting card (N·N+1 cards). On each turn the active player takes the table card and puts one card from their hand in its place; you cannot put down a card of the same country as the table card. The first player to hold N cards of one country wins, and the Global card never counts toward a set. See README.md for the full rules.

The repo also contains a **separate React/Vite port** of the same game (`src/`, `index.html`, `package.json`, `vite.config.ts`, generated via AI Studio; `.aistudio/` holds its artifacts). It is not built from the Dart code. Rule changes in `lib/game/` should be mirrored in `src/game/gameLogic.ts` and `src/models/types.ts` if the port is meant to stay in sync.

## Commands

```sh
flutter pub get
flutter analyze                       # lint rules in analysis_options.yaml (platform dirs, .aistudio, node_modules excluded)
flutter test                          # all tests
flutter test test/game_engine_test.dart
flutter test test/game_engine_test.dart --plain-name "createDeck rejects"   # single test by name
flutter run                           # device / desktop
flutter run -d chrome                 # web

# React port
npm install && npm run dev            # vite on :3000
npm run lint                          # tsc --noEmit
```

## Architecture

**Rules engine (`lib/game/`, pure Dart, UI-independent).** `GameEngine` (a `ChangeNotifier`) owns the immutable `GameState` and replaces it via `copyWith` on every move. A new game is built in three steps: `CardDeckFactory.createDeck` (picks countries, avoiding an immediate repeat via a static `_previousSelection`), then `InitialExchangeService.performInitialExchange` (deterministic simultaneous exchange so every hand holds one card of each country; player 0 is always the human, "You"), then a random starting player who opens by trading for Global.
- Discard legality lives in **one place**: `GameState.isLegalDiscard`. `MoveValidator` wraps it with error messages and `BotStrategy` filters through it.
- Win check: `GamePlayer.getWinningType(requiredSetSize: totalPlayers)` (wrapped by `WinnerDetector`).
- `verifyIntegrity()` asserts card conservation and uniqueness after every move (debug/tests only).
- Bots: `BotStrategy.evaluateDecision` scores legal discards and returns a "think" delay. Behaviour depends on `GameSettings.botDifficulty`: Easy (default) reads the human's hand to release their leading country and also takes "relaxed pivot" turns; Normal keeps only the relaxed pivots; Hard has neither.

**Engine ↔ animation handshake (the trickiest part).** `GameScreen` creates the engine with `waitForExchangeAnimation: true`. After each move the engine sets `isExchangeAnimating` and does **not** schedule the next bot until `completeExchangeAnimation()` is called. `PlayingTable` detects a new move in `didUpdateWidget` by comparing `turnCount`, runs the two-phase pass animation, and calls `onExchangeAnimationComplete`. With animations disabled it calls that callback on the next frame. Bot timers are paused and resumed through `pauseActivePlay` / `resumeActivePlay`, which keep the remaining delay. `GameScreen` pauses the engine whenever an overlay (tutorial, history, stats, pause/exit dialog) is open or cards are being dealt. Any new overlay must follow the same pause/resume pattern.

**Layout.** `PlayingTable` lays everything out on a fixed 1920×1080 design stage that is scaled to fit. Seat positions per player count are static tables in `_PlayingTableState` (exposed via `PlayingTable.opponentSeatCenter` / `stageSize`). `main.dart`'s `LandscapeViewportWrapper` rotates a portrait host into a landscape coordinate space and clamps text scale.

**Platform services (`lib/services/`) use conditional imports.** Each service has an interface, a `*_stub.dart` (mobile/native) and a `*_web.dart` (`dart:html`), selected with `if (dart.library.html)`:
- `StatsStorage` is the shared key-value store. On web it uses `localStorage` (and `sessionStorage` for the session intro flag). On mobile it is an in-memory map, loaded once in `main()` via `StatsStorage.init()` before any service singleton reads it. Keep that ordering. If the native load fails, writes stay in memory so they cannot overwrite saved data.
- Mobile audio, haptics, prefs, keep-screen-on (`ScreenAwake`, used while a room is open) and the Android Wi-Fi multicast lock (`multicastLock`, held while the nearby-rooms list listens) all go through one `MethodChannel('com.example.country_game/native_feedback')`, implemented in `android/app/src/main/kotlin/com/example/country_game/MainActivity.kt` and `ios/Runner/AppDelegate.swift`. Changing a method name means changing all three sides.
- Sounds are synthesized at startup as WAV bytes (`SoundSynthesizer`); there are no audio assets.
- Settings: `GameSettings.current` is a mutable global. `SettingsStore.load()` (in `main`) and `SettingsStore.save()` (in the Settings screen) persist it. Sound and haptic flags are persisted by their own services.
- `StatsService` (singleton `ChangeNotifier`) keys player records by **name** ("You" for the human). Scoring is `computeRoundPoints` (set bonus + speed bonus), shared by the victory overlay and the stats.

## Multiplayer (Internet and nearby rooms)

- `lib/online/` holds the multiplayer code; screens are `play_with_friends_screen.dart`, `internet_rooms_screen.dart` and `online_room_screen.dart` (lobby + table).
- **The host's phone is the referee.** `HostReferee` runs the unchanged `GameEngine` (`startNewGame(playerNames: …)` for an all-human round, `loadState` + `makeMove` per move). Other phones insert move requests into `room_moves`; the host validates (round, turn, seat, legality), then writes the new state to `rooms.state`, and every phone receives it via Supabase Realtime.
- `RoomSession` is the transport-neutral interface the UI uses (`OnlineRoomScreen`, `RoomEntryScreen`). Implementations: `SupabaseRoomSession` (Internet) and `LanHostSession` / `LanClientSession` (nearby).
- **Nearby rooms** (`lib/online/lan/`): the host phone runs a WebSocket server on port 47820 and is the referee, exactly like Internet rooms; friends connect directly. The room code is the last number of the host's IPv4 address (192.168.43.1 → "001"), so a friend derives the host address from the code plus its own subnet (`LanProtocol`). UDP broadcasts on port 47821 add a best-effort "rooms nearby" list. A dropped phone keeps its seat for 20 s and reconnects with its `DeviceIdentity` id. `lan_rooms.dart` picks `lan_rooms_io.dart` or the browser stub `lan_rooms_web.dart` (no local sockets on web); keep `dart:io` out of files the web build imports.
- Every phone renders `SeatView.forSeat(state, mySeat)`: the round rotated so the local player is seat 0 and the only `isHuman` player, because `PlayingTable` always draws `players[0]` at the bottom.
- `GameStateCodec` serializes `GameState` to JSON. When `GameState`, `GamePlayer` or `GameCard` gain fields, update the codec (and `SeatView`) too.
- Database schema, RLS policies and the `create_room` / `join_room` / `leave_room` functions live in `supabase/rooms.sql`; it is idempotent and is run by hand in the Supabase SQL Editor. Project URL and publishable key are in `lib/online/supabase_config.dart` (never a secret / service_role key).
- Supabase Dart `.order()` defaults to **descending**; always pass `ascending: true` where order matters.
- Network tests live in `tool/`, outside `test/`, so `flutter test` stays offline:
  - `flutter test tool/online_e2e_test.dart`: simulated phones play full rounds against the real project.
  - `ROOM_CODE=123 flutter test tool/friend_bots_test.dart`: two bot friends join a room you created, for manual testing.
  - `flutter test tool/lan_e2e_test.dart`: a nearby room on this computer's real network address (discovery + join by code).
  - `test/lan_test.dart` runs nearby rooms over localhost, so it stays in the normal suite.

## Conventions

- Lint set is an explicit list in `analysis_options.yaml` (not `flutter_lints` defaults). Web-only files use `// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use`.
- Player count 3–7 is validated in both `GameEngine.startNewGame` and `CardDeckFactory`. 7-player mode adds Brazil and has its own seat layout and sizing (`isSevenPlayerMode`). Check player-count-specific code paths when touching layout.
- Generated platform files (`android/local.properties`, `ios/Flutter/Generated.xcconfig`, `*/ephemeral/`, `GeneratedPluginRegistrant.*`) are gitignored. Do not re-add them.
