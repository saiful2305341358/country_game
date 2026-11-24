import 'package:material_ui/material_ui.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../widgets/game_logo.dart';
import '../widgets/mode_card.dart';
import '../widgets/player_stats_overlay.dart';
import 'play_with_friends_screen.dart';
import 'player_selection_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  /// The "Online multiplayer" tile is not built yet. App Store review rejects
  /// placeholder features, so it stays hidden until it works; set to true to
  /// show it again (with its "Coming soon" badge).
  static const bool showOnlineMultiplayer = false;

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
              final availH = constraints.maxHeight;
              final isCompactH = availH < 400;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: availW < 640 ? 20 : 32,
                    vertical: isCompactH ? 10 : 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: brand crest, title and tagline (unchanged identity)
                        Expanded(
                          flex: 9,
                          child: _buildBrand(isCompactH: isCompactH),
                        ),
                        SizedBox(width: availW < 680 ? 20 : 36),
                        // Right: game modes + secondary actions
                        Expanded(
                          flex: 12,
                          child: _buildMenu(context, isCompactH: isCompactH),
                        ),
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

  Widget _buildBrand({required bool isCompactH}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GameLogo(size: isCompactH ? 82 : 96, withGlow: true),
        SizedBox(height: isCompactH ? 12 : 16),
        Text(
          'COUNTRY GAME',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: MenuColors.gold,
            fontSize: isCompactH ? 24 : 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
            shadows: const [
              Shadow(
                color: Colors.black87,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Unite the Nations: Collect all cards of a country to conquer the round!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: MenuColors.goldText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            height: 1.35,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context, {required bool isCompactH}) {
    final tileHeight = isCompactH ? 118.0 : 140.0;
    final gap = isCompactH ? 8.0 : 12.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Leaves room above the tiles for their corner badges.
        const SizedBox(height: 8),
        ModeCardRow(
          minHeight: tileHeight,
          gap: gap,
          children: [
            ModeCard(
              icon: Icons.play_arrow_rounded,
              title: 'PLAY OFFLINE',
              subtitle: 'You vs bots',
              primary: true,
              compact: isCompactH,
              onTap: () {
                _click();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlayerSelectionScreen(),
                  ),
                );
              },
            ),
            ModeCard(
              icon: Icons.groups_rounded,
              title: 'PLAY WITH FRIENDS',
              subtitle: 'Internet or nearby',
              accent: MenuColors.emerald,
              compact: isCompactH,
              onTap: () {
                _click();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlayWithFriendsScreen(),
                  ),
                );
              },
            ),
            if (showOnlineMultiplayer)
              ModeCard(
                icon: Icons.public_rounded,
                title: 'ONLINE MULTIPLAYER',
                subtitle: 'Play with anyone',
                badge: 'COMING SOON',
                dimmed: true,
                compact: isCompactH,
                onTap: () {
                  _click();
                  showMenuNotice(
                    context,
                    'Online multiplayer is coming soon. '
                    'Meanwhile, try Play with Friends!',
                  );
                },
              ),
          ],
        ),
        SizedBox(height: isCompactH ? 12 : 16),
        Row(
          children: [
            Expanded(
              child: MenuUtilityButton(
                icon: Icons.help_outline_rounded,
                label: 'RULES',
                onPressed: () {
                  _click();
                  showDialog(
                    context: context,
                    builder: (_) => const BilingualRulesDialog(),
                  );
                },
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: MenuUtilityButton(
                icon: Icons.settings_rounded,
                label: 'SETTINGS',
                onPressed: () {
                  _click();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: MenuUtilityButton(
                icon: Icons.leaderboard_rounded,
                label: 'STATS',
                onPressed: () {
                  _click();
                  showDialog(
                    context: context,
                    builder: (dialogContext) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: EdgeInsets.zero,
                      child: PlayerStatsOverlay(
                        onClose: () => Navigator.pop(dialogContext),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bilingual "How to Play & Rules" modal with English and Bangla (বাংলা) segmented toggle.
class BilingualRulesDialog extends StatefulWidget {
  const BilingualRulesDialog({super.key});

  @override
  State<BilingualRulesDialog> createState() => _BilingualRulesDialogState();
}

class _BilingualRulesDialogState extends State<BilingualRulesDialog> {
  bool _isBangla = false;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final isCompactH = screenH < 420;

    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: isCompactH ? 10 : 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 540),
        child: Padding(
          padding: EdgeInsets.all(isCompactH ? 14 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header + Language Segmented Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          color: const Color(0xFFFFD54F),
                          size: isCompactH ? 20 : 24,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _isBangla
                                ? 'খেলার নিয়মাবলী'
                                : 'How to Play & Rules',
                            style: TextStyle(
                              color: const Color(0xFFFFD54F),
                              fontSize: isCompactH ? 16 : 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Language Toggle Pill (English | বাংলা)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLangTab(
                          label: 'English',
                          selected: !_isBangla,
                          onTap: () => setState(() => _isBangla = false),
                        ),
                        _buildLangTab(
                          label: 'বাংলা',
                          selected: _isBangla,
                          onTap: () => setState(() => _isBangla = true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: isCompactH ? 8 : 12),
              const Divider(color: Colors.white12, height: 1),
              SizedBox(height: isCompactH ? 8 : 12),

              // Rules Body
              Flexible(
                child: SingleChildScrollView(
                  child: _isBangla ? _buildBanglaRules() : _buildEnglishRules(),
                ),
              ),

              SizedBox(height: isCompactH ? 8 : 12),

              // Close Action
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: isCompactH ? 8 : 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    _isBangla ? 'বুঝেছি!' : 'Got it!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFD97706) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEnglishRules() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RuleSection(
          icon: Icons.emoji_events_outlined,
          title: '1. Core Goal — Unite One Country',
          body:
              'Your mission is to collect a complete set of cards belonging to a single country. As soon as any player holds all cards of a single country, they are declared the sole winner and the game immediately ends!',
        ),
        _RuleSection(
          icon: Icons.groups_outlined,
          title: '2. Dynamic Difficulty (Player-Based Set Size)',
          body:
              'The number of cards required to win matches the total number of players at the table (N):\n'
              '• 3 Players → Collect 3 cards of the same country (9 country cards total)\n'
              '• 4 Players → Collect 4 cards of the same country (16 country cards total)\n'
              '• 5 Players → Collect 5 cards of the same country (25 country cards total)\n'
              '• 6 Players → Collect 6 cards of the same country (36 country cards total)\n'
              '• 7 Players → Collect 7 cards of the same country (49 country cards total)',
        ),
        _RuleSection(
          icon: Icons.public_outlined,
          title: '3. Balanced Deal & \'Global\' Starter Card',
          body:
              'At the start of every round, cards are shuffled and dealt so every player begins with a balanced hand containing 1 card of each active country. The special \'Global\' card begins on the center table. It acts as a neutral bridge card that can be passed freely, but does not count toward any country\'s winning set.',
        ),
        _RuleSection(
          icon: Icons.swap_horiz_rounded,
          title: '4. Turn Order & Card Passing Flow',
          body:
              '• A randomly chosen player starts by taking the \'Global\' card from the table and passing 1 card from their hand onto the table.\n'
              '• Turns move sequentially around the table. On your turn, you pick up the face-up table card and discard 1 card from your hand.\n'
              '• Same-Type Restriction: You cannot discard a card of the exact same country that is currently on the table.',
        ),
      ],
    );
  }

  Widget _buildBanglaRules() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RuleSection(
          icon: Icons.emoji_events_outlined,
          title: '১. মূল লক্ষ্য — একটি দেশের সব কার্ড সংগ্রহ',
          body:
              'খেলার মূল উদ্দেশ্য হলো যেকোনো একটি দেশের সম্পূর্ণ কার্ড সেট নিজের হাতে মেলানো। যেকোনো একজন খেলোয়াড় একটি দেশের সব কার্ড একত্রিত করামাত্রই একক বিজয়ী ঘোষিত হবেন এবং খেলাটি সাথে সাথেই শেষ হয়ে যাবে।',
        ),
        _RuleSection(
          icon: Icons.groups_outlined,
          title: '২. গতিশীল চ্যালেঞ্জ (খেলোয়াড় সংখ্যা অনুযায়ী জয়ের শর্ত)',
          body:
              'জয়ের জন্য কয়টি একই দেশের কার্ড লাগবে তা নির্ভর করে মোট খেলোয়াড় সংখ্যার (N) ওপর:\n'
              '• ৩ জন খেলোয়াড় → একই দেশের ৩টি কার্ড মেলাতে হবে (মোট ৯টি দেশ কার্ড)\n'
              '• ৪ জন খেলোয়াড় → একই দেশের ৪টি কার্ড মেলাতে হবে (মোট ১৬টি দেশ কার্ড)\n'
              '• ৫ জন খেলোয়াড় → একই দেশের ৫টি কার্ড মেলাতে হবে (মোট ২৫টি দেশ কার্ড)\n'
              '• ৬ জন খেলোয়াড় → একই দেশের ৬টি কার্ড মেলাতে হবে (মোট ৩৬টি দেশ কার্ড)\n'
              '• ৭ জন খেলোয়াড় → একই দেশের ৭টি কার্ড মেলাতে হবে (মোট ৪৯টি দেশ কার্ড)',
        ),
        _RuleSection(
          icon: Icons.public_outlined,
          title: '৩. প্রাথমিক সুষম বণ্টন ও \'Global\' স্টার্টার কার্ড',
          body:
              'খেলার শুরুতে কার্ডগুলো এমনভাবে ভাগ করা হয় যাতে প্রত্যেক খেলোয়াড়ের হাতে প্রতিটি সক্রিয় দেশের ১টি করে কার্ড থাকে। টেবিলের মাঝখানে বিশেষ \'Global\' স্টার্টার কার্ডটি রাখা হয়। এটি যেকোনো সময় বিনিময় করা যায়, তবে এটি কোনো নির্দিষ্ট দেশের সেট পূরণে গণনা করা হয় না।',
        ),
        _RuleSection(
          icon: Icons.swap_horiz_rounded,
          title: '৪. খেলার ক্রম ও কার্ড আদান-প্রদান নিয়ম',
          body:
              '• লটারির মাধ্যমে নির্বাচিত প্রথম খেলোয়াড় টেবিল থেকে \'Global\' কার্ডটি হাতে নেন এবং নিজের হাত থেকে যেকোনো ১টি কার্ড টেবিলে রাখেন।\n'
              '• এরপর পর্যায়ক্রমে প্রত্যেকের চাল আসে। আপনার চালে টেবিলের কার্ডটি হাতে তুলে নেবেন এবং হাত থেকে ১টি বৈধ কার্ড টেবিলে রাখবেন।\n'
              '• একই দেশের কার্ড নিষেধাজ্ঞা: টেবিলে যে দেশের কার্ডটি রয়েছে, সেই একই দেশের কার্ড সঙ্গে সঙ্গে টেবিলে ফেলা যাবে না।',
        ),
      ],
    );
  }
}

class _RuleSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _RuleSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFFFD54F), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFE082),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11.8,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
