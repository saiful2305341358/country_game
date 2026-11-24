import 'package:flutter/foundation.dart';

/// A room announced on the local network.
@immutable
class NearbyRoom {
  final String code;
  final String hostName;
  final int players;
  final String address;
  final DateTime lastSeen;

  const NearbyRoom({
    required this.code,
    required this.hostName,
    required this.players,
    required this.address,
    required this.lastSeen,
  });
}
