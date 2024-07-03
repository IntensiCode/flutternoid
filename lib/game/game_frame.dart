import 'package:flame/components.dart';

import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import 'game_context.dart';

class GameFrame extends PositionComponent with AutoDispose, GameScriptFunctions {
  @override
  onLoad() async {
    priority = 1;

    position.setFrom(visual.background_offset);
    await spriteXY('skin_frame.png', 0, 0, Anchor.topLeft);
  }
}
