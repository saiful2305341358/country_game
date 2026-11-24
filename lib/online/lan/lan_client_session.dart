import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/game_card.dart';
import '../../models/game_state.dart';
import '../game_state_codec.dart';
import '../room_session.dart';
import 'lan_errors.dart';
import 'lan_protocol.dart';

/// A friend's phone in a nearby room: it sends move requests to the host's
/// phone and shows the room snapshots the host sends back.
class LanClientSession extends RoomSession {
  static const Duration _connectTimeout = Duration(seconds: 4);
  static const Duration _moveTimeout = Duration(seconds: 8);

  final String _host;
  final int _port;
  final String _myId;
  final String _myName;
  WebSocket? _socket;
  bool _leaving = false;
  bool _disposed = false;
  bool _reconnecting = false;

  String _code;
  String _hostId = '';
  String? _address;
  RoomStatus _status = RoomStatus.lobby;
  int _round = 0;
  List<String> _seats = const [];
  GameState? _state;
  String? _notice;
  String? _error;
  List<RoomMember> _members = const [];

  bool _submitting = false;
  int? _submittedTurn;
  Timer? _submitTimer;

  LanClientSession._(
      this._host, this._port, this._myId, this._myName, this._code);

  /// Connects to the room hosted at [host]:[port]. Throws [LanJoinException].
  static Future<LanClientSession> connect({
    required String host,
    int port = LanProtocol.roomPort,
    required String code,
    required String myId,
    required String myName,
  }) async {
    final session = LanClientSession._(host, port, myId, myName, code);
    await session._open();
    return session;
  }

  // ------------------------------------------------------------ RoomSession

  @override
  String get code => _code;
  @override
  String get myUserId => _myId;
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
  String? get connectionInfo =>
      _address == null ? null : 'Host address $_address';

  @override
  String? takeError() {
    final e = _error;
    _error = null;
    return e;
  }

  // Only the host starts rounds and returns to the lobby.
  @override
  Future<void> startRound() async {}
  @override
  Future<void> backToLobby({String? notice}) async {}

  @override
  Future<void> playCard(GameCard card) async {
    final s = _state;
    final socket = _socket;
    if (s == null ||
        socket == null ||
        _status != RoomStatus.playing ||
        _submitting ||
        mySeat != s.currentTurnPlayerIndex) {
      return;
    }
    final turn = s.turnCount;
    _submitting = true;
    _submittedTurn = turn;
    _submitTimer?.cancel();
    _submitTimer = Timer(_moveTimeout, () {
      if (_submitting && _submittedTurn == turn) {
        _clearSubmitting();
        _fail('Your move was not confirmed. Check the Wi-Fi and try again.');
      }
    });
    _changed();
    socket.add(jsonEncode({
      't': LanProtocol.move,
      'round': _round,
      'turn': turn,
      'cardId': card.id,
    }));
  }

