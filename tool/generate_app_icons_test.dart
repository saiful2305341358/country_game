// Generates the app icons for every platform from the in-game logo
// (`GameLogo`), so the launcher icon, launch screen and home screen match.
//
//   flutter test tool/generate_app_icons_test.dart
//
// Re-run it whenever `lib/widgets/game_logo.dart` changes. It writes PNGs
// (and the Windows .ico) straight into the platform folders.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:country_game/widgets/game_logo.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Everything is drawn on a 1024×1024 canvas and scaled to the target size.
const double _canvas = 1024;

/// The dark emerald felt of the menus and launch screen.
const _felt = RadialGradient(
  radius: 0.75,
  colors: [Color(0xFF0F3B2C), Color(0xFF09251B), Color(0xFF03140E)],
  stops: [0.0, 0.62, 1.0],
);

// The Android adaptive-icon background colour is `ic_launcher_background`
// (#09251B) in android/app/src/main/res/values/colors.xml.

enum _Style {
  /// Full-bleed felt square with the medallion (iOS, web).
  square,

  /// Medallion alone on transparency (Android before 8.0, favicon, Windows).
  medallion,

  /// Medallion inside Android's adaptive-icon safe zone, on transparency.
  adaptiveForeground,

  /// Full-bleed felt, medallion inside the 80 % maskable safe zone (web).
  maskable,

  /// macOS rounded-square plate with margin, as Apple's icon grid expects.
  macos,
}

class _IconArt extends StatelessWidget {
  final _Style style;
  const _IconArt(this.style);

  @override
  Widget build(BuildContext context) {
    Widget medallion(double fraction) => Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: _canvas * fraction * 0.05,
                  offset: Offset(0, _canvas * fraction * 0.02),
                ),
              ],
            ),
            child: GameLogo(size: _canvas * fraction, withGlow: false),
          ),
        );

    switch (style) {
      case _Style.square:
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: _felt),
          child: medallion(0.86),
        );
      case _Style.medallion:
        return Center(child: GameLogo(size: _canvas * 0.98, withGlow: false));
      case _Style.adaptiveForeground:
        // 108dp canvas; launchers show at most the inner 72dp and guarantee
        // the inner 66dp. A 64dp medallion keeps the gold rim on every mask.
        return medallion(64 / 108);
      case _Style.maskable:
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: _felt),
          child: medallion(0.72),
        );
      case _Style.macos:
        return Padding(
          padding: const EdgeInsets.all(100),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _felt,
              borderRadius: BorderRadius.circular(185),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: medallion(0.66),
          ),
        );
    }
  }
}

class _Target {
  final String path;
  final int size;
  final _Style style;

  /// App Store icons must not have an alpha channel.
  final bool opaque;

  const _Target(this.path, this.size, this.style, {this.opaque = false});
}

List<_Target> _targets() {
  const android = 'android/app/src/main/res';
  const densities = {
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0,
  };
  const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  const iosIcons = {
    '20x20@1x': 20, '20x20@2x': 40, '20x20@3x': 60, //
    '29x29@1x': 29, '29x29@2x': 58, '29x29@3x': 87,
    '40x40@1x': 40, '40x40@2x': 80, '40x40@3x': 120,
    '60x60@2x': 120, '60x60@3x': 180,
    '76x76@1x': 76, '76x76@2x': 152,
    '83.5x83.5@2x': 167, '1024x1024@1x': 1024,
  };
  const macos = 'macos/Runner/Assets.xcassets/AppIcon.appiconset';

  return [
    for (final d in densities.entries) ...[
      _Target('$android/mipmap-${d.key}/ic_launcher.png',
          (48 * d.value).round(), _Style.medallion),
      _Target('$android/mipmap-${d.key}/ic_launcher_foreground.png',
          (108 * d.value).round(), _Style.adaptiveForeground),
    ],
    for (final i in iosIcons.entries)
      _Target('$ios/Icon-App-${i.key}.png', i.value, _Style.square,
          opaque: true),
    for (final s in [16, 32, 64, 128, 256, 512, 1024])
      _Target('$macos/app_icon_$s.png', s, _Style.macos),
    const _Target('web/icons/Icon-192.png', 192, _Style.square, opaque: true),
    const _Target('web/icons/Icon-512.png', 512, _Style.square, opaque: true),
    const _Target('web/icons/Icon-maskable-192.png', 192, _Style.maskable,
        opaque: true),
    const _Target('web/icons/Icon-maskable-512.png', 512, _Style.maskable,
        opaque: true),
    const _Target('web/favicon.png', 32, _Style.medallion),
  ];
}

void main() {
  testWidgets('generate app icons', (tester) async {
    tester.view.physicalSize = const Size(_canvas, _canvas);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<Uint8List> render(_Style style, int size,
        {bool opaque = false}) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: _IconArt(style)),
      );
      late Uint8List png;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: size / _canvas);
        final data = await image.toByteData(
          format: ui.ImageByteFormat.rawStraightRgba,
        );
        png = _encodePng(
          data!.buffer.asUint8List(),
          image.width,
          image.height,
          opaque: opaque,
        );
        image.dispose();
      });
      return png;
    }

    for (final t in _targets()) {
      final bytes = await render(t.style, t.size, opaque: t.opaque);
      File(t.path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);
    }

    // Windows: an .ico holding PNG images.
    final ico = <int, Uint8List>{
      for (final s in [16, 24, 32, 48, 64, 128, 256])
        s: await render(_Style.medallion, s),
    };
    File('windows/runner/resources/app_icon.ico')
        .writeAsBytesSync(_encodeIco(ico));
  });
}

// ---- Minimal PNG / ICO writers (no extra dependencies) ----

Uint8List _encodePng(
  Uint8List rgba,
  int width,
  int height, {
  required bool opaque,
}) {
  final channels = opaque ? 3 : 4;
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // filter: none
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw.add(rgba.sublist(i, i + channels));
    }
  }

  final out = BytesBuilder()
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final body = [...type.codeUnits, ...data];
    out
      ..add(_u32(data.length))
      ..add(body)
      ..add(_u32(_crc32(body)));
  }

  chunk('IHDR', [
    ..._u32(width),
    ..._u32(height),
    8, // bit depth
    opaque ? 2 : 6, // colour type: RGB / RGBA
    0, 0, 0,
  ]);
  chunk('IDAT', ZLibEncoder(level: 9).convert(raw.takeBytes()));
  chunk('IEND', const []);
  return out.takeBytes();
}

Uint8List _encodeIco(Map<int, Uint8List> pngs) {
  final out = BytesBuilder()
    ..add(_u16le(0))
    ..add(_u16le(1)) // type: icon
    ..add(_u16le(pngs.length));
  var offset = 6 + 16 * pngs.length;
  for (final e in pngs.entries) {
    final s = e.key >= 256 ? 0 : e.key; // 0 means 256
    out
      ..add([s, s, 0, 0])
      ..add(_u16le(1)) // colour planes
      ..add(_u16le(32)) // bits per pixel
      ..add(_u32le(e.value.length))
      ..add(_u32le(offset));
    offset += e.value.length;
  }
  for (final png in pngs.values) {
    out.add(png);
  }
  return out.takeBytes();
}

List<int> _u32(int v) => [v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255];
List<int> _u32le(int v) =>
    [v & 255, v >> 8 & 255, v >> 16 & 255, v >> 24 & 255];
List<int> _u16le(int v) => [v & 255, v >> 8 & 255];

final List<int> _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
