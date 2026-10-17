import 'package:flutter/material.dart';

enum CountryType {
  australia,
  greatBritain,
  saudiArabia,
  iran,
  japan,
  bangladesh;

  String get id => name;

  String get displayName {
    switch (this) {
      case CountryType.australia:
        return 'Australia';
      case CountryType.greatBritain:
        return 'Great Britain';
      case CountryType.saudiArabia:
        return 'Saudi Arabia';
      case CountryType.iran:
        return 'Iran';
      case CountryType.japan:
        return 'Japan';
      case CountryType.bangladesh:
        return 'Bangladesh';
    }
  }

  String get nativeName {
    switch (this) {
      case CountryType.australia:
        return 'Australia';
      case CountryType.greatBritain:
        return 'United Kingdom';
      case CountryType.saudiArabia:
        return 'السعودية';
      case CountryType.iran:
        return 'ایران';
      case CountryType.japan:
        return '日本 • Nippon';
      case CountryType.bangladesh:
        return 'বাংলাদেশ';
    }
  }

  String get shortCode {
    switch (this) {
      case CountryType.australia:
        return 'AUS';
      case CountryType.greatBritain:
        return 'GBR';
      case CountryType.saudiArabia:
        return 'SAU';
      case CountryType.iran:
        return 'IRN';
      case CountryType.japan:
        return 'JPN';
      case CountryType.bangladesh:
        return 'BGD';
    }
  }

  /// High-contrast primary color for each country to ensure instant visual distinction.
  Color get primaryColor {
    switch (this) {
      case CountryType.australia:
        return const Color(0xFFD97706); // Vibrant Outback Amber/Gold
      case CountryType.greatBritain:
        return const Color(0xFF2563EB); // Royal Sapphire Blue
      case CountryType.saudiArabia:
        return const Color(0xFF059669); // Lush Emerald Green
      case CountryType.iran:
        return const Color(0xFF0891B2); // Vivid Persian Turquoise
      case CountryType.japan:
        return const Color(0xFFE11D48); // Imperial Crimson Red
      case CountryType.bangladesh:
        return const Color(0xFF7C3AED); // Deep Royal Amethyst Purple
    }
  }

  /// Secondary deep gradient shade for each country card.
  Color get secondaryColor {
    switch (this) {
      case CountryType.australia:
        return const Color(0xFF78350F);
      case CountryType.greatBritain:
        return const Color(0xFF1E1B4B);
      case CountryType.saudiArabia:
        return const Color(0xFF064E3B);
      case CountryType.iran:
        return const Color(0xFF164E63);
      case CountryType.japan:
        return const Color(0xFF881337);
      case CountryType.bangladesh:
        return const Color(0xFF3B0764);
    }
  }

  /// High-contrast accent tint for borders, badges, and emblems.
  Color get accentColor {
    switch (this) {
      case CountryType.australia:
        return const Color(0xFFFDE68A);
      case CountryType.greatBritain:
        return const Color(0xFF93C5FD);
      case CountryType.saudiArabia:
        return const Color(0xFF6EE7B7);
      case CountryType.iran:
        return const Color(0xFF67E8F9);
      case CountryType.japan:
        return const Color(0xFFFDA4AF);
      case CountryType.bangladesh:
        return const Color(0xFFDDD6FE);
    }
  }
}
