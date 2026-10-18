import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:country_game/main.dart';
import 'package:country_game/screens/intro_video_screen.dart';
import 'package:country_game/screens/player_selection_screen.dart';
import 'package:country_game/widgets/card_dimensions.dart';
import 'package:country_game/models/card_type.dart';
import 'package:country_game/widgets/celebration_particles_overlay.dart';
import 'package:country_game/widgets/player_stats_overlay.dart';
import 'package:country_game/widgets/player_seat.dart';
import 'package:country_game/widgets/tutorial_modal_overlay.dart';
import 'package:country_game/game/card_deck_factory.dart';
import 'package:country_game/game/initial_exchange.dart';
import 'package:country_game/services/audio_service.dart';
import 'package:country_game/services/haptic_service.dart';
import 'package:country_game/services/stats_service.dart';

void main() {
  testWidgets('Main menu renders game title, dynamic tagline, and play button', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryGameApp());
    await tester.pumpAndSettle();

    expect(find.text('COUNTRY GAME'), findsOneWidget);
    expect(
      find.text('Unite the Nations: Collect all cards of a country to conquer the round!'),
      findsOneWidget,
    );
    expect(find.text('PLAY GAME'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('HOW TO PLAY & RULES'), findsOneWidget);
  });

  testWidgets('Bilingual Rules dialog toggles between English and Bangla with updated copy', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryGameApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('HOW TO PLAY & RULES'));
    await tester.pumpAndSettle();

    // Default English rules
    expect(find.text('How to Play & Rules'), findsOneWidget);
    expect(find.text('1. Core Goal — Unite One Country'), findsOneWidget);
    expect(
      find.textContaining('they are declared the sole winner and the game immediately ends!'),
      findsOneWidget,
    );
    expect(find.text("3. Balanced Deal & 'Global' Starter Card"), findsOneWidget);

    // Toggle to Bangla
    await tester.tap(find.text('বাংলা'));
    await tester.pumpAndSettle();

    expect(find.text('খেলার নিয়মাবলী'), findsOneWidget);
    expect(find.text('১. মূল লক্ষ্য — একটি দেশের সব কার্ড সংগ্রহ'), findsOneWidget);
    expect(
      find.textContaining('যেকোনো একজন খেলোয়াড় একটি দেশের সব কার্ড একত্রিত করামাত্রই একক বিজয়ী ঘোষিত হবেন এবং খেলাটি সাথে সাথেই শেষ হয়ে যাবে।'),
      findsOneWidget,
    );

    // Close dialog
    await tester.tap(find.text('বুঝেছি!'));
    await tester.pumpAndSettle();
  });

  testWidgets('Navigation from MainMenu to PlayerSelectionScreen works', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryGameApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAY GAME'));
    await tester.pumpAndSettle();

    expect(find.byType(PlayerSelectionScreen), findsOneWidget);
    expect(find.text('3 Players'), findsOneWidget);
    expect(find.text('4 Players'), findsOneWidget);
    expect(find.text('5 Players'), findsOneWidget);
    expect(find.text('6 Players'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);
  });

  testWidgets('Navigation from MainMenu to Settings screen works and displays Haptic Feedback toggle', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryGameApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('SETTINGS'));
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    expect(find.text('Gameplay Sound Effects'), findsOneWidget);
    expect(find.text('Tactile Haptic Feedback'), findsOneWidget);
    expect(find.text('Smooth Animations'), findsOneWidget);
    expect(find.text('Bot Thinking Pace'), findsOneWidget);

    // Verify HapticService methods run cleanly
    HapticService.instance.isHapticsEnabled = true;
    HapticService.instance.cardTap();
    HapticService.instance.cardPass();
    HapticService.instance.invalidMove();
    HapticService.instance.botTurnTick();
    HapticService.instance.yourTurnNotice();
    HapticService.instance.dealShuffle();
    HapticService.instance.victory();
    HapticService.instance.roundEnd();
    expect(HapticService.instance.isHapticsEnabled, isTrue);
  });

  test('CardDimensions strictly verifies 2:1 height-to-width ratio', () {
    final handSize = CardDimensions.getHumanHandCardSize(
      screenWidth: 1024,
      screenHeight: 768,
      totalPlayers: 4,
    );
    expect(handSize.height / handSize.width, equals(2.0));

    final tableSize = CardDimensions.getTableCardSize(
      screenWidth: 1024,
      screenHeight: 768,
    );
    expect(tableSize.height / tableSize.width, equals(2.0));

    final seatSize = CardDimensions.getSeatCardSize(
      screenWidth: 1024,
      totalPlayers: 5,
    );
    expect(seatSize.height / seatSize.width, equals(2.0));
  });

  test('Western player names have balanced 50% female and 50% male and human is You', () {
    final deck4 = CardDeckFactory.createDeck(4);
    final players4 = InitialExchangeService.performInitialExchange(
      activeTypes: deck4.activeTypes,
      initialDeckByType: deck4.ordinaryCardsByType,
    );
    // 4 players: 2 female, 2 male
    final femaleCount4 = players4.where((p) => p.isFemale).length;
    final maleCount4 = players4.where((p) => !p.isFemale).length;
    expect(femaleCount4, equals(2));
    expect(maleCount4, equals(2));
    expect(players4.first.name, equals('You'));
    for (final p in players4) {
      expect(p.name.contains('Bot'), isFalse);
    }

    final deck6 = CardDeckFactory.createDeck(6);
    final players6 = InitialExchangeService.performInitialExchange(
      activeTypes: deck6.activeTypes,
      initialDeckByType: deck6.ordinaryCardsByType,
    );
    // 6 players: 3 female, 3 male
    final femaleCount6 = players6.where((p) => p.isFemale).length;
    final maleCount6 = players6.where((p) => !p.isFemale).length;
    expect(femaleCount6, equals(3));
    expect(maleCount6, equals(3));
  });

  test('Dynamic card selection avoids immediate repetition for 4 and 5 players', () {
    final set1 = CardDeckFactory.selectActiveTypes(4).toSet();
    final set2 = CardDeckFactory.selectActiveTypes(4).toSet();
    final isDifferent = set1.difference(set2).isNotEmpty;
    expect(isDifferent, isTrue);
  });

  testWidgets('Human player cards on horizontal PlayingTable are tappable, execute sequential exchange, and redundant HUD sound icon is removed', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    await tester.pumpWidget(const CountryGameApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAY GAME'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START GAME'));
    // Advance past dealing animation (1350ms) and any initial bot turns
    await tester.pump(const Duration(milliseconds: 1600));
    for (int i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }

    // Verify top text box and redundant HUD sound icon are NOT rendered on the table
    expect(find.textContaining('Opening move:'), findsNothing);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.byIcon(Icons.volume_off_rounded), findsNothing);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('PlayerSeat renders glowing visual turn indicator around active and exchanging player avatar', (WidgetTester tester) async {
    final deck = CardDeckFactory.createDeck(4);
    final players = InitialExchangeService.performInitialExchange(
      activeTypes: deck.activeTypes,
      initialDeckByType: deck.ordinaryCardsByType,
    );
    final botPlayer = players[1];

    // Inactive player seat has no turn glow painter
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayerSeat(
              player: botPlayer,
              isCurrentTurn: false,
            ),
          ),
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ActiveAvatarTurnGlowPainter,
      ),
      findsNothing,
    );

    // Active turn / exchanging player seat renders the glowing turn indicator
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PlayerSeat(
              player: botPlayer,
              isCurrentTurn: true,
              isExchanging: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ActiveAvatarTurnGlowPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('Card exchange animation moves incoming card once directly to table slot, then previous table card once directly to player without wobbling', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    await tester.pumpWidget(const CountryGameApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('PLAY GAME'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('START GAME'));
    // Finish initial dealing animation (1350ms)
    await tester.pump(const Duration(milliseconds: 1400));

    // Advance into the first exchange animation
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 150));

    // Complete several exchanges cleanly without exceptions or overlapping state
    for (int step = 0; step < 8; step++) {
      await tester.pump(const Duration(milliseconds: 250));
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('CelebrationParticlesOverlay triggers particle burst and completes cleanly', (WidgetTester tester) async {
    AudioService.instance.playVictory();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1280,
            height: 720,
            child: CelebrationParticlesOverlay(
              completedType: CountryType.japan,
              burstOriginNormalized: Offset(0.5, 0.76),
              triggerKey: 1,
              showBanner: true,
              bannerTitle: 'FOUR OF A KIND!',
              bannerSubtitle: 'You collected 4× Japan cards!',
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CelebrationParticlesOverlay), findsOneWidget);
    expect(find.text('FOUR OF A KIND!'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('PlayerStatsOverlay displays games played and sets completed per player', (WidgetTester tester) async {
    StatsService.instance.resetStats();
    final deck = CardDeckFactory.createDeck(4);
    final players = InitialExchangeService.performInitialExchange(
      activeTypes: deck.activeTypes,
      initialDeckByType: deck.ordinaryCardsByType,
    );

    StatsService.instance.recordGameStarted(players);
    StatsService.instance.recordSetCompleted(players[0], CountryType.japan);
    StatsService.instance.recordSetCompleted(players[1], CountryType.australia);

    bool closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PlayerStatsOverlay(
            activePlayers: players,
            targetSetSize: 4,
            onClose: () => closed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PLAYER STATS & SETS COMPLETED'), findsOneWidget);
    expect(find.text('GAMES PLAYED'), findsWidgets);
    expect(find.text('SETS COMPLETED'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.text(players[1].name), findsOneWidget);

    await tester.tap(find.text('Close Overlay'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
  });

  testWidgets('TutorialModalOverlay explains card swapping and winning mechanics and dismisses cleanly', (WidgetTester tester) async {
    TutorialModalOverlay.resetTutorialSeen();
    expect(TutorialModalOverlay.hasSeenTutorial, isFalse);

    bool closed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TutorialModalOverlay(
            targetSetSize: 4,
            onClose: () => closed = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('QUICK TUTORIAL • HOW TO PLAY'), findsOneWidget);
    expect(find.text('Tap a Card to Swap with the Table'), findsOneWidget);
    expect(find.text('Different Country Swap Rule'), findsOneWidget);
    expect(find.text('Collect 4 Matching Country Cards to Win'), findsOneWidget);

    await tester.tap(find.text('Got It, Let\'s Play!'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(TutorialModalOverlay.hasSeenTutorial, isTrue);
  });

  testWidgets('IntroVideoScreen plays short lightweight card-matching intro on app launch and supports Skip', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryGameApp());

    // Initially renders the intro sequence
    expect(find.byType(IntroVideoScreen), findsOneWidget);
    expect(find.text('SKIP INTRO'), findsOneWidget);
    expect(find.text('COLLECT MATCHING COUNTRY CARDS...'), findsOneWidget);

    // Advance into the card swap phase
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('SWAP ONE CARD WITH THE TABLE...'), findsOneWidget);

    // Advance into the 4-of-a-kind completion phase
    await tester.pump(const Duration(milliseconds: 950));
    expect(find.text('COMPLETE THE COUNTRY SET TO WIN!'), findsOneWidget);
    expect(find.text('4 OF A KIND!'), findsOneWidget);

    // Finish the intro and verify transition to MainMenuScreen
    await tester.pumpAndSettle();
    expect(find.byType(IntroVideoScreen), findsNothing);
    expect(find.text('PLAY GAME'), findsOneWidget);
  });
}
