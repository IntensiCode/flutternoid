import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutternoid/core/common.dart';
import 'package:flutternoid/game/game_messages.dart';
import 'package:flutternoid/util/auto_dispose.dart';
import 'package:flutternoid/util/extensions.dart';
import 'package:flutternoid/util/on_message.dart';

class Teleports extends Component with AutoDispose {
  late final TexturePackerSpriteSheet _sheet;

  final _active = <_Teleport>[];

  // Component

  @override
  onLoad() async {
    priority = 5;
    _sheet = atlas.sheetIWH('enemy_teleport.png', 32, 32);
    onMessage<SpawnTeleport>((it) => _active.add(_Teleport(it.position)));
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final it in _active.reversed) {
      it.time += dt * 4;
    }
    _active.removeWhere((it) => it.time >= 1.0);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final it in _active) {
      final max_frame = _sheet.columns * _sheet.rows - 1;
      final frame = it.time * max_frame;
      _sheet.getSpriteById(frame.round()).render(canvas, position: it.pos, anchor: Anchor.center);
    }
  }
}

class _Teleport {
  _Teleport(this.pos);

  final Vector2 pos;

  double time = 0;
}
