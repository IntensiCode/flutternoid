import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import 'components/basic_menu.dart';
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
}

class AudioMenu extends GameScriptComponent {
  final bool show_back;
  final String music_theme;

  AudioMenu({required this.show_back, required this.music_theme});

  late final BasicMenu menu;

  @override
  onLoad() async {
    add(await sprite_comp('background.png'));

    fontSelect(tiny_font, scale: 2);
    textXY('Audio Mode', xCenter, 20, scale: 2, anchor: Anchor.topCenter);

    final preselected = switch (soundboard.audio_mode) {
      AudioMode.music_and_sound => AudioMenuEntry.music_and_sound,
      AudioMode.music_only => AudioMenuEntry.music_only,
      AudioMode.sound_only => AudioMenuEntry.sound_only,
      AudioMode.silent => AudioMenuEntry.silent_mode,
    };

    final buttonSheet = await sheetI('button_menu.png', 1, 2);
    menu = added(BasicMenu<AudioMenuEntry>(buttonSheet, tiny_font, _selected, spacing: 2)
      ..addEntry(AudioMenuEntry.music_and_sound, 'Music & Sound')
      ..addEntry(AudioMenuEntry.music_only, 'Music Only')
      ..addEntry(AudioMenuEntry.sound_only, 'Sound Only')
      ..addEntry(AudioMenuEntry.silent_mode, 'Silent Mode')
      ..preselectEntry(preselected));

    menu.position.setValues(xCenter, yCenter);
    menu.anchor = Anchor.center;

    menu.onPreselected = (it) => _preselected(it);

    if (show_back) softkeys('Back', null, (_) => popScreen());
  }

  _selected(AudioMenuEntry it) => menu.preselectEntry(it);

  _preselected(AudioMenuEntry? it) {
    logInfo('audio menu preselected: $it');
    switch (it) {
      case AudioMenuEntry.music_and_sound:
        soundboard.audio_mode = AudioMode.music_and_sound;
        _make_sound();
      case AudioMenuEntry.music_only:
        soundboard.audio_mode = AudioMode.music_only;
      case AudioMenuEntry.sound_only:
        soundboard.audio_mode = AudioMode.sound_only;
        _make_sound();
      case AudioMenuEntry.silent_mode:
        soundboard.audio_mode = AudioMode.silent;
      case null:
        break;
    }
  }

  void _make_sound() {
    final which = Sound.values.random().name;
    soundboard.play_one_shot_sample('sound/$which');
  }
}
