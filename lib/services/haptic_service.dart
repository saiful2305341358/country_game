import 'haptic_service_interface.dart';
import 'haptic_service_stub.dart'
    if (dart.library.html) 'haptic_service_web.dart' as platform_haptic;

class HapticService implements HapticServiceInterface {
  static final HapticService instance = HapticService._internal();

  late final HapticServiceInterface _delegate;

  HapticService._internal() {
    _delegate = platform_haptic.createHapticService();
  }

  @override
  bool get isHapticsEnabled => _delegate.isHapticsEnabled;

  @override
  set isHapticsEnabled(bool enabled) => _delegate.isHapticsEnabled = enabled;

  @override
  void cardTap() => _delegate.cardTap();

  @override
  void cardPass() => _delegate.cardPass();

  @override
  void invalidMove() => _delegate.invalidMove();

  @override
  void botTurnTick() => _delegate.botTurnTick();

  @override
  void yourTurnNotice() => _delegate.yourTurnNotice();

  @override
  void dealShuffle() => _delegate.dealShuffle();

  @override
  void victory() => _delegate.victory();

  @override
  void roundEnd() => _delegate.roundEnd();

  @override
  void uiTap() => _delegate.uiTap();
}
