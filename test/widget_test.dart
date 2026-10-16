import 'package:flutter_test/flutter_test.dart';
import 'package:country_game/main.dart';
import 'package:country_game/screens/player_selection_screen.dart';
import 'package:country_game/widgets/card_dimensions.dart';
import 'package:country_game/game/card_deck_factory.dart';
import 'package:country_game/game/initial_exchange.dart';

void main() {
  testWidgets('Main menu renders game title and play button', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryGameApp());
    await tester.pumpAndSettle();

    expect(find.text('COUNTRY GAME'), findsOneWidget);
    expect(find.text('PLAY GAME'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(find.text('HOW TO PLAY & RULES'), findsOneWidget);
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

  testWidgets('Navigation from MainMenu to Settings screen works with no assertions', (WidgetTester tester) async {
    await tester.pumpWidget(const CountryGameApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('SETTINGS'));
    await tester.tap(find.text('SETTINGS'));
    await tester.pumpAndSettle();

    expect(find.text('Gameplay Sound Effects'), findsOneWidget);
    expect(find.text('Smooth Animations'), findsOneWidget);
    expect(find.text('Bot Thinking Pace'), findsOneWidget);
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

  test('Western player names have balanced 50% female and 50% male', () {
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
    // 4 players: 15 combinations available
    final set1 = CardDeckFactory.selectActiveTypes(4).toSet();
    final set2 = CardDeckFactory.selectActiveTypes(4).toSet();
    // Subsequent selection should not be identical when alternatives exist
    final isDifferent = set1.difference(set2).isNotEmpty;
    expect(isDifferent, isTrue);
  });
}
