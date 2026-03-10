import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';

class TimerToolPage extends StatefulWidget {
  const TimerToolPage({super.key});

  @override
  State<TimerToolPage> createState() => _TimerToolPageState();
}

class _TimerToolPageState extends State<TimerToolPage> {
  static const int _defaultSeconds = 5 * 60;

  Timer? _timer;
  final AudioPlayer _runningSfxPlayer = AudioPlayer();
  final AudioPlayer _alarmSfxPlayer = AudioPlayer();
  int _remainingSeconds = _defaultSeconds;
  int _selectedSeconds = _defaultSeconds;
  bool _isRunning = false;

  Future<void> _startRunningSfx() async {
    try {
      await _runningSfxPlayer.setReleaseMode(ReleaseMode.loop);
      await _runningSfxPlayer.stop();
      await _runningSfxPlayer.play(AssetSource('sounds/timer.wav'));
    } catch (_) {
      // Running SFX should never break timer behavior.
    }
  }

  Future<void> _stopRunningSfx() async {
    try {
      await _runningSfxPlayer.stop();
    } catch (_) {
      // Best effort cleanup.
    }
  }

  Future<void> _playTimerDoneSfx() async {
    try {
      await _alarmSfxPlayer.stop();
      await _alarmSfxPlayer.play(AssetSource('sounds/alarm.wav'));
    } catch (_) {
      // SFX should never break timer behavior.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _runningSfxPlayer.dispose();
    _alarmSfxPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _setQuickTime(int seconds) {
    if (_isRunning) return;
    setState(() {
      _selectedSeconds = seconds;
      _remainingSeconds = seconds;
    });
  }

  void _startTimer() {
    if (_isRunning || _remainingSeconds <= 0) return;

    setState(() {
      _isRunning = true;
    });
    _startRunningSfx();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _stopRunningSfx();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });

        _stopRunningSfx();
        _playTimerDoneSfx();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Timer finished.',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            ),
          ),
        );
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
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _stopRunningSfx();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedSeconds;
    });
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
                    child: OutlinedButton.icon(
                      onPressed: _resetTimer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5D4A3A),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.restart_alt),
                      label: const StrokedButtonLabel(
                        'Reset',
                        fillColor: Color(0xFF5D4A3A),
                        strokeColor: Color(0xFFF8EFE3),
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
