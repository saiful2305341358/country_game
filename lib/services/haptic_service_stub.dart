import 'package:flutter/services.dart';
import 'haptic_service_interface.dart';
import 'stats_storage_stub.dart';

HapticServiceInterface createHapticService() => HapticServiceMobile();

/// Native Mobile (Android APK/AAB & iOS IPA) Haptic Service.
/// Uses both direct native hardware vibration via MethodChannel (Android `Vibrator` /
/// `VibrationEffect` & iOS `UIImpactFeedbackGenerator`) and Flutter's `HapticFeedback`
/// so tactile vibration works reliably even when Android system touch-feedback is disabled.
class HapticServiceMobile implements HapticServiceInterface {
  static const MethodChannel _channel = MethodChannel(
    'com.example.country_game/native_feedback',
  );
  static const String _prefKey = 'country_game_haptics_enabled';

  bool _hapticsEnabled = true;

  HapticServiceMobile() {
    final saved = StatsStorage.read(_prefKey);
    if (saved != null) {
      _hapticsEnabled = saved == 'true';
    }
  }

  @override
  bool get isHapticsEnabled => _hapticsEnabled;

  @override
  set isHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
    StatsStorage.write(_prefKey, enabled.toString());
  }

  void _nativeVibrate({
    required List<int> pattern,
    required int amplitude,
    required String style,
  }) {
    if (!_hapticsEnabled) return;
    try {
      _channel
          .invokeMethod<void>('vibrate', <String, dynamic>{
            'pattern': pattern,
            'amplitude': amplitude,
            'style': style,
          })
          .catchError((_) {});
    } catch (_) {}
  }

  @override
  void cardTap() {
    // No haptic vibration during card moves in play time
  }

  @override
  void cardPass() {
    // No haptic vibration during card moves in play time
  }

  @override
  void invalidMove() {
    // No haptic vibration during card moves in play time
  }

  @override
  void botTurnTick() {
    // No haptic vibration during card moves in play time
  }

  @override
  void yourTurnNotice() {
    // No haptic vibration during play time
  }

  @override
  void dealShuffle() {
    // No haptic vibration during card dealing
  }

  @override
  void victory() {
    if (!_hapticsEnabled) return;
    // Real player win: strong celebratory 3-pulse vibration pattern
    _nativeVibrate(
      pattern: const [75, 50, 95, 50, 150],
      amplitude: 255,
      style: 'success',
    );
    HapticFeedback.heavyImpact();
  }

  @override
  void roundEnd() {
    if (!_hapticsEnabled) return;
    // Bot win: noticeably lighter, brief single pulse
    _nativeVibrate(
      pattern: const [32],
      amplitude: 110,
      style: 'light',
    );
    HapticFeedback.lightImpact();
  }

  @override
  void uiTap() {
    // No haptic vibration on routine UI/card taps during play
  }
}
