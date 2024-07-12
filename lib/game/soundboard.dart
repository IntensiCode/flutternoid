import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';

import '../core/common.dart';
import '../core/storage.dart';
import 'game_object.dart';

enum Sound {
  ball_held,
  ball_lost,
  bat_expand_arcade,
  catcher,
  disruptor,
  doh_ugh,
  enemy_destroyed,
  expander,
  explosion,
  extra_blast,
  extra_life_jingle,
  game_over,
  get_ready,
  hiscore,
  laser,
  laser_shot,
  level_complete,
  multi_ball,
  plasma,
  slow_down,
  teleport,
  vaus_lost,
  wall_hit,
}

final soundboard = Soundboard();

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

class Soundboard extends Component with HasGameData {
  AudioMode _audio_mode = AudioMode.music_and_sound;

  AudioMode get audio_mode => _audio_mode;

  set audio_mode(AudioMode mode) {
    if (_audio_mode == mode) return;
    _audio_mode = mode;

    logVerbose('change audio mode: $mode');

    save('soundboard', this);

    switch (mode) {
      case AudioMode.music_and_sound:
        _music = 0.4;
        _sound = 0.6;
        _voice = 0.8;
        _muted = false;
      case AudioMode.music_only:
        _music = 1.0;
        _sound = 0.0;
        _voice = 0.0;
        _muted = false;
      case AudioMode.silent:
        _music = 0.0;
        _sound = 0.0;
        _voice = 0.0;
        _muted = true;
      case AudioMode.sound_only:
        _music = 0.0;
        _sound = 0.8;
        _voice = 1.0;
        _muted = false;
    }

    active_music?.$2.volume = _music;
    active_music?.$2.paused = _music == 0;
  }

  final double _master = 0.5;

  double _music = 0.4;
  double _sound = 0.6;
  double _voice = 0.8;

  bool _muted = false;

  // flag used during initialization
  bool _blocked = false;

  // used by [trigger] to play every sound only once per tick
  final _triggered = <Sound>{};

  // raw sample data for mixing
  final _samples = <Sound, Float32List>{};

  // some notes to play instead of wall hit
  final _notes = <Float32List>[];

  // constant audio stream for mixing sound effects
  AudioStream? _stream;

  // sample states for mixing into [_stream]
  final _play_state = <PlayState>[];

  int? note_index;

  toggleMute() => _muted = !_muted;

  clear(String filename) => FlameAudio.audioCache.clear(filename);

  _preload() async {
    _blocked = true;

    if (_samples.isEmpty) {
      for (final it in Sound.values) {
        logVerbose('preload sample $it');
        _samples[it] = await _make_sample('audio/sound/${it.name}.raw');
      }
    }

    if (_stream == null) {
      logVerbose('start audio mixing stream');
      _stream = getAudioStream();
      final result = _stream!.init(
        bufferMilliSec: 500,
        waitingBufferMilliSec: 10,
        channels: 1,
        sampleRate: 11025,
      );
      logVerbose('audio mixing stream started: $result');
      _stream!.resume();
      _mix_stream();
    }

    _blocked = false;
  }

