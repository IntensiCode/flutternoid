import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import 'components/basic_menu.dart';
import 'components/basic_menu_button.dart';
import 'components/flow_text.dart';
import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/functions.dart';
import 'core/screens.dart';
import 'game/soundboard.dart';
import 'scripting/game_script.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';

enum AudioMenuEntry {
  music_and_sound,
  music_only,
  sound_only,
  silent_mode,
  brick_notes,
  stream_music,
}

class AudioMenu extends GameScriptComponent {
  final bool show_back;
  final String music_theme;

  AudioMenu({required this.show_back, required this.music_theme});

  late final BasicMenu menu;
  late final BasicMenuButton brick_notes;
  late final BasicMenuButton stream_music;

  @override
  onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 2);
    textXY('Audio Mode', xCenter, 20, scale: 2, anchor: Anchor.topCenter);

    logInfo('initial audio mode: ${soundboard.audio_mode}');
    final preselected = switch (soundboard.audio_mode) {
      AudioMode.music_and_sound => AudioMenuEntry.music_and_sound,
      AudioMode.music_only => AudioMenuEntry.music_only,
      AudioMode.sound_only => AudioMenuEntry.sound_only,
      AudioMode.silent => AudioMenuEntry.silent_mode,
    };

    final buttonSheet = await sheetI('button_option.png', 1, 2);
    menu = added(BasicMenu<AudioMenuEntry>(
      button: buttonSheet,
      font: tiny_font,
      onSelected: _selected,
      spacing: 2,
      fixed_position: Vector2(gameWidth - 16, 48),
      fixed_anchor: Anchor.topRight,
    )
      ..addEntry(AudioMenuEntry.music_and_sound, 'Music & Sound')
      ..addEntry(AudioMenuEntry.music_only, 'Music Only')
      ..addEntry(AudioMenuEntry.sound_only, 'Sound Only')
      ..addEntry(AudioMenuEntry.silent_mode, 'Silent Mode')
      ..preselectEntry(preselected));

    brick_notes = menu.addEntry(AudioMenuEntry.brick_notes, 'Brick Notes', anchor: Anchor.centerLeft);
    brick_notes.checked = soundboard.stream_music;

    stream_music = menu.addEntry(AudioMenuEntry.stream_music, 'Stream Music', anchor: Anchor.centerLeft);
    stream_music.checked = soundboard.stream_music;

    menu.position.setValues(xCenter, yCenter);
    menu.anchor = Anchor.center;

    menu.onPreselected = (it) => _preselected(it);

    if (show_back) softkeys('Back', null, (_) => popScreen());

    add(FlowText(
      text: "If game sounds are glitched, try turning 'Brick Notes' off.\n\n"
          "If music isn't playing, try toggling 'Stream Music' option.",
      font: tiny_font,
      insets: Vector2(5, 5),
      position: Vector2(160 - 64, 174 - 16),
      size: Vector2(160 + 64, 24 + 16),
      anchor: Anchor.topLeft,
    ));
  }

  _selected(AudioMenuEntry it) {
    if (it == AudioMenuEntry.brick_notes) {
      soundboard.brick_notes = !soundboard.brick_notes;
      brick_notes.checked = soundboard.brick_notes;
    }
    if (it == AudioMenuEntry.stream_music) {
      soundboard.stream_music = !soundboard.stream_music;
      stream_music.checked = soundboard.stream_music;
    }
    return menu.preselectEntry(it);
  }

  _preselected(AudioMenuEntry? it) {
    logVerbose('audio menu preselected: $it');
    switch (it) {
      case AudioMenuEntry.music_and_sound:
        soundboard.audio_mode = AudioMode.music_and_sound;
        _make_sound();
      case AudioMenuEntry.music_only:
        soundboard.audio_mode = AudioMode.music_only;
      case AudioMenuEntry.sound_only:
        soundboard.audio_mode = AudioMode.sound_only;
        _make_sound();
      case AudioMenuEntry.brick_notes:
        break;
      case AudioMenuEntry.silent_mode:
        soundboard.audio_mode = AudioMode.silent;
      case AudioMenuEntry.stream_music:
        break;
      case null:
        break;
    }
  }

  void _make_sound() {
    final which = Sound.values.random().name;
    soundboard.play_one_shot_sample('sound/$which.ogg');
  }
}
