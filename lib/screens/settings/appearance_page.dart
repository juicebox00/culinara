import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/app_appearance.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appearance',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
      ),
      body: ValueListenableBuilder<Color>(
        valueListenable: AppAppearance.tileTintColor,
        builder: (context, selectedColor, child) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: AppAppearance.tileColorOptions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final option = AppAppearance.tileColorOptions[index];
              final isSelected = option.color == selectedColor;

              return ListTile(
                onTap: () => AppAppearance.setTileTintColor(option.color),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF8B5E3C)
                        : const Color(0xFFD9D9D9),
                    width: isSelected ? 2 : 1,
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
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Color(0xFF8B5E3C))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
