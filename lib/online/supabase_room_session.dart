import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game_card.dart';
import '../models/game_state.dart';
import 'game_state_codec.dart';
import 'host_referee.dart';
import 'room_session.dart';
import 'supabase_config.dart';

/// Connects to Supabase on first use and signs this phone in anonymously.
/// Offline play never calls this, so the app starts without a network.
class OnlineBackend {
  static Future<SupabaseClient>? _client;

  static Future<SupabaseClient> client() {
    return _client ??= _connect().catchError((Object e) {
      _client = null; // allow a retry, e.g. after the network comes back
      throw e;
    });
  }

  static bool _initialized = false;

  static Future<SupabaseClient> _connect() async {
    if (!_initialized) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
      );
      _initialized = true;
    }
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      await client.auth.signInAnonymously();
    }
    return client;
  }
}

/// Turns server and network errors into short messages for players.
String friendlyRoomError(Object error) {
  final text = error is PostgrestException
      ? error.message
      : error is AuthException
          ? 'AUTH:${error.message}'
          : error.toString();
  if (text.contains('ROOM_NOT_FOUND')) return 'No open room has that code.';
  if (text.contains('ROOM_FULL')) return 'That room is full (7 players).';
  if (text.contains('NAME_TAKEN')) {
    return 'Someone in that room already uses that name. Pick another name.';
  }
  if (text.contains('NAME_REQUIRED')) return 'Please enter your name first.';
  if (text.contains('NO_FREE_CODE')) {
    return 'All room codes are busy right now. Try again in a minute.';
  }
  if (text.startsWith('AUTH:')) {
    return 'Could not sign in to the game server (${text.substring(5)}).';
  }
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('XMLHttpRequest') ||
      text.contains('TimeoutException')) {
    return 'Cannot reach the game server. Check your internet connection.';
  }
  return 'Something went wrong: $text';
}

/// A room shared through Supabase. The host's phone is the referee: it reads
/// move requests from `room_moves`, applies them with [HostReferee] and writes
/// the new state to `rooms.state`, which every phone receives in real time.
class SupabaseRoomSession extends RoomSession {
  static const Duration _moveTimeout = Duration(seconds: 10);

  final SupabaseClient _db;
  final String _roomId;
  RealtimeChannel? _channel;

  String _code;
  String _hostId;
  RoomStatus _status = RoomStatus.lobby;
  int _round = 0;
  List<String> _seats = const [];
  GameState? _state;
  String? _notice;
  String? _error;
  List<RoomMember> _members = const [];
  final Map<String, String> _knownNames = {};

  bool _submitting = false;
  int? _submittedTurn;
  Timer? _submitTimer;
  Future<void> _hostQueue = Future<void>.value();
  bool _disposed = false;

  SupabaseRoomSession._(this._db, Map<String, dynamic> row)
      : _roomId = row['id'] as String,
        _code = row['code'] as String,
        _hostId = row['host_id'] as String {
    _applyRoomRow(row);
  }

  /// Creates a new room (this phone becomes the host).
  ///
  /// [client] replaces the app's shared connection (used by tests that act as
  /// several phones at once).
  static Future<SupabaseRoomSession> create(
    String playerName, {
    SupabaseClient? client,
  }) async {
    final db = client ?? await OnlineBackend.client();
    final row = await db.rpc('create_room', params: {'p_name': playerName});
    return _open(db, row as Map<String, dynamic>);
  }

  /// Joins the open room with [code].
  static Future<SupabaseRoomSession> join(
    String code,
    String playerName, {
    SupabaseClient? client,
  }) async {
    final db = client ?? await OnlineBackend.client();
    final row = await db.rpc(
      'join_room',
      params: {'p_code': code, 'p_name': playerName},
    );
    return _open(db, row as Map<String, dynamic>);
  }

  static Future<SupabaseRoomSession> _open(
    SupabaseClient db,
    Map<String, dynamic> row,
  ) async {
    final session = SupabaseRoomSession._(db, row);
    await session._refreshAll();
    session._subscribe();
    return session;
  }

  // ------------------------------------------------------------ RoomSession

  @override
  String get code => _code;
  @override
  String get myUserId => _db.auth.currentUser?.id ?? '';
  @override
  String get hostUserId => _hostId;
  @override
  RoomStatus get status => _status;
  @override
  int get round => _round;
  @override
  List<RoomMember> get members => _members;
  @override
  List<String> get seats => _seats;
  @override
  GameState? get gameState => _state;
  @override
  String? get notice => _notice;
  @override
  bool get isSubmittingMove => _submitting;

