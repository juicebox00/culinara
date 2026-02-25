import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(Culinara());
}

class Culinara extends StatelessWidget {
  const Culinara({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Culinara',
      home: SplashScreen(), // Starts here!
    );
  }
}