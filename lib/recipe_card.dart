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
    final Color borderColor = recipe.isPinned ? Colors.orangeAccent : Color(0xFF8B5E3C);
    final Color labelBgColor = recipe.isPinned ? Color(0xFFFFD54F) : Color(0xFFF5E6D3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: Image.asset(
                      recipe.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  if (recipe.cooked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.greenAccent,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              width: double.infinity,
              color: labelBgColor,
              child: Row(
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
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              recipe.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(recipe.isPinned ? 'Unpin' : 'Pin',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          onPin(recipe);
                        },
                      ),
                    ],
                    child: Icon(Icons.more_vert, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}