  @override
  String? takeError() {
    final e = _error;
    _error = null;
    return e;
  }

  @override
  Future<void> startRound() async {
    if (!isHost) return;
    await _refreshMembers();
    if (!canStartRound) {
      _fail('A round needs ${HostReferee.minPlayers} to '
          '${HostReferee.maxPlayers} players in the room.');
      return;
    }
    final players = List<RoomMember>.of(_members);
    try {
      final state = HostReferee.startRound(players.map((m) => m.name).toList());
      await _updateRoom({
        'status': 'playing',
        'round': _round + 1,
        'seats': players.map((m) => m.userId).toList(),
        'state': GameStateCodec.encode(state),
        'notice': null,
      });
    } catch (e) {
      _fail(friendlyRoomError(e));
    }
  }

  @override
  Future<void> backToLobby({String? notice}) async {
    if (!isHost) return;
    try {
      await _updateRoom({
        'status': 'lobby',
        'seats': <String>[],
        'state': null,
        'notice': notice,
      });
    } catch (e) {
      _fail(friendlyRoomError(e));
    }
  }

  @override
  Future<void> playCard(GameCard card) async {
    final s = _state;
    if (s == null ||
        _status != RoomStatus.playing ||
        _submitting ||
        mySeat != s.currentTurnPlayerIndex) {
      return;
    }
    _setSubmitting(s.turnCount);
    final move = <String, dynamic>{
      'room_id': _roomId,
      'round': _round,
      'turn': s.turnCount,
      'card_id': card.id,
    };
    try {
      if (isHost) {
        _enqueueHostMove({...move, 'user_id': myUserId});
        await _hostQueue;
      } else {
        await _db.from('room_moves').insert(move);
      }
    } catch (e) {
      _clearSubmitting();
      _fail(friendlyRoomError(e));
    }
  }

  @override
  Future<void> leave() async {
    _status = RoomStatus.closed;
    _notify();
    try {
      await _db.rpc('leave_room', params: {'p_room': _roomId});
    } catch (_) {
      // Leaving locally is what matters; abandoned rooms expire on the server.
    }
    await _unsubscribe();
  }

  @override
  void dispose() {
    _disposed = true;
    _submitTimer?.cancel();
    _unsubscribe();
    super.dispose();
  }

  // ------------------------------------------------------------ sync

  void _subscribe() {
    PostgresChangeFilter byRoom(String column) => PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: column,
          value: _roomId,
        );

