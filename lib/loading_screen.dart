import 'package:flutternoid/core/functions.dart';

import 'core/common.dart';
import 'core/screens.dart';
import 'core/soundboard.dart';
import 'input/shortcuts.dart';
import 'scripting/game_script.dart';
import 'util/fonts.dart';

class LoadingScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  @override
  void onLoad() async {
    at(0.0, () => fontSelect(menuFont, scale: 0.25));

    at(0.0, () => fadeIn(textXY('An', xCenter, yCenter - lineHeight), duration: 3));
    at(1.0, () => fadeIn(textXY('IntensiCode', xCenter, yCenter), duration: 3));
    at(1.0, () => fadeIn(textXY('Presentation', xCenter, yCenter + lineHeight), duration: 3));
    at(3.0, () => fadeOutAll(3.0));

    at(2.0, () => fadeIn(textXY('Assets by', xCenter, yCenter - lineHeight), duration: 3));
    at(1.0, () => fadeIn(textXY('www.kronbits.com', xCenter, yCenter), duration: 3));
    at(1.0, () => fadeIn(textXY('(itch.io)', xCenter, yCenter + lineHeight), duration: 3));
    at(3.0, () => fadeOutAll(3.0));

    final psychocell = await image('psychocell.png');
    at(2.0, () => fontSelect(menuFont, scale: 0.5));
    at(0.0, () => fadeIn(spriteIXY(psychocell, xCenter, yCenter), duration: 3));
    at(1.0, () => fadeIn(textXY('A', xCenter, yCenter - lineHeight * 2), duration: 3));
    at(1.0, () => fadeIn(textXY('Psychocell', xCenter, yCenter), duration: 3));
    at(1.0, () => fadeIn(textXY('Game', xCenter, yCenter + lineHeight * 2), duration: 3));
    at(4.0, () => fadeOutAll(3.0));

    final intro = await image('intro.png');
    at(3.0, () => fadeIn(spriteIXY(intro, xCenter, yCenter), duration: 3));
    at(10.0, () => fadeOutAll(3.0));

    at(3.0, () => _leave());

    onKey('<Space>', () => _leave());
  }

  void _leave() {
    showScreen(Screen.title, skip_fade_out: true);
    removeFromParent();
  }

  @override
  void onMount() {
    super.onMount();
    soundboard.master = 0.75;
    soundboard.music = 0.5;
    soundboard.muted = false;
    soundboard.sound = 0.75;
    soundboard.voice = 0.75;
  }

  @override
  void onRemove() {
    super.onRemove();
    images.clear('psychocell.png');
  }
}
