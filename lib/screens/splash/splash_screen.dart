import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_page.dart';
import '../auth/login_page.dart';
import '../../services/auth_service.dart';
import '../../services/background_music_service.dart';
import '../../services/ui_sound_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.5;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted) return;
      unawaited(UiSoundService.instance.playGameOpen());
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
      });
    });

    Timer(Duration(seconds: 3), () {
      _navigateToNextPage();
    });
  }

  Future<void> _navigateToNextPage() async {
    User? user = _authService.currentUser;
    final bool isLoggedIn = user != null;

    if (!mounted) return;

    // Never block the transition on audio initialization/playback.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => isLoggedIn ? HomePage() : LoginPage(),
      ),
    );

    unawaited(
      (isLoggedIn
              ? BackgroundMusicService.instance.setGameTrack()
              : BackgroundMusicService.instance.setAuthTrack())
          .catchError((error) {
            debugPrint('Background music failed on splash transition: $error');
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: Duration(seconds: 1),
          child: AnimatedScale(
            scale: _scale,
            duration: Duration(seconds: 1),
            curve: Curves.elasticOut,
            child: Image.asset('images/culinara_logo.png', width: 200),
          ),
        ),
      ),
    );
  }
}
