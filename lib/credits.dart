import 'package:flame/components.dart';

import 'components/flow_text.dart';
import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/functions.dart';
import 'core/screens.dart';
import 'scripting/game_script.dart';
import 'util/fonts.dart';

class Credits extends GameScriptComponent {
  @override
  void onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tinyFont, scale: 1);
    textXY('Credits', xCenter, 08, scale: 2, anchor: Anchor.topCenter);

    add(FlowText(
      text: await game.assets.readFile('data/credits.txt'),
      font: tinyFont,
      position: Vector2(0, 24) ,
      size: Vector2(320, 160 - 24),
    ));

    softkeys('Back', null, (_) => popScreen());
  }
}
