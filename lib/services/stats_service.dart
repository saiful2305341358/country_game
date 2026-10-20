import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/card_type.dart';
import '../models/game_player.dart';
import 'stats_storage_stub.dart'
    if (dart.library.html) 'stats_storage_web.dart';

class PlayerStatsRecord {
  final String name;
  final bool isHuman;
  final int avatarIndex;
  final int gamesPlayed;
  final int setsCompleted;
  final int totalPoints;
  final int lastRoundPoints;
  final CountryType? lastCompletedCountry;

  const PlayerStatsRecord({
    required this.name,
    required this.isHuman,
    required this.avatarIndex,
    this.gamesPlayed = 0,
    this.setsCompleted = 0,
    this.totalPoints = 0,
    this.lastRoundPoints = 0,
    this.lastCompletedCountry,
  });

  PlayerStatsRecord copyWith({
    String? name,
    bool? isHuman,
    int? avatarIndex,
    int? gamesPlayed,
    int? setsCompleted,
    int? totalPoints,
    int? lastRoundPoints,
    CountryType? lastCompletedCountry,
  }) {
    return PlayerStatsRecord(
      name: name ?? this.name,
      isHuman: isHuman ?? this.isHuman,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      setsCompleted: setsCompleted ?? this.setsCompleted,
      totalPoints: totalPoints ?? this.totalPoints,
      lastRoundPoints: lastRoundPoints ?? this.lastRoundPoints,
      lastCompletedCountry: lastCompletedCountry ?? this.lastCompletedCountry,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'isHuman': isHuman,
        'avatarIndex': avatarIndex,
        'gamesPlayed': gamesPlayed,
        'setsCompleted': setsCompleted,
        'totalPoints': totalPoints,
        'lastRoundPoints': lastRoundPoints,
        'lastCompletedCountry': lastCompletedCountry?.name,
      };

  factory PlayerStatsRecord.fromJson(Map<String, dynamic> json) {
    CountryType? parsedType;
    final rawType = json['lastCompletedCountry'] as String?;
    if (rawType != null) {
      for (final t in CountryType.values) {
        if (t.name == rawType) {
          parsedType = t;
          break;
        }
      }
    }
    final sets = (json['setsCompleted'] as int?) ?? 0;
    return PlayerStatsRecord(
      name: (json['name'] as String?) ?? 'Player',
      isHuman: (json['isHuman'] as bool?) ?? false,
      avatarIndex: (json['avatarIndex'] as int?) ?? 0,
      gamesPlayed: (json['gamesPlayed'] as int?) ?? 0,
      setsCompleted: sets,
      totalPoints: (json['totalPoints'] as int?) ?? (sets * 500),
      lastRoundPoints: (json['lastRoundPoints'] as int?) ?? 0,
      lastCompletedCountry: parsedType,
    );
  }
}

/// Manages and persists the number of games played, sets completed, and points per player.
class StatsService extends ChangeNotifier {
  static final StatsService instance = StatsService._internal();
  static const String _storageKey = 'country_game_player_stats_v1';

  static ({int setBonus, int speedBonus, int roundPoints}) computeRoundPoints({
    required int totalPlayers,
    required int turnCount,
  }) {
    final setBonus = (totalPlayers < 3 ? 3 : totalPlayers) * 100;
    final clampedTurns = turnCount < 0 ? 0 : turnCount;
    final rawSpeed = 250 - clampedTurns * 10;
    final speedBonus = rawSpeed < 50 ? 50 : rawSpeed;
    return (
      setBonus: setBonus,
      speedBonus: speedBonus,
      roundPoints: setBonus + speedBonus,
    );
  }

  int _totalGamesPlayed = 0;
  final Map<String, PlayerStatsRecord> _playerRecords =
      <String, PlayerStatsRecord>{};

  StatsService._internal() {
    _loadFromStorage();
  }

  int get totalGamesPlayed => _totalGamesPlayed;

  int get totalSetsCompleted => _playerRecords.values.fold<int>(
        0,
        (sum, record) => sum + record.setsCompleted,
      );

  PlayerStatsRecord getRecordForPlayer(GamePlayer player) {
    return _playerRecords[player.name] ??
        PlayerStatsRecord(
          name: player.name,
          isHuman: player.isHuman,
          avatarIndex: player.id,
          gamesPlayed: 0,
          setsCompleted: 0,
          totalPoints: 0,
          lastRoundPoints: 0,
        );
  }

