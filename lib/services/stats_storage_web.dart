// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class StatsStorage {
  static const String _sessionIntroKey = '__session_intro_played__';

  static Future<void> init() async {}

  static String? read(String key) {
    try {
      if (key == _sessionIntroKey) {
        return html.window.sessionStorage[key];
      }
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static void write(String key, String value) {
    try {
      if (key == _sessionIntroKey) {
        html.window.sessionStorage[key] = value;
        return;
      }
      html.window.localStorage[key] = value;
    } catch (_) {}
  }

  static void remove(String key) {
    try {
      if (key == _sessionIntroKey) {
        html.window.sessionStorage.remove(key);
        return;
      }
      html.window.localStorage.remove(key);
    } catch (_) {}
  }
}
