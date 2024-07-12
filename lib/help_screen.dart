import 'package:flame/components.dart';

import 'components/flow_text.dart';
import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/functions.dart';
import 'core/screens.dart';
import 'scripting/game_script.dart';
import 'util/fonts.dart';

bool help_triggered_at_first_start = false;

class HelpScreen extends GameScriptComponent {
  @override
  void onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 1);
    textXY('How To Play', xCenter, 10, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/controls.txt'),
      font: tiny_font,
      position: Vector2(0, 25) ,
      size: Vector2(160, 160 - 16),
    ));

    add(FlowText(
      text: await game.assets.readFile('data/help.txt'),
      font: tiny_font,
      position: Vector2(xCenter, 25) ,
      size: Vector2(160, 176),
    ));

    final label = help_triggered_at_first_start ? 'Start' : 'Back';
    softkeys(label, null, (_) => popScreen());
  }
}
