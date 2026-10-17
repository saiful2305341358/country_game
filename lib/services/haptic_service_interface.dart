abstract class HapticServiceInterface {
  bool get isHapticsEnabled;
  set isHapticsEnabled(bool enabled);

  /// Light, crisp tap when selecting or picking up a legal card.
  void cardTap();

  /// Medium tactile thud when placing/passing a card onto the center table.
  void cardPass();

  /// Double-tick physical resistance when tapping a restricted (same-type) card.
  void invalidMove();

  /// Soft micro-tick when a bot completes a turn and passes a card.
  void botTurnTick();

  /// Distinct alert pulse when active turn transitions to the human player ("Your Turn").
  void yourTurnNotice();

  /// Rhythmic shuffle/deal pulse when a new game starts and hands are dealt.
  void dealShuffle();

  /// Celebratory multi-pulse haptic fanfare when the human player wins the match.
  void victory();

  /// Distinct closing pulse when the round concludes with a bot winner.
  void roundEnd();

  /// Subtle selection click for UI controls and settings switches.
  void uiTap();
}
