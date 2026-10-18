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
    if (!_hapticsEnabled) return;
    _nativeVibrate(pattern: const [16], amplitude: 140, style: 'light');
    HapticFeedback.lightImpact();
  }

  @override
  void cardPass() {
    if (!_hapticsEnabled) return;
    _nativeVibrate(pattern: const [24], amplitude: 185, style: 'medium');
    HapticFeedback.mediumImpact();
  }

  @override
  void invalidMove() {
    if (!_hapticsEnabled) return;
    _nativeVibrate(
      pattern: const [22, 45, 32],
      amplitude: 230,
      style: 'error',
    );
    HapticFeedback.heavyImpact();
  }

  @override
  void botTurnTick() {
    if (!_hapticsEnabled) return;
    _nativeVibrate(pattern: const [10], amplitude: 110, style: 'selection');
    HapticFeedback.selectionClick();
  }

  @override
  void yourTurnNotice() {
    if (!_hapticsEnabled) return;
    _nativeVibrate(
      pattern: const [16, 35, 24],
      amplitude: 195,
      style: 'medium',
    );
    HapticFeedback.mediumImpact();
  }

  @override
  void dealShuffle() {
    if (!_hapticsEnabled) return;
    _nativeVibrate(
      pattern: const [12, 30, 14, 30, 18],
      amplitude: 160,
      style: 'light',
    );
    HapticFeedback.selectionClick();
  }

  @override
  void victory() {
    if (!_hapticsEnabled) return;
    _nativeVibrate(
      pattern: const [40, 50, 50, 50, 90],
      amplitude: 255,
      style: 'success',
    );
    HapticFeedback.heavyImpact();
  }

  @override
  void roundEnd() {
    if (!_hapticsEnabled) return;
    _nativeVibrate(
      pattern: const [28, 60, 42],
      amplitude: 200,
      style: 'warning',
    );
    HapticFeedback.mediumImpact();
  }

  @override
  void uiTap() {
    if (!_hapticsEnabled) return;
    _nativeVibrate(pattern: const [12], amplitude: 130, style: 'selection');
    HapticFeedback.selectionClick();
  }
}