  Future<Float32List> _make_sample(String fileName) async {
    final bytes = await game.assets.readBinaryFile(fileName);
    final data = Float32List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      data[i] = ((bytes[i] / 128) - 1);
    }
    return data;
  }

  trigger(Sound sound) => _triggered.add(sound);

  int last = 0;

  play(Sound sound, {double? volume}) async {
    if (_muted) return;
    if (_blocked) return;

    if (sound == Sound.wall_hit) {
      final index = note_index ?? 0;
      if (_notes.length <= index) {
        for (int i = _notes.length; i <= index; i++) {
          final freq = 261.626 + i * (293.665 - 261.626);
          final wave = _synth_sine_wave(freq, 11025, const Duration(milliseconds: 50));
          _notes.add(wave);
        }
      }
      _play_state.add(PlayState(_notes[index], volume: volume ?? _sound));
      note_index = 0;
    } else {
      _play_state.add(PlayState(_samples[sound]!, volume: volume ?? _sound));
    }
  }

  play_one_shot_sample(String filename, {double? volume}) async {
    if (filename.endsWith('.ogg')) filename = filename.replaceFirst('.ogg', '');

    logVerbose('play sample $filename');
    final data = await _make_sample('audio/$filename.raw');
    _play_state.add(PlayState(data, volume: volume ?? _voice));
  }

  (String, PlayState)? active_music;
  (String, double?)? pending_music;

  play_music(String filename, {double? volume}) async {
    if (filename == active_music?.$1) {
      logInfo('skip playing same music $filename');
      return;
    }
    if (active_music != null) {
      if (fade_out_volume != null) {
        logInfo('schedule music $filename');
        pending_music = (filename, volume);
        return;
      } else {
        _play_state.remove(active_music?.$2);
        active_music = null;
      }
    }

    logInfo('play music $filename');
    _play_state.remove(active_music?.$2);
    active_music = null;

    filename = filename.replaceFirst('.ogg', '').replaceFirst('.mp3', '');

    logVerbose('loop sample $filename');
    final data = await _make_sample('audio/$filename.raw');
    active_music = (filename, PlayState(data, loop: true, volume: volume ?? _music));
    _play_state.add(active_music!.$2);
  }

  double? fade_out_volume;

  void fade_out_music() {
    logInfo('fade out music ${active_music?.$2.volume}');
    fade_out_volume = active_music?.$2.volume;
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    await load('soundboard', this);
    _preload();
  }

  @override
  update(double dt) {
    super.update(dt);

    double? fov = fade_out_volume;
    if (fov != null) {
      fov -= dt;
      if (fov <= 0) {
        _play_state.remove(active_music?.$2);
        active_music = null;
        fade_out_volume = null;
        if (pending_music != null) {
          play_music(pending_music!.$1, volume: pending_music!.$2);
          pending_music = null;
        }
      } else {
        active_music?.$2.volume = fov;
        fade_out_volume = fov;
      }
    }

    if (_triggered.isEmpty) return;
    _triggered.forEach(play);
    _triggered.clear();
  }

  // HasGameData

  @override
  void load_state(Map<String, dynamic> data) {
    audio_mode = AudioMode.from_name(data['audio_mode'] ?? audio_mode.name);
  }

  @override
  GameData save_state(Map<String, dynamic> data) => data..['audio_mode'] = audio_mode.name;

  // Implementation

  static Float32List _synth_sine_wave(double freq, int rate, Duration duration) {
    final length = duration.inMilliseconds * rate ~/ 1000;

    final fadeSamples = min(100, length ~/ 2);

    final sineWave = List.generate(length, (i) {
      final amp = sin(2 * pi * ((i * freq) % rate) / rate);

      // apply fade in/out to avoid click noise
      final volume = (i > length - fadeSamples)
          ? (length - i - 1) / fadeSamples
          : (i < fadeSamples)
              ? i / fadeSamples
              : 1.0;

      return amp * volume;
    });

    return Float32List.fromList(sineWave);
  }

  _mix_stream() async {
    const hz = 10;
    const rate = 11025;
    const step = rate ~/ hz;
    final mixed = Float32List(step);
    logInfo('mixing at $hz hz - frame step $step - buffer bytes ${mixed.length}');

    Timer.periodic(const Duration(milliseconds: 1000 ~/ hz), (t) {
      mixed.fillRange(0, mixed.length, 0);
      if (_play_state.isEmpty || _muted) {
        _stream!.push(mixed);
        return;
      }

      for (final it in _play_state) {
        if (it.paused) continue;

        final data = it.sample;
        final start = it.sample_pos;
        final end = min(start + step, data.length);
        for (int i = start; i < end; i++) {
          final at = i - start;
          mixed[at] += data[i] * it.volume;
        }
        if (end == data.length) {
          it.sample_pos = it.loop ? 0 : -1;
        } else {
          it.sample_pos = end;
        }
      }

      double? compress;
      for (int i = 0; i < mixed.length; i++) {
        final v = mixed[i];
        // limit before compression
        if (v.abs() > 1) compress = max(compress ?? 0, v.abs());
        // apply master for absolute limit
        mixed[i] = v * _master;
      }

      if (compress != null) {
        logInfo('need compression: $compress');
        for (int i = 0; i < mixed.length; i++) {
          mixed[i] /= compress;
        }
      }

      _stream!.push(mixed);

      _play_state.removeWhere((e) => e.sample_pos == -1);
    });
  }
}
