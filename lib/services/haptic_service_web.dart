// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/services.dart';
import 'haptic_service_interface.dart';

HapticServiceInterface createHapticService() => HapticServiceWeb();

class HapticServiceWeb implements HapticServiceInterface {
  bool _hapticsEnabled = true;

  @override
  bool get isHapticsEnabled => _hapticsEnabled;

  @override
  set isHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
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
    if (!_hapticsEnabled) return;
    HapticFeedback.lightImpact();
    _vibratePattern(12);
  }

  @override
  void cardPass() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
    _vibratePattern(22);
  }

  @override
  void invalidMove() {
    if (!_hapticsEnabled) return;
    HapticFeedback.heavyImpact();
    _vibratePattern([18, 45, 24]);
  }

  @override
  void botTurnTick() {
    if (!_hapticsEnabled) return;
    HapticFeedback.selectionClick();
    _vibratePattern(8);
  }

  @override
  void yourTurnNotice() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
    _vibratePattern([14, 35, 22]);
  }

  @override
  void dealShuffle() {
    if (!_hapticsEnabled) return;
    HapticFeedback.selectionClick();
    _vibratePattern([10, 30, 12, 30, 16]);
  }

  @override
  void victory() {
    if (!_hapticsEnabled) return;
    HapticFeedback.heavyImpact();
    _vibratePattern([35, 50, 45, 50, 85]);
  }

  @override
  void roundEnd() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
    _vibratePattern([25, 60, 40]);
  }

  @override
  void uiTap() {
    if (!_hapticsEnabled) return;
    HapticFeedback.selectionClick();
    _vibratePattern(10);
  }
}
