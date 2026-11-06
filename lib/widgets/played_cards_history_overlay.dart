import 'package:flutter/material.dart';
import '../models/card_type.dart';
import '../models/game_state.dart';
import '../services/audio_service.dart';
import '../services/haptic_service.dart';
import 'country_card_view.dart';

/// Custom momentum scroll physics combining iOS/Android BouncingScrollPhysics
/// with magnetic card-slot settling so mobile swipe gestures feel native.
class _MomentumCardSnapScrollPhysics extends BouncingScrollPhysics {
  final double itemStride;

  const _MomentumCardSnapScrollPhysics({
    required this.itemStride,
    super.parent,
  });

  @override
  _MomentumCardSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _MomentumCardSnapScrollPhysics(
      itemStride: itemStride,
      parent: buildParent(ancestor),
    );
  }

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    if (itemStride <= 0) return position.pixels;
    double page = position.pixels / itemStride;
    if (velocity < -tolerance.velocity) {
      page -= 0.45;
    } else if (velocity > tolerance.velocity) {
      page += 0.45;
    }
    final target = page.roundToDouble() * itemStride;
    return target.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final Tolerance tolerance = toleranceFor(position);
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }
}

/// A compact, smoothly horizontally scrollable overlay in the GameScreen that tracks
/// the last 5 cards played so players can keep track of the game flow on mobile touch devices.
class PlayedCardsHistoryOverlay extends StatefulWidget {
  final List<PlayedCardHistoryEntry> recentPlayedCards;
  final String currentTableCardName;
  final VoidCallback onClose;

  const PlayedCardsHistoryOverlay({
    super.key,
    required this.recentPlayedCards,
    required this.currentTableCardName,
    required this.onClose,
  });

  @override
  State<PlayedCardsHistoryOverlay> createState() =>
      _PlayedCardsHistoryOverlayState();
}

class _PlayedCardsHistoryOverlayState extends State<PlayedCardsHistoryOverlay> {
  static const double _cardWidth = 158.0;
  static const double _cardGap = 10.0;
  static const double _cardStep = _cardWidth + _cardGap;

