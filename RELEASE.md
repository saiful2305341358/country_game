# Release checklist

What still has to be done before the app can go on **Google Play** and the **Apple App Store**. Tick items off as they are done. New feature ideas go in [backlog.md](backlog.md); this file is only about shipping.

Format: `- [ ] Short title — what and why`

## Status today (2026-11-24)

- `flutter build apk --release` works with Android Gradle Plugin 9.3.1, Kotlin 2.4.20 and Gradle 9.5.0, with no version warnings.
- Not yet tested on a real phone. iOS has never been built (it needs a Mac).
- App ID is still `com.example.country_game` (Android) / `com.example.countryGame` (iOS). Both stores reject or discourage `com.example`.
- Release builds are signed with the **debug key**. Google Play rejects that.

---

## 1. Both stores

### App identity
- [ ] **Choose the final app ID**, for example `com.yourname.countrygame`. It can never be changed after the first upload, so pick it carefully. Use the same ID on Android and iOS.
- [ ] **Final app name.** It is "Country Game" in `AndroidManifest.xml` (`android:label`) and in `ios/Runner/Info.plist` (`CFBundleDisplayName`). Check that the name is not already taken in the stores.
- [ ] **App icon.** Make sure the icons in `android/app/src/main/res/mipmap-*` and `ios/Runner/Assets.xcassets/AppIcon.appiconset` are the final design, not Flutter's default. The `flutter_launcher_icons` package can generate every size from one 1024×1024 image.
- [ ] **Version number.** `version: 1.0.0+1` in `pubspec.yaml`. The part after `+` (the build number) must go up with **every** upload to either store.

### Multiplayer readiness
- [ ] **Hide other players' cards** from network data (already in backlog.md). A store reviewer will not notice, but players could cheat.
- [ ] **"Online Multiplayer — COMING SOON" on the home screen.** Apple often rejects apps that show unfinished features (guideline 2.1). Hide the button for the store build, or finish the feature first.
- [ ] **Supabase free plan pauses a project after about 1 week without use.** While it is paused, Internet rooms fail. Before launch, either upgrade to a paid plan or make sure the project is used regularly. Also check the free-plan limits (Realtime connections, database size).
- [ ] **Supabase abuse protection.** Anyone can sign in anonymously. In the Supabase dashboard, turn on CAPTCHA for anonymous sign-ins (Authentication → Attack Protection) or keep the rate limits low.
- [ ] **Clean up old rooms.** Add a scheduled job (Supabase `pg_cron`) that deletes rooms and moves older than one day, so the database does not keep growing.

### Privacy and legal
- [ ] **Privacy policy web page.** Both stores require a public URL. It must say:
  - Internet rooms use Supabase: an anonymous account, the player name you type, room and move data.
  - A random device ID is stored on the phone to reconnect to nearby rooms.
  - Stats and settings stay on the phone.
  - No ads, no tracking, no data is sold.
  - A free GitHub Pages site is enough.
- [ ] **Account / data deletion.** Google Play asks how users can delete data linked to an account. Anonymous Supabase users count. The simplest answer: rooms are deleted when closed (plus the cleanup job above), and an email address users can write to.
- [ ] **Content rating.** Card game, no gambling with real money, no violence. Users can type a name that others see, so answer "yes" to "users can interact / share content".

### Testing before submitting
- [ ] Offline game with 3, 5 and 7 players on a small phone and a tablet (layout, sounds, vibration, stats saved after the app restarts).
- [ ] Internet room with 3+ real phones on mobile data and on Wi-Fi: create, join, play several rounds, someone leaves, someone joins mid-round.
- [ ] Nearby room with 3+ phones on **one phone's hotspot** and on **home Wi-Fi**: join by code, the nearby list, turn Wi-Fi off and on during a round (20-second reconnect).
- [ ] Android and iPhone in the same nearby room.
- [ ] Test the **release** build, not only debug (code shrinking can remove things that debug keeps).

---

## 2. Google Play (Android)

### Code and build
- [ ] **Change the Android app ID.**
  1. In `android/app/build.gradle.kts`, change both `namespace` and `applicationId`.
  2. Move `android/app/src/main/kotlin/com/example/country_game/MainActivity.kt` into a folder that matches the new ID and update its `package` line.
  3. Update the `-keep class com.example.country_game.**` line in `android/app/proguard-rules.pro`.
  4. Optional: the MethodChannel name `com.example.country_game/native_feedback` can stay as it is. It is only a label. If you change it, change all five places together: `MainActivity.kt`, `ios/Runner/AppDelegate.swift`, and `haptic_service_stub.dart`, `audio_service_stub.dart` and `stats_storage_stub.dart` in `lib/services/`.
