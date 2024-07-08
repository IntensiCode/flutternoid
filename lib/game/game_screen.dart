import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_forge2d/body_component.dart';
import 'package:supercharged/supercharged.dart';

import '../core/common.dart';
import '../core/messaging.dart';
import '../core/random.dart';
import '../input/keys.dart';
import '../input/shortcuts.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/extensions.dart';
import '../util/on_message.dart';
import 'background_screen.dart';
import 'ball.dart';
import 'enemy_spawner.dart';
import 'extra_id.dart';
import 'flash_text.dart';
import 'game_frame.dart';
import 'game_messages.dart';
import 'game_phase.dart';
import 'game_state.dart';
import 'hiscore.dart';
import 'laser_weapon.dart';
import 'level.dart';
import 'plasma_blast.dart';
import 'player.dart';
import 'power_ups.dart';
import 'shadows.dart';
import 'slow_down_area.dart';
import 'visual_configuration.dart';

class GameScreen extends PositionComponent
    with AutoDispose, GameScriptFunctions, HasAutoDisposeShortcuts, HasVisibility {
  GameScreen({required this.keys});

  final Keys keys;

  final state = GameState();
  final level = Level();
  final flash_text = FlashText();
  final power_ups = PowerUps();
  final laser = LaserWeapon();
  final slow_down_area = SlowDownArea();
  final plasma_blasts = PlasmaBlasts();

  late final player = Player(laser, () => children.whereType<Ball>());

  GamePhase _phase = GamePhase.game_over;

  GamePhase get phase => _phase;

  set phase(GamePhase value) {
    if (_phase == value) return;
    _phase = value;

    final activate = _phase == GamePhase.game_on;
    world.propagateToChildren<BodyComponent>((it) {
      it.body.setActive(activate);
      return true;
    });

    sendMessage(GamePhaseUpdate(_phase));
  }

  @override
  bool get is_active => phase == GamePhase.game_on;

  // Component

  @override
  onLoad() async {
    position.setFrom(visual.game_position);
    await add(state);
    await add(visual);
    await add(hiscore);
    await add(BackgroundScreen());
    await add(Shadows(() => children.whereType<Ball>()));
    await add(level);
    await add(EnemySpawner());
    await add(flash_text);
    await add(power_ups);
    await add(laser);
    await add(GameFrame());
    await add(player);
    await add(slow_down_area);
    await add(plasma_blasts);

    onMessage<PlayerReady>((it) => add(Ball()));
    onMessage<MultiBall>((_) => _split_ball());

    if (dev) {
      onKey('1', () => sendMessage(SpawnExtra(ExtraId.laser)));
      onKey('2', () => sendMessage(SpawnExtra(ExtraId.catcher)));
      onKey('3', () => sendMessage(SpawnExtra(ExtraId.expander)));
      onKey('4', () => sendMessage(SpawnExtra(ExtraId.disruptor)));
      onKey('5', () => sendMessage(SpawnExtra(ExtraId.slow_down)));
      onKey('6', () => sendMessage(SpawnExtra(ExtraId.multi_ball)));
      onKey('7', () => sendMessage(SpawnExtra(ExtraId.extra_life)));
      onKey('b', () => add(Ball()));
      onKey('c', () => sendMessage(LevelComplete()));
      onKey('n', () => sendMessage(LevelComplete()));
      onKey('p', () {
        state.level_number_starting_at_1--;
        phase = GamePhase.enter_round;
      });
      onKey('r', () {
        removeAll(children.whereType<Ball>());
        add(Ball());
      });
      onKey('x', () => phase = GamePhase.game_over);
    }
  }

  @override
  void updateTree(double dt) {
    if (!isVisible) return;
    super.updateTree(dt);
  }

  // Implementation

  void _split_ball() {
    final ball = children.whereType<Ball>().maxBy((a, b) => (b.position.y - a.position.y).sign.toInt());
    if (ball == null) {
      add(Ball());
    } else {
      final inverted = ball.body.linearVelocity.inverted();
      inverted.rotate(rng.nextDoublePM(pi / 8));
      if (inverted.y > 0) inverted.y = -inverted.y;
      add(Ball.spawned(ball, inverted));
    }
  }
}
