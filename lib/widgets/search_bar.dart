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
    final borderRadius = BorderRadius.circular(32);

    return SizedBox(
      height: 50,
      child: TextField(
        onChanged: onChanged,
        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: hintText,
          hintStyle: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          filled: true,
          fillColor: const Color(0xFFFDFBF8),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          border: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: borderRadius,
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
