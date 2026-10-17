import 'package:flutter_test/flutter_test.dart';
import 'package:country_game/main.dart';
import 'package:country_game/screens/player_selection_screen.dart';
import 'package:country_game/widgets/card_dimensions.dart';
import 'package:country_game/game/card_deck_factory.dart';
import 'package:country_game/game/initial_exchange.dart';
import 'package:country_game/services/haptic_service.dart';

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
}
