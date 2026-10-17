import 'audio_service_interface.dart';

AudioServiceInterface createAudioService() => AudioServiceStub();

class AudioServiceStub implements AudioServiceInterface {
  bool _soundEnabled = true;

  @override
  bool get isSoundEnabled => _soundEnabled;

  @override
  set isSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  @override
  void playCardTap() {}

  @override
  void playCardTake() {}

  @override
  void playCardPlace() {}

  @override
  void playExchange() {}

  @override
  void playGameStart() {}

  @override
  void playGameEnd() {}

  @override
  void playVictory() {}

  @override
  void playButtonClick() {}

  @override
  void dispose() {}
}
