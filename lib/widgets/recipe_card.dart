import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/models/recipe.dart';
import 'package:culinara/widgets/tap_bounce.dart';

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
    final hasFileCover =
        recipe.coverImageFilePath != null &&
        recipe.coverImageFilePath!.trim().isNotEmpty;

    final Widget polaroidCard = Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: hasFileCover
                    ? Image.file(
                        File(recipe.coverImageFilePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) =>
                            recipe.coverImageBytes != null
                            ? Image.memory(
                                recipe.coverImageBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                              )
                            : Image.asset(
                                (recipe.imagePath.isNotEmpty ? recipe.imagePath : 'images/default_recipe.jpg'),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                              ),
                      )
                    : (recipe.coverImageBytes != null
                          ? Image.memory(
                              recipe.coverImageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.center,
                            )
                          : Image.asset(
                              (recipe.imagePath.isNotEmpty ? recipe.imagePath : 'images/default_recipe.jpg'),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              alignment: Alignment.center,
                            )),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
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
                            isPinned ? Icons.push_pin : Icons.push_pin_outlined,
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
    );

    return TapBounce(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isPinned)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 238, 197, 85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: polaroidCard,
            )
          else
            polaroidCard,
          if (isPinned)
            Positioned(
              top: -14,
              right: 8,
              child: Image.asset(
                'images/red_thumbtack.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
