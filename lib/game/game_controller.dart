import 'dart:math';
import 'dart:ui';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';

import '../core/common.dart';
import '../core/functions.dart';
import '../core/messaging.dart';
import '../core/screens.dart';
import '../input/keys.dart';
import '../input/shortcuts.dart';
import '../scripting/game_script.dart';
import '../util/bitmap_button.dart';
import '../util/bitmap_text.dart';
import '../util/delayed.dart';
import '../util/fonts.dart';
import '../util/on_message.dart';
import 'background_stars.dart';
import 'game_context.dart';
import 'game_dialog.dart';
import 'game_messages.dart';
import 'game_phase.dart';
import 'game_screen.dart';
import 'scoreboard.dart';
import 'soundboard.dart';

class GameController extends GameScriptComponent with HasAutoDisposeShortcuts {
  final _keys = Keys();
  final _stars = BackgroundStars();
  final _scoreboard = Scoreboard();

  late final Image _button;
  late final _game = GameScreen(keys: _keys);

  Component? _overlay;

  @override
  onLoad() async {
    super.onLoad();

    _button = await image('button_plain.png');

    await add(_stars);
    await add(_keys);
    await add(_game);
    await add(_scoreboard);

    onMessage<LevelComplete>((_) => _game.phase = GamePhase.next_round);
    onMessage<GameComplete>((_) => _game.phase = GamePhase.game_over);
    onMessage<GameOver>((_) => _game.phase = GamePhase.game_over);

    onMessage<GamePhaseUpdate>((it) {
      logInfo('game phase update: ${it.phase}');
      if (it.phase == GamePhase.round_intro) _on_round_intro();
      if (it.phase == GamePhase.next_round) _on_next_round();
      if (it.phase == GamePhase.game_over) _on_game_over();
    });

    _game.phase = GamePhase.round_intro;
  }

  void _on_next_round() {
    add(Delayed(0.5, () async {
      _game.state.level_number_starting_at_1++;
      logInfo('next round: ${_game.state.level_number_starting_at_1}');
      await _game.state.save_checkpoint();
      _game.phase = GamePhase.round_intro;
    }));
  }

  void _on_round_intro() {
    logInfo('on round intro');

    _overlay?.removeFromParent();
    _overlay = null;
    _stars.split_mode = true;
    _scoreboard.isVisible = true;
    _game.isVisible = true;
    // _game.phase = GamePhase.round_intro;
    _overlay = BitmapText(
      text: 'Round ${_game.state.level_number_starting_at_1}',
      position: visual.game_position + visual.game_pixels / 2,
      anchor: Anchor.center,
      font: miniFont,
    );
    add(_overlay!);

    sendMessage(LoadLevel());
  }

  void _on_game_on() {
    _overlay?.removeFromParent();
    _overlay = null;
    _stars.split_mode = true;
    _scoreboard.isVisible = true;
    _game.isVisible = true;
    _game.phase = GamePhase.game_on;
    _overlay = _make_in_game_overlay();
    add(_overlay!);
  }

  Component _make_in_game_overlay() => Component(children: [
        BitmapButton(
          bgNinePatch: _button,
          text: 'Exit',
          position: Vector2(0, 32),
          anchor: Anchor.topLeft,
          font: tinyFont,
          onTap: (_) => _on_confirm_exit(),
        )..angle = -pi / 2,
        BitmapButton(
          bgNinePatch: _button,
          text: 'Pause',
          position: Vector2(0, gameHeight + 16),
          anchor: Anchor.bottomLeft,
          font: tinyFont,
          onTap: (_) => _on_game_paused(),
        )..angle = -pi / 2,
      ]);

  _on_game_paused() {
    _overlay?.removeFromParent();
    _overlay = null;
    _game.phase = GamePhase.game_paused;
    _overlay = GameDialog(_on_key[GamePhase.game_paused]!, 'Game paused', 'Exit', 'Resume');
    add(_overlay!);
  }

  _on_confirm_exit() {
    _overlay?.removeFromParent();
    _overlay = null;
    _game.phase = GamePhase.confirm_exit;
    _overlay = GameDialog(_on_key[GamePhase.confirm_exit]!, 'Back to title?', 'Yes', 'No');
    add(_overlay!);
  }

  _on_game_over() async {
    _overlay?.removeFromParent();
    _overlay = null;
    _overlay = GameDialog(_on_key[GamePhase.game_over]!, 'GAME OVER', 'Exit', 'Try Again');
    add(_overlay!);

    soundboard.play_one_shot_sample('doh_laugh.ogg');

    await _game.state.clear_and_reset();
  }

  late final Map<GamePhase, Map<GameKey, void Function()>> _on_key = {
    GamePhase.round_intro: {
      GameKey.soft1: () => _on_game_on(),
      GameKey.soft2: () => _on_game_on(),
      GameKey.fire1: () => _on_game_on(),
      GameKey.fire2: () => _on_game_on(),
    },
    GamePhase.next_round: {
      // GameKey.soft1: () => _on_game_on(),
      // GameKey.soft2: () => _on_game_on(),
      // GameKey.fire1: () => _on_game_on(),
      // GameKey.fire2: () => _on_game_on(),
    },
    GamePhase.game_on: {
      GameKey.soft1: () => _on_confirm_exit(),
      GameKey.soft2: () => _on_game_paused(),
    },
    GamePhase.game_paused: {
      GameKey.soft1: () => showScreen(Screen.title),
      GameKey.soft2: () => _on_game_on(),
    },
    GamePhase.game_over: {
      GameKey.soft1: () => showScreen(Screen.title),
      GameKey.soft2: () => _game.phase = GamePhase.round_intro,
    },
    GamePhase.confirm_exit: {
      GameKey.soft1: () => showScreen(Screen.title),
      GameKey.soft2: () => _on_game_on(),
    },
  };

  @override
  void update(double dt) {
    super.update(dt);

    final mapping = _on_key[_game.phase];
    for (final key in mapping!.keys) {
      if (_keys.check_and_consume(key)) mapping[key]!();
    }
  }

  @override
  void renderTree(Canvas canvas) {
    if (visual.pixelate && false) {
      final recorder = PictureRecorder();
      super.renderTree(Canvas(recorder));
      final picture = recorder.endRecording();
      final image = picture.toImageSync(gameWidth ~/ 1, gameHeight ~/ 1);
      canvas.drawImage(image, Offset.zero, pixelPaint());
      image.dispose();
      picture.dispose();
    } else {
      super.renderTree(canvas);
    }
  }
}
