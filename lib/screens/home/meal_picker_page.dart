import 'dart:io';
import 'dart:math';

import 'package:culinara/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';

class MealPickerPage extends StatefulWidget {
  const MealPickerPage({
    super.key,
    required this.recipes,
    required this.onRecipeTap,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipeTap;

  @override
  State<MealPickerPage> createState() => _MealPickerPageState();
}

class _MealPickerPageState extends State<MealPickerPage> {
  final Random _random = Random();
  static const int _maxSelectedTags = 3;
  final List<String> _selectedTags = <String>[];
  Recipe? _pickedRecipe;

  List<String> _buildTagOptions() {
    final unique = <String>{};
    for (final recipe in widget.recipes) {
      for (final tag in recipe.tags) {
        final clean = tag.trim();
        if (clean.isNotEmpty) unique.add(clean);
      }
    }

    return unique.toList()..sort((a, b) => a.compareTo(b));
  }

  List<Recipe> _filteredRecipes() {
    if (_selectedTags.isEmpty) return widget.recipes;
    final selected = _selectedTags.map((tag) => tag.toLowerCase()).toSet();
    return widget.recipes
        .where((recipe) {
          final recipeTags = recipe.tags
              .map((tag) => tag.trim().toLowerCase())
              .where((tag) => tag.isNotEmpty)
              .toSet();
          return selected.every(recipeTags.contains);
        })
        .toList(growable: false);
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
        return;
      }

      if (_selectedTags.length >= _maxSelectedTags) {
        return;
      }
      _selectedTags.add(tag);
    });
  }

  void _pickMeal() {
    final candidates = _filteredRecipes();
    if (candidates.isEmpty) {
      setState(() {
        _pickedRecipe = null;
      });
      return;
    }

    setState(() {
      _pickedRecipe = candidates[_random.nextInt(candidates.length)];
    });
  }

  ImageProvider<Object> _coverImageFor(Recipe recipe) {
    if (recipe.coverImageFilePath != null &&
        recipe.coverImageFilePath!.trim().isNotEmpty) {
      return FileImage(File(recipe.coverImageFilePath!));
    }
    if (recipe.coverImageBytes != null) {
      return MemoryImage(recipe.coverImageBytes!);
    }
    return AssetImage(recipe.imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final tagOptions = _buildTagOptions();
    final filteredCount = _filteredRecipes().length;
    final canSelectMoreTags = _selectedTags.length < _maxSelectedTags;

    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE3),
      appBar: AppBar(
        centerTitle: true,
        title: const StrokedButtonLabel(
          'Meal Picker',
          fillColor: Colors.white,
          strokeColor: Color(0xFF5D4A3A),
        ),
        backgroundColor: const Color.fromARGB(255, 194, 143, 96),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6D3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B6F47), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by tags (up to $_maxSelectedTags)',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4A3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tagOptions.isEmpty)
                      Text(
                        'No tags available yet.',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7A6450),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tagOptions
                            .map((tag) {
                              final isSelected = _selectedTags.contains(tag);
                              return FilterChip(
                                label: Text(
                                  tag,
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                selected: isSelected,
                                showCheckmark: false,
                                selectedColor: const Color(0xFFE9CDA8),
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFF8B6F47),
                                  width: 1.3,
                                ),
                                onSelected: (selected) {
                                  if (!isSelected && !canSelectMoreTags) {
                                    return;
                                  }
                                  _toggleTag(tag);
                                },
                              );
                            })
                            .toList(growable: false),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedTags.isEmpty
                          ? 'All tags included'
                          : 'Selected: ${_selectedTags.join(', ')}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A6450),
                      ),
                    ),
                    if (!canSelectMoreTags)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Maximum $_maxSelectedTags tags selected.',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B6F47),
                          ),
                        ),
                      ),
                    if (_selectedTags.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: PressBounce(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedTags.clear();
                              });
                            },
                            icon: const Icon(Icons.close_rounded),
                            label: const StrokedButtonLabel(
                              'Clear tags',
                              fillColor: Color(0xFF8B5E3C),
                              strokeColor: Color(0xFFF8EFE3),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8B5E3C),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Recipes must match all selected tags.',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A6450),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$filteredCount available recipe(s)',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B6F47),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PressBounce(
                child: ElevatedButton.icon(
                  onPressed: _pickMeal,
                  icon: const Icon(Icons.casino_rounded),
                  label: const StrokedButtonLabel('Pick For Me'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5E3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6D3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8B6F47), width: 2),
                ),
                child: _pickedRecipe == null
                    ? Center(
                        child: Text(
                          'Tap "Pick For Me" to get a meal suggestion.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggested Meal',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8B6F47),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pickedRecipe!.title,
                            style: GoogleFonts.fredoka(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF5D4A3A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pickedRecipe!.tags.isEmpty
                                ? 'No tags'
                                : _pickedRecipe!.tags
                                      .map((tag) => '#$tag')
                                      .join(', '),
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF7A6450),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              height: 220,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF8B6F47),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                image: DecorationImage(
                                  image: _coverImageFor(_pickedRecipe!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: PressBounce(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickMeal,
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const StrokedButtonLabel(
                                      'Pick Again',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5E3C),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: PressBounce(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      final picked = _pickedRecipe;
                                      if (picked == null) return;
                                      widget.onRecipeTap(picked);
                                    },
                                    icon: const Icon(Icons.open_in_new_rounded),
                                    label: const StrokedButtonLabel(
                                      'Open Recipe',
                                      fillColor: Color(0xFF5D4A3A),
                                      strokeColor: Color(0xFFF5E6D3),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF5D4A3A),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
