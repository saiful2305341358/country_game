import 'package:flutter/material.dart';
import '../models/game_card.dart';
import '../models/game_player.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import 'card_dimensions.dart';
import 'country_card_view.dart';
import 'player_seat.dart';

class PlayingTable extends StatelessWidget {
  final GameState state;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onPause;
  final bool isProcessingMove;

  const PlayingTable({
    super.key,
    required this.state,
    required this.onCardSelected,
    required this.onPause,
    this.isProcessingMove = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Card sizing strictly following 2:1 ratio from CardDimensions
        final handCardSize = CardDimensions.getHumanHandCardSize(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          totalPlayers: state.totalPlayers,
        );

        final tableCardSize = CardDimensions.getTableCardSize(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        );

        final humanPlayer = state.players[0];
        final opponentPlayers = state.players.sublist(1);

        return Container(
          width: screenWidth,
          height: screenHeight,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Color(0xFF0F3B2C), // Center felt green
                Color(0xFF09251B),
                Color(0xFF04140E), // Vignette edges
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle table felt felt texture & golden border
              Positioned.fill(
                child: CustomPaint(
                  painter: TableFeltPainter(),
                ),
              ),

              // Top HUD Bar: Game status, turn info, and pause button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopHud(context),
              ),

              // Central Table Area: Dais & Central Table Card
              Center(
                child: _buildCentralTableArea(context, tableCardSize),
              ),

              // Opponent Seats arranged responsively around edges
              ..._buildOpponentSeats(
                opponentPlayers: opponentPlayers,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),

              // Human Player Hand Area at Bottom
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: _buildHumanHandArea(
                  context: context,
                  humanPlayer: humanPlayer,
                  cardSize: handCardSize,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopHud(BuildContext context) {
    final activePlayer = state.currentPlayer;
    final isHuman = activePlayer.isHuman;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Turn Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isHuman
                    ? const Color(0xFF059669).withValues(alpha: 0.85)
                    : const Color(0xFF1E293B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHuman ? const Color(0xFFFFD54F) : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHuman ? Icons.person : Icons.smart_toy,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isHuman ? 'YOUR TURN' : '${activePlayer.name}\'s Turn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Status message
            Expanded(
              child: Text(
                state.statusMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFFFE082).withValues(alpha: 0.95),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Pause / Menu button
            IconButton(
              icon: const Icon(Icons.pause, color: Color(0xFFFFD54F)),
              tooltip: 'Game Menu',
              onPressed: () {
                AudioService.instance.playButtonClick();
                onPause();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralTableArea(BuildContext context, Size cardSize) {
    final tableCard = state.tableCard;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Table Dais / Pedestal
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_restaurant, color: Color(0xFFFFD54F), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      state.isOpeningMove ? 'STARTING CARD' : 'TABLE CARD',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CountryCardView(
                  card: tableCard,
                  width: cardSize.width,
                  height: cardSize.height,
                  isLegal: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOpponentSeats({
    required List<GamePlayer> opponentPlayers,
    required double screenWidth,
    required double screenHeight,
  }) {
    final widgets = <Widget>[];
    final totalPlayers = state.totalPlayers;
    final topOffset = screenHeight < 600 ? 50.0 : 65.0;

    if (totalPlayers == 4) {
      // 3 opponents: Left (p1), Top (p2), Right (p3)
      // Bot 1: Left
      widgets.add(
        Positioned(
          left: 14,
          top: screenHeight * 0.38,
          child: _seatWidget(opponentPlayers[0]),
        ),
      );
      // Bot 2: Top
      widgets.add(
        Positioned(
          top: topOffset,
          left: screenWidth * 0.5 - 75,
          child: _seatWidget(opponentPlayers[1]),
        ),
      );
      // Bot 3: Right
      widgets.add(
        Positioned(
          right: 14,
          top: screenHeight * 0.38,
          child: _seatWidget(opponentPlayers[2]),
        ),
      );
    } else if (totalPlayers == 5) {
      // 4 opponents: Mid-Left, Top-Left, Top-Right, Mid-Right
      // Bot 1: Mid-Left
      widgets.add(
        Positioned(
          left: 12,
          top: screenHeight * 0.40,
          child: _seatWidget(opponentPlayers[0], isCompact: true),
        ),
      );
      // Bot 2: Top-Left
      widgets.add(
        Positioned(
          top: topOffset,
          left: screenWidth * 0.22,
          child: _seatWidget(opponentPlayers[1], isCompact: true),
        ),
      );
      // Bot 3: Top-Right
      widgets.add(
        Positioned(
          top: topOffset,
          right: screenWidth * 0.22,
          child: _seatWidget(opponentPlayers[2], isCompact: true),
        ),
      );
      // Bot 4: Mid-Right
      widgets.add(
        Positioned(
          right: 12,
          top: screenHeight * 0.40,
          child: _seatWidget(opponentPlayers[3], isCompact: true),
        ),
      );
    } else {
      // 6 players -> 5 opponents:
      // Bot 1: Bottom-Left
      widgets.add(
        Positioned(
          left: 12,
          bottom: screenHeight * 0.26,
          child: _seatWidget(opponentPlayers[0], isCompact: true),
        ),
      );
      // Bot 2: Top-Left
      widgets.add(
        Positioned(
          left: 14,
          top: topOffset,
          child: _seatWidget(opponentPlayers[1], isCompact: true),
        ),
      );
      // Bot 3: Top-Center
      widgets.add(
        Positioned(
          top: topOffset,
          left: screenWidth * 0.5 - 65,
          child: _seatWidget(opponentPlayers[2], isCompact: true),
        ),
      );
      // Bot 4: Top-Right
      widgets.add(
        Positioned(
          right: 14,
          top: topOffset,
          child: _seatWidget(opponentPlayers[3], isCompact: true),
        ),
      );
      // Bot 5: Bottom-Right
      widgets.add(
        Positioned(
          right: 12,
          bottom: screenHeight * 0.26,
          child: _seatWidget(opponentPlayers[4], isCompact: true),
        ),
      );
    }

    return widgets;
  }

  Widget _seatWidget(GamePlayer player, {bool isCompact = false}) {
    final isCurrentTurn = state.currentTurnPlayerIndex == player.id;
    final isThinking = isCurrentTurn && !player.isHuman && !state.isGameOver;

    return PlayerSeat(
      player: player,
      isCurrentTurn: isCurrentTurn,
      isThinking: isThinking,
      isCompact: isCompact,
    );
  }

  Widget _buildHumanHandArea({
    required BuildContext context,
    required GamePlayer humanPlayer,
    required Size cardSize,
  }) {
    final isHumanTurn = state.isHumanTurn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Helper hint when it's human's turn
        if (isHumanTurn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white70, width: 0.8),
            ),
            child: Text(
              state.isOpeningMove
                  ? 'Opening Move: Tap any card to place on table and take Starting Card'
                  : 'Tap a legal card to discard onto the table and take ${state.tableCard.displayName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Hand cards row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final card in humanPlayer.hand)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildHumanCard(
                    card: card,
                    isHumanTurn: isHumanTurn,
                    cardSize: cardSize,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHumanCard({
    required GameCard card,
    required bool isHumanTurn,
    required Size cardSize,
  }) {
    final isLegal = isHumanTurn && state.isLegalDiscard(card);

    return CountryCardView(
      card: card,
      width: cardSize.width,
      height: cardSize.height,
      isLegal: !isHumanTurn || isLegal,
      isSelected: false,
      onTap: isLegal && !isProcessingMove
          ? () {
              AudioService.instance.playCardTap();
              onCardSelected(card);
            }
          : null,
    );
  }
}

class TableFeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Outer gold border inset
    final borderPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(10), const Radius.circular(20)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
