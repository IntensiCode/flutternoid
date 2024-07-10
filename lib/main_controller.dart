import 'package:collection/collection.dart';
import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import 'audio_menu.dart';
import 'core/common.dart';
import 'core/messaging.dart';
import 'core/screens.dart';
import 'credits.dart';
import 'enter_hiscore_screen.dart';
import 'game/game_controller.dart';
import 'help_screen.dart';
import 'hiscore_screen.dart';
import 'loading_screen.dart';
import 'title_screen.dart';
import 'util/extensions.dart';
import 'video_menu.dart';
import 'web_play_screen.dart';

class MainController extends Forge2DWorld implements ScreenNavigation {
  final _stack = <Screen>[];

  @override
  onLoad() async => messaging.listen<ShowScreen>((it) => showScreen(it.screen));

  @override
  void onMount() {
    if (dev) {
      showScreen(Screen.game);
    } else if (kIsWeb) {
      add(WebPlayScreen());
    } else {
      add(LoadingScreen());
    }
  }

  @override
  void popScreen() {
    logVerbose('pop screen with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    _stack.removeLastOrNull();
    showScreen(_stack.lastOrNull ?? Screen.title);
  }

  @override
  void pushScreen(Screen it) {
    logVerbose('push screen $it with stack=$_stack and children=${children.map((it) => it.runtimeType)}');
    if (_stack.lastOrNull == it) throw 'stack already contains $it';
    _stack.add(it);
    showScreen(it);
  }

  Screen? _triggered;
  StackTrace? _previous;

  @override
  void showScreen(Screen screen, {bool skip_fade_out = false, bool skip_fade_in = false}) {
    if (_triggered == screen) {
      logError('duplicate trigger ignored: $screen', StackTrace.current);
      logError('previous trigger', _previous);
      return;
    }
    _triggered = screen;
    _previous = StackTrace.current;

    logInfo('show $screen');
    logVerbose('screen stack: $_stack');
    logVerbose('children: ${children.map((it) => it.runtimeType)}');

    if (!skip_fade_out && children.isNotEmpty) {
      children.last.fadeOutDeep(and_remove: true);
      children.last.removed.then((_) {
        if (_triggered == screen) {
          _triggered = null;
        } else if (_triggered != screen) {
          return;
        }
        showScreen(screen, skip_fade_out: skip_fade_out, skip_fade_in: skip_fade_in);
      });
    } else {
      final it = added(_makeScreen(screen));
      if (screen != Screen.game && !skip_fade_in) {
        it.mounted.then((_) => it.fadeInDeep());
      }
    }
  }

  Component _makeScreen(Screen it) => switch (it) {
        Screen.audio_menu => AudioMenu(show_back: true, music_theme: 'music/theme.mp3'),
        Screen.credits => Credits(),
        Screen.game => GameController(),
        Screen.help => HelpScreen(),
        Screen.hiscore => HiscoreScreen(),
        Screen.enter_hiscore => EnterHiscoreScreen(),
        Screen.loading => LoadingScreen(),
        Screen.title => TitleScreen(),
        Screen.video_menu => VideoMenu(),
      };
}
