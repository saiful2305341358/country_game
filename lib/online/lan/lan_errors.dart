import 'lan_protocol.dart';

/// Thrown when a nearby room cannot be opened or joined; [reason] is one of
/// the [LanProtocol] reject reasons or one of the constants below.
class LanJoinException implements Exception {
  final String reason;
  const LanJoinException(this.reason);

  /// No host answered (wrong code, different network, or host gone).
  static const String unreachable = 'UNREACHABLE';

  /// This phone is not on a Wi-Fi network or hotspot.
  static const String noNetwork = 'NO_NETWORK';

  /// Another app (or room) already uses the game's network port.
  static const String portBusy = 'PORT_BUSY';

  @override
  String toString() => 'LanJoinException($reason)';
}

/// Turns nearby-room errors into short messages for players.
String friendlyLanError(Object error) {
  if (error is UnsupportedError) {
    return 'Nearby play needs the Android, iPhone or desktop app '
        '(browsers cannot use the local network).';
  }
  final reason = error is LanJoinException ? error.reason : '';
  switch (reason) {
    case LanJoinException.noNetwork:
      return 'Connect to a Wi-Fi network or turn on your hotspot first.';
    case LanJoinException.portBusy:
      return 'Could not open a room on this phone. Close other game rooms and try again.';
    case LanProtocol.roomNotFound:
    case LanJoinException.unreachable:
      return 'No room with that code on this Wi-Fi. Make sure you are on the '
          "same Wi-Fi or hotspot as the host.";
    case LanProtocol.roomFull:
      return 'That room is full (7 players).';
    case LanProtocol.nameTaken:
      return 'Someone in that room already uses that name. Pick another name.';
    case LanProtocol.nameRequired:
      return 'Please enter your name first.';
  }
  return 'Something went wrong: $error';
}
