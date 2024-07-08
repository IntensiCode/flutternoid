import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/functions.dart';

class Scoreboard extends PositionComponent with HasVisibility {
  @override
  onLoad() async {
    super.onLoad();

    size.setValues(320 - 216, gameHeight);
    position.setValues(216, 0);

    await add(await sprite_comp(
      'scoreboard_title.png',
      position: Vector2(size.x / 2, 0),
      anchor: Anchor.topCenter,
    ));
  }
}
