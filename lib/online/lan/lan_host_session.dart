import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../models/game_card.dart';
import '../../models/game_state.dart';
import '../game_state_codec.dart';
import '../host_referee.dart';
import '../room_session.dart';
import 'lan_protocol.dart';

/// A nearby room hosted on this phone: a WebSocket server on the local network
/// that is also the referee (it applies moves with [HostReferee] and sends the
/// room to every connected phone after each change).
class LanHostSession extends RoomSession {
  final HttpServer _server;
  final String _code;
  final String _hostId;
  final String _address;
  RawDatagramSocket? _beacon;
  Timer? _beaconTimer;

  final List<_Peer> _peers = [];
  late final _Peer _self;

  RoomStatus _status = RoomStatus.lobby;
  int _round = 0;
  List<String> _seats = const [];
  GameState? _state;
  String? _notice;
  String? _error;
  bool _disposed = false;

  LanHostSession._(
    this._server,
    this._code,
    this._hostId,
    this._address,
    String hostName,
  ) {
    _self = _Peer(_hostId, hostName, DateTime.now(), isHost: true);
    _peers.add(_self);
    _server.listen(_onRequest, onError: (_) {});
  }

  /// Opens a room on this phone.
  ///
  /// [address] is this phone's local IPv4 address (it determines the code).
  /// [port] and [bindAddress] can be changed for tests (port 0 = any free port).
  /// When [announce] is true, the room is announced on the local network so
  /// nearby phones can list it.
  static Future<LanHostSession> start({
    required String hostId,
    required String hostName,
    required String address,
    int port = LanProtocol.roomPort,
    Object? bindAddress,
    bool announce = true,
  }) async {
    final server = await HttpServer.bind(
      bindAddress ?? InternetAddress.anyIPv4,
      port,
      shared: false,
    );
    final session = LanHostSession._(
      server,
      LanProtocol.codeForAddress(address),
      hostId,
      address,
      hostName,
    );
    if (announce) await session._startBeacon();
    return session;
  }

  /// The TCP port the room is served on.
  int get port => _server.port;

  // ------------------------------------------------------------ RoomSession

  @override
  String get code => _code;
  @override
  String get myUserId => _hostId;
  @override
  String get hostUserId => _hostId;
  @override
  RoomStatus get status => _status;
  @override
  int get round => _round;
  @override
  List<String> get seats => _seats;
  @override
  GameState? get gameState => _state;
  @override
  String? get notice => _notice;
  @override
  bool get isSubmittingMove => false;
  @override
  String? get connectionInfo => 'Host address $_address';

  @override
  List<RoomMember> get members => _peers
      .map((p) => RoomMember(
            userId: p.id,
            name: p.name,
            joinedAt: p.joinedAt,
            connected: p.isHost || p.socket != null,
          ))
      .toList();

  @override
  String? takeError() {
    final e = _error;
    _error = null;
    return e;
  }

  @override
  Future<void> startRound() async {
    if (!canStartRound) {
      _error = 'A round needs ${HostReferee.minPlayers} to '
          '${HostReferee.maxPlayers} players in the room.';
      _changed();
      return;
    }
    final players = List<_Peer>.of(_peers);
    _state = HostReferee.startRound(players.map((p) => p.name).toList());
    _seats = players.map((p) => p.id).toList();
    _round++;
    _status = RoomStatus.playing;
    _notice = null;
    _changed();
  }

  @override
  Future<void> backToLobby({String? notice}) async {
    _status = RoomStatus.lobby;
    _seats = const [];
    _state = null;
    _notice = notice;
    _changed();
  }

  @override
  Future<void> playCard(GameCard card) async {
    _applyMove(_hostId, _round, _state?.turnCount ?? -1, card.id);
  }

