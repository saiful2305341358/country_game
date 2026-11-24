import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../online/device_identity.dart';
import '../online/lan/lan_rooms.dart';
import '../online/room_session.dart';
import '../online/supabase_room_session.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/stats_storage_stub.dart'
    if (dart.library.html) '../services/stats_storage_web.dart';
import '../widgets/game_logo.dart';
import '../widgets/mode_card.dart';
import 'online_room_screen.dart';

/// "Play via Internet": rooms shared through the game server (Supabase).
class InternetRoomsScreen extends StatelessWidget {
  const InternetRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoomEntryScreen(
      title: 'Play via Internet',
      createRoom: (name) => SupabaseRoomSession.create(name),
      joinRoom: (code, name, _) => SupabaseRoomSession.join(code, name),
      errorText: friendlyRoomError,
    );
  }
}

/// "Play Nearby": rooms on the same Wi-Fi or hotspot, hosted on a phone.
class NearbyRoomsScreen extends StatelessWidget {
  const NearbyRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoomEntryScreen(
      title: 'Play Nearby',
      createRoom: (name) =>
          LanRooms.create(myId: DeviceIdentity.id, myName: name),
      joinRoom: (code, name, address) => LanRooms.join(
        code: code,
        myId: DeviceIdentity.id,
        myName: name,
        knownAddress: address,
      ),
      errorText: friendlyLanError,
      discoverRooms: LanRooms.discover,
      help: const _HotspotHelp(),
    );
  }
}

/// Opens or joins a room: enter your name, then create a room (and get a
/// 3-digit code to share) or join a friend's room with their code.
class RoomEntryScreen extends StatefulWidget {
  final String title;
  final Future<RoomSession> Function(String name) createRoom;

  /// Joins room [code]; [address] is set when the room was found nearby.
  final Future<RoomSession> Function(String code, String name, String? address)
      joinRoom;
  final String Function(Object error) errorText;

  /// Lists rooms announced nearby (optional).
  final Stream<List<NearbyRoom>> Function()? discoverRooms;
  final Widget? help;

  const RoomEntryScreen({
    super.key,
    required this.title,
    required this.createRoom,
    required this.joinRoom,
    required this.errorText,
    this.discoverRooms,
    this.help,
  });

  @override
  State<RoomEntryScreen> createState() => _RoomEntryScreenState();
}

class _RoomEntryScreenState extends State<RoomEntryScreen> {
  static const String _nameKey = 'country_game_player_name';
  static const int _maxNameLength = 16;

