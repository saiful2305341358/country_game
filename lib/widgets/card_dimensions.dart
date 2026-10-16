import 'package:flutter/material.dart';

/// Card Dimensions Utility
///
/// Implements the exact specification:
/// - Reference size: 3 inches × 1.5 inches (length × width)
/// - Height-to-width ratio: 2:1
/// - Width-to-height ratio: 1:2
/// - Aspect ratio (width / height): 0.5
class CardDimensions {
  static const double aspectRatio = 0.5;
  static const double heightToWidthRatio = 2.0;

  /// Returns size for the human player's hand cards, respecting screen width and player count.
  static Size getHumanHandCardSize({
    required double screenWidth,
    required double screenHeight,
    required int totalPlayers,
  }) {
    final isLandscape = screenWidth > screenHeight;
    final isMobile = screenWidth < 600 || (!isLandscape && screenWidth < 800);

    double targetWidth;
    if (isMobile) {
      if (totalPlayers >= 6) {
        targetWidth = (screenWidth * 0.14).clamp(48.0, 60.0);
      } else if (totalPlayers == 5) {
        targetWidth = (screenWidth * 0.16).clamp(52.0, 66.0);
      } else {
        targetWidth = (screenWidth * 0.18).clamp(58.0, 74.0);
      }
    } else {
      if (screenWidth > 1200) {
        targetWidth = (screenWidth * 0.08).clamp(85.0, 105.0);
      } else {
        targetWidth = (screenWidth * 0.10).clamp(72.0, 92.0);
      }
    }

    final targetHeight = targetWidth * heightToWidthRatio;
    return Size(targetWidth, targetHeight);
  }

  /// Returns size for the central table card.
  static Size getTableCardSize({
    required double screenWidth,
    required double screenHeight,
  }) {
    final isMobile = screenWidth < 600;
    final targetWidth = isMobile
        ? (screenWidth * 0.20).clamp(70.0, 90.0)
        : (screenWidth * 0.12).clamp(95.0, 115.0);
    return Size(targetWidth, targetWidth * heightToWidthRatio);
  }

  /// Returns size for opponent preview cards in seats.
  static Size getSeatCardSize({
    required double screenWidth,
    required int totalPlayers,
  }) {
    final isMobile = screenWidth < 600;
    final targetWidth = isMobile
        ? (totalPlayers >= 6 ? 24.0 : 28.0)
        : (totalPlayers >= 6 ? 32.0 : 38.0);
    return Size(targetWidth, targetWidth * heightToWidthRatio);
  }

  /// Returns size for dialogs / preview cards.
  static Size getPreviewCardSize({double width = 70.0}) {
    return Size(width, width * heightToWidthRatio);
  }
}
