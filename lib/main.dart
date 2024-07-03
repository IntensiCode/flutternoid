import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';

import 'core/common.dart';
import 'flutternoid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (dev) {
    FlameAudio.audioCache.clearAll();
    imageCache.clear();
  } else {
    logLevel = LogLevel.none;
  }
  runApp(GameWidget(game: Flutternoid()));
}
