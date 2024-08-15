import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'flutternoid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  logLevel = kDebugMode ? LogLevel.debug : LogLevel.none;
  runApp(GameWidget(game: Flutternoid()));
}
