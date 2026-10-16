import 'audio_service_interface.dart';
import 'audio_service_stub.dart'
    if (dart.library.html) 'audio_service_web.dart' as platform_audio;

class AudioService implements AudioServiceInterface {
  static final AudioService instance = AudioService._internal();

  late final AudioServiceInterface _platformService;

  AudioService._internal() {
    _platformService = platform_audio.createAudioService();
  }

  @override
  bool get isSoundEnabled => _platformService.isSoundEnabled;

  @override
  set isSoundEnabled(bool enabled) {
    _platformService.isSoundEnabled = enabled;
  }

  @override
  void playCardTap() => _platformService.playCardTap();

  @override
  void playCardTake() => _platformService.playCardTake();

  @override
  void playCardPlace() => _platformService.playCardPlace();

  @override
  void playExchange() => _platformService.playExchange();

  @override
  void playGameStart() => _platformService.playGameStart();

  @override
  void playVictory() => _platformService.playVictory();

  @override
  void playButtonClick() => _platformService.playButtonClick();

  @override
  void dispose() => _platformService.dispose();
}