  @override
  Future<void> leave() async {
    if (_status == RoomStatus.closed) return;
    _status = RoomStatus.closed;
    _broadcast({'t': LanProtocol.closed});
    _changed(broadcast: false);
    await _shutdown();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_status != RoomStatus.closed) {
      _status = RoomStatus.closed;
      _broadcast({'t': LanProtocol.closed});
    }
    _shutdown();
    super.dispose();
  }

  // ------------------------------------------------------------ connections

  Future<void> _onRequest(HttpRequest request) async {
    if (request.uri.path != LanProtocol.path ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final WebSocket socket;
    try {
      socket = await WebSocketTransformer.upgrade(request);
    } catch (_) {
      return;
    }
    socket.pingInterval = const Duration(seconds: 5);
    _Peer? peer;
    socket.listen(
      (data) {
        final msg = _decode(data);
        if (msg == null) return;
        if (peer == null) {
          peer = _onHello(socket, msg);
        } else {
          _onMessage(peer!, msg);
        }
      },
      onDone: () {
        final p = peer;
        if (p != null && identical(p.socket, socket)) _onDisconnected(p);
      },
      onError: (_) {},
      cancelOnError: true,
    );
  }

  /// Handles a phone's first message; returns its peer when accepted.
  _Peer? _onHello(WebSocket socket, Map<String, dynamic> msg) {
    void refuse(String reason) {
      socket.add(jsonEncode({'t': LanProtocol.reject, 'reason': reason}));
      socket.close();
    }

    if (msg['t'] != LanProtocol.hello) {
      socket.close();
      return null;
    }
    final id = msg['id'] as String? ?? '';
    final name = (msg['name'] as String? ?? '').trim();
    final code = msg['code'] as String?;
    if (_status == RoomStatus.closed || (code != null && code != _code)) {
      refuse(LanProtocol.roomNotFound);
      return null;
    }
    if (id.isEmpty || name.isEmpty || name.length > 16) {
      refuse(LanProtocol.nameRequired);
      return null;
    }

    var peer = _peers.where((p) => p.id == id).firstOrNull;
    if (peer != null && !peer.isHost) {
      // The same phone reconnecting: give it its seat back.
      peer.dropTimer?.cancel();
      peer.dropTimer = null;
      peer.socket?.close();
      peer.socket = socket;
      peer.name = name;
    } else {
      final taken =
          _peers.any((p) => p.name.toLowerCase() == name.toLowerCase());
      if (taken || peer != null) {
        refuse(LanProtocol.nameTaken);
        return null;
      }
      if (_peers.length >= HostReferee.maxPlayers) {
        refuse(LanProtocol.roomFull);
        return null;
      }
      peer = _Peer(id, name, DateTime.now())..socket = socket;
      _peers.add(peer);
    }
    socket.add(jsonEncode({'t': LanProtocol.welcome, 'code': _code}));
    _changed();
    return peer;
  }

  void _onMessage(_Peer peer, Map<String, dynamic> msg) {
    switch (msg['t']) {
      case LanProtocol.move:
        _applyMove(
          peer.id,
          msg['round'] as int? ?? -1,
          msg['turn'] as int? ?? -1,
          msg['cardId'] as String? ?? '',
        );
      case LanProtocol.leave:
        peer.socket?.close();
        peer.socket = null;
        _removePeer(peer);
    }
  }

  void _onDisconnected(_Peer peer) {
    peer.socket = null;
    _changed();
    peer.dropTimer?.cancel();
    peer.dropTimer = Timer(LanProtocol.reconnectGrace, () => _removePeer(peer));
  }

  void _removePeer(_Peer peer) {
    peer.dropTimer?.cancel();
    if (!_peers.remove(peer)) return;
    if (_status == RoomStatus.playing && _seats.contains(peer.id)) {
      backToLobby(
          notice: '${peer.name} left the room, so the round was stopped.');
    } else {
      _changed();
    }
  }

  /// Applies a move request; stale, duplicate and illegal ones are ignored.
  void _applyMove(String userId, int round, int turn, String cardId) {
    final s = _state;
    if (s == null || _status != RoomStatus.playing) return;
    if (round != _round || turn != s.turnCount) return;
    final seat = _seats.indexOf(userId);
    if (seat < 0) return;
    final next = HostReferee.applyMove(s, seat, cardId);
    if (next == null) return;
    _state = next;
    if (next.isGameOver) _status = RoomStatus.roundOver;
    _changed();
  }

  // ------------------------------------------------------------ sync

  Map<String, dynamic> _snapshot() => {
        't': LanProtocol.room,
        'code': _code,
        'hostId': _hostId,
        'address': _address,
        'status': _status.name,
        'round': _round,
        'seats': _seats,
        'notice': _notice,
        'members': [
          for (final m in members)
            {
              'id': m.userId,
              'name': m.name,
              'joinedAt': m.joinedAt.toIso8601String(),
              'connected': m.connected,
            },
        ],
        'state': _state == null ? null : GameStateCodec.encode(_state!),
      };

  void _broadcast(Map<String, dynamic> message) {
    final text = jsonEncode(message);
    for (final p in _peers) {
      final socket = p.socket;
      if (socket != null) {
        try {
          socket.add(text);
        } catch (_) {}
      }
    }
  }

  void _changed({bool broadcast = true}) {
    if (broadcast && _status != RoomStatus.closed) _broadcast(_snapshot());
    if (!_disposed) notifyListeners();
  }

  // ------------------------------------------------------------ discovery

  Future<void> _startBeacon() async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      _beacon = socket;
      final targets = {
        InternetAddress('255.255.255.255'),
        InternetAddress(_address.replaceFirst(RegExp(r'\.\d+$'), '.255')),
      };
      void send() {
        if (_status == RoomStatus.closed) return;
        final data = utf8.encode(jsonEncode({
          'g': LanProtocol.game,
          'v': LanProtocol.version,
          'code': _code,
          'name': _self.name,
          'players': _peers.length,
          'port': port,
        }));
        for (final target in targets) {
          try {
            socket.send(data, target, LanProtocol.discoveryPort);
          } catch (_) {}
        }
      }

      send();
      _beaconTimer =
          Timer.periodic(const Duration(milliseconds: 1500), (_) => send());
    } catch (_) {
      // Discovery is optional; joining by code still works.
    }
  }

  Future<void> _shutdown() async {
    _beaconTimer?.cancel();
    _beacon?.close();
    for (final p in _peers) {
      p.dropTimer?.cancel();
      await p.socket?.close();
      p.socket = null;
    }
    await _server.close(force: true);
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

class _Peer {
  final String id;
  String name;
  final DateTime joinedAt;
  final bool isHost;
  WebSocket? socket;
  Timer? dropTimer;

  _Peer(this.id, this.name, this.joinedAt, {this.isHost = false});
}
