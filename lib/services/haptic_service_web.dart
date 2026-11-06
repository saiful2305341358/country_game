// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'haptic_service_interface.dart';

HapticServiceInterface createHapticService() => HapticServiceWeb();

class HapticServiceWeb implements HapticServiceInterface {
  static const String _prefKey = 'country_game_haptics_enabled';
  bool _hapticsEnabled = true;

  HapticServiceWeb() {
    try {
      final saved = html.window.localStorage[_prefKey];
      if (saved != null) {
        _hapticsEnabled = saved == 'true';
      }
    } catch (_) {}
  }

  @override
  bool get isHapticsEnabled => _hapticsEnabled;

  @override
  set isHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
    try {
      html.window.localStorage[_prefKey] = enabled.toString();
    } catch (_) {}
  }

  void _vibratePattern(Object pattern) {
    if (!_hapticsEnabled) return;
    try {
      final dynamic nav = html.window.navigator;
      nav.vibrate(pattern);
    } catch (_) {
      // Ignore if browser or device does not support navigator.vibrate
    }
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
    HapticFeedback.heavyImpact();
    _vibratePattern([75, 50, 95, 50, 150]);
  }

  @override
  void roundEnd() {
    if (!_hapticsEnabled) return;
    HapticFeedback.lightImpact();
    _vibratePattern(32);
  }

  @override
  void uiTap() {
    // No haptic vibration on routine UI/card taps during play
  }
}