    final channel = _db.channel('room-$_roomId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'rooms',
        filter: byRoom('id'),
        callback: (payload) => _onRoomRow(payload.newRecord),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'room_members',
        filter: byRoom('room_id'),
        callback: (_) => _refreshMembers(),
      );
    if (isHost) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'room_moves',
        filter: byRoom('room_id'),
        callback: (payload) => _enqueueHostMove(payload.newRecord),
      );
    }
    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        // (Re)connected: catch up on anything missed while disconnected.
        _refreshAll();
      } else if (status == RealtimeSubscribeStatus.channelError ||
          status == RealtimeSubscribeStatus.timedOut) {
        _fail('Connection problem. Reconnecting…');
      }
    });
    _channel = channel;
  }

  Future<void> _unsubscribe() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      try {
        await _db.removeChannel(channel);
      } catch (_) {}
    }
  }

  Future<void> _refreshAll() async {
    try {
      final row =
          await _db.from('rooms').select().eq('id', _roomId).maybeSingle();
      if (row == null) {
        // No longer visible: the room was closed or we were removed.
        _status = RoomStatus.closed;
        _notify();
        return;
      }
      _onRoomRow(row);
      await _refreshMembers();
      if (isHost) await _catchUpMoves();
    } catch (e) {
      _fail(friendlyRoomError(e));
    }
  }

  Future<void> _refreshMembers() async {
    try {
      final rows = await _db
          .from('room_members')
          .select('user_id, name, joined_at')
          .eq('room_id', _roomId)
          .isFilter('left_at', null)
          .order('joined_at', ascending: true);
      final previous = _members;
      _members = rows
          .map((r) => RoomMember(
                userId: r['user_id'] as String,
                name: r['name'] as String,
                joinedAt: DateTime.parse(r['joined_at'] as String),
              ))
          .toList();
      for (final m in _members) {
        _knownNames[m.userId] = m.name;
      }
      _notify();
      if (isHost) _stopRoundIfPlayerLeft(previous);
    } catch (e) {
      _fail(friendlyRoomError(e));
    }
  }

  /// Host: a round cannot continue without one of its players (their cards
  /// would be missing), so it is stopped and everyone returns to the lobby.
  void _stopRoundIfPlayerLeft(List<RoomMember> previous) {
    if (_status != RoomStatus.playing) return;
    final present = _members.map((m) => m.userId).toSet();
    final gone = _seats.where((id) => !present.contains(id)).toList();
    if (gone.isEmpty) return;
    final names = gone.map((id) => _knownNames[id] ?? 'A player').join(', ');
    backToLobby(notice: '$names left the room, so the round was stopped.');
  }

  void _onRoomRow(Map<String, dynamic> row) {
    if (row.isEmpty || row['id'] != _roomId) return;
    _applyRoomRow(row);
    final s = _state;
    if (_submitting && (s == null || s.turnCount != _submittedTurn)) {
      _clearSubmitting();
    }
    _notify();
  }

  void _applyRoomRow(Map<String, dynamic> row) {
    _code = row['code'] as String? ?? _code;
    _hostId = row['host_id'] as String? ?? _hostId;
    _status = switch (row['status']) {
      'playing' => RoomStatus.playing,
      'round_over' => RoomStatus.roundOver,
      'closed' => RoomStatus.closed,
      _ => RoomStatus.lobby,
    };
    _round = row['round'] as int? ?? _round;
    _seats = (row['seats'] as List? ?? const []).cast<String>();
    _notice = row['notice'] as String?;
    final rawState = row['state'];
    try {
      _state = rawState is Map<String, dynamic>
          ? GameStateCodec.decode(rawState)
          : null;
    } on FormatException catch (e) {
      _state = null;
      _error = 'Received a damaged game state ($e).';
    }
  }

  // ------------------------------------------------------------ host referee

  void _enqueueHostMove(Map<String, dynamic> move) {
    _hostQueue = _hostQueue
        .then((_) => _applyHostMove(move))
        .catchError((Object e) => _fail(friendlyRoomError(e)));
  }

  /// Applies one move request if it is for the current turn; stale, duplicate
  /// and illegal requests are ignored (the sender's phone just stays in sync).
  Future<void> _applyHostMove(Map<String, dynamic> move) async {
    final s = _state;
    if (s == null || _status != RoomStatus.playing) return;
    if (move['round'] != _round || move['turn'] != s.turnCount) return;
    final seat = _seats.indexOf(move['user_id'] as String? ?? '');
    if (seat < 0) return;
    final next = HostReferee.applyMove(s, seat, move['card_id'] as String);
    if (next == null) return;
    await _updateRoom({
      'state': GameStateCodec.encode(next),
      'status': next.isGameOver ? 'round_over' : 'playing',
    });
  }

  /// Host: replays moves sent while this phone was disconnected.
  Future<void> _catchUpMoves() async {
    final s = _state;
    if (s == null || _status != RoomStatus.playing) return;
    final rows = await _db
        .from('room_moves')
        .select('room_id, user_id, round, turn, card_id')
        .eq('room_id', _roomId)
        .eq('round', _round)
        .gte('turn', s.turnCount)
        .order('id', ascending: true);
    for (final row in rows) {
      _enqueueHostMove(row);
    }
  }

  Future<void> _updateRoom(Map<String, dynamic> values) async {
    final row = await _db
        .from('rooms')
        .update(values)
        .eq('id', _roomId)
        .select()
        .single();
    _onRoomRow(row);
  }

  // ------------------------------------------------------------ helpers

  void _setSubmitting(int turn) {
    _submitting = true;
    _submittedTurn = turn;
    _submitTimer?.cancel();
    _submitTimer = Timer(_moveTimeout, () {
      if (_submitting && _submittedTurn == turn) {
        _clearSubmitting();
        _fail(
            'Your move was not confirmed. Check the connection and try again.');
      }
    });
    _notify();
  }

  void _clearSubmitting() {
    _submitting = false;
    _submittedTurn = null;
    _submitTimer?.cancel();
  }

  void _fail(String message) {
    _error = message;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
