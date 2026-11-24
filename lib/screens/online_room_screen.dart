import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/game_settings.dart';
import '../models/game_state.dart';
import '../online/host_referee.dart';
import '../online/room_session.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/screen_awake.dart';
import '../widgets/game_logo.dart';
import '../widgets/mode_card.dart';
import '../widgets/played_cards_history_overlay.dart';
import '../widgets/playing_table.dart';
import '../widgets/tutorial_modal_overlay.dart';

/// A multiplayer room: the lobby (room code, players, start) and, while a
/// round is being played, the same game table as offline play.
///
/// Works for any [RoomSession] (Internet now, nearby Wi-Fi later). The screen
/// owns the session and disposes it when closed.
class OnlineRoomScreen extends StatefulWidget {
  final RoomSession session;

  const OnlineRoomScreen({super.key, required this.session});

  @override
  State<OnlineRoomScreen> createState() => _OnlineRoomScreenState();
}

class _OnlineRoomScreenState extends State<OnlineRoomScreen> {
  RoomSession get _room => widget.session;

  bool _leaving = false;
  bool _showHistory = false;
  bool _showTutorial = false;

  /// Round-over panel appears after the winning card has finished moving.
  bool _showRoundOver = false;
  Timer? _roundOverTimer;
  RoomStatus _lastStatus = RoomStatus.lobby;

  @override
  void initState() {
    super.initState();
    _lastStatus = _room.status;
    _room.addListener(_onRoomChanged);
    if (_room.status == RoomStatus.roundOver) _showRoundOver = true;
    // The host's phone is the referee: if it locks, the room stops.
    ScreenAwake.set(true);
  }

  @override
  void dispose() {
    ScreenAwake.set(false);
    _roundOverTimer?.cancel();
    _room.removeListener(_onRoomChanged);
    _room.dispose();
    super.dispose();
  }

  void _onRoomChanged() {
    if (!mounted) return;
    final error = _room.takeError();
    if (error != null) showMenuNotice(context, error);

    final status = _room.status;
    if (status != _lastStatus) {
      _onStatusChanged(status);
      _lastStatus = status;
    }
    setState(() {});
  }

  void _onStatusChanged(RoomStatus status) {
    _roundOverTimer?.cancel();
    _showRoundOver = false;
    switch (status) {
      case RoomStatus.closed:
        if (!_leaving) {
          showMenuNotice(context, 'The host closed the room.');
          Navigator.of(context).maybePop();
        }
      case RoomStatus.roundOver:
        // Let the winning exchange animation play before the result panel.
        _roundOverTimer = Timer(const Duration(milliseconds: 1300), () {
          if (!mounted || _room.status != RoomStatus.roundOver) return;
          setState(() => _showRoundOver = true);
          _playRoundOverCue();
        });
      case RoomStatus.playing:
        _showHistory = false;
        AudioService.instance.playGameStart();
      case RoomStatus.lobby:
        break;
    }
  }

  void _playRoundOverCue() {
    final view = _room.myView;
    if (view?.winner?.id == 0) {
      AudioService.instance.playVictory();
      HapticService.instance.victory();
    } else {
      AudioService.instance.playGameEnd();
      HapticService.instance.roundEnd();
    }
  }

