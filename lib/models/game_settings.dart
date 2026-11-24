import 'package:flutter/foundation.dart';

/// How hard the bots play.
enum BotDifficulty {
  /// Bots release cards of the country you are collecting and sometimes
  /// pause their own set-building. To do this they look at your hand.
  easy,

  /// Bots play for themselves only (no help, no peeking at your hand), but
  /// still sometimes pause their own set-building.
  normal,

  /// Bots always pursue their strongest set.
  hard;

  String get label => switch (this) {
        BotDifficulty.easy => 'Easy',
        BotDifficulty.normal => 'Normal',
        BotDifficulty.hard => 'Hard',
      };
}

@immutable
class GameSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool animationsEnabled;
  final int botDelayMs;
  final BotDifficulty botDifficulty;
  final String themeName;
  final int totalPlayers;

  const GameSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.animationsEnabled = true,
    this.botDelayMs = 1650,
    this.botDifficulty = BotDifficulty.easy,
    this.themeName = 'emerald',
    this.totalPlayers = 4,
  });

  /// Global shared settings across screens.
  static GameSettings current = const GameSettings();

  GameSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? animationsEnabled,
    int? botDelayMs,
    BotDifficulty? botDifficulty,
    String? themeName,
    int? totalPlayers,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      botDelayMs: botDelayMs ?? this.botDelayMs,
      botDifficulty: botDifficulty ?? this.botDifficulty,
      themeName: themeName ?? this.themeName,
      totalPlayers: totalPlayers ?? this.totalPlayers,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameSettings &&
        other.soundEnabled == soundEnabled &&
        other.hapticsEnabled == hapticsEnabled &&
        other.animationsEnabled == animationsEnabled &&
        other.botDelayMs == botDelayMs &&
        other.botDifficulty == botDifficulty &&
        other.themeName == themeName &&
        other.totalPlayers == totalPlayers;
  }

  @override
  int get hashCode => Object.hash(
        soundEnabled,
        hapticsEnabled,
        animationsEnabled,
        botDelayMs,
        botDifficulty,
        themeName,
        totalPlayers,
      );
}
