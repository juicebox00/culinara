import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/models/recipe.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final bool isPinned;
  final Function(Recipe) onPin;
  final VoidCallback onTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isPinned,
    required this.onPin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.asset(
                            recipe.imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                        if (recipe.cooked)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Image.asset(
                              'images/cooked_stamp.png',
                              width: 52,
                              height: 52,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (_) => onPin(recipe),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'toggle_pin',
                            child: Row(
                              children: [
                                Icon(
                                  isPinned
                                      ? Icons.push_pin
                                      : Icons.push_pin_outlined,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  isPinned ? 'Unpin' : 'Pin',
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        child: const Icon(Icons.more_vert, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isPinned)
            Positioned(
              top: -14,
              right: 8,
              child: Image.asset(
                'images/red_thumbtack.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