  @override
  Future<void> leave() async {
    _leaving = true;
    _status = RoomStatus.closed;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        socket.add(jsonEncode({'t': LanProtocol.leave}));
        await socket.close();
      } catch (_) {}
    }
    _changed();
  }

  /// Tests only: cut the connection as if the Wi-Fi dropped (the session then
  /// reconnects on its own).
  @visibleForTesting
  void debugDropConnection() => _socket?.close();

  @override
  void dispose() {
    _disposed = true;
    _leaving = true;
    _submitTimer?.cancel();
    _socket?.close();
    _socket = null;
    super.dispose();
  }

  // ------------------------------------------------------------ connection

  /// Opens the socket, says hello and waits for the host's answer.
  Future<void> _open() async {
    final WebSocket socket;
    try {
      socket = await WebSocket.connect('ws://$_host:$_port${LanProtocol.path}')
          .timeout(_connectTimeout);
    } catch (_) {
      throw const LanJoinException(LanJoinException.unreachable);
    }
    socket.pingInterval = const Duration(seconds: 5);
    final answer = Completer<void>();
    socket.listen(
      (data) {
        final msg = _decode(data);
        if (msg == null) return;
        if (!answer.isCompleted) {
          if (msg['t'] == LanProtocol.welcome) {
            answer.complete();
          } else if (msg['t'] == LanProtocol.reject) {
            answer.completeError(
              LanJoinException(
                  msg['reason'] as String? ?? LanProtocol.roomNotFound),
            );
          }
          return;
        }
        _onMessage(msg);
      },
      onDone: () {
        if (!answer.isCompleted) {
          answer.completeError(
            const LanJoinException(LanJoinException.unreachable),
          );
        } else if (identical(_socket, socket)) {
          _onConnectionLost();
        }
      },
      onError: (_) {},
      cancelOnError: true,
    );
    socket.add(jsonEncode({
      't': LanProtocol.hello,
      'v': LanProtocol.version,
      'id': _myId,
      'name': _myName,
      'code': _code,
    }));
    try {
      await answer.future.timeout(_connectTimeout);
    } on TimeoutException {
      await socket.close();
      throw const LanJoinException(LanJoinException.unreachable);
    } catch (_) {
      await socket.close();
      rethrow;
    }
    _socket = socket;
  }

  /// Tries to reconnect for the grace period the host keeps our seat.
  Future<void> _onConnectionLost() async {
    _socket = null;
    if (_leaving || _disposed || _reconnecting) return;
    _reconnecting = true;
    _fail('Connection to the host lost. Reconnecting…');
    final deadline = DateTime.now().add(LanProtocol.reconnectGrace);
    while (!_leaving && !_disposed && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_leaving || _disposed) break;
      try {
        await _open();
        _reconnecting = false;
        _fail('Reconnected.');
        return;
      } catch (_) {}
    }
    _reconnecting = false;
    if (!_leaving && !_disposed) {
      _status = RoomStatus.closed;
      _fail('Lost connection to the host.');
    }
  }

  void _onMessage(Map<String, dynamic> msg) {
    switch (msg['t']) {
      case LanProtocol.room:
        _applySnapshot(msg);
      case LanProtocol.closed:
        _leaving = true;
        _status = RoomStatus.closed;
        _changed();
    }
  }

  void _applySnapshot(Map<String, dynamic> msg) {
    _code = msg['code'] as String? ?? _code;
    _hostId = msg['hostId'] as String? ?? _hostId;
    _address = msg['address'] as String? ?? _address;
    _status = RoomStatus.values.firstWhere(
      (s) => s.name == msg['status'],
      orElse: () => RoomStatus.lobby,
    );
    _round = msg['round'] as int? ?? _round;
    _seats = (msg['seats'] as List? ?? const []).cast<String>();
    _notice = msg['notice'] as String?;
    _members = [
      for (final m in (msg['members'] as List? ?? const []))
        RoomMember(
          userId: m['id'] as String,
          name: m['name'] as String,
          joinedAt: DateTime.tryParse(m['joinedAt'] as String? ?? '') ??
              DateTime.now(),
          connected: m['connected'] as bool? ?? true,
        ),
    ];
    final raw = msg['state'];
    try {
      _state = raw is Map<String, dynamic> ? GameStateCodec.decode(raw) : null;
    } on FormatException catch (e) {
      _state = null;
      _error = 'Received a damaged game state ($e).';
    }
    if (_submitting &&
        (_state == null || _state!.turnCount != _submittedTurn)) {
      _clearSubmitting();
    }
    _changed();
  }

  // ------------------------------------------------------------ helpers

  void _clearSubmitting() {
    _submitting = false;
    _submittedTurn = null;
    _submitTimer?.cancel();
  }

  void _fail(String message) {
    _error = message;
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  static Map<String, dynamic>? _decode(Object? data) {
    if (data is! String) return null;
    try {
      final decoded = jsonDecode(data);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
