import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/gingham_pattern_background.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'About Us',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5E6D3),
        foregroundColor: const Color(0xFF5D4A3A),
        elevation: 0,
      ),
      body: Stack(
        children: [
          const GinghamPatternBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1DFC8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8B6F47),
                        width: 1.8,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'images/about.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Meet the Team',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _MemberCard(
                    name: 'Justine Bucud',
                    role: 'Product Lead',
                    bio:
                        'A true cooking enthusiast who shaped the vision of Culinara from the ground up and led the app design. She started with a notes app full of recipe clutter and turned that challenge into this project.',
                  ),
                  const SizedBox(height: 12),
                  _MemberCard(
                    name: 'Jay Ehm Manalang',
                    role: 'Backend Developer',
                    bio:
                        'Handles the backend side of Culinara and keeps the core features dependable. He mostly cooks with a health and diet focus, which helps keep the app practical.',
                  ),
                  const SizedBox(height: 12),
                  _MemberCard(
                    name: 'Jesanne Bucud',
                    role: 'Frontend Designer',
                    bio:
                        'The frontend designer behind Culinara\'s look and feel. Not the biggest fan of cooking yet, but great at turning ideas into an interface that feels clean and easy to use.',
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

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.name,
    required this.role,
    required this.bio,
  });

  final String name;
  final String role;
  final String bio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B6F47), width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            role,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B6F47),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: GoogleFonts.fredoka(
              fontSize: 14,
              color: const Color(0xFF5D4A3A),
            ),
          ),
        ],
      ),
    );
  }
}