import 'dart:async';
import 'dart:math';

import 'package:dart_minilog/dart_minilog.dart';
import 'package:flame/components.dart' hide Timer;
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';

import '../core/common.dart';
import 'game_object.dart';
import 'storage.dart';

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
  bool _stream_music = true;

  bool get stream_music => _stream_music;

  set stream_music(bool value) {
    if (_stream_music == value) return;
    _stream_music = value;

    logInfo('switch stream_music: $value');

    if (_stream_music && FlameAudio.bgm.isPlaying) {
      logInfo('stop bgm music');
      FlameAudio.bgm.stop();
      logInfo('switch to streaming: $active_music_name?');
      _replay_music();
    }
    if (!_stream_music && active_music != null) {
      logInfo('stop streaming music');
      _play_state.remove(active_music);
      active_music = null;
      logInfo('switch to bgm: $active_music_name?');
      _replay_music();
    }
    save('soundboard', this);
  }

  void _replay_music() {
    if (active_music_name != null) play_music(active_music_name!);
  }

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

    if (kIsWeb && FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.audioPlayer.setVolume(_music);
      FlameAudio.bgm.pause();
    }
    if (kIsWeb && FlameAudio.bgm.audioPlayer.state == PlayerState.paused) {
      FlameAudio.bgm.audioPlayer.setVolume(_music);
      FlameAudio.bgm.resume();
    }

    active_music?.volume = _music;
    active_music?.paused = _music == 0;
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

  // for web version
  final _sounds = <Sound, AudioPlayer>{};
  final _web_notes = <AudioPlayer>[];

  String? active_music_name;
  PlayState? active_music;
  String? pending_music;
  double? fade_out_volume;

  toggleMute() => _muted = !_muted;

  clear(String filename) => FlameAudio.audioCache.clear(filename);

  preload() async {
    if (_blocked) return;
    _blocked = true;

    if (kIsWeb) {
      if (_sounds.isEmpty) await _preload_sounds();
    } else {
      if (_samples.isEmpty) await _make_samples();
    }

    // mp_audio_stream has too much lag for kIsWeb. audio_players works fine for kIsWeb.
    // therefore, the if just above.

    // but having the stream for music is nice.
    // therefore, we play samples via audio_players if kIsWeb, but always play music via mp_audio_stream.

    if (_stream == null) {
      logVerbose('start audio mixing stream');
      _stream = getAudioStream();
      final result = _stream!.init(
        bufferMilliSec: kIsWeb ? 1000 : 500,
        waitingBufferMilliSec: kIsWeb ? 100 : 50,
        channels: 1,
        sampleRate: 11025,
      );
      logVerbose('audio mixing stream started: $result');
      _stream!.resume();
      _mix_stream();
    }

    _blocked = false;

    logInfo('preload done');
  }

  Future _preload_sounds() async {
    for (final it in Sound.values) {
      try {
        // can't figure out why this one sound does not play in the web version ‾\_('')_/‾
        final ext = it == Sound.enemy_destroyed ? 'mp3' : 'ogg';
        _sounds[it] = await _preload_player('${it.name}.$ext');
      } catch (e) {
        logError('failed loading $it: $e');
      }
    }
    for (int i = 0; i <= 20; i++) {
      _web_notes.add(await _preload_player('note$i.ogg'));
    }
  }

  Future<AudioPlayer> _preload_player(String name) async {
    final player = await FlameAudio.play('sound/$name', volume: _sound);
    player.setReleaseMode(ReleaseMode.stop);
    player.setPlayerMode(PlayerMode.lowLatency);
    player.stop();
    return player;
  }

  Future _make_samples() async {
    for (final it in Sound.values) {
      _samples[it] = await _make_sample('audio/sound/${it.name}.raw');
    }
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

  play(Sound sound, {double? volume}) async {
    if (_muted) return;
    if (_blocked) return;

    if (kIsWeb) {
      final it = sound == Sound.wall_hit ? _web_notes[note_index ?? 0] : _sounds[sound];
      if (it == null) {
        logError('null sound: $sound');
        preload();
        return;
      }
      if (it.state != PlayerState.stopped) await it.stop();
      await it.setVolume(_sound);
      await it.resume();
      note_index = 0;
      return;
    }

    if (sound == Sound.wall_hit) {
      final index = note_index ?? 0;
      if (_notes.length <= index) {
        for (int i = _notes.length; i <= max(20, index); i++) {
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
    if (kIsWeb) {
      final it = await FlameAudio.play(filename, volume: volume ?? _voice);
      it.setReleaseMode(ReleaseMode.release);
      return;
    }

    if (filename.endsWith('.ogg')) filename = filename.replaceFirst('.ogg', '');

    logVerbose('play sample $filename');
    final data = await _make_sample('audio/$filename.raw');
    _play_state.add(PlayState(data, volume: volume ?? _voice));
  }

  play_music(String filename) async {
    if (kIsWeb && !_stream_music) {
      logInfo('playing music via audio_players');
      if (FlameAudio.bgm.isPlaying) {
        logInfo('stopping active bgm');
        await FlameAudio.bgm.stop();
      }
      await FlameAudio.bgm.play(filename, volume: _music);
      return;
    }

    logInfo('play music via mp_audio_stream');

    if (filename == active_music_name && active_music != null) {
      logInfo('skip playing same music $filename');
      return;
    }
    if (active_music != null) {
      if (fade_out_volume != null) {
        logInfo('schedule music $filename');
        pending_music = filename;
        return;
      } else {
        _play_state.remove(active_music);
        active_music = null;
      }
    }

    logInfo('play music $filename');
    _play_state.remove(active_music);
    active_music = null;

    final raw_name = '${filename.replaceFirst('.ogg', '').replaceFirst('.mp3', '')}.raw';

    logVerbose('loop sample $filename');
    final data = await _make_sample('audio/$raw_name');
    active_music_name = filename;
    active_music = PlayState(data, loop: true, volume: _music);
    _play_state.add(active_music!);
  }

  void fade_out_music() {
    logInfo('fade out music ${active_music?.volume}');
    fade_out_volume = active_music?.volume;
  }

  // Component

  @override
  onLoad() async {
    super.onLoad();
    await load('soundboard', this);
    if (!kIsWeb) preload();
  }

  @override
  update(double dt) {
    super.update(dt);

    _fade_music(dt);

    if (_triggered.isEmpty) return;
    _triggered.forEach(play);
    _triggered.clear();
  }

  void _fade_music(double dt) {
    double? fov = fade_out_volume;
    if (fov != null) {
      fov -= dt;
      if (fov <= 0) {
        _play_state.remove(active_music);
        active_music = null;
        fade_out_volume = null;
        if (pending_music != null) {
          play_music(pending_music!);
          pending_music = null;
        }
      } else {
        active_music?.volume = fov;
        fade_out_volume = fov;
      }
    }
  }

  // HasGameData

  @override
  void load_state(Map<String, dynamic> data) {
    audio_mode = AudioMode.from_name(data['audio_mode'] ?? audio_mode.name);
    stream_music = data['stream_music'] ?? stream_music;
  }

  @override
  GameData save_state(Map<String, dynamic> data) => data
    ..['audio_mode'] = audio_mode.name
    ..['stream_music'] = stream_music;

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
