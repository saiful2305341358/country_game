import '../models/game_settings.dart';
import 'audio_service.dart';
import 'haptic_service.dart';
import 'stats_storage_stub.dart'
    if (dart.library.html) 'stats_storage_web.dart';

/// Loads and saves [GameSettings.current] so every setting survives restarts.
///
/// Sound and haptics are persisted by their own services; this store covers the
/// remaining gameplay settings (animations, bot pace and bot difficulty).
class SettingsStore {
  static const String _animationsKey = 'country_game_animations_enabled';
  static const String _botDelayKey = 'country_game_bot_delay_ms';
  static const String _botDifficultyKey = 'country_game_bot_difficulty';

  /// Bot pace presets offered in Settings.
  static const int fastBotDelayMs = 1100;
  static const int normalBotDelayMs = 1650;
  static const int relaxedBotDelayMs = 2300;

  /// Call once after [StatsStorage.init].
  static void load() {
    final savedAnimations = StatsStorage.read(_animationsKey);
    final savedDelay = int.tryParse(StatsStorage.read(_botDelayKey) ?? '');
    final savedDifficulty = StatsStorage.read(_botDifficultyKey);
    GameSettings.current = GameSettings.current.copyWith(
      soundEnabled: AudioService.instance.isSoundEnabled,
      hapticsEnabled: HapticService.instance.isHapticsEnabled,
      animationsEnabled:
          savedAnimations == null ? null : savedAnimations == 'true',
      botDelayMs: savedDelay != null &&
              savedDelay >= fastBotDelayMs &&
              savedDelay <= relaxedBotDelayMs
          ? savedDelay
          : null,
      botDifficulty: BotDifficulty.values
          .where((d) => d.name == savedDifficulty)
          .firstOrNull,
    );
  }

  /// Applies [settings] globally and persists them.
  static void save(GameSettings settings) {
    GameSettings.current = settings;
    AudioService.instance.isSoundEnabled = settings.soundEnabled;
    HapticService.instance.isHapticsEnabled = settings.hapticsEnabled;
    StatsStorage.write(_animationsKey, settings.animationsEnabled.toString());
    StatsStorage.write(_botDelayKey, settings.botDelayMs.toString());
    StatsStorage.write(_botDifficultyKey, settings.botDifficulty.name);
  }
}
