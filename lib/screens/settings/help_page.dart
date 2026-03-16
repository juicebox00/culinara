import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/gingham_pattern_background.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Help',
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                _SectionCard(
                  title: 'Getting Started',
                  icon: Icons.rocket_launch_outlined,
                  items: const [
                    'Tap + on Home to add your first recipe.',
                    'Fill in title, ingredients, and directions first, then optional details.',
                    'Use shelves for broad groups and tags for specific keywords.',
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Searching, Shelves, and Sorting',
                  icon: Icons.search_rounded,
                  items: const [
                    'Search checks recipe title, ingredients, and tags.',
                    'Use a shelf chip to filter your recipe list by category.',
                    'Use Sort to order recipes A-Z, Newest to Oldest, or Oldest to Newest.',
                    'Tip: type #tagName in search to quickly find recipes by tag.',
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Managing Recipes',
                  icon: Icons.menu_book_rounded,
                  items: const [
                    'Long-press a recipe card to enter selection mode for bulk delete.',
                    'Pin up to 3 recipes so they stay at the top.',
                    'Duplicate a recipe to create a quick variation.',
                  ],
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'FAQ',
                  icon: Icons.quiz_outlined,
                  items: const [
                    'Q: What is the difference between shelves and tags?\nA: Shelves are broad categories, tags are flexible labels for details.',
                    'Q: Why can\'t I find a recipe?\nA: Check your active shelf filter and search text first.',
                    'Q: Why is a renamed shelf or tag updating many recipes?\nA: Rename applies to all recipes currently using that shelf or tag.',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B6F47), width: 1.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF5D4A3A), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4A3A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF8B6F47),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.fredoka(
                        fontSize: 14.5,
                        color: const Color(0xFF5D4A3A),
                      ),
                    ),
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