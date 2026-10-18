import 'package:flutter/material.dart';
import '../widgets/player_stats_overlay.dart';
import 'player_selection_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF0F3B2C),
              Color(0xFF09251B),
              Color(0xFF03140E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo: Vector Card Crest with Globe
                    _buildAppLogo(),

                    const SizedBox(height: 20),

                    // Game Title
                    const Text(
                      'COUNTRY GAME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Dynamic Tagline (No hardcoded "Four" or "4")
                    const Text(
                      'Unite the Nations: Collect all cards of a country to conquer the round!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFE082),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Play Button (Muted on Home Page per audio scope rules)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_circle_fill, size: 26),
                        label: const Text(
                          'PLAY GAME',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 6,
                          shadowColor:
                              const Color(0xFFD97706).withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayerSelectionScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Bilingual How to Play & Rules Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.help_outline, size: 20),
                        label: const Text(
                          'HOW TO PLAY & RULES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFE082),
                          side: const BorderSide(
                            color: Color(0xFFD4AF37),
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _showRulesDialog(context),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Settings Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(Icons.settings, size: 20),
                        label: const Text(
                          'SETTINGS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Player Stats & Sets Overlay Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        icon: const Icon(
                          Icons.leaderboard_rounded,
                          size: 19,
                          color: Color(0xFFFFD54F),
                        ),
                        label: const Text(
                          'PLAYER STATS & SETS',
                          style: TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        onPressed: () {
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

                    const SizedBox(height: 22),

                    // Offline status indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.offline_pin,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '100% Offline • No Network Required',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -0.25,
              child: Container(
                width: 32,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1),
                ),
              ),
            ),
            Transform.rotate(
              angle: 0.25,
              child: Container(
                width: 32,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFFD700), width: 1),
                ),
              ),
            ),
            Container(
              width: 34,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.public,
                  color: Color(0xFF38BDF8),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const BilingualRulesDialog(),
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
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFD4AF37), width: 1.4),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(22),
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
                        const Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFFFFD54F),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _isBangla ? 'খেলার নিয়মাবলী' : 'How to Play & Rules',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 18,
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

              const SizedBox(height: 16),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 14),

              // Rules Body
              Flexible(
                child: SingleChildScrollView(
                  child: _isBangla
                      ? _buildBanglaRules()
                      : _buildEnglishRules(),
                ),
              ),

              const SizedBox(height: 16),

              // Close Action
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              '• 4 Players → Collect 4 cards of the same country (16 country cards total)\n'
              '• 5 Players → Collect 5 cards of the same country (25 country cards total)\n'
              '• 6 Players → Collect 6 cards of the same country (36 country cards total)',
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
              '• ৪ জন খেলোয়াড় → একই দেশের ৪টি কার্ড মেলাতে হবে (মোট ১৬টি দেশ কার্ড)\n'
              '• ৫ জন খেলোয়াড় → একই দেশের ৫টি কার্ড মেলাতে হবে (মোট ২৫টি দেশ কার্ড)\n'
              '• ৬ জন খেলোয়াড় → একই দেশের ৬টি কার্ড মেলাতে হবে (মোট ৩৬টি দেশ কার্ড)',
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
