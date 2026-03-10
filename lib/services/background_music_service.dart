import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMusicTrack { auth, game }

class BackgroundMusicService with WidgetsBindingObserver {
  BackgroundMusicService._();

  // Temporary safety switch while troubleshooting background music assets.
  static const bool _playbackDisabled = true;

  static final BackgroundMusicService instance = BackgroundMusicService._();

  static const String _musicPrefKey = 'music_enabled';
  static const String _musicVolumePrefKey = 'music_volume';

  final AudioPlayer _player = AudioPlayer();
  bool _isEnabled = true;
  double _volume = 0.35;
  AppMusicTrack _currentTrack = AppMusicTrack.game;
  bool _isInitialized = false;

  bool get isEnabled => _isEnabled;
  double get volume => _volume;
  AppMusicTrack get currentTrack => _currentTrack;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_musicPrefKey) ?? true;
    _volume = prefs.getDouble(_musicVolumePrefKey) ?? 0.35;

    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(_volume);

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;

    if (_isEnabled && !_playbackDisabled) {
      await _playCurrentTrack();
    }
  }

  Future<void> setTrack(AppMusicTrack track) async {
    if (!_isInitialized) {
      await init();
    }

    _currentTrack = track;
    if (_isEnabled && !_playbackDisabled) {
      await _playCurrentTrack();
    }
  }

  Future<void> setAuthTrack() => setTrack(AppMusicTrack.auth);

  Future<void> setGameTrack() => setTrack(AppMusicTrack.game);

  Future<void> setEnabled(bool enabled) async {
    if (!_isInitialized) {
      await init();
    }

    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicPrefKey, enabled);

    if (enabled) {
      await _player.stop();
      if (!_playbackDisabled) {
        await _playCurrentTrack();
      }
    } else {
      await _player.stop();
    }
  }

  Future<void> setVolume(double volume) async {
    if (!_isInitialized) {
      await init();
    }

    final normalized = volume.clamp(0.0, 1.0);
    _volume = normalized;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumePrefKey, _volume);
    await _player.setVolume(_volume);
  }

  String _assetForTrack(AppMusicTrack track) {
    switch (track) {
      case AppMusicTrack.auth:
        return 'sounds/auth-bg.wav';
      case AppMusicTrack.game:
        return 'sounds/game-bg.wav';
    }
  }

  Future<void> _playCurrentTrack() async {
    if (_playbackDisabled) return;

    try {
      await _player.play(AssetSource(_assetForTrack(_currentTrack)));
    } catch (error) {
      debugPrint('Failed to play background music: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || !_isEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _player.pause();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_playCurrentTrack());
    }
  }
}
