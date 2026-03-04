import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_page.dart';
import '../auth/login_page.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0.0;
  double _scale = 0.5;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _opacity = 1.0;
        _scale = 1.0;
      });
    });

    Timer(Duration(seconds: 3), () {
      _navigateToNextPage();
    });
  }

  void _navigateToNextPage() {
    User? user = _authService.currentUser;
    
    if (user != null) {
      // User is logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // User is not logged in, show login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
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
            child: Image.asset(
              'images/culinara_logo.png',
              width: 200,
            ),
          ),
        ),
      ),
    );
  }
}
