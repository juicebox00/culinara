import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized (duplicate-app error)');
    } else {
      print('Firebase initialization error: $e');
    }
  }
  runApp(const Culinara());
}

class Culinara extends StatelessWidget {
  const Culinara({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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