  late final ScrollController _scrollController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final total = widget.recentPlayedCards.length;
    if (total <= 0) return;
    final idx = (_scrollController.offset / _cardStep)
        .round()
        .clamp(0, total - 1);
    if (idx != _activeIndex && mounted) {
      HapticService.instance.uiTap();
      setState(() => _activeIndex = idx);
    }
  }

  void _animateToIndex(int index) {
    final total = widget.recentPlayedCards.length;
    if (total <= 0 || !_scrollController.hasClients) return;
    final clamped = index.clamp(0, total - 1);
    setState(() => _activeIndex = clamped);
    final maxExtent = _scrollController.position.maxScrollExtent;
    final targetOffset = (clamped * _cardStep).clamp(0.0, maxExtent);
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderedEntries =
        widget.recentPlayedCards.reversed.toList(growable: false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AudioService.instance.playButtonClick();
        HapticService.instance.uiTap();
        widget.onClose();
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () {},
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 465,
                  maxHeight: 255,
                ),
                child: Container(
                  margin: const EdgeInsets.only(top: 4, right: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.72),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD54F)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFFFD54F)
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: Color(0xFFFFD54F),
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Flexible(
                                      child: Text(
                                        'LAST 5 CARDS PLAYED',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD97706)
                                            .withValues(alpha: 0.30),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFFFFD54F)
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Text(
                                        '${orderedEntries.length}/5',
                                        style: const TextStyle(
                                          color: Color(0xFFFFE082),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'On Table Now: ${widget.currentTableCardName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (orderedEntries.length > 1) ...[
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: 'Previous Card',
                                icon: Icon(
                                  Icons.chevron_left_rounded,
                                  color: _activeIndex > 0
                                      ? const Color(0xFFFFD54F)
                                      : Colors.white24,
                                  size: 18,
                                ),
                                onPressed: _activeIndex > 0
                                    ? () {
                                        AudioService.instance.playButtonClick();
                                        HapticService.instance.uiTap();
                                        _animateToIndex(_activeIndex - 1);
                                      }
                                    : null,
                              ),
                            ),
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: 'Next Card',
                                icon: Icon(
                                  Icons.chevron_right_rounded,
                                  color: _activeIndex <
                                          orderedEntries.length - 1
                                      ? const Color(0xFFFFD54F)
                                      : Colors.white24,
                                  size: 18,
                                ),
                                onPressed: _activeIndex <
                                        orderedEntries.length - 1
                                    ? () {
                                        AudioService.instance.playButtonClick();
                                        HapticService.instance.uiTap();
                                        _animateToIndex(_activeIndex + 1);
                                      }
                                    : null,
                              ),
                            ),
                          ],
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: 'Close History',
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 17,
                              ),
                              onPressed: () {
                                AudioService.instance.playButtonClick();
                                HapticService.instance.uiTap();
                                widget.onClose();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 8),

                      // Smooth Horizontally Scrollable Last 5 Cards Carousel
                      if (orderedEntries.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.style_rounded,
                                color: Color(0x99FFD54F),
                                size: 22,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'No Cards Played Yet',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'As soon as players trade cards with the table, the last 5 cards played will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10.5,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        SizedBox(
                          height: 118,
                          child: ListView.separated(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const _MomentumCardSnapScrollPhysics(
                              itemStride: _cardStep,
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            itemCount: orderedEntries.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: _cardGap),
                            itemBuilder: (context, index) {
                              final entry = orderedEntries[index];
                              final isLatest = index == 0;
                              final isActive = index == _activeIndex;
                              final playedName = entry.playedCard.displayName;
                              final takenName = entry.takenCard.displayName;
                              final shortCode = !entry
                                          .playedCard.isStartingCard &&
                                      entry.playedCard.type != null
                                  ? entry.playedCard.type!.shortCode
                                  : null;

                              return GestureDetector(
                                onTap: () {
                                  HapticService.instance.uiTap();
                                  _animateToIndex(index);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  width: _cardWidth,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isLatest
                                        ? const Color(0xFF1E293B)
                                            .withValues(alpha: 0.95)
                                        : isActive
                                            ? const Color(0xFF1E293B)
                                                .withValues(alpha: 0.75)
                                            : Colors.white
                                                .withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isLatest
                                          ? const Color(0xFFFFD54F)
                                              .withValues(alpha: 0.75)
                                          : isActive
                                              ? const Color(0xFFFFD54F)
                                                  .withValues(alpha: 0.45)
                                              : Colors.white12,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Top Row: Player Name & Turn Badge
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              entry.playerName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: entry.isHuman
                                                    ? const Color(0xFFFFD700)
                                                    : Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black38,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color: Colors.white12,
                                              ),
                                            ),
                                            child: Text(
                                              '#${entry.turnNumber}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Middle Row: Mini Card Visual + Played Card Info
                                      Row(
                                        children: [
                                          CountryCardView(
                                            card: entry.playedCard,
                                            width: 32,
                                            height: 48,
                                            isLegal: true,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isLatest)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 4.5,
                                                      vertical: 1,
                                                    ),
                                                    margin:
                                                        const EdgeInsets.only(
                                                      bottom: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFD97706),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: const Text(
                                                      'LATEST',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 7.5,
                                                        fontWeight:
                                                            FontWeight.w900,
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  const Text(
                                                    'PLAYED',
                                                    style: TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                Text(
                                                  playedName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Color(0xFFFFE082),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                if (shortCode != null)
                                                  Text(
                                                    shortCode,
                                                    style: const TextStyle(
                                                      color: Colors.white60,
                                                      fontSize: 8.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Bottom Row: Taken From Table
                                      Text(
                                        'Took: $takenName',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Swipe left/right to browse moves',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                orderedEntries.length,
                                (idx) {
                                  final active = idx == _activeIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      HapticService.instance.uiTap();
                                      _animateToIndex(idx);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(left: 4),
                                      width: active ? 16 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: active
                                            ? const Color(0xFFFFD54F)
                                            : Colors.white24,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
