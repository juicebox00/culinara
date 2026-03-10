import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StrokedButtonLabel extends StatelessWidget {
  const StrokedButtonLabel(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.fillColor = Colors.white,
    this.strokeColor = const Color(0xFF5D4A3A),
  });

  final String text;
  final double fontSize;
  final Color fillColor;
  final Color strokeColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          text,
          style: GoogleFonts.fredoka(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          style: GoogleFonts.fredoka(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: fillColor,
          ),
        ),
      ],
    );
  }
}
