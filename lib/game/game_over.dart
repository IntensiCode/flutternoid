import 'package:flame/components.dart';

import '../components/soft_keys.dart';
import '../core/common.dart';
import '../input/keys.dart';
import '../scripting/game_script.dart';
import '../util/fonts.dart';

class GameOver extends GameScriptComponent {
  GameOver(this._handlers);

  final Map<GameKey, Function> _handlers;

  @override
  onLoad() async {
    super.onLoad();

    fontSelect(tinyFont, scale: 2);
    add(RectangleComponent(size: gameSize, paint: pixelPaint()..color = shadow));
    at(0.0, () => textXY('Game Over', xCenter, yCenter, anchor: Anchor.center)..priority = 10);
    at(0.0, () => playAudio('sound/doh_laugh.ogg'));
    softkeys('Exit', null, _handle, shortcuts: false);
  }

  _handle(SoftKey it) {
    if (it == SoftKey.left) _handlers[GameKey.soft1]!();
    if (it == SoftKey.right) _handlers[GameKey.soft2]!();
  }
}