  late final TextEditingController _nameController;
  bool _busy = false;
  Stream<List<NearbyRoom>>? _nearby;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: StatsStorage.read(_nameKey) ?? '');
    _nearby = widget.discoverRooms?.call().asBroadcastStream();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _click() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
  }

  /// Returns the trimmed name, or null (with a message) when it is empty.
  String? _validName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showMenuNotice(context, 'Please enter your name first.');
      return null;
    }
    StatsStorage.write(_nameKey, name);
    return name;
  }

  Future<void> _createRoom() async {
    _click();
    final name = _validName();
    if (name == null) return;
    await _enterRoom(() => widget.createRoom(name));
  }

  Future<void> _joinRoom() async {
    _click();
    final name = _validName();
    if (name == null) return;
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _JoinCodeDialog(),
    );
    if (code == null || !mounted) return;
    await _enterRoom(() => widget.joinRoom(code, name, null));
  }

  Future<void> _joinNearby(NearbyRoom room) async {
    _click();
    final name = _validName();
    if (name == null) return;
    await _enterRoom(() => widget.joinRoom(room.code, name, room.address));
  }

  Future<void> _enterRoom(Future<RoomSession> Function() open) async {
    setState(() => _busy = true);
    try {
      final session = await open();
      if (!mounted) {
        session.dispose();
        return;
      }
      setState(() => _busy = false);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OnlineRoomScreen(session: session)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showMenuNotice(context, widget.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: menuBackgroundDecoration,
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompactH = constraints.maxHeight < 400;
                  return Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth < 640 ? 16 : 24,
                        vertical: isCompactH ? 8 : 14,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            SizedBox(height: isCompactH ? 12 : 18),
                            _buildNameField(),
                            SizedBox(height: isCompactH ? 16 : 22),
                            ModeCardRow(
                              minHeight: isCompactH ? 120 : 150,
                              gap: isCompactH ? 12 : 18,
                              children: [
                                ModeCard(
                                  icon: Icons.add_rounded,
                                  title: 'CREATE ROOM',
                                  subtitle: 'Get a 3-digit code to share',
                                  primary: true,
                                  compact: isCompactH,
                                  onTap: _busy ? () {} : _createRoom,
                                ),
                                ModeCard(
                                  icon: Icons.login_rounded,
                                  title: 'JOIN ROOM',
                                  subtitle: "Enter a friend's room code",
                                  accent: MenuColors.emerald,
                                  compact: isCompactH,
                                  onTap: _busy ? () {} : _joinRoom,
                                ),
                              ],
                            ),
                            if (_nearby != null) ...[
                              SizedBox(height: isCompactH ? 12 : 16),
                              _buildNearbyRooms(),
                            ],
                            if (widget.help != null) ...[
                              SizedBox(height: isCompactH ? 12 : 16),
                              widget.help!,
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_busy)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: const Center(
                      child: CircularProgressIndicator(color: MenuColors.gold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: MenuColors.gold),
            onPressed: () {
              _click();
              Navigator.pop(context);
            },
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GameLogo(size: 26, withGlow: false),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.title,
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

  /// Rooms announced on this Wi-Fi / hotspot, each with a Join button.
  Widget _buildNearbyRooms() {
    return StreamBuilder<List<NearbyRoom>>(
      stream: _nearby,
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? const <NearbyRoom>[];
        final label = TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 11.5,
        );
        if (rooms.isEmpty) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Looking for rooms on this network… '
                  '(if none appear, join with the code)',
                  style: label,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('ROOMS NEARBY', style: label.copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 6),
            for (final room in rooms)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MenuColors.emerald.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_tethering_rounded,
                        color: MenuColors.emerald, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${room.hostName}'s room · code ${room.code} · "
                        '${room.players} '
                        '${room.players == 1 ? 'player' : 'players'}',
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _joinNearby(room),
                      style: TextButton.styleFrom(
                        foregroundColor: MenuColors.gold,
                      ),
                      child: const Text('JOIN'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      maxLength: _maxNameLength,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Your name (shown to your friends)',
        labelStyle: const TextStyle(color: MenuColors.goldText, fontSize: 12.5),
        prefixIcon: const Icon(Icons.person_rounded, color: MenuColors.gold),
        counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        isDense: true,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: MenuColors.gold),
        ),
      ),
    );
  }
}

/// Asks for a 3-digit room code; returns it, or null when cancelled.
class _JoinCodeDialog extends StatefulWidget {
  const _JoinCodeDialog();

  @override
  State<_JoinCodeDialog> createState() => _JoinCodeDialogState();
}

class _JoinCodeDialogState extends State<_JoinCodeDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isComplete => RegExp(r'^\d{3}$').hasMatch(_controller.text);

  void _submit() {
    if (_isComplete) Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: MenuColors.goldBorder),
      ),
      title: const Text(
        'Join a room',
        style: TextStyle(color: MenuColors.gold, fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 3,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: 12,
        ),
        decoration: InputDecoration(
          hintText: '000',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
          helperText: 'Enter the 3-digit code from the host',
          helperStyle: const TextStyle(color: MenuColors.goldText),
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isComplete ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: MenuColors.amber,
            foregroundColor: Colors.white,
          ),
          child: const Text('Join'),
        ),
      ],
    );
  }
}

/// How to set up nearby play (hotspot or shared Wi-Fi).
class _HotspotHelp extends StatelessWidget {
  const _HotspotHelp();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'One phone turns on its hotspot, or everyone joins the same Wi-Fi.',
      'Friends connect to that hotspot / Wi-Fi. If a phone says "no internet", '
          'choose to stay connected.',
      'The host taps Create Room; friends tap Join Room and type the code.',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW TO PLAY NEARBY · no internet data used',
            style: TextStyle(
              color: MenuColors.goldText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${i + 1}. ${steps[i]}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
