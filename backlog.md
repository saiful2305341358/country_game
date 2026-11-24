# Backlog

Ideas to improve the Country Card Game. Add new ideas under **Ideas**; move them along as they progress.

Format: `- [ ] Short title — what and why (optional notes)`

Publishing to Google Play / the App Store is tracked separately in [RELEASE.md](RELEASE.md).

## Ideas

- [ ] 

## Planned

- [ ] **Multiplayer: play with friends via Internet and nearby Wi-Fi / hotspot** — real human opponents instead of bots, with the same rules, cards and table as offline play. Source: feature request plus the `game_screens.drawio.xml` diagram. Nearby play uses Wi-Fi / hotspot instead of Bluetooth (decided: it works with Android and iPhone together, handles all 7 players reliably, and shares its code with Internet play).
  - [x] **Stage 1: Home screen redesign**: three options, **Play Offline** (the current game, unchanged), **Play with Friends**, and **Play Online Multiplayer** (shown as "Coming soon"). Keep the existing logo, card design, visual identity and background colour; layout, buttons and navigation may be redesigned (clean, modern, minimal), following the diagram.
  - [x] **Stage 1: Play with Friends screen**: choose **Play via Internet** or **Play nearby (Wi-Fi / Hotspot)**.
  - [x] **Stage 2: Internet rooms (Supabase)**
    - Create Room: auto-generate a unique 3-digit room code and show it for the host to share.
    - Join Room: a text field for the code; validate it, then join if the room exists.
  - [x] **Stage 3: Nearby rooms (Wi-Fi / hotspot)**: the same flow as Internet. The host phone runs the game server on the local network (its own hotspot or a shared Wi-Fi); the other players connect to it. Rooms use a 3-digit code, and rooms on the network are also discovered automatically. No internet data is used. Show a short hint on how to turn on and join a hotspot.
  - [ ] **Synchronized gameplay**: reuse the existing engine, cards and table. Every device sees the same moves and turn order, and moves are only accepted from the player whose turn it is.
  - [ ] Offline play must keep working exactly as now, with no regressions.
  - [ ] Hide other players' cards from the shared room data. Today every phone receives the whole round (the app only shows your own hand), so a technical player could read other hands from network traffic. Fix: send each player only their own hand.
  - [ ] Online rounds are not recorded in Player Stats (to keep the offline leaderboard clean); decide whether to track online wins separately.
  - [ ] Internet rooms: show when a player's connection drops (nearby rooms already show OFFLINE and keep the seat for 20 s; for Internet rooms the host can stop the round from the ⚙ menu).
  - [ ] Nearby rooms on iPhone: automatic room discovery needs Apple's multicast entitlement; until then iPhones join with the code (which always works).
  - Room rules (decided, apply to Internet and Nearby):
    - No bots: every seat is a real player.
    - No fixed player count: a round can start once at least 3 players are in the room (the game supports up to 7). Each round is dealt for the players present (N players → N-card winning set).
    - A player who joins during a round appears to everyone as a join request and is dealt in from the next round.
    - The room stays open across rounds; the room creator decides how many rounds to play and when to close the room. The code is freed when the room closes.
    - Handle disconnects, leaving, wrong codes and lost connections.

## In progress

## Done

- [x] Bot difficulty setting — Easy / Normal / Hard in Settings (Easy is the previous behaviour and stays the default).

## From code review (suggestions, keep or delete)

- [ ] Decide the future of the React port in `src/` — keep it in sync with the Flutter app, or remove it.
- [ ] Speed bonus with many players — the speed bonus counts every player's turns, so in 6–7 player games it almost always falls to the 50-point minimum.
