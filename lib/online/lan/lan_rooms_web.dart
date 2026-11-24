import '../room_session.dart';
import 'nearby_room.dart';

/// Browsers cannot open local network connections, so nearby rooms are only
/// available in the Android, iOS and desktop apps.
class LanRooms {
  static const bool isSupported = false;

  static Future<List<String>> localAddresses() async => const [];

  static Future<RoomSession> create({
    required String myId,
    required String myName,
  }) =>
      throw UnsupportedError('Nearby rooms are not available in the browser.');

  static Future<RoomSession> join({
    required String code,
    required String myId,
    required String myName,
    String? knownAddress,
  }) =>
      throw UnsupportedError('Nearby rooms are not available in the browser.');

  static Stream<List<NearbyRoom>> discover() => const Stream.empty();
}
