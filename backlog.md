# Backlog

Ideas to improve the Country Card Game. Add new ideas under **Ideas**; move them along as they progress.

Format: `- [ ] Short title — what and why (optional notes)`

## Ideas

- [ ] 

## Planned

- [ ] **Multiplayer: play with friends via Internet and nearby Wi-Fi / hotspot** — real human opponents instead of bots, with the same rules, cards and table as offline play. Source: feature request plus the `game_screens.drawio.xml` diagram. Nearby play uses Wi-Fi / hotspot instead of Bluetooth (decided: it works with Android and iPhone together, handles all 7 players reliably, and shares its code with Internet play).
  - [ ] **Home screen redesign**: three options, **Play Offline** (the current game, unchanged), **Play with Friends**, and **Play Online Multiplayer** (shown as "Coming soon"). Keep the current background colour and visual identity; clean, modern, minimal.
  - [ ] **Play with Friends screen**: choose **Play via Internet** or **Play nearby (Wi-Fi / Hotspot)**.
  - [ ] **Internet, Create Room**: auto-generate a unique 3-digit room code, choose the number of players, show the code for the host to share, and set up the online session.
  - [ ] **Internet, Join Room**: a text field for the code; validate it, then join if the room exists and has a free seat.
  - [ ] **Nearby, Create / Join Room**: the same flow as Internet (per the diagram). The host phone runs the game server on the local network (its own hotspot or a shared Wi-Fi); the other players connect to it. Rooms use a 3-digit code, and rooms on the network are also discovered automatically. No internet data is used. Show a short hint on how to turn on and join a hotspot.
  - [ ] **Synchronized gameplay**: reuse the existing engine, cards and table. Every device sees the same moves and turn order, and moves are only accepted from the player whose turn it is.
  - [ ] **Session handling**: lobby and ready state, start game, disconnect and leave handling, errors (wrong code, full room, lost connection), and clean-up of finished rooms.
  - [ ] Offline play must keep working exactly as now, with no regressions.
  - Open questions to settle before starting:
    1. Internet backend: Firebase, Supabase, or a self-hosted server? Each needs a project or hosting that you set up.
    2. ~~Bluetooth platforms~~ — settled: nearby play uses Wi-Fi / hotspot, so Android and iPhone can play together.
    3. "Striker visual concept": this game has no striker. Which element is meant (the logo, the card style)?
    4. Rooms with fewer friends than the chosen player count: fill the empty seats with bots, or wait until the room is full?

## In progress

## Done

- [x] Bot difficulty setting — Easy / Normal / Hard in Settings (Easy is the previous behaviour and stays the default).

## From code review (suggestions, keep or delete)

- [ ] Decide the future of the React port in `src/` — keep it in sync with the Flutter app, or remove it.
- [ ] Speed bonus with many players — the speed bonus counts every player's turns, so in 6–7 player games it almost always falls to the 50-point minimum.
