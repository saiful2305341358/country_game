abstract class AudioServiceInterface {
  bool get isSoundEnabled;
  set isSoundEnabled(bool enabled);

  void playCardTap();
  void playCardTake();
  void playCardPlace();
  void playExchange();
  void playGameStart();
  void playVictory();
  void playButtonClick();

  void dispose();
}
