# Country Card Game

An offline, landscape card-trading game for 3 to 7 players (you plus bots), built with Flutter.

## Rules

- With **N** players there are N countries in play, N cards of each, plus one neutral **Global** card (N × N + 1 cards).
- Every player starts with one card of each active country. The Global card starts on the table.
- On your turn you take the face-up table card and put one card from your hand in its place.
- **Same-type restriction:** you cannot put down a card of the same country as the card currently on the table. The Global card can always be played, and any card can be played onto it.
- The first player to hold **N cards of one country** wins. The Global card never counts toward a set.

Bot difficulty is chosen in **Settings** (see `lib/game/bot_strategy.dart`):

- **Easy** (default): bots release cards of the country you are collecting and occasionally pause their own collecting. To do this they look at your hand.
- **Normal**: bots only see their own hand and play for themselves, but still occasionally pause their own collecting.
- **Hard**: bots always pursue their strongest set.

## Running

```sh
flutter pub get
flutter run          # Android / iOS / desktop
flutter run -d chrome
flutter test
```

## Project layout

| Path | Contents |
| --- | --- |
| `lib/game/` | Rules engine: deck creation, initial deal, move validation, win detection, bot strategy |
| `lib/models/` | Immutable game data (cards, players, game state, settings) |
| `lib/services/` | Audio, haptics, stats and settings persistence (web: `localStorage`; mobile: native prefs over the `native_feedback` method channel in `MainActivity.kt` / `AppDelegate.swift`) |
| `lib/screens/`, `lib/widgets/` | UI |
| `test/` | Engine and widget tests |
| `src/`, `index.html`, `package.json` | A separate React/Vite port of the same game (`npm install && npm run dev`) |
