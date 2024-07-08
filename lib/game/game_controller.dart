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
import '../util/extensions.dart';
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

/// Reminder to self: Controls the top-level game logic (here called [GamePhase]s) in contrast to the [GameScreen]
/// handling the game-play
///
/// While the [GameScreen] represents/manages the actual game-play, the [GameController] handles the overlays ("Game
/// Paused", etc) and un-/pausing the game-play as necessary. The top-level game state/phase related events are
/// handled here. Other components like [Level] for [LevelComplete] emit events and react directly to many events.
/// But the [GameController] handles the top-level progression of the game.
///
class GameController extends GameScriptComponent with HasAutoDisposeShortcuts {
  final _keys = Keys();
  final _stars = BackgroundStars();
  final _scoreboard = Scoreboard();

  late final Image _button;
  late final model = GameScreen(keys: _keys);

  Component? _overlay;

  @override
  onLoad() async {
    super.onLoad();

    _button = await image('button_plain.png');

    await add(_stars);
    await add(_keys);
    await add(model);
    await add(_scoreboard);

    onMessage<LevelComplete>((_) => model.phase = GamePhase.next_round);
    onMessage<PlayerReady>((_) => _on_enter_round_get_ready());
    // onMessage<PlayerReady>((_) => _game.phase = GamePhase.game_on);
    onMessage<GameComplete>((_) => model.phase = GamePhase.game_over); // TODO
    onMessage<GameOver>((_) => model.phase = GamePhase.game_over);

    onMessage<GamePhaseUpdate>((it) {
      logInfo('game phase update: ${it.phase}');
      _phase_handler(it.phase).call();
    });

    model.phase = GamePhase.enter_round;
  }

  void _on_enter_round_get_ready() {

    final bt = _overlay as BitmapText;
    bt.add(
        BitmapText(
          text: 'GET READY',
          position: Vector2(bt.width / 2, 14),
          anchor: Anchor.center,
          font: mini_font,
        ));

    add(Delayed(2.0, () {
      bt.fadeOutDeep();
      model.phase = GamePhase.game_on;
    }));

    soundboard.play_one_shot_sample('sound/get_ready.ogg');
  }

  Function _phase_handler(GamePhase it) => switch (it) {
        GamePhase.confirm_exit => _on_confirm_exit,
        GamePhase.enter_round => _on_enter_round,
        GamePhase.game_on => _on_game_on,
        GamePhase.game_over => _on_game_over,
        GamePhase.game_paused => _on_game_paused,
        GamePhase.next_round => _on_next_round,
      };

  void _on_confirm_exit() => _switch_overlay(GameDialog(
        _key_handlers(),
        'END GAME?',
        'YES',
        'NO',
      ));

  void _on_enter_round() {
    _stars.split_mode = true;
    _scoreboard.isVisible = true;
    model.isVisible = true;

    _switch_overlay(BitmapText(
      text: 'ROUND ${model.state.level_number_starting_at_1}',
      position: (visual.game_position + visual.game_pixels / 2)..y += 48,
      anchor: Anchor.center,
      font: mini_font,
    ));

    sendMessage(RoundIntro());
    sendMessage(LoadLevel());

    soundboard.play_one_shot_sample('sound/enter_round.ogg');
  }

  void _on_game_on() {
    _stars.split_mode = true;
    _scoreboard.isVisible = true;
    model.isVisible = true;

    _switch_overlay(_make_in_game_overlay());
  }

  void _on_game_over() async {
    _switch_overlay(GameDialog(
      _key_handlers(),
      'GAME OVER',
      'EXIT',
      'TRY AGAIN',
    ));

    soundboard.play_one_shot_sample('doh_laugh.ogg');

    await model.state.clear_and_reset();
  }

  void _on_game_paused() => _switch_overlay(GameDialog(
        _key_handlers(),
        'GAME PAUSED',
        'EXIT',
        'RESUME',
      ));

  void _on_next_round() {
    // TODO do what?
    add(Delayed(0.5, () async {
      model.state.level_number_starting_at_1++;
      logInfo('next round: ${model.state.level_number_starting_at_1}');
      await model.state.save_checkpoint();
      model.phase = GamePhase.enter_round;
    }));
  }

  @override
  void update(double dt) {
    super.update(dt);
    final mapping = _key_handlers();
    for (final key in mapping.keys) {
      if (_keys.check_and_consume(key)) {
        mapping[key]?.call();
      }
    }
  }

  Map<GameKey, Function> _key_handlers() => switch (model.phase) {
        GamePhase.confirm_exit => {
            GameKey.soft1: () => showScreen(Screen.title),
            GameKey.soft2: () => model.phase = GamePhase.game_on,
          },
        GamePhase.enter_round => {},
        GamePhase.game_on => {
            GameKey.soft1: () => model.phase = GamePhase.confirm_exit,
            GameKey.soft2: () => model.phase = GamePhase.game_paused,
          },
        GamePhase.game_over => {
            GameKey.soft1: () => showScreen(Screen.title),
            GameKey.soft2: () => model.phase = GamePhase.enter_round,
          },
        GamePhase.game_paused => {
            GameKey.soft1: () => showScreen(Screen.title),
            GameKey.soft2: () => model.phase = GamePhase.game_on,
          },
        GamePhase.next_round => {},
      };

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

  // Implementation

  void _switch_overlay(Component it) {
    _overlay?.fadeOutDeep();
    _overlay = added(it)..fadeInDeep();
  }

  Component _make_in_game_overlay() => Component(children: [
        BitmapButton(
          bgNinePatch: _button,
          text: 'Exit',
          position: Vector2(0, 32),
          anchor: Anchor.topLeft,
          font: tiny_font,
          onTap: (_) => model.phase = GamePhase.confirm_exit,
        )..angle = -pi / 2,
        BitmapButton(
          bgNinePatch: _button,
          text: 'Pause',
          position: Vector2(0, gameHeight + 16),
          anchor: Anchor.bottomLeft,
          font: tiny_font,
          onTap: (_) => model.phase = GamePhase.game_paused,
        )..angle = -pi / 2,
      ]);
}
