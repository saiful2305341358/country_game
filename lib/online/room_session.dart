import 'package:flutter/foundation.dart';

import '../models/game_card.dart';
import '../models/game_state.dart';
import 'host_referee.dart';
import 'seat_view.dart';

enum RoomStatus { lobby, playing, roundOver, closed }

@immutable
class RoomMember {
  final String userId;
  final String name;
  final DateTime joinedAt;

  const RoomMember({
    required this.userId,
    required this.name,
    required this.joinedAt,
  });
}

/// A multiplayer room as the UI sees it, independent of how phones connect
/// (Internet now; nearby Wi-Fi / hotspot in stage 3).
///
/// Room rules: no bots; a round starts with 3 to 7 players; people who join
/// during a round wait and are dealt in from the next round; the room stays
/// open across rounds until the host closes it.
abstract class RoomSession extends ChangeNotifier {
  String get code;
  String get myUserId;
  String get hostUserId;
  bool get isHost => myUserId == hostUserId;

  RoomStatus get status;
  int get round;

  /// Players currently in the room, in joining order (the host first).
  List<RoomMember> get members;

  /// User ids of this round's players, by seat. Empty in the lobby.
  List<String> get seats;

  /// The shared state of the current round, or null in the lobby.
  GameState? get gameState;

  /// The last room event shown to everyone (e.g. "Sara left").
  String? get notice;

  /// A problem that the UI should show once (then it is cleared).
  String? takeError();

  /// True while this phone's move has been sent but not yet applied.
  bool get isSubmittingMove;

  int get mySeat => seats.indexOf(myUserId);
  bool get isInCurrentRound => mySeat >= 0;

  /// The round seen from this phone (rotated so this player is seat 0).
  GameState? get myView {
    final s = gameState;
    final seat = mySeat;
    if (s == null || seat < 0 || seat >= s.totalPlayers) return null;
    return SeatView.forSeat(s, seat);
  }

  /// Members waiting to be dealt in from the next round.
  List<RoomMember> get waitingMembers => status == RoomStatus.playing
      ? members.where((m) => !seats.contains(m.userId)).toList()
      : const [];

  bool get canStartRound =>
      isHost &&
      status != RoomStatus.playing &&
      status != RoomStatus.closed &&
      members.length >= HostReferee.minPlayers &&
      members.length <= HostReferee.maxPlayers;

  /// Host: deal a new round to everyone in the room.
  Future<void> startRound();

  /// Host: stop the current round and return everyone to the lobby.
  Future<void> backToLobby({String? notice});

  /// Play [card] from this phone's hand (only on this player's turn).
  Future<void> playCard(GameCard card);

  /// Leave the room. When the host leaves, the room closes for everyone.
  Future<void> leave();
}
