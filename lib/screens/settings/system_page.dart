import 'package:culinara/services/background_music_service.dart';
import 'package:culinara/services/ui_sound_service.dart';
import 'package:culinara/widgets/gingham_pattern_background.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SystemPage extends StatefulWidget {
  const SystemPage({super.key});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.35;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    await BackgroundMusicService.instance.init();
    await UiSoundService.instance.init();
    if (!mounted) return;

    setState(() {
      _musicEnabled = BackgroundMusicService.instance.isEnabled;
      _sfxEnabled = UiSoundService.instance.isEnabled;
      _musicVolume = BackgroundMusicService.instance.volume;
      _isLoading = false;
    });
  }

  Future<void> _toggleMusic(bool value) async {
    await BackgroundMusicService.instance.setEnabled(value);
    if (!mounted) return;

    setState(() {
      _musicEnabled = value;
    });
  }

  Future<void> _setVolume(double value) async {
    setState(() {
      _musicVolume = value;
    });
    await BackgroundMusicService.instance.setVolume(value);
  }

  Future<void> _toggleSfx(bool value) async {
    await UiSoundService.instance.setEnabled(value);
    if (!mounted) return;

    setState(() {
      _sfxEnabled = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const GinghamPatternBackground(),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 194, 143, 96),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PressBounce(
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                color: const Color(0xFF5D4A3A),
                              ),
                            ),
                            const StrokedButtonLabel(
                              'System',
                              fillColor: Color(0xFF5D4A3A),
                              strokeColor: Color(0xFFF5E6D3),
                              fontSize: 24,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6D3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF8B6F47),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _musicEnabled
                                        ? Icons.volume_up_rounded
                                        : Icons.volume_off_rounded,
                                    color: const Color(0xFF5D4A3A),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Background Music',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF5D4A3A),
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _musicEnabled,
                                    activeColor: const Color(0xFF8B5E3C),
                                    onChanged: _toggleMusic,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _musicEnabled ? 'On' : 'Off',
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7A6450),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Music Volume',
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D4A3A),
                                ),
                              ),
                              Slider(
                                value: _musicVolume,
                                min: 0,
                                max: 1,
                                divisions: 20,
                                label: '${(_musicVolume * 100).round()}%',
                                activeColor: const Color(0xFF8B5E3C),
                                inactiveColor: const Color(0xFFD7C2AA),
                                onChanged: _musicEnabled ? _setVolume : null,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(
                                    _sfxEnabled
                                        ? Icons.graphic_eq_rounded
                                        : Icons.volume_mute_rounded,
                                    color: const Color(0xFF5D4A3A),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Sound Effects',
                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF5D4A3A),
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _sfxEnabled,
                                    activeColor: const Color(0xFF8B5E3C),
                                    onChanged: _toggleSfx,
                                  ),
                                ],
                              ),
                              Text(
                                _sfxEnabled ? 'On' : 'Off',
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF7A6450),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
