/// Nearby (Wi-Fi / hotspot) rooms. Uses local network sockets on Android, iOS
/// and desktop; the browser build gets a stub with `isSupported == false`.
library;

export 'lan_errors.dart';
export 'lan_rooms_io.dart' if (dart.library.html) 'lan_rooms_web.dart';
export 'nearby_room.dart';
