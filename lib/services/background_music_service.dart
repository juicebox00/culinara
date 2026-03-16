import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMusicTrack { auth, game }

class BackgroundMusicService with WidgetsBindingObserver {
  BackgroundMusicService._();

  // Temporary safety switch while troubleshooting background music assets.
  static const bool _playbackDisabled = false;

  static final BackgroundMusicService instance = BackgroundMusicService._();

  static const String _musicPrefKey = 'music_enabled';
  static const String _musicVolumePrefKey = 'music_volume';

  final AudioPlayer _player = AudioPlayer();
  bool _isEnabled = true;
  double _volume = 0.35;
  AppMusicTrack _currentTrack = AppMusicTrack.game;
  bool _isInitialized = false;
  int _timerPauseDepth = 0;

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
    // If the requested track is already playing, don't restart it.
    if (_currentTrack == track) return;

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
        return 'sounds/auth-bg.mp3';
      case AppMusicTrack.game:
        return 'sounds/game-bg.mp3';
    }
  }

  Future<void> _playCurrentTrack() async {
    if (_playbackDisabled) return;

    try {
      // Always stop any existing playback before starting the new track
      await _player.stop();
      await _player.play(AssetSource(_assetForTrack(_currentTrack)));
    } catch (error) {
      debugPrint('Failed to play background music: $error');
    }
  }

  /// Temporarily pause background music while a timer is running.
  /// This does not change the user's music setting.
  Future<void> pauseForTimer() async {
    if (!_isInitialized) {
      await init();
    }
    if (!_isEnabled || _playbackDisabled) return;

    _timerPauseDepth++;
    if (_timerPauseDepth == 1) {
      try {
        await _player.pause();
      } catch (error) {
        debugPrint('Failed to pause background music for timer: $error');
      }
    }
  }

  /// Resume background music after a timer (and its alarm) has finished.
  /// Safe to call multiple times; music only resumes when all timers are done.
  Future<void> resumeAfterTimer() async {
    if (!_isInitialized) {
      await init();
    }
    if (_timerPauseDepth <= 0) return;

    _timerPauseDepth--;
    if (_timerPauseDepth == 0 && _isEnabled && !_playbackDisabled) {
      try {
        await _player.resume();
      } catch (error) {
        // If resume fails (e.g. app was restarted), fall back to replaying.
        debugPrint('Failed to resume music after timer, replaying: $error');
        await _playCurrentTrack();
      }
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
      // If a timer has paused music, don't auto-restart it here.
      if (_timerPauseDepth > 0) return;
      unawaited(_playCurrentTrack());
    }
  }
}
