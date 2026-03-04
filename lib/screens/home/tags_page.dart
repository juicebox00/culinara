import 'package:culinara/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TagsPage extends StatefulWidget {
  const TagsPage({super.key, required this.recipes});

  final List<Recipe> recipes;

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

  @override
  Widget build(BuildContext context) {
    final tags = _buildSortedTags();
    final filteredTags = _filterTags(tags);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tags',
            style: GoogleFonts.fredoka(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          const SizedBox(height: 12),
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
                borderSide: const BorderSide(
                  color: Color(0xFF8B6F47),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8B6F47),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF5D4A3A),
                  width: 2,
                ),
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
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 194, 143, 96),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color.fromARGB(255, 93, 74, 58),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tag, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '#$tag',
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
