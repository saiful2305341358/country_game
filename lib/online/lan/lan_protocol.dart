/// Shared definitions for nearby (Wi-Fi / hotspot) rooms.
///
/// The host's phone runs a WebSocket server on the local network; friends'
/// phones connect to it directly (no internet). The 3-digit room code is the
/// last part of the host's IPv4 address (192.168.43.1 -> "001"), so a phone on
/// the same Wi-Fi / hotspot can work out the host's address from the code.
abstract final class LanProtocol {
  /// TCP port of the host's WebSocket server.
  static const int roomPort = 47820;

  /// UDP port for "a room is open here" announcements (best-effort discovery).
  static const int discoveryPort = 47821;

  static const String path = '/country-game-room';
  static const int version = 1;
  static const String game = 'country_game';

  /// Seconds a disconnected player keeps their seat before being removed
  /// (covers screen locks and short Wi-Fi drops).
  static const Duration reconnectGrace = Duration(seconds: 20);

  // Message types.
  static const String hello = 'hello'; // client -> host: {id, name, code}
  static const String welcome = 'welcome'; // host -> client
  static const String reject = 'reject'; // host -> client: {reason}
  static const String room = 'room'; // host -> clients: full room snapshot
  static const String move = 'move'; // client -> host: {round, turn, cardId}
  static const String leave = 'leave'; // client -> host
  static const String closed = 'closed'; // host -> clients: room closed

  // Reject reasons (same names as the Internet rooms use).
  static const String roomNotFound = 'ROOM_NOT_FOUND';
  static const String roomFull = 'ROOM_FULL';
  static const String nameTaken = 'NAME_TAKEN';
  static const String nameRequired = 'NAME_REQUIRED';

  /// Room code for a host at [ipv4] (its last number, padded to 3 digits).
  static String codeForAddress(String ipv4) {
    final parts = ipv4.split('.');
    if (parts.length != 4) throw FormatException('Not an IPv4 address: $ipv4');
    final last = int.parse(parts[3]);
    if (last < 0 || last > 255) {
      throw FormatException('Not an IPv4 address: $ipv4');
    }
    return last.toString().padLeft(3, '0');
  }

  /// The host address for [code] on the network of a phone at [localIpv4]
  /// (same first three numbers), or null when the code cannot be an address.
  static String? addressForCode(String code, String localIpv4) {
    if (!RegExp(r'^\d{3}$').hasMatch(code)) return null;
    final last = int.parse(code);
    if (last < 1 || last > 254) return null;
    final parts = localIpv4.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}.$last';
  }

  /// Orders candidate local addresses: Wi-Fi / hotspot ranges first, because
  /// 10.x is often the mobile-data (carrier) address. Public and loopback
  /// addresses are dropped.
  static List<String> rankLocalAddresses(Iterable<String> addresses) {
    int rank(String ip) {
      final p = ip.split('.').map(int.tryParse).toList();
      if (p.length != 4 || p.contains(null)) return -1;
      if (p[0] == 192 && p[1] == 168) return 3;
      if (p[0] == 172 && p[1]! >= 16 && p[1]! <= 31) return 2;
      if (p[0] == 10) return 1;
      return -1;
    }

    final ranked = addresses.where((ip) => rank(ip) > 0).toSet().toList()
      ..sort((a, b) => rank(b).compareTo(rank(a)));
    return ranked;
  }
}
