import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CulinaraSearchBar extends StatelessWidget {
  const CulinaraSearchBar({
    super.key,
    this.hintText = 'Search Sinigang or #meat',
    this.onChanged,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32.0),
          border: Border.all(color: Color(0xFF8B4513), width: 2),
        ),
        clipBehavior: Clip.hardEdge,
        child: TextField(
          onChanged: onChanged,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: hintText,
            hintStyle: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