  /// Returns stats records for the active match players (`You` first, followed by table order).
  List<PlayerStatsRecord> getRecordsForActivePlayers(List<GamePlayer> players) {
    return players.map(getRecordForPlayer).toList();
  }

  /// Returns all tracked player stats (ensuring 'You' is always present even before the first game).
  List<PlayerStatsRecord> getAllRecords({List<GamePlayer>? activePlayers}) {
    if (activePlayers != null && activePlayers.isNotEmpty) {
      return getRecordsForActivePlayers(activePlayers);
    }
    final list = _playerRecords.values.toList();
    if (!list.any((r) => r.isHuman)) {
      list.insert(
        0,
        const PlayerStatsRecord(
          name: 'You',
          isHuman: true,
          avatarIndex: 0,
          gamesPlayed: 0,
          setsCompleted: 0,
          totalPoints: 0,
          lastRoundPoints: 0,
        ),
      );
    }
    list.sort((a, b) {
      if (a.isHuman != b.isHuman) return a.isHuman ? -1 : 1;
      final byPoints = b.totalPoints.compareTo(a.totalPoints);
      if (byPoints != 0) return byPoints;
      final bySets = b.setsCompleted.compareTo(a.setsCompleted);
      if (bySets != 0) return bySets;
      return b.gamesPlayed.compareTo(a.gamesPlayed);
    });
    return list;
  }

  /// Records that a new game has started with [players].
  void recordGameStarted(List<GamePlayer> players) {
    _totalGamesPlayed++;
    for (final p in players) {
      final existing = getRecordForPlayer(p);
      _playerRecords[p.name] = existing.copyWith(
        isHuman: p.isHuman,
        avatarIndex: p.id,
        gamesPlayed: existing.gamesPlayed + 1,
      );
    }
    _saveToStorage();
    notifyListeners();
  }

  /// Records that [player] completed a set of [type] and awards round points.
  void recordSetCompleted(
    GamePlayer player,
    CountryType type, {
    int totalPlayers = 4,
    int turnCount = 1,
  }) {
    final existing = getRecordForPlayer(player);
    final score = computeRoundPoints(
      totalPlayers: totalPlayers,
      turnCount: turnCount,
    );
    _playerRecords[player.name] = existing.copyWith(
      isHuman: player.isHuman,
      avatarIndex: player.id,
      setsCompleted: existing.setsCompleted + 1,
      totalPoints: existing.totalPoints + score.roundPoints,
      lastRoundPoints: score.roundPoints,
      lastCompletedCountry: type,
    );
    _saveToStorage();
    notifyListeners();
  }

  /// Resets all games played and sets completed statistics.
  void resetStats({List<GamePlayer>? currentPlayers}) {
    _totalGamesPlayed = 0;
    _playerRecords.clear();
    if (currentPlayers != null) {
      for (final p in currentPlayers) {
        _playerRecords[p.name] = PlayerStatsRecord(
          name: p.name,
          isHuman: p.isHuman,
          avatarIndex: p.id,
          gamesPlayed: 0,
          setsCompleted: 0,
        );
      }
    }
    StatsStorage.remove(_storageKey);
    notifyListeners();
  }

  /// Reloads persisted statistics from storage (called after async mobile storage init).
  void reloadFromStorage() {
    _loadFromStorage();
    notifyListeners();
  }

  void _loadFromStorage() {
    final raw = StatsStorage.read(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _totalGamesPlayed = (decoded['totalGamesPlayed'] as int?) ?? 0;
      final recordsMap = decoded['players'] as Map<String, dynamic>?;
      if (recordsMap != null) {
        _playerRecords.clear();
        for (final entry in recordsMap.entries) {
          if (entry.value is Map<String, dynamic>) {
            _playerRecords[entry.key] = PlayerStatsRecord.fromJson(
              entry.value as Map<String, dynamic>,
            );
          }
        }
      }
    } catch (_) {}
  }

  void _saveToStorage() {
    try {
      final data = <String, dynamic>{
        'totalGamesPlayed': _totalGamesPlayed,
        'players': _playerRecords.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      };
      StatsStorage.write(_storageKey, jsonEncode(data));
    } catch (_) {}
  }
}
