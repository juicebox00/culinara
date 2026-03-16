import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';
import 'package:culinara/services/background_music_service.dart';

class TimerToolPage extends StatefulWidget {
  const TimerToolPage({super.key});

  @override
  State<TimerToolPage> createState() => _TimerToolPageState();
}

class _TimerToolPageState extends State<TimerToolPage> {
  static const int _defaultSeconds = 5 * 60;

  // Timer SFX should never steal audio focus from background music.
  static final AudioContext _sfxContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  Timer? _timer;
  // Single player handles both running loop and alarm sound
  final AudioPlayer _sfxPlayer = AudioPlayer();
  int _remainingSeconds = _defaultSeconds;
  int _selectedSeconds = _defaultSeconds;
  bool _isRunning = false;
  bool _isAlarmRinging = false;

  Future<void> _startRunningSfx() async {
    try {
      await _sfxPlayer.setReleaseMode(ReleaseMode.loop);
      await _sfxPlayer.setVolume(0.5); // Set volume to 50%
      await _sfxPlayer.stop();
      debugPrint('Attempting to play timer sound');
      
      // AssetSource automatically looks in assets/ folder
      await _sfxPlayer.play(
        AssetSource('sounds/timer.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: _sfxContext,
      );
      debugPrint('Timer sound started successfully');
    } catch (e) {
      debugPrint('Error playing timer sound: $e');
      // SFX should never break timer behavior.
    }
  }

  Future<void> _stopRunningSfx() async {
    try {
      await _sfxPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping timer sound: $e');
      // Best effort cleanup.
    }
  }

  Future<void> _playTimerDoneSfx() async {
    try {
      _isAlarmRinging = true;
      await _sfxPlayer.setReleaseMode(ReleaseMode.loop);
      await _sfxPlayer.setVolume(0.9); // Louder for alarm
      await _sfxPlayer.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('Attempting to play alarm sound');
      await _sfxPlayer.play(
        AssetSource('sounds/alarm.mp3'),
        mode: PlayerMode.lowLatency,
        ctx: _sfxContext,
      );
      debugPrint('Alarm sound played successfully');
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
      // Ensure music does not stay paused if alarm fails.
      BackgroundMusicService.instance.resumeAfterTimer();
      _isAlarmRinging = false;
      // SFX should not interrupt timer.
    }
  }

  Future<void> _stopTimerDoneAlarm() async {
    if (!_isAlarmRinging) return;
    try {
      await _sfxPlayer.stop();
    } catch (_) {
      // Best effort cleanup.
    }
    _isAlarmRinging = false;
    BackgroundMusicService.instance.resumeAfterTimer();
  }


  @override
  void dispose() {
    _timer?.cancel();
    _stopTimerDoneAlarm();
    _sfxPlayer.dispose();
    // In case a timer had paused music and the page is closed.
    BackgroundMusicService.instance.resumeAfterTimer();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _setQuickTime(int seconds) {
    if (_isRunning) return;
    _stopTimerDoneAlarm();
    setState(() {
      _selectedSeconds = seconds;
      _remainingSeconds = seconds;
    });
  }

  void _startTimer() {
    if (_isRunning || _remainingSeconds <= 0) return;
    _stopTimerDoneAlarm();

    setState(() {
      _isRunning = true;
    });
    BackgroundMusicService.instance.pauseForTimer();
    _startRunningSfx();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _stopRunningSfx();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _stopRunningSfx();
        
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });

        // Play alarm sound immediately, don't wait for context
        _playTimerDoneSfx();

        // Show snackbar with explicit stop action for looping alarm
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Timer finished.',
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                ),
                duration: const Duration(days: 1),
                action: SnackBarAction(
                  label: 'Stop',
                  onPressed: () {
                    _stopTimerDoneAlarm();
                  },
                ),
              ),
            );
          }
        });
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _stopRunningSfx();
    _stopTimerDoneAlarm();
    BackgroundMusicService.instance.resumeAfterTimer();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _stopRunningSfx();
    _stopTimerDoneAlarm();
    BackgroundMusicService.instance.resumeAfterTimer();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedSeconds;
    });
  }

  Future<void> _showCustomTimePickerDialog() async {
    int selectedHours = 0;
    int selectedMinutes = 0;
    int selectedSeconds = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFF5E6D3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
          ),
          title: Text(
            'Set Custom Time',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          content: SizedBox(
            width: 300,
            height: 200,
            child: Row(
              children: [
                // Hours Picker
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Hours',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4A3A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController:
                              FixedExtentScrollController(initialItem: 0),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setDialogState(() {
                              selectedHours = index;
                            });
                          },
                          children: List<Widget>.generate(
                            100,
                            (index) => Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D4A3A),
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Minutes Picker
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Minutes',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4A3A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController:
                              FixedExtentScrollController(initialItem: 0),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setDialogState(() {
                              selectedMinutes = index;
                            });
                          },
                          children: List<Widget>.generate(
                            60,
                            (index) => Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D4A3A),
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Seconds Picker
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Seconds',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4A3A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController:
                              FixedExtentScrollController(initialItem: 0),
                          itemExtent: 40,
                          onSelectedItemChanged: (index) {
                            setDialogState(() {
                              selectedSeconds = index;
                            });
                          },
                          children: List<Widget>.generate(
                            60,
                            (index) => Center(
                              child: Text(
                                index.toString().padLeft(2, '0'),
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D4A3A),
                                  fontSize: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final totalSeconds =
                    selectedHours * 3600 + selectedMinutes * 60 + selectedSeconds;

                if (totalSeconds > 0) {
                  _stopTimerDoneAlarm();
                  setState(() {
                    _selectedSeconds = totalSeconds;
                    _remainingSeconds = totalSeconds;
                  });
                }

                Navigator.pop(context);
              },
              child: Text(
                'Set',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B5E3C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE3),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 194, 143, 96),
        centerTitle: true,
        title: const StrokedButtonLabel(
          'Timer',
          fillColor: Colors.white,
          strokeColor: Color(0xFF5D4A3A),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B6F47), width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: GoogleFonts.fredoka(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRunning ? 'Running...' : 'Ready',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B6F47),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickTimeButton(
                  label: '1 min',
                  onTap: () => _setQuickTime(60),
                  enabled: !_isRunning,
                ),
                _QuickTimeButton(
                  label: '3 min',
                  onTap: () => _setQuickTime(3 * 60),
                  enabled: !_isRunning,
                ),
                _QuickTimeButton(
                  label: '5 min',
                  onTap: () => _setQuickTime(5 * 60),
                  enabled: !_isRunning,
                ),
                _QuickTimeButton(
                  label: '10 min',
                  onTap: () => _setQuickTime(10 * 60),
                  enabled: !_isRunning,
                ),
                PressBounce(
                  enabled: !_isRunning,
                  child: ElevatedButton(
                    onPressed: !_isRunning ? () => _showCustomTimePickerDialog() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5E3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const StrokedButtonLabel(
                      'Custom',
                      fillColor: Colors.white,
                      strokeColor: Color(0xFF8B5E3C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PressBounce(
                    child: ElevatedButton.icon(
                      onPressed: _isRunning ? _pauseTimer : _startTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5E3C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      label: StrokedButtonLabel(_isRunning ? 'Pause' : 'Start'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PressBounce(
                    child: ElevatedButton.icon(
                      onPressed: _resetTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B6F47),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.restart_alt),
                      label: const StrokedButtonLabel(
                        'Reset',
                        fillColor: Colors.white,
                        strokeColor: Color(0xFF8B6F47),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTimeButton extends StatelessWidget {
  const _QuickTimeButton({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PressBounce(
      enabled: enabled,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5D4A3A),
          side: BorderSide.none,
        ),
        child: StrokedButtonLabel(
          label,
          fillColor: const Color(0xFF5D4A3A),
          strokeColor: const Color(0xFFF8EFE3),
        ),
      ),
    );
  }
}
