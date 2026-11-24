import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../room_session.dart';
import 'lan_client_session.dart';
import 'lan_errors.dart';
import 'lan_host_session.dart';
import 'lan_protocol.dart';
import 'nearby_room.dart';

/// Nearby (Wi-Fi / hotspot) rooms on Android, iOS and desktop.
class LanRooms {
  static const bool isSupported = true;

  /// This phone's local Wi-Fi / hotspot addresses, best candidate first.
  static Future<List<String>> localAddresses() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    return LanProtocol.rankLocalAddresses(
      interfaces.expand((i) => i.addresses).map((a) => a.address),
    );
  }

  /// Opens a room on this phone. Throws [LanJoinException] with reason
  /// 'NO_NETWORK' when the phone is not on a Wi-Fi network or hotspot.
  static Future<RoomSession> create({
    required String myId,
    required String myName,
  }) async {
    final addresses = await localAddresses();
    if (addresses.isEmpty) {
      throw const LanJoinException(LanJoinException.noNetwork);
    }
    try {
      return await LanHostSession.start(
        hostId: myId,
        hostName: myName,
        address: addresses.first,
      );
    } on SocketException {
      throw const LanJoinException(LanJoinException.portBusy);
    }
  }

  /// Joins the room with [code] on this Wi-Fi / hotspot. A room heard by
  /// [discover] is tried first ([knownAddress]); otherwise the host address is
  /// worked out from the code on each local network this phone is on.
  static Future<RoomSession> join({
    required String code,
    required String myId,
    required String myName,
    String? knownAddress,
  }) async {
    final addresses = await localAddresses();
    final candidates = <String>{
      if (knownAddress != null) knownAddress,
      for (final local in addresses)
        if (LanProtocol.addressForCode(code, local) case final host?) host,
    };
    if (addresses.isEmpty && knownAddress == null) {
      throw const LanJoinException(LanJoinException.noNetwork);
    }

    LanJoinException? refusal;
    for (final host in candidates) {
      try {
        return await LanClientSession.connect(
          host: host,
          code: code,
          myId: myId,
          myName: myName,
        );
      } on LanJoinException catch (e) {
        // A real answer from a host (e.g. name taken) beats "unreachable".
        if (e.reason != LanJoinException.unreachable) refusal ??= e;
      }
    }
    throw refusal ?? const LanJoinException(LanProtocol.roomNotFound);
  }

  /// Rooms announced on the local network, refreshed as announcements arrive.
  /// Best-effort: some phones (notably iPhones) do not receive announcements;
  /// joining by code works without them.
  static Stream<List<NearbyRoom>> discover() {
    late StreamController<List<NearbyRoom>> controller;
    RawDatagramSocket? socket;
    Timer? pruneTimer;
    final rooms = <String, NearbyRoom>{};

    void emit() {
      final list = rooms.values.toList()
        ..sort((a, b) => a.code.compareTo(b.code));
      if (!controller.isClosed) controller.add(list);
    }

    controller = StreamController<List<NearbyRoom>>(
      onListen: () async {
        try {
          socket = await RawDatagramSocket.bind(
            InternetAddress.anyIPv4,
            LanProtocol.discoveryPort,
            reuseAddress: true,
          );
        } catch (_) {
          emit();
          return;
        }
        socket!.listen((event) {
          if (event != RawSocketEvent.read) return;
          final packet = socket?.receive();
          if (packet == null) return;
          try {
            final msg = jsonDecode(utf8.decode(packet.data));
            if (msg is! Map || msg['g'] != LanProtocol.game) return;
            final room = NearbyRoom(
              code: msg['code'] as String,
              hostName: msg['name'] as String? ?? '?',
              players: msg['players'] as int? ?? 1,
              address: packet.address.address,
              lastSeen: DateTime.now(),
            );
            rooms[room.code] = room;
            emit();
          } catch (_) {}
        });
        pruneTimer = Timer.periodic(const Duration(seconds: 2), (_) {
          final cutoff = DateTime.now().subtract(const Duration(seconds: 6));
          final before = rooms.length;
          rooms.removeWhere((_, r) => r.lastSeen.isBefore(cutoff));
          if (rooms.length != before) emit();
        });
        emit();
      },
      onCancel: () {
        pruneTimer?.cancel();
        socket?.close();
      },
    );
    return controller.stream;
  }
}
