import 'package:material_ui/material_ui.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../widgets/game_logo.dart';
import '../widgets/mode_card.dart';
import 'internet_rooms_screen.dart';

/// Lets the player choose how to connect with friends: over the Internet or
/// on the same Wi-Fi / hotspot. Every seat is a real player (no bots); a round
/// needs at least 3 players and supports up to 7.
class PlayWithFriendsScreen extends StatelessWidget {
  const PlayWithFriendsScreen({super.key});

  void _click() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: menuBackgroundDecoration,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availW = constraints.maxWidth;
              final isCompactH = constraints.maxHeight < 400;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: availW < 640 ? 16 : 24,
                    vertical: isCompactH ? 8 : 14,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        SizedBox(height: isCompactH ? 18 : 26),
                        ModeCardRow(
                          minHeight: isCompactH ? 140 : 170,
                          gap: isCompactH ? 12 : 18,
                          children: [
                            ModeCard(
                              icon: Icons.language_rounded,
                              title: 'PLAY VIA INTERNET',
                              subtitle:
                                  'Friends anywhere · create or join a room with a 3-digit code',
                              accent: MenuColors.goldBorder,
                              compact: isCompactH,
                              onTap: () {
                                _click();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const InternetRoomsScreen(),
                                  ),
                                );
                              },
                            ),
                            ModeCard(
                              icon: Icons.wifi_tethering_rounded,
                              title: 'PLAY NEARBY',
                              subtitle:
                                  'Same Wi-Fi or hotspot · no internet needed',
                              accent: MenuColors.emerald,
                              badge: 'COMING SOON',
                              compact: isCompactH,
                              onTap: () {
                                _click();
                                showMenuNotice(
                                  context,
                                  'Nearby (Wi-Fi / hotspot) rooms are coming soon.',
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: isCompactH ? 14 : 20),
                        _buildRoomRulesNote(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                  'Play with Friends',
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

  Widget _buildRoomRulesNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 15,
          color: Colors.white.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Real players only · 3 to 7 players per round · '
            'friends who join mid-round play from the next round',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
