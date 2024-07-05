import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_audio/flame_audio.dart';

import 'components/basic_menu.dart';
import 'components/soft_keys.dart';
import 'core/common.dart';
import 'core/functions.dart';
import 'core/screens.dart';
import 'core/soundboard.dart';
import 'scripting/game_script.dart';
import 'util/extensions.dart';
import 'util/fonts.dart';

AudioPlayer? _music;
AudioMenuEntry _preselected = AudioMenuEntry.music_and_sound;

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

  @override
  onLoad() async {
    _music = FlameAudio.bgm.audioPlayer;

    add(await sprite_comp('background.png'));

    fontSelect(tinyFont, scale: 2);
    textXY('Audio Mode', xCenter, 20, scale: 2, anchor: Anchor.topCenter);

    final buttonSheet = await sheetI('button_menu.png', 1, 2);
    final menu = added(BasicMenu<AudioMenuEntry>(buttonSheet, tinyFont, _selected, spacing: 2)
      ..addEntry(AudioMenuEntry.music_and_sound, 'Music & Sound')
      ..addEntry(AudioMenuEntry.music_only, 'Music Only')
      ..addEntry(AudioMenuEntry.sound_only, 'Sound Only')
      ..addEntry(AudioMenuEntry.silent_mode, 'Silent Mode')
      ..preselectEntry(_preselected));

    menu.position.setValues(xCenter, yCenter);
    menu.anchor = Anchor.center;

    menu.onPreselected = (it) => _selected(it);

    if (show_back) softkeys('Back', null, (_) => popScreen());
  }

  void _selected(AudioMenuEntry? it) {
    logInfo('audio menu preselected: $it');
    _preselected = it ?? AudioMenuEntry.sound_only;

    switch (it) {
      case AudioMenuEntry.music_and_sound:
        soundboard.muted = false;
        soundboard.music = 0.5;
        soundboard.sound = 1.0;
        soundboard.voice = 1.0;
        // _make_music();
        _make_sound();
        break;
      case AudioMenuEntry.music_only:
        soundboard.muted = false;
        soundboard.music = 1.0;
        soundboard.sound = 0.0;
        soundboard.voice = 0.0;
        // _make_music();
        break;
      case AudioMenuEntry.sound_only:
        soundboard.muted = false;
        soundboard.music = 0.0;
        soundboard.sound = 1.0;
        soundboard.voice = 1.0;
        // _stop_music();
        _make_sound();
        break;
      case AudioMenuEntry.silent_mode:
        soundboard.muted = true;
        soundboard.music = 0.0;
        soundboard.sound = 0.0;
        soundboard.voice = 0.0;
        // _stop_music();
        break;
      case null:
        break;
    }
  }

  void _make_music() async {
    logInfo('make music');
    if (_music?.state != PlayerState.playing) {
      await FlameAudio.bgm.play(music_theme, volume: soundboard.music);
    }
    await _music?.setVolume(soundboard.music);
  }

  void _make_sound() {
    logInfo('make sound');
    final which = Sound.values.random().name;
    soundboard.playAudio('sound/$which.ogg', volume: soundboard.sound);
  }

  void _stop_music() async {
    logInfo('stop music');
    if (_music?.state == PlayerState.playing) {
      await _music?.pause();
    }
    await _music?.setVolume(0.0);
  }
}
