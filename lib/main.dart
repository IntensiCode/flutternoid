import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

import 'core/common.dart';
import 'flutternoid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  logLevel = dev ? LogLevel.verbose : LogLevel.info;
  runApp(GameWidget(game: Flutternoid()));
}
