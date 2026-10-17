import 'package:flutter/services.dart';
import 'haptic_service_interface.dart';

HapticServiceInterface createHapticService() => HapticServiceStub();

class HapticServiceStub implements HapticServiceInterface {
  bool _hapticsEnabled = true;

  @override
  bool get isHapticsEnabled => _hapticsEnabled;

  @override
  set isHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  @override
  void cardTap() {
    if (!_hapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  @override
  void cardPass() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  @override
  void invalidMove() {
    if (!_hapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }

  @override
  void botTurnTick() {
    if (!_hapticsEnabled) return;
    HapticFeedback.selectionClick();
  }

  @override
  void yourTurnNotice() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  @override
  void dealShuffle() {
    if (!_hapticsEnabled) return;
    HapticFeedback.selectionClick();
  }

  @override
  void victory() {
    if (!_hapticsEnabled) return;
    HapticFeedback.heavyImpact();
  }

  @override
  void roundEnd() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  @override
  void uiTap() {
    if (!_hapticsEnabled) return;
    HapticFeedback.selectionClick();
  }
}
