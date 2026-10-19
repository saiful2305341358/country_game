# Landscape Orientation Lock & Immersive Native Splash Screen Plan

This plan details the native and Flutter runtime updates to lock the entire application to sensor-driven landscape orientation and establish a seamless, edge-to-edge dark emerald splash screen with a centered gold emblem that transitions without visual flashes into the choreographed intro sequence.

## User Review & Critical Decisions

> [!IMPORTANT]
> The following architectural and visual decisions have been confirmed and will govern the implementation across the native Android/iOS host layers and Flutter runtime:

- **Confirmed Decision 1 — Sensor Landscape Orientation Lock**: Enforce bi-directional horizontal orientation (`sensorLandscape` on Android, landscapeleft/right on iOS and Flutter) across all activities, routes, dialogs, and overlays so the user can hold the device in either horizontal direction while never rotating into portrait mode.
- **Confirmed Decision 2 — Dark Emerald Splash with Centered Gold Emblem**: Replace the default white/system launch canvas with a custom dark emerald (`#04140E` / `#061A12`) native splash screen featuring a vector gold card/globe emblem in the center, eliminating the white startup flash before the Flutter engine renders its first frame.
- **Confirmed Decision 3 — Fullscreen Immersive Edge-to-Edge From Launch**: Configure the native window for fullscreen immersive mode and `shortEdges` display cutout rendering immediately at process start (`LaunchTheme` / `NormalTheme` and `MainActivity` window attributes) so system bars and camera cutouts never cause layout jumps between the native splash and Flutter intro screen.

---

## 1. Overview & Core Concept

- **What It Does**: Guarantees that from the moment the user taps the app icon, the OS window launches in landscape orientation, renders a themed dark-emerald and gold emblem splash screen edge-to-edge across the entire display (including notch/cutout areas), and hands off smoothly to the Flutter intro sequence and all subsequent screens without orientation flips or viewport resizing.
- **Target Audience / Persona**: Mobile card game players on Android and iOS devices (including low-end phones, ultra-wide phones with camera cutouts, and devices with system rotation lock enabled).
- **Key Value**: Eliminates startup white flashes, status-bar layout jumps, and accidental portrait switches when navigating between the splash screen, intro sequence, main menu, player selection, gameplay table, and modal dialogs.

---

## 2. User Experience & Visual Design

- **Key User Flows**:
  1. **Cold Start / App Launch**: The OS immediately locks the activity window to sensor-landscape in fullscreen edge-to-edge mode and displays the native dark emerald canvas (`#04140E`) with a centered gold emblem.
  2. **Splash-to-Intro Handoff**: As the Flutter engine initializes its first frame, the background color and coordinate space match the native launch window (`#04140E` -> `#061A12`), transitioning without a flash or status-bar resize into the 2.4-second choreographed card-swap intro sequence.
  3. **Cross-Screen Navigation & Lifecycle Resume**: Navigating between the Main Menu, Player Selection (3, 4, 5, or 6 players), Gameplay Table, Settings, Tutorial, Pause/Controls, and Victory overlays—or returning from background/multi-window states—maintains the exact same landscape viewport and immersive cutout behavior.
- **Visual Identity & Theme**:
  - *Aesthetic Direction*: Tactile casino-lawn card table aesthetic with crisp gold accents and zero startup flicker.
  - *Color Palette & Mood*:
    - Dominant Canvas (60%): Deep Emerald (`#04140E` to `#061A12`) matching the game table background.
    - Structural Surfaces (30%): Slate Navy (`#0F172A`) panels with subtle gold hairline borders.
    - Focal Accent (10%): Championship Gold (`#FFD700` / `#FFD54F`) for the launch emblem, primary CTAs, and winning-set indicators.
  - *Typography & Hierarchy*: Clean sans-serif display headings with controlled text-scale clamping (`0.85x` to `1.12x`) so accessibility font scaling never breaks single-screen landscape layouts.
  - *Component Styling & Layout*: Every screen and dialog is structured for a horizontal aspect ratio (`width >= height`), anchored by a root viewport wrapper and safe-area insets.
- **Interactive Feedback & Motion**: Compositor-only GPU transforms (`transform`, `opacity`) for the intro card swap and gameplay dealing animations, with native low-latency PCM audio and haptic feedback preserved.

---

## 3. Key Product Decisions & Trade-Offs

- **Decision 1: Multi-Layer Sensor Landscape Enforcement (Manifest + Activity Lifecycle + Flutter Runtime + Viewport Wrapper)**
  - *Chosen Approach*: Combine `android:screenOrientation="sensorLandscape"` and `android:resizeableActivity="false"` in the manifest with runtime enforcement in `MainActivity` (`onCreate`, `onResume`, `onWindowFocusChanged`), `SystemChrome.setPreferredOrientations` in Flutter, and a root `LandscapeViewportWrapper`.
  - *Why*: Relying on a single layer can fail on certain OEM Android skins, split-screen states, or web/embedded preview frames. Multi-layer enforcement guarantees landscape coordinates everywhere.
  - *Alternatives Considered*: Manifest-only orientation lock (rejected because OEM multi-window or web hosts can bypass manifest attributes).
