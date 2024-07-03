import 'package:flame/components.dart';
import 'package:flutternoid/core/soundboard.dart';

import 'core/common.dart';
import 'core/screens.dart';
import 'input/shortcuts.dart';
import 'scripting/game_script.dart';
import 'util/effects.dart';

class TitleScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  @override
  onLoad() async {
    await spriteXY('title.png', xCenter, yCenter);
    textXY('Insert coin', xCenter, gameHeight + 19, anchor: Anchor.bottomCenter).add(BlinkEffect());

    soundboard.preload();
  }

  @override
  void onMount() {
    super.onMount();
    playAudio('arkanoid.ogg');
    onKey('<Space>', () => showScreen(Screen.game));
    backgroundMusic('voyage_of_vaus.mp3');
  }
}
