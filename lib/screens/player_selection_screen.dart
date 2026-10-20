import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/card_deck_factory.dart';
import '../models/card_type.dart';
import '../models/game_card.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import '../widgets/country_card_view.dart';
import '../widgets/game_logo.dart';
import 'game_screen.dart';

class PlayerSelectionScreen extends StatefulWidget {
  const PlayerSelectionScreen({super.key});

  @override
  State<PlayerSelectionScreen> createState() => _PlayerSelectionScreenState();
}

class _PlayerSelectionScreenState extends State<PlayerSelectionScreen> {
  int _selectedPlayers = 4;
  late List<CountryType> _activeTypes;

  @override
  void initState() {
    super.initState();
    _refreshActiveTypes();
  }

  void _refreshActiveTypes() {
    setState(() {
      _activeTypes = CardDeckFactory.selectActiveTypes(_selectedPlayers);
    });
  }

  void _onPlayerCountChanged(int count) {
    if (_selectedPlayers == count) return;
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    setState(() {
      _selectedPlayers = count;
      _activeTypes = CardDeckFactory.selectActiveTypes(count);
    });
  }

  void _startGame() {
    AudioService.instance.playButtonClick();
    HapticService.instance.uiTap();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          totalPlayers: _selectedPlayers,
          predefinedTypes: _activeTypes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04140E),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availW = constraints.maxWidth;
              final availH = constraints.maxHeight;

              // Responsive vertical metrics tailored for landscape mobile viewports
              // (from compact 320px height phones to standard 360-412px phones and tablets).
              final isCompactH = availH < 380;
              final isMediumH = availH >= 380 && availH < 460;

              final horizontalPad = availW < 640 ? 16.0 : 24.0;
              final verticalPad = isCompactH ? 6.0 : (isMediumH ? 10.0 : 14.0);

              final headerHeight = isCompactH ? 42.0 : (isMediumH ? 48.0 : 54.0);
              final selectorHeight =
                  isCompactH ? 56.0 : (isMediumH ? 64.0 : 72.0);
              final activeBarHeight =
                  isCompactH ? 34.0 : (isMediumH ? 38.0 : 42.0);
              final startBtnHeight =
                  isCompactH ? 40.0 : (isMediumH ? 44.0 : 48.0);
              final sectionGap = isCompactH ? 6.0 : (isMediumH ? 8.0 : 12.0);

              final fixedSectionsTotal = (verticalPad * 2) +
                  headerHeight +
                  selectorHeight +
                  activeBarHeight +
                  startBtnHeight +
                  (sectionGap * 4);

              // Reserve a deterministic, constant height for the country card stage based ONLY
              // on the viewport height (never on _selectedPlayers), so switching between
              // 3, 4, 5, and 6 players NEVER causes any section or the START GAME button to shift.
              final remainingForCards = availH - fixedSectionsTotal;
              final cardStageHeight = remainingForCards.clamp(96.0, 172.0);
              final totalLayoutHeight = fixedSectionsTotal + cardStageHeight;