- **Decision 2: Pure Vector Drawable Native Splash Emblem & Android 12+ SplashScreen Compatibility**
  - *Chosen Approach*: Use lightweight Android XML layer-list and vector drawables (`#04140E` background + centered gold card/globe emblem) across standard, v21+, and v31+ (Android 12+) launch themes, paired with matching dark emerald background styling on iOS and Web.
  - *Why*: Vector drawables add virtually zero APK/AAB binary size (keeping the app ultra-lightweight for low-end Android devices), scale crisply across all pixel densities (`mdpi` to `xxxhdpi`), and avoid aspect-ratio stretching in landscape mode.
  - *Alternatives Considered*: High-resolution raster PNG splash bitmaps (rejected because full-screen bitmaps either stretch across varying aspect ratios or bloat binary size).
- **Decision 3: Early Window Cutout & Fullscreen Immersive Configuration**
  - *Chosen Approach*: Apply `android:windowFullscreen="true"` and `android:windowLayoutInDisplayCutoutMode="shortEdges"` directly in the Android XML themes (`LaunchTheme` and `NormalTheme`) as well as programmatically in `MainActivity` before/during `super.onCreate`.
  - *Why*: Setting fullscreen and cutout rules only after Flutter starts causes a visible 1-frame viewport jump when the status bar hides after the native splash screen disappears.

---

## 4. Technical Architecture & Data Strategy *(Technical Reference)*

- **Architecture & Component Diagram**:

```text
┌────────────────────────────────────────────────────────────────────────────┐
│                     OS Launch & Native Host Window                         │
│  ┌──────────────────────────────┐      ┌────────────────────────────────┐  │
│  │ Android Manifest & Themes    │      │ MainActivity / AppDelegate     │  │
│  │ • sensorLandscape lock       │─────▶│ • Pre-frame sensorLandscape    │  │
│  │ • resizeableActivity="false" │      │ • Immersive sticky system bars │  │
│  │ • Fullscreen + shortEdges    │      │ • Display cutout shortEdges    │  │
│  │ • Emerald + Gold Vector Icon │      │ • Native PCM Audio & Haptics   │  │
│  └──────────────┬───────────────┘      └───────────────┬────────────────┘  │
└─────────────────┼──────────────────────────────────────┼───────────────────┘
                  │ Seamless First-Frame Handoff         │
                  ▼                                      ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                         Flutter Application Root                           │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ CountryGameApp + WidgetsBindingObserver                              │  │
│  │ • Enforces [landscapeLeft, landscapeRight] + immersiveSticky         │  │
│  │ • Re-asserts orientation on app resume & window metrics changes      │  │
│  └──────────────────────────────────┬───────────────────────────────────┘  │
│                                     ▼                                      │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │ LandscapeViewportWrapper (Global Builder)                            │  │
│  │ • Guarantees width >= height coordinate space for all routes/dialogs │  │
│  │ • Rotates MediaQuery insets & clamps textScaler (0.85x – 1.12x)      │  │
│  └─────────┬────────────────────────┬─────────────────────────┬─────────┘  │
│            ▼                        ▼                         ▼            │
│  ┌──────────────────┐    ┌─────────────────────┐   ┌────────────────────┐  │
│  │ IntroVideoScreen │───▶│ MainMenu &          │──▶│ GameScreen &       │  │
│  │ (800x450 Stage)  │    │ PlayerSelection     │   │ PlayingTable       │  │
│  │ • 2.4s Card Swap │    │ • Fixed Top/Bottom  │   │ • 1920x1080 Stage  │  │
│  │ • Skip Intro CTA │    │ • Horizontal Row    │   │ • Landscape Modals │  │
│  └──────────────────┘    └─────────────────────┘   └────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────┘
```

- **Data Model & State**:
  - **Window & Orientation State**: Managed deterministically by the native host window (`SCREEN_ORIENTATION_SENSOR_LANDSCAPE`, `LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES`, immersive fullscreen flags) and mirrored by `SystemChrome` in Flutter.
  - **Intro & Navigation State**: `CountryGameApp` manages the `_showingIntro` transition from the native splash screen to `IntroVideoScreen` and then to `MainMenuScreen`, while preserving all existing `GameSettings` and `StatsService` persistence.
- **Interactive Component & State Mapping**:
  - **Native Splash Layer**: Displays `#04140E` emerald background and centered gold emblem vector immediately on cold start across API levels (including Android 12+ `windowSplashScreenBackground` and `windowSplashScreenAnimatedIcon`), with fullscreen and cutout flags pre-applied so no layout shift occurs when Flutter renders frame 1.
  - **MainActivity Window Controller**: Applies orientation lock, cutout mode, and immersive fullscreen flags in `onCreate` (before first frame), `onResume`, and `onWindowFocusChanged` so system dialogs or task switchers never leave system bars visible or unlock portrait mode.
  - **IntroVideoScreen & App Screens**: Rely on the unified root `LandscapeViewportWrapper` (removing redundant nested portrait rotation wrappers where appropriate) so touch coordinates, `SafeArea` insets, and layout bounds remain 100% consistent across all screens and dialogs.
