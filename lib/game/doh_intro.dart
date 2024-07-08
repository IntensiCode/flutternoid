import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/soundboard.dart';
import '../scripting/game_script.dart';
import '../util/fade_parent.dart';

class DohIntro extends GameScriptComponent {
  DohIntro(this._on_complete);

  final Function _on_complete;

  bool _leaving = false;

  @override
  onLoad() async {
    super.onLoad();

    final doh_sheet = await sheetIWH('doh.png', 32, 47);
    final doh_sprite = SpriteComponent(
      sprite: doh_sheet.getSpriteById(0),
      position: Vector2(xCenter, yCenter),
      anchor: Anchor.center,
    );

    doh_sprite.scale.setAll(2);
    doh_sprite.add(FadeParent(from: 0, to: 0.5, duration: 5));

    at(0.0, () => add(doh_sprite));
    at(1.0, () => soundboard.play_one_shot_sample('doh_laugh'));
    at(4.0, () => doh_sprite.add(FadeParent(from: 0.5, to: 0, duration: 2)));
    at(2.0, () => _leave());
  }

  void _leave() {
    if (_leaving) return;
    _leaving = true;
    removeFromParent();
    _on_complete();
  }
}
