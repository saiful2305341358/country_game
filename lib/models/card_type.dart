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
        return 'Commonwealth of Australia';
      case CountryType.greatBritain:
        return 'United Kingdom';
      case CountryType.saudiArabia:
        return 'المملكة العربية السعودية';
      case CountryType.iran:
        return 'جمهوری اسلامی ایران';
      case CountryType.japan:
        return '日本国 (Nippon)';
      case CountryType.bangladesh:
        return 'গণপ্রজাতন্ত্রী বাংলাদেশ';
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
}
