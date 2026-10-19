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

Future<void> _enforceLandscapeSystemUI() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _enforceLandscapeSystemUI();
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

class _CountryGameAppState extends State<CountryGameApp>
    with WidgetsBindingObserver {
  late bool _showingIntro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showingIntro = widget.showIntroOnStart;
    _enforceLandscapeSystemUI();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enforceLandscapeSystemUI();
    }
  }

  @override
  void didChangeMetrics() {
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return LandscapeViewportWrapper(child: child);
      },
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

/// Ensures the entire application tree (including all routes, dialogs, and overlays)
/// always renders in a unified landscape coordinate space (`width >= height`) with
/// controlled font scaling across Android, iOS, and Web viewports.
class LandscapeViewportWrapper extends StatelessWidget {
  final Widget child;

  const LandscapeViewportWrapper({
    super.key,
    required this.child,
  });

  static EdgeInsets _rotateInsetsQuarterTurn1(EdgeInsets insets) {
    return EdgeInsets.fromLTRB(
      insets.bottom,
      insets.left,
      insets.top,
      insets.right,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final clampedTextScaler = mediaQuery.textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.12,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final isPortraitHost = width > 0 && height > 0 && width < height;

        if (!isPortraitHost) {
          return MediaQuery(
            data: mediaQuery.copyWith(textScaler: clampedTextScaler),
            child: child,
          );
        }

        final landscapeSize = Size(height, width);
        final rotatedMediaQuery = mediaQuery.copyWith(
          size: landscapeSize,
          textScaler: clampedTextScaler,
          padding: _rotateInsetsQuarterTurn1(mediaQuery.padding),
          viewPadding: _rotateInsetsQuarterTurn1(mediaQuery.viewPadding),
          viewInsets: _rotateInsetsQuarterTurn1(mediaQuery.viewInsets),
          systemGestureInsets:
              _rotateInsetsQuarterTurn1(mediaQuery.systemGestureInsets),
        );

        return RotatedBox(
          quarterTurns: 1,
          child: MediaQuery(
            data: rotatedMediaQuery,
            child: SizedBox(
              width: landscapeSize.width,
              height: landscapeSize.height,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
