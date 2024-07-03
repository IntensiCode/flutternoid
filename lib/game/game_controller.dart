import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flutternoid/input/shortcuts.dart';

import '../core/game.dart';
import '../core/messaging.dart';
import '../core/soundboard.dart';
import '../input/keys.dart';
import '../scripting/game_script_functions.dart';
import '../util/auto_dispose.dart';
import '../util/on_message.dart';
import 'background_screen.dart';
import 'ball.dart';
import 'game_configuration.dart';
import 'game_frame.dart';
import 'game_object.dart';
import 'level.dart';
import 'player.dart';
import 'shadows.dart';
import 'visual_configuration.dart';

class GameController extends PositionComponent with AutoDispose, GameScriptFunctions, HasAutoDisposeShortcuts {
  final configuration = GameConfiguration();
  final visual = VisualConfiguration();

  final keys = Keys();
  final level = Level();
  final player = Player();

  GamePhase _phase = GamePhase.start_game;

  GamePhase get phase => _phase;

  bool is_new_game = true;

  set phase(GamePhase value) {
    if (_phase == value) return;
    logVerbose('set state to $value');
    _phase = value;
    sendMessage(GamePhaseUpdate(value));
  }

  void start_new_game() {
    logInfo('start_new_game');
    is_new_game = true;
    propagateToChildren((it) {
      if (it case GameObject go) go.on_start_new_game();
      return true;
    });
    phase = GamePhase.start_game;
  }

  void start_playing() {
    logInfo('start_playing');
    phase = GamePhase.playing_level;
    is_new_game = false;

    propagateToChildren((it) {
      if (it case GameObject go) go.on_start_playing();
      return true;
    });
  }

  void confirm_exit() {
    logInfo('confirm_exit');
    phase = GamePhase.confirm_exit;
  }

  void pause_game() {
    logInfo('pause_game');
    phase = GamePhase.game_paused;
  }

  void resume_game() {
    logInfo('resume_game');
    phase = GamePhase.playing_level;
    // logInfo(player.state);
    propagateToChildren((it) {
      if (it case GameObject go) go.on_resume_game();
      return true;
    });
    is_new_game = false;
  }

  void on_end_of_level() {
    logInfo('on_end_of_level');
    propagateToChildren((it) {
      if (it case GameObject go) go.on_end_of_level();
      return true;
    });
  }

  void on_end_of_game() {
    logInfo('on_end_of_game');
    propagateToChildren((it) {
      if (it case GameObject go) go.on_end_of_game();
      return true;
    });
  }

  // Component

  @override
  onLoad() async {
    position.setFrom(visual.game_position);
    await add(BackgroundScreen());
    await add(Shadows());
    await add(keys);
    await add(level);
    await add(player);
    await add(GameFrame());
  }

  @override
  void onMount() {
    super.onMount();
    onMessage<PlayerReady>((it) => add(Ball()));
    onKey('b', () => add(Ball()));
    onKey('r', () {
      removeAll(children.whereType<Ball>());
      add(Ball());
    });
  }

  //
  // // HasGameData
  //
  // @override
  // void load_state(GameData data) {
  //   final update = _phase = GamePhase.from(data['state']);
  //   propagateToChildren((it) {
  //     if (it case GameObject go) {
  //       go.load_state(data[it.runtimeType.toString()]);
  //     }
  //     return true;
  //   });
  //   is_new_game = false;
  //   phase = update;
  //   logInfo('game state loaded');
  // }
  //
  // @override
  // GameData save_state(GameData data) {
  //   logInfo('save game state: $_phase');
  //   data['state'] = GamePhase.game_paused.name;
  //   propagateToChildren((it) {
  //     if (it case GameObject go) {
  //       if (data.containsKey(it.runtimeType.toString())) throw '$it already taken';
  //       data[it.runtimeType.toString()] = go.save_state({});
  //     }
  //     return true;
  //   });
  //   logInfo('game state saved');
  //   return data;
  // }

  // Component

  @override
  void updateTree(double dt) {
    if (phase == GamePhase.confirm_exit) return;
    if (phase == GamePhase.game_paused) return;
    if (phase == GamePhase.game_over) return;
    super.updateTree(dt);
  }

  void _advance_level() {
    logInfo('advance_level');
    // level.advance();
    soundboard.play(Sound.level_complete);
    is_new_game = false;
  }
}