- [ ] **Create an upload key and sign release builds with it.**
  1. Run `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
  2. Create `android/key.properties` with the keystore path, alias and passwords. It is already ignored by git. **Never commit the `.jks` file or `key.properties`; back them up somewhere safe.**
  3. In `android/app/build.gradle.kts`, add a `release` signing config that reads `key.properties` and use it instead of `signingConfigs.getByName("debug")`.
  4. Guide: https://docs.flutter.dev/deployment/android
- [x] **Raise build tool versions** to remove the "support will soon be dropped" warnings: Android Gradle Plugin 9.3.1 and Kotlin 2.4.20 in `android/settings.gradle.kts`.
- [ ] **Build the bundle:** `flutter build appbundle --release`. The output is `build/app/outputs/bundle/release/app-release.aab`. Play needs `.aab`, not `.apk`.
- [ ] **Target API level.** Play requires a recent `targetSdk`. It comes from `flutter.targetSdkVersion`; check Play Console's current requirement at upload time.
- [ ] **Optional:** use `flutter build appbundle --obfuscate --split-debug-info=build/symbols` and keep the symbols folder to read crash reports.
- [ ] **Optional, nearby-list reliability:** some Android phones drop the UDP "room announcements" while idle. Holding a `WifiManager.MulticastLock` in `MainActivity.kt` while the nearby screen is open (plus the `CHANGE_WIFI_MULTICAST_STATE` permission) makes the list more reliable. Joining by code works without it.

### Play Console
- [ ] **Google Play developer account** (one-time US$25 fee, identity verification).
- [ ] **New personal accounts must run a closed test first**: at least 12 testers opted in for 14 days in a row before production is allowed. Plan for this; it is the longest step.
- [ ] **Store listing:**
  - short description (80 characters);
  - full description;
  - 512×512 icon;
  - 1024×500 feature graphic;
  - at least 2 phone screenshots (landscape is fine), plus 7" and 10" tablet screenshots if you want to appear on tablets.
- [ ] **Data safety form.**
  - Data collected: user ID (anonymous Supabase account), name (in-game display name), and app interactions (game moves). Each one is "not shared", "encrypted in transit" and "required for multiplayer only".
  - Device ID: declare it only if it leaves the phone. Today it is sent to the host phone over the local network, not to a server.
- [ ] **Other forms:** content rating questionnaire, target audience (if you include under-13s, the Families policy applies; "13+" is simpler), ads declaration ("No ads"), and the app access note ("no login needed").
- [ ] **Release:** internal testing → closed testing → production. Use Play App Signing (the default): Google holds the final signing key, and you keep the upload key.

---

## 3. Apple App Store (iPhone / iPad)

### What you need
- [ ] **A Mac with Xcode** (current version) and CocoaPods. iOS apps cannot be built on Linux. A cloud Mac service such as Codemagic or GitHub Actions macOS runners also works.
- [ ] **Apple Developer Program membership** (US$99 per year).

### Code and build
- [ ] **Change the bundle ID** in Xcode (Runner target → Signing & Capabilities), or replace `com.example.countryGame` in `ios/Runner.xcodeproj/project.pbxproj`. Also update the `RunnerTests` entries.
- [ ] **Set the signing team** in Xcode (Runner → Signing & Capabilities → Team). Automatic signing is easiest.
- [x] **iPad, landscape only: add `UIRequiresFullScreen` = `true` to `ios/Runner/Info.plist`.** The app supports only landscape. Without this key, App Store upload validation fails for iPad, because iPad multitasking apps must support all four orientations.
- [x] **Export compliance:** add `ITSAppUsesNonExemptEncryption` = `false` to `Info.plist`. The app only uses standard HTTPS/TLS, which is exempt, so Apple stops asking on every upload.
- [ ] **Local Network permission:** the text is already in `Info.plist` (`NSLocalNetworkUsageDescription`). Test that the first nearby join after tapping "Allow" works. The very first attempt can fail while the permission popup is open; consider retrying once automatically.
- [ ] **Multicast entitlement (optional):** needed only for the automatic "rooms nearby" list on iPhone. Request `com.apple.developer.networking.multicast` from Apple (developer.apple.com/contact/request/networking-multicast), then add it to the app's entitlements. Without it, iPhones join by code.
- [ ] **Hosting from an iPhone:** the room stops if the host locks the phone or switches apps (iOS suspends background apps). Show a hint to the host ("keep the app open"), or keep the screen awake while hosting (`wakelock_plus` package).
- [ ] **Build:** `flutter build ipa --release`. The first run creates `ios/Podfile` and installs pods. Upload with Xcode (Product → Archive → Distribute) or the Transporter app. The deployment target is iOS 15.0.

### App Store Connect
- [ ] **Create the app record:** name, bundle ID, SKU, primary category "Games → Card".
- [ ] **Screenshots:** iPhone 6.9" (required), plus iPad 13" if iPad is supported.
- [ ] **App Privacy ("nutrition label"):** the same data as the Google Play Data safety form: user ID, name, gameplay content; not linked to identity; no tracking.
- [ ] **Privacy policy URL**, plus a support URL (it can be the same site).
- [ ] **Age rating questionnaire.**
- [ ] **App Review notes.** Multiplayer needs at least 3 players, which reviewers cannot easily do alone. Explain that offline mode shows the full game, and include a short video of a nearby and an Internet room. Otherwise review may reject with "could not test the feature".
- [ ] **TestFlight:** test the build with friends first, then submit for review.

---

## 4. Web (optional)

- [ ] `flutter build web --release` works today. Host `build/web` on any static host (GitHub Pages, Netlify, Firebase Hosting).
- [ ] Nearby rooms cannot work in a browser (no local network sockets); the app already shows this. Offline play and Internet rooms work.

---

## 5. After launch

- [ ] Crash reporting (for example Firebase Crashlytics or Sentry), so release crashes are visible.
- [ ] Answer store reviews; plan a small 1.0.1 update for fixes.
- [ ] Keep the upload keystore, Supabase account and Apple/Google accounts backed up and with two-factor login.
