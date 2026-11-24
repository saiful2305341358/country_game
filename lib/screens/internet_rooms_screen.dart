import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../online/supabase_room_session.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../services/stats_storage_stub.dart'
    if (dart.library.html) '../services/stats_storage_web.dart';
import '../widgets/game_logo.dart';
import '../widgets/mode_card.dart';
import 'online_room_screen.dart';

/// "Play via Internet": enter your name, then create a room (and get a 3-digit
/// code to share) or join a friend's room with their code.
class InternetRoomsScreen extends StatefulWidget {
  const InternetRoomsScreen({super.key});

  @override
  State<InternetRoomsScreen> createState() => _InternetRoomsScreenState();
}

class _InternetRoomsScreenState extends State<InternetRoomsScreen> {
  static const String _nameKey = 'country_game_player_name';
  static const int _maxNameLength = 16;

  late final TextEditingController _nameController;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: StatsStorage.read(_nameKey) ?? '');
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
    await _enterRoom(() => SupabaseRoomSession.create(name));
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
    await _enterRoom(() => SupabaseRoomSession.join(code, name));
  }

  Future<void> _enterRoom(Future<SupabaseRoomSession> Function() open) async {
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
      showMenuNotice(context, friendlyRoomError(e));
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
        const Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameLogo(size: 26, withGlow: false),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Play via Internet',
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
