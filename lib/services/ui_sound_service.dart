import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiSoundService {
  UiSoundService._();

  static final UiSoundService instance = UiSoundService._();
  static const String _sfxEnabledPrefKey = 'sfx_enabled';

  // Use a context that never grabs audio focus, so it won't
  // pause/stop background music when short UI sounds play.
  static final AudioContext _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      // Match background music category so sounds are always audible,
      // but still allow mixing with other audio.
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  final AudioPlayer _buttonPlayer = AudioPlayer();
  final AudioPlayer _menuPlayer = AudioPlayer();
  final AudioPlayer _gameOpenPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isEnabled = true;

  bool get isEnabled => _isEnabled;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_sfxEnabledPrefKey) ?? true;
    _isInitialized = true;
  }

  Future<void> setEnabled(bool enabled) async {
    if (!_isInitialized) {
      await init();
    }

    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxEnabledPrefKey, enabled);
  }

  Future<void> playButtonBeep() async {
    if (!_isInitialized) {
      await init();
    }
    if (!_isEnabled) return;

    try {
      await _buttonPlayer.stop();
      await _buttonPlayer.play(
        AssetSource('sounds/button_beep.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: _sfxContext,
      );
    } catch (_) {
      // UI sound should not interrupt interactions.
    }
  }

  Future<void> playSideMenuOpen() async {
    if (!_isInitialized) {
      await init();
    }
    if (!_isEnabled) return;

    try {
      await _menuPlayer.stop();
      await _menuPlayer.play(
        AssetSource('sounds/side_menu.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: _sfxContext,
      );
    } catch (_) {
      // UI sound should not interrupt interactions.
    }
  }

  Future<void> playGameOpen() async {
    if (!_isInitialized) {
      await init();
    }
    if (!_isEnabled) return;

    try {
      await _gameOpenPlayer.stop();
      await _gameOpenPlayer.play(
        AssetSource('sounds/game-open.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: _sfxContext,
      );
    } catch (_) {
      // UI sound should not interrupt interactions.
    }
  }

  Future<void> dispose() async {
    await _buttonPlayer.dispose();
    await _menuPlayer.dispose();
    await _gameOpenPlayer.dispose();
  }
}
