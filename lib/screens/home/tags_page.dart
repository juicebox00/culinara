
import 'package:culinara/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key, required this.recipes, required this.onRecipeTap});

  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipeTap;

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _buildSortedTags() {
    final Set<String> uniqueTags = <String>{};

    for (final recipe in widget.recipes) {
      for (final rawTag in recipe.tags) {
        final cleanedTag = rawTag.trim();
        if (cleanedTag.isNotEmpty) {
          uniqueTags.add(cleanedTag);
        }
      }
    }

    final sorted = uniqueTags.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  List<String> _filterTags(List<String> tags) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return tags;

    return tags
        .where((tag) => tag.toLowerCase().contains(query))
        .toList(growable: false);
  }

  List<Recipe> _recipesForTag(String tag) {
    final needle = tag.trim().toLowerCase();
    if (needle.isEmpty) return const <Recipe>[];

    return widget.recipes
        .where((recipe) {
          return recipe.tags.any(
            (rawTag) => rawTag.trim().toLowerCase() == needle,
          );
        })
        .toList(growable: false);
  }

  Future<void> _showRecipesForTag(String tag) async {
    final taggedRecipes = _recipesForTag(tag);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF8EFE3),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$tag',
                  style: GoogleFonts.fredoka(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4A3A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${taggedRecipes.length} recipe(s)',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B6F47),
                  ),
                ),
                const SizedBox(height: 12),
                if (taggedRecipes.isEmpty)
                  Text(
                    'No recipes found for this tag.',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: taggedRecipes.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final recipe = taggedRecipes[index];
                        return ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onRecipeTap(recipe);
                          },
                          tileColor: const Color(0xFFF5E6D3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFF8B6F47),
                              width: 1.5,
                            ),
                          ),
                          leading: const Icon(
                            Icons.menu_book_rounded,
                            color: Color(0xFF5D4A3A),
                          ),
                          title: Text(
                            recipe.title,
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5D4A3A),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Color(0xFF5D4A3A),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tags = _buildSortedTags();
    final filteredTags = _filterTags(tags);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Search for a tag',
              hintStyle: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF8EFE3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: filteredTags.isEmpty
                ? Center(
                    child: Text(
                      tags.isEmpty
                          ? 'No tags yet. Add tags when creating recipes.'
                          : 'No tags match your search.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4A3A),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredTags.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tag = filteredTags[index];
                      final recipeCount = _recipesForTag(tag).length;
                      return TapBounce(
                        onTap: () => _showRecipesForTag(tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 194, 143, 96),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tag, color: Colors.white),
                              const SizedBox(width: 10),
                              Expanded(
                                child: StrokedButtonLabel(
                                  '#$tag',
                                  fillColor: Colors.white,
                                  strokeColor: const Color(0xFF5D4A3A),
                                  fontSize: 18,
                                ),
                              ),
                              StrokedButtonLabel(
                                '$recipeCount',
                                fillColor: Colors.white,
                                strokeColor: const Color(0xFF5D4A3A),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
