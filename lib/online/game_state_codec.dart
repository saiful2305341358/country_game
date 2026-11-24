import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_player.dart';
import '../models/game_state.dart';

/// Converts [GameState] to and from JSON so a round can be stored in the
/// `rooms.state` column and sent to every phone in the room.
class GameStateCodec {
  static Map<String, dynamic> encode(GameState s) => <String, dynamic>{
        'totalPlayers': s.totalPlayers,
        'activeTypes': s.activeTypes.map((t) => t.name).toList(),
        'players': s.players.map(_player).toList(),
        'tableCard': _card(s.tableCard),
        'startingPlayerIndex': s.startingPlayerIndex,
        'currentTurnPlayerIndex': s.currentTurnPlayerIndex,
        'turnCount': s.turnCount,
        'isOpeningMove': s.isOpeningMove,
        'winnerIndex': s.winner?.id,
        'winningType': s.winningType?.name,
        'statusMessage': s.statusMessage,
        'moveLog': s.moveLog,
        'recentPlayedCards': s.recentPlayedCards.map(_history).toList(),
        'lastMovePlayerIndex': s.lastMovePlayerIndex,
        'lastMoveHandIndex': s.lastMoveHandIndex,
        'lastTakenCard': _cardOrNull(s.lastTakenCard),
        'lastDiscardedCard': _cardOrNull(s.lastDiscardedCard),
      };

  /// Throws [FormatException] when [json] is not a valid encoded state.
  static GameState decode(Map<String, dynamic> json) {
    try {
      final players = (json['players'] as List)
          .map((p) => _parsePlayer(p as Map<String, dynamic>))
          .toList();
      final winnerIndex = json['winnerIndex'] as int?;
      return GameState(
        totalPlayers: json['totalPlayers'] as int,
        activeTypes: (json['activeTypes'] as List)
            .map((t) => _type(t as String))
            .toList(),
        players: players,
        tableCard: _parseCard(json['tableCard'] as Map<String, dynamic>),
        startingPlayerIndex: json['startingPlayerIndex'] as int,
        currentTurnPlayerIndex: json['currentTurnPlayerIndex'] as int,
        turnCount: json['turnCount'] as int,
        isOpeningMove: json['isOpeningMove'] as bool,
        winner: winnerIndex == null ? null : players[winnerIndex],
        winningType: json['winningType'] == null
            ? null
            : _type(json['winningType'] as String),
        statusMessage: json['statusMessage'] as String? ?? '',
        moveLog: (json['moveLog'] as List? ?? const []).cast<String>(),
        recentPlayedCards: (json['recentPlayedCards'] as List? ?? const [])
            .map((e) => _parseHistory(e as Map<String, dynamic>))
            .toList(),
        lastMovePlayerIndex: json['lastMovePlayerIndex'] as int?,
        lastMoveHandIndex: json['lastMoveHandIndex'] as int?,
        lastTakenCard: _parseCardOrNull(json['lastTakenCard']),
        lastDiscardedCard: _parseCardOrNull(json['lastDiscardedCard']),
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Invalid game state: $e');
    }
  }

  static Map<String, dynamic> _card(GameCard c) => <String, dynamic>{
        'id': c.id,
        'type': c.type?.name,
        if (c.isStartingCard) 'starting': true,
      };

  static Map<String, dynamic>? _cardOrNull(GameCard? c) =>
      c == null ? null : _card(c);

  static GameCard _parseCard(Map<String, dynamic> j) => GameCard(
        id: j['id'] as String,
        type: j['type'] == null ? null : _type(j['type'] as String),
        isStartingCard: j['starting'] as bool? ?? false,
      );

  static GameCard? _parseCardOrNull(Object? j) =>
      j == null ? null : _parseCard(j as Map<String, dynamic>);

  static Map<String, dynamic> _player(GamePlayer p) => <String, dynamic>{
        'id': p.id,
        'name': p.name,
        'isHuman': p.isHuman,
        'isFemale': p.isFemale,
        'homeType': p.homeType.name,
        'hand': p.hand.map(_card).toList(),
      };

  static GamePlayer _parsePlayer(Map<String, dynamic> j) => GamePlayer(
        id: j['id'] as int,
        name: j['name'] as String,
        isHuman: j['isHuman'] as bool,
        isFemale: j['isFemale'] as bool? ?? false,
        homeType: _type(j['homeType'] as String),
        hand: List.unmodifiable(
          (j['hand'] as List).map((c) => _parseCard(c as Map<String, dynamic>)),
        ),
      );

  static Map<String, dynamic> _history(PlayedCardHistoryEntry e) =>
      <String, dynamic>{
        'turnNumber': e.turnNumber,
        'playerId': e.playerId,
        'playerName': e.playerName,
        'isHuman': e.isHuman,
        'isFemale': e.isFemale,
        'playedCard': _card(e.playedCard),
        'takenCard': _card(e.takenCard),
      };

  static PlayedCardHistoryEntry _parseHistory(Map<String, dynamic> j) =>
      PlayedCardHistoryEntry(
        turnNumber: j['turnNumber'] as int,
        playerId: j['playerId'] as int,
        playerName: j['playerName'] as String,
        isHuman: j['isHuman'] as bool,
        isFemale: j['isFemale'] as bool? ?? false,
        playedCard: _parseCard(j['playedCard'] as Map<String, dynamic>),
        takenCard: _parseCard(j['takenCard'] as Map<String, dynamic>),
      );

  static CountryType _type(String name) => CountryType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => throw FormatException('Unknown country "$name"'),
      );
}
