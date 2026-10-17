import 'package:flutter/foundation.dart';

@immutable
class GameSettings {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool animationsEnabled;
  final int botDelayMs;
  final String themeName;
  final int totalPlayers;

  const GameSettings({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.animationsEnabled = true,
    this.botDelayMs = 1650,
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
    String? themeName,
    int? totalPlayers,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      botDelayMs: botDelayMs ?? this.botDelayMs,
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
        other.themeName == themeName &&
        other.totalPlayers == totalPlayers;
  }

  @override
  int get hashCode => Object.hash(
        soundEnabled,
        hapticsEnabled,
        animationsEnabled,
        botDelayMs,
        themeName,
        totalPlayers,
      );
}