              final content = Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPad,
                      vertical: verticalPad,
                    ),
                    child: SizedBox(
                      height: totalLayoutHeight - (verticalPad * 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Anchored Top Bar: Back Button + Screen Title + Winning Set Info
                          SizedBox(
                            height: headerHeight,
                            child: _buildAnchoredHeader(isCompactH: isCompactH),
                          ),

                          SizedBox(height: sectionGap),

                          // 2. Anchored Player Count Selector Row (3, 4, 5, 6 Players)
                          SizedBox(
                            height: selectorHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildPlayerCountOption(
                                  count: 3,
                                  title: '3 Players',
                                  subtitle: 'Win Set: 3× Cards',
                                  isCompactH: isCompactH,
                                ),
                                const SizedBox(width: 8),
                                _buildPlayerCountOption(
                                  count: 4,
                                  title: '4 Players',
                                  subtitle: 'Win Set: 4× Cards',
                                  isCompactH: isCompactH,
                                ),
                                const SizedBox(width: 8),
                                _buildPlayerCountOption(
                                  count: 5,
                                  title: '5 Players',
                                  subtitle: 'Win Set: 5× Cards',
                                  isCompactH: isCompactH,
                                ),
                                const SizedBox(width: 8),
                                _buildPlayerCountOption(
                                  count: 6,
                                  title: '6 Players',
                                  subtitle: 'Win Set: 6× Cards',
                                  isCompactH: isCompactH,
                                ),
                                const SizedBox(width: 8),
                                _buildPlayerCountOption(
                                  count: 7,
                                  title: '7 Players',
                                  subtitle: 'Win Set: 7× Cards',
                                  isCompactH: isCompactH,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: sectionGap),

                          // 3. Anchored Active Countries Header Bar
                          SizedBox(
                            height: activeBarHeight,
                            child: _buildActiveCountriesBar(
                              isCompactH: isCompactH,
                            ),
                          ),

                          SizedBox(height: sectionGap),

                          // 4. Anchored Country Card Stage (Constant Height & Constant Card Proportions)
                          SizedBox(
                            height: cardStageHeight,
                            child: _buildCountryCardStage(
                              stageHeight: cardStageHeight,
                            ),
                          ),

                          SizedBox(height: sectionGap),

                          // 5. Anchored Start Game Button
                          SizedBox(
                            height: startBtnHeight,
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(
                                Icons.play_arrow,
                                size: isCompactH ? 20 : 22,
                              ),
                              label: Text(
                                'START GAME',
                                style: TextStyle(
                                  fontSize: isCompactH ? 13.5 : 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 6,
                                shadowColor: const Color(0xFFD97706)
                                    .withValues(alpha: 0.5),
                              ),
                              onPressed: _startGame,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              // Deliberate fallback only if an extreme split-screen viewport is shorter than 280px
              if (availH < totalLayoutHeight) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: content,
                );
              }

              return content;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnchoredHeader({required bool isCompactH}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD54F)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GameLogo(size: 26, withGlow: false),
                  const SizedBox(width: 8),
                  Text(
                    'Select Players',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontSize: isCompactH ? 15 : 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              const Color(0xFFFFD700).withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        'TOTAL PLAYERS & WINNING SET',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFFFE082),
                          fontSize: isCompactH ? 9.0 : 10.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Win by collecting $_selectedPlayers cards of the same country (${_selectedPlayers * _selectedPlayers} country cards in deck)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: isCompactH ? 10.5 : 11.5,
                ),
              ),
            ],
          ),
        ),
        // Symmetrical 40px spacer to keep header text dead-center
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildActiveCountriesBar({required bool isCompactH}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public,
                  color: const Color(0xFFFFD54F),
                  size: isCompactH ? 16 : 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Active Countries (${_activeTypes.length})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFFFE082),
                      fontSize: isCompactH ? 11.5 : 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              Icons.shuffle,
              size: 14,
              color: Color(0xFFFFD54F),
            ),
            label: const Text(
              'Reroll Set',
              style: TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _refreshActiveTypes,
          ),
        ],
      ),
    );
  }

  /// Renders the active country cards in a single balanced horizontal row.
  /// Card dimensions are derived from the stage's fixed capacity for 6 cards so that
  /// switching between 3, 4, 5, and 6 players keeps card sizes and proportions 100% identical.
  Widget _buildCountryCardStage({required double stageHeight}) {
    return LayoutBuilder(
      builder: (context, stageConstraints) {
        final maxW = stageConstraints.maxWidth;
        const maxPossibleCards = 7;
        const cardSpacing = 12.0;
        const labelReservation = 18.0;

        // Compute consistent 2:1 card dimensions that fit both stageHeight and 6 cards across maxW
        final maxCardHeightByStage =
            (stageHeight - labelReservation).clamp(68.0, 116.0);
        final maxCardWidthByHeight = maxCardHeightByStage / 2.0;
        final maxCardWidthByRow =
            ((maxW - (cardSpacing * (maxPossibleCards - 1))) / maxPossibleCards)
                .clamp(34.0, 58.0);

        final cardWidth =
            math.min(maxCardWidthByHeight, maxCardWidthByRow).clamp(34.0, 58.0);
        final cardHeight = cardWidth * 2.0;

        return Container(
          width: double.infinity,
          height: stageHeight,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < _activeTypes.length; i++) ...[
                  if (i > 0) const SizedBox(width: cardSpacing),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CountryCardView(
                        card: GameCard.ordinary(
                          id: 'preview_${_activeTypes[i].id}',
                          type: _activeTypes[i],
                        ),
                        width: cardWidth,
                        height: cardHeight,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _activeTypes[i].shortCode,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerCountOption({
    required int count,
    required String title,
    required String subtitle,
    required bool isCompactH,
  }) {
    final isSelected = _selectedPlayers == count;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onPlayerCountChanged(count),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0F172A).withValues(alpha: 0.95)
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFD700)
                  : Colors.white.withValues(alpha: 0.15),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      color:
                          isSelected ? const Color(0xFFFFD700) : Colors.white,
                      fontSize: isCompactH ? 18 : 22,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFFFE082)
                          : Colors.white70,
                      fontSize: isCompactH ? 10.5 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: isCompactH ? 8.5 : 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
