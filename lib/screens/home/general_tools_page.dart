import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:culinara/models/recipe.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';
import 'timer_tool_page.dart';
import 'units_converter_page.dart';
import 'meal_picker_page.dart';

class GeneralToolsPage extends StatelessWidget {
  const GeneralToolsPage({
    super.key,
    required this.recipes,
    required this.onRecipeTap,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipeTap;

  void _openTimer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TimerToolPage()),
    );
  }

  void _openUnitsConverter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UnitsConverterPage()),
    );
  }

  void _openMealPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MealPickerPage(recipes: recipes, onRecipeTap: onRecipeTap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const StrokedButtonLabel(
          'General Tools',
          fillColor: Colors.white,
          strokeColor: Color(0xFF5D4A3A),
        ),
        backgroundColor: const Color.fromARGB(255, 194, 143, 96),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolButton(
            context: context,
            label: 'Timer',
            subtitle: 'Countdown timer for your cooking steps.',
            icon: Icons.timer_rounded,
            onTap: () => _openTimer(context),
          ),
          const SizedBox(height: 12),
          _buildToolButton(
            context: context,
            label: 'Units Converter',
            subtitle: 'Convert volume, weight, and temperature.',
            icon: Icons.swap_horiz_rounded,
            onTap: () => _openUnitsConverter(context),
          ),
          const SizedBox(height: 12),
          _buildToolButton(
            context: context,
            label: 'Meal Picker',
            subtitle: 'Pick what to cook when you cannot decide.',
            icon: Icons.restaurant_menu_rounded,
            onTap: () => _openMealPicker(context),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TapBounce(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6D3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 194, 143, 96),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.fredoka(
                      color: const Color(0xFF7A6450),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
