import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'services/app_appearance.dart';
import 'services/background_music_service.dart';
import 'services/ui_sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized (duplicate-app error)');
    } else {
      debugPrint('Firebase initialization error: $e');
    }
  }

  await AppAppearance.init();
  await UiSoundService.instance.init();
  runApp(const Culinara());

  // Start BGM after the first frame so platform channels are fully ready.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    if (loggedIn) {
      await BackgroundMusicService.instance.setGameTrack();
    } else {
      await BackgroundMusicService.instance.setAuthTrack();
    }
  });
}

class Culinara extends StatelessWidget {
  const Culinara({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        // Apply bottom system inset app-wide so controls remain tappable.
        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          maintainBottomViewPadding: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
      debugShowCheckedModeBanner: false,
      title: 'Culinara',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.fredokaTextTheme(
          TextTheme(
            bodyLarge: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            bodyMedium: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            bodySmall: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            headlineLarge: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            headlineMedium: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            headlineSmall: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            titleLarge: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            titleMedium: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            titleSmall: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            labelLarge: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            labelMedium: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            labelSmall: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: SplashScreen(), // Starts here!
    );
  }
}
