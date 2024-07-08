import 'core/common.dart';
import 'core/functions.dart';
import 'core/screens.dart';
import 'game/soundboard.dart';
import 'input/shortcuts.dart';
import 'scripting/game_script.dart';
import 'util/fonts.dart';

class LoadingScreen extends GameScriptComponent with HasAutoDisposeShortcuts {
  @override
  void onLoad() async {
    at(0.0, () => fontSelect(menuFont, scale: 0.25));

    at(0.0, () => fadeIn(textXY('An', xCenter, yCenter - lineHeight), duration: 1));
    at(1.0, () => fadeIn(textXY('IntensiCode', xCenter, yCenter), duration: 1));
    at(1.0, () => fadeIn(textXY('Presentation', xCenter, yCenter + lineHeight), duration: 1));
    at(2.0, () => fadeOutAll(1.0));

    final psychocell = await image('psychocell.png');
    at(1.0, () => fontSelect(menuFont, scale: 0.5));
    at(1.0, () => fadeIn(textXY('A', xCenter, yCenter - lineHeight * 2), duration: 1));
    at(1.0, () => fadeIn(textXY('Psychocell', xCenter, yCenter), duration: 1));
    at(0.0, () => soundboard.play_one_shot_sample('psychocell.ogg'));
    at(0.0, () => fadeIn(spriteIXY(psychocell, xCenter, yCenter / 2), duration: 1));
    at(1.0, () => fadeIn(textXY('Game', xCenter, yCenter + lineHeight * 2), duration: 1));
    at(2.0, () => fadeOutAll(1.0));

    final intro = await image('intro.png');
    at(1.0, () => fadeIn(spriteIXY(intro, xCenter, yCenter), duration: 1));
    at(10.0, () => fadeOutAll(1.0));

    at(1.0, () => _leave());

    onKey('<Space>', () => _leave());
  }

  void _leave() {
    showScreen(Screen.title, skip_fade_out: true);
    removeFromParent();
  }

  @override
  void onRemove() {
    super.onRemove();
    images.clear('psychocell.png');
  }
}
