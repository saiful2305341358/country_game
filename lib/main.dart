import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/game_settings.dart';
import 'screens/intro_video_screen.dart';
import 'screens/main_menu_screen.dart';
import 'services/audio_service.dart';
import 'services/haptic_service.dart';
import 'services/stats_service.dart';
import 'services/stats_storage_stub.dart'
    if (dart.library.html) 'services/stats_storage_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await StatsStorage.init();
  StatsService.instance.reloadFromStorage();
  GameSettings.current = GameSettings.current.copyWith(
    soundEnabled: AudioService.instance.isSoundEnabled,
    hapticsEnabled: HapticService.instance.isHapticsEnabled,
  );
  runApp(const CountryGameApp());
}

class CountryGameApp extends StatefulWidget {
  final bool showIntroOnStart;

  const CountryGameApp({
    super.key,
    this.showIntroOnStart = true,
  });

  @override
  State<CountryGameApp> createState() => _CountryGameAppState();
}

class _CountryGameAppState extends State<CountryGameApp> {
  late bool _showingIntro;

  @override
  void initState() {
    super.initState();
    _showingIntro = widget.showIntroOnStart;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Country Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF04140E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFFD97706),
          surface: Color(0xFF0F172A),
        ),
        fontFamily: 'Roboto',
      ),
      home: _showingIntro
          ? IntroVideoScreen(
              onFinished: () {
                if (mounted) {
                  setState(() => _showingIntro = false);
                }
              },
            )
          : const MainMenuScreen(),
    );
  }
}
