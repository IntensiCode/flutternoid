import 'dart:async';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flutter/foundation.dart';

import '../core/common.dart';
import 'game_object.dart';
import 'soundboard_mixed.dart' if (dart.library.html) 'soundboard_web.dart';
import 'storage.dart';

enum Sound {
  ball_held,
  ball_lost,
  bat_expand_arcade,
  catcher,
  disruptor,
  doh_ugh,
  enemy_destroyed,
  enemy_hit,
  expander,
  explosion,
  extra_life,
  extra_life_jingle,
  laser,
  laser_shot,
  multi_ball,
  plasma,
  slow_down,
  teleport,
  vaus_lost,
  wall_hit,
}

final soundboard = SoundboardImpl();

enum AudioMode {
  music_and_sound,
  music_only,
  silent,
  sound_only,
  ;

  static AudioMode from_name(String name) => AudioMode.values.firstWhere((it) => it.name == name);
}

class PlayState {
  PlayState(this.sample, {this.loop = false, this.paused = false, required this.volume});

  final Float32List sample;
  int sample_pos = 0;

  bool loop = false;
  bool paused = false;

  double volume;
}

abstract class Soundboard extends Component with HasGameData {
  void _save() => save('soundboard', this);

  bool _brick_notes = true;

  bool get brick_notes => _brick_notes;

  set brick_notes(bool value) {
    if (_brick_notes == value) return;
    _brick_notes = value;
    _save();

    if (value) {
      do_play_notes();
    } else {
      do_not_play_notes();
    }
  }

  AudioMode _audio_mode = AudioMode.music_and_sound;

  AudioMode get audio_mode => _audio_mode;

  set audio_mode(AudioMode mode) {
    if (_audio_mode == mode) return;
    _audio_mode = mode;
    logInfo('change audio mode: $mode');
    _update_volumes(mode);
    _save();
    do_update_volume();
  }

  void _update_volumes(AudioMode mode) {
    switch (mode) {
      case AudioMode.music_and_sound:
        _music = 0.4;
        _sound = 0.6;
        _muted = false;
      case AudioMode.music_only:
        _music = 1.0;
        _sound = 0.0;
        _muted = false;
      case AudioMode.silent:
        _music = 0.0;
        _sound = 0.0;
        _muted = true;
      case AudioMode.sound_only:
        _music = 0.0;
        _sound = 1.0;
        _muted = false;
    }
  }

  double _master = 0.5;

  double get master => _master;

  set master(double value) {
    if (_master == value) return;
    _master = value;
    _save();
  }

  double _music = 0.4;

  double get music => _music;

  set music(double value) {
    if (_music == value) return;
    _music = value;
    _save();
    do_update_volume();
  }

  double _sound = 0.6;

  double get sound => _sound;

  set sound(double value) {
    if (_sound == value) return;
    _sound = value;
    _save();
  }

  bool _muted = false;

  bool get muted => _muted;

  set muted(bool value) {
    if (_muted == value) return;
    _muted = value;
    _save();
  }

  // flag used during initialization
  bool _blocked = false;

  // used by [trigger] to play every sound only once per tick
  final _triggered = <Sound, bool>{};

  // for playing notes instead of Sound.wall_hit
  int? note_index;

  String? active_music_name;
  String? pending_music;
  double? fade_out_volume;

  @protected
  double? get active_music_volume;

  set active_music_volume(double? it);

  @protected
  void do_play_notes() {}

  @protected
  void do_not_play_notes() {}

  @protected
  void do_update_volume();

  @protected
  Future do_init_and_preload();

  @protected
  Future do_play(Sound sound, double volume_factor);

  @protected
  Future do_play_one_shot_sample(String filename, double volume_factor);

  @protected
  Future do_play_music(String filename);

  @protected
  void do_stop_active_music();

  void toggleMute() => muted = !muted;

  void clear(String filename) => TODO('nyi'); // FlameAudio.audioCache.clear(filename);

  Future preload() async {
    if (_blocked) return;
    _blocked = true;
    await do_init_and_preload();
    _blocked = false;
    logInfo('preload done');
  }

  void trigger(Sound sound) {
    if (_triggered[sound] == true) return;
    _triggered[sound] = true;
  }

  Future play(Sound sound, {double volume_factor = 1}) async {
    if (_muted) return;
    if (_blocked) return;
    await do_play(sound, volume_factor);
  }

  Future play_one_shot_sample(String filename, {double volume_factor = 1}) async {
    if (_muted) return;
    if (_blocked) return;
    await do_play_one_shot_sample(filename, volume_factor);
  }

  Future play_music(String filename) async {
    // TODO check is_playing_music, too?
    if (active_music_name == filename) {
      logInfo('music already playing: $filename');
    } else if (fade_out_volume != null) {
      logInfo('schedule music $filename');
      pending_music = filename;
    } else {
      logInfo('play music $filename');
      do_stop_active_music();
      active_music_name = filename;
      await do_play_music(filename);
    }
  }

  void stop_active_music() {
    fade_out_volume = null;
    active_music_name = null;
    do_stop_active_music();
  }

  void fade_out_music() {
    logInfo('fade out music $active_music_volume');
    fade_out_volume = active_music_volume;
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    await load('soundboard', this);
  }

  @override
  update(double dt) {
    super.update(dt);

    _fade_music(dt);

    if (_triggered.isEmpty) return;
    _triggered.entries.forEach((it) {
      if (it.value) play(it.key);
    });
    _triggered.clear();
  }

  void _fade_music(double dt) {
    double? fov = fade_out_volume;
    if (fov == null) return;

    fov -= dt;
    if (fov <= 0) {
      stop_active_music();
      fade_out_volume = null;
      if (pending_music != null) {
        play_music(pending_music!);
        pending_music = null;
      }
    } else {
      active_music_volume = fov;
      fade_out_volume = fov;
    }
  }

  // HasGameData

  @override
  void load_state(Map<String, dynamic> data) {
    logInfo('load soundboard: $data');
    _audio_mode = AudioMode.from_name(data['audio_mode'] ?? audio_mode.name);
    _brick_notes = data['brick_notes'] ?? brick_notes;
    _master = data['master'] ?? _master;
    _music = data['music'] ?? _music;
    _muted = data['muted'] ?? _muted;
    _sound = data['sound'] ?? _sound;
  }

  @override
  GameData save_state(Map<String, dynamic> data) => data
    ..['master'] = _master
    ..['music'] = _music
    ..['muted'] = _muted
    ..['sound'] = _sound
    ..['audio_mode'] = _audio_mode.name
    ..['brick_notes'] = _brick_notes;
}
