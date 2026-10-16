import 'package:flutter/foundation.dart';

@immutable
class GameSettings {
  final bool soundEnabled;
  final bool animationsEnabled;
  final int botDelayMs;
  final String themeName;
  final int totalPlayers;

  const GameSettings({
    this.soundEnabled = true,
    this.animationsEnabled = true,
    this.botDelayMs = 800,
    this.themeName = 'emerald',
    this.totalPlayers = 4,
  });

  GameSettings copyWith({
    bool? soundEnabled,
    bool? animationsEnabled,
    int? botDelayMs,
    String? themeName,
    int? totalPlayers,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      animationsEnabled: animationsEnabled ?? this.animationsEnabled,
      botDelayMs: botDelayMs ?? this.botDelayMs,
      themeName: themeName ?? this.themeName,
      totalPlayers: totalPlayers ?? this.totalPlayers,
    );
  }
}