  void _click() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
  }

  Future<void> _confirmLeave() async {
    _click();
    final isHost = _room.isHost;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: Text(
          isHost ? 'Close this room?' : 'Leave this room?',
          style: const TextStyle(color: MenuColors.gold),
        ),
        content: Text(
          isHost
              ? 'Everyone will be returned to the menu and code ${_room.code} '
                  'will be freed.'
              : _room.isInCurrentRound && _room.status == RoomStatus.playing
                  ? 'The current round will stop for everyone.'
                  : 'You can join again later with code ${_room.code}.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(isHost ? 'Close room' : 'Leave'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _leaving = true;
    await _room.leave();
    if (mounted) Navigator.of(context).pop();
  }

  void _showRoomMenu() {
    _click();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.play_arrow_rounded, color: MenuColors.gold),
              title:
                  const Text('Resume', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(sheetContext),
            ),
            if (_room.isHost && _room.status == RoomStatus.playing)
              ListTile(
                leading: const Icon(Icons.stop_circle_outlined,
                    color: MenuColors.goldText),
                title: const Text(
                  'Stop round and return to the lobby',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Use this if a player lost their connection.',
                  style: TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _room.backToLobby(notice: 'The host stopped the round.');
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text(
                _room.isHost ? 'Close room' : 'Leave room',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmLeave();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = _room.myView;
    final atTable = view != null &&
        (_room.status == RoomStatus.playing ||
            _room.status == RoomStatus.roundOver);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_leaving) _confirmLeave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFBFE3A5),
        body: atTable ? _buildTable(view) : _buildLobby(),
      ),
    );
  }

  // ------------------------------------------------------------ table

  Widget _buildTable(GameState view) {
    final waiting = _room.waitingMembers;
    return Stack(
      children: [
        PlayingTable(
          key: ValueKey<int>(_room.round),
          state: view,
          isPaused: _showHistory || _showTutorial,
          isProcessingMove: _room.isSubmittingMove,
          animationsEnabled: GameSettings.current.animationsEnabled,
          onCardSelected: _room.playCard,
          onBack: _confirmLeave,
          onPause: _showRoomMenu,
          onShowHistory: () {
            _click();
            setState(() => _showHistory = !_showHistory);
          },
          onShowTutorial: () {
            _click();
            setState(() => _showTutorial = true);
          },
        ),
        if (waiting.isNotEmpty)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: _Pill(
                icon: Icons.person_add_alt_1_rounded,
                text: '${waiting.map((m) => m.name).join(', ')} '
                    '${waiting.length == 1 ? 'wants' : 'want'} to join · '
                    'dealt in next round',
              ),
            ),
          ),
        if (_showHistory)
          Positioned.fill(
            child: PlayedCardsHistoryOverlay(
              recentPlayedCards: view.recentPlayedCards,
              currentTableCardName: view.tableCard.displayName,
              onClose: () => setState(() => _showHistory = false),
            ),
          ),
        if (_showTutorial)
          Positioned.fill(
            child: TutorialModalOverlay(
              targetSetSize: view.totalPlayers,
              onClose: () => setState(() => _showTutorial = false),
            ),
          ),
        if (_room.status == RoomStatus.roundOver && _showRoundOver)
          Positioned.fill(child: _buildRoundOver(view)),
      ],
    );
  }

  Widget _buildRoundOver(GameState view) {
    final winner = view.winner;
    final iWon = winner?.id == 0;
    final country = view.winningType?.displayName ?? '';
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: MenuColors.goldBorder, width: 1.4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: iWon ? MenuColors.gold : MenuColors.goldText,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  iWon
                      ? 'You won the round!'
                      : '${winner?.name ?? '?'} won the round',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: MenuColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Collected all ${view.totalPlayers} $country cards '
                  'in ${view.turnCount} turns · round ${_room.round}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
                const SizedBox(height: 18),
                if (_room.isHost) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _click();
                            _room.backToLobby();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MenuColors.goldText,
                            side:
                                const BorderSide(color: MenuColors.goldBorder),
                          ),
                          child: const Text('LOBBY'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _room.canStartRound
                              ? () {
                                  _click();
                                  _room.startRound();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MenuColors.amber,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('NEXT ROUND'),
                        ),
                      ),
                    ],
                  ),
                  if (!_room.canStartRound)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Need at least ${HostReferee.minPlayers} players for the next round.',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11.5),
                      ),
                    ),
                ] else
                  const Text(
                    'Waiting for the host to start the next round…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MenuColors.goldText, fontSize: 13),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ lobby

  Widget _buildLobby() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: menuBackgroundDecoration,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactH = constraints.maxHeight < 400;
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 640 ? 16 : 24,
                  vertical: isCompactH ? 8 : 14,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLobbyHeader(),
                      if (_room.notice != null) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: _Pill(
                            icon: Icons.info_outline_rounded,
                            text: _room.notice!,
                          ),
                        ),
                      ],
                      SizedBox(height: isCompactH ? 10 : 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 4, child: _buildCodeCard()),
                            const SizedBox(width: 14),
                            Expanded(flex: 6, child: _buildPlayersCard()),
                          ],
                        ),
                      ),
                      SizedBox(height: isCompactH ? 10 : 16),
                      _buildLobbyAction(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLobbyHeader() {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: _room.isHost ? 'Close room' : 'Leave room',
            icon: const Icon(Icons.arrow_back, color: MenuColors.gold),
            onPressed: _confirmLeave,
          ),
        ),
        const Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameLogo(size: 26, withGlow: false),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Room Lobby',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: MenuColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildCodeCard() {
    return _Panel(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ROOM CODE',
            style: TextStyle(
              color: MenuColors.goldText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _room.code,
            style: const TextStyle(
              color: MenuColors.gold,
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Share this code with your friends',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          if (_room.connectionInfo != null) ...[
            const SizedBox(height: 2),
            Text(
              _room.connectionInfo!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 10.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              _click();
              Clipboard.setData(ClipboardData(text: _room.code));
              showMenuNotice(context, 'Room code ${_room.code} copied.');
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy code'),
            style: TextButton.styleFrom(foregroundColor: MenuColors.goldText),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersCard() {
    final members = _room.members;
    final inRound = _room.status == RoomStatus.playing;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PLAYERS  ${members.length}/${HostReferee.maxPlayers}',
            style: const TextStyle(
              color: MenuColors.goldText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          for (final m in members)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: MenuColors.emerald.withValues(alpha: 0.25),
                    child: Text(
                      m.name.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      m.name,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13.5),
                    ),
                  ),
                  if (m.userId == _room.hostUserId) const _Tag('HOST'),
                  if (m.userId == _room.myUserId) const _Tag('YOU'),
                  if (!m.connected) const _Tag('OFFLINE'),
                  if (inRound && !_room.seats.contains(m.userId))
                    const _Tag('NEXT ROUND'),
                ],
              ),
            ),
          if (members.isEmpty)
            const Text('Loading players…',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLobbyAction() {
    final count = _room.members.length;
    if (_room.status == RoomStatus.playing && !_room.isInCurrentRound) {
      return const _Hint(
        'A round is in progress. You will be dealt in from the next round.',
      );
    }
    if (!_room.isHost) {
      return _Hint(
        count < HostReferee.minPlayers
            ? 'Waiting for more players (at least ${HostReferee.minPlayers})…'
            : 'Waiting for the host to start the round…',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _room.canStartRound
              ? () {
                  _click();
                  _room.startRound();
                }
              : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            _room.round == 0 ? 'START ROUND' : 'START ROUND ${_room.round + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: MenuColors.amber,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white12,
            disabledForegroundColor: Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (count < HostReferee.minPlayers) ...[
          const SizedBox(height: 6),
          _Hint(
            'Need at least ${HostReferee.minPlayers} players to start '
            '($count/${HostReferee.minPlayers}).',
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: child,
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MenuColors.goldBorder),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: MenuColors.goldText,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: MenuColors.goldText, fontSize: 12.5),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MenuColors.goldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: MenuColors.gold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
