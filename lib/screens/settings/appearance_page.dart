import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/stroked_button_label.dart';
import '../../services/app_appearance.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE3),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 194, 143, 96),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const StrokedButtonLabel(
          'Appearance',
          fillColor: Colors.white,
          strokeColor: Color(0xFF5D4A3A),
        ),
      ),
      body: ValueListenableBuilder<Color>(
        valueListenable: AppAppearance.tileTintColor,
        builder: (context, selectedColor, child) {
          return ValueListenableBuilder<String>(
            valueListenable: AppAppearance.selectedPatternId,
            builder: (context, selectedPatternId, child) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Pattern',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...AppAppearance.patternOptions.map((option) {
                    final isSelected = option.id == selectedPatternId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => AppAppearance.setPattern(option.id),
                        tileColor: const Color(0xFFF5E6D3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF8B5E3C)
                                : const Color(0xFF8B6F47),
                            width: isSelected ? 2 : 1.5,
                          ),
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF8B6F47)),
                            image: DecorationImage(
                              image: AssetImage(option.assetPath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          option.name,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Color(0xFF8B5E3C))
                            : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Text(
                    'Color Tint',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...AppAppearance.tileColorOptions.map((option) {
                    final isSelected = option.color == selectedColor;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () =>
                            AppAppearance.setTileTintColor(option.color),
                        tileColor: const Color(0xFFF5E6D3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF8B5E3C)
                                : const Color(0xFF8B6F47),
                            width: isSelected ? 2 : 1.5,
                          ),
                        ),
                        leading: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: option.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black12),
                          ),
                        ),
                        title: Text(
                          option.name,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Color(0xFF8B5E3C))
                            : null,
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
