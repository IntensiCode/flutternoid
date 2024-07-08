import 'package:flame/components.dart';

import '../components/soft_keys.dart';
import '../core/common.dart';
import '../core/functions.dart';
import '../input/keys.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/fonts.dart';
import '../util/nine_patch_image.dart';

class GameDialog extends PositionComponent with AutoDispose, GameScriptFunctions {
  GameDialog(this._handlers, this._text, this._left, this._right);

  final Map<GameKey, Function> _handlers;
  final String _text;
  final String _left;
  final String _right;

  @override
  onLoad() async {
    super.onLoad();

    position.setValues(80, 68);
    size.setValues(160, 64);

    final bg = await image('button_plain.png');
    fontSelect(tinyFont, scale: 2);
    add(RectangleComponent(position: -position, size: gameSize, paint: pixelPaint()..color = shadow));
    add(NinePatchComponent(image: bg, size: size));
    textXY(_text, size.x / 2, size.y / 2, anchor: Anchor.center);

    await add_button(bg, _left, 0, size.y, Anchor.topLeft, () => _handle(SoftKey.left));
    await add_button(bg, _right, size.x, size.y, Anchor.topRight, () => _handle(SoftKey.right));
  }

  _handle(SoftKey it) {
    if (it == SoftKey.left) _handlers[GameKey.soft1]!();
    if (it == SoftKey.right) _handlers[GameKey.soft2]!();
  }
}
