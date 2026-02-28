import 'package:culinara/moving_tile_pattern.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/recipe_card.dart';
import 'package:culinara/search_bar.dart';
import 'package:culinara/bottom_nav_bar.dart';
import 'package:culinara/models/recipe.dart';
import 'package:culinara/recipe_detail_page.dart';
import 'package:culinara/randomizer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  late List<Recipe> recipes;
  String _sortBy = 'recent'; // 'recent' or 'a-z'
  String _filterBy = 'all'; // 'all', 'cooked', 'uncooked'

  @override
  void initState() {
    super.initState();
    recipes = [
      Recipe(id: '1', title: 'Pork Sinigang', imagePath: 'images/placeholder_thumbnail.png', isPinned: true, cooked: true),
      Recipe(id: '2', title: 'Pork Adobo', imagePath: 'images/placeholder_thumbnail.png', isPinned: true, cooked: false),
      Recipe(id: '3', title: 'Chicken Tinola', imagePath: 'images/placeholder_thumbnail.png', isPinned: true, cooked: false),
      Recipe(id: '4', title: 'Menudo', imagePath: 'images/placeholder_thumbnail.png', isPinned: false, cooked: true),
      Recipe(id: '5', title: 'Sinigang na Baka', imagePath: 'images/placeholder_thumbnail.png', isPinned: false, cooked: false),
      Recipe(id: '6', title: 'Lumpia Shanghai', imagePath: 'images/placeholder_thumbnail.png', isPinned: false, cooked: true),
      Recipe(id: '7', title: 'Fried Chicken', imagePath: 'images/placeholder_thumbnail.png', isPinned: false, cooked: false),
    ];
  }

  void _onRecipePin(Recipe recipe) {
    setState(() {
      List<Recipe> pinnedRecipes = recipes.where((r) => r.isPinned).toList();
      
      if (recipe.isPinned) {
        // Unpinning
        recipe.isPinned = false;
      } else {
        // Pinning
        if (pinnedRecipes.length >= 3) {
          // Replace the oldest pinned recipe
          pinnedRecipes.first.isPinned = false;
        }
        recipe.isPinned = true;
      }
    });
  }

  void _onRecipeDelete(Recipe recipe) {
    setState(() {
      recipes.removeWhere((r) => r.id == recipe.id);
    });
  }

  void _onRecipeCardTap(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(
          recipe: recipe,
          onPin: _onRecipePin,
          onDelete: _onRecipeDelete,
        ),
      ),
    );
  }

  List<Recipe> _getSortedAndFilteredRecipes(List<Recipe> recipeList) {
    List<Recipe> filtered = recipeList;

    // Apply filter
    if (_filterBy == 'cooked') {
      filtered = filtered.where((r) => r.cooked).toList();
    } else if (_filterBy == 'uncooked') {
      filtered = filtered.where((r) => !r.cooked).toList();
    }

    // Apply sort
    if (_sortBy == 'a-z') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }
    // 'recent' is the default order (as added)

    return filtered;
  }

  void _showSortFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort & Filter',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Sort By',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            RadioListTile(
              title: Text('Most Recent', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              value: 'recent',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value ?? 'recent');
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text('A - Z', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              value: 'a-z',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value ?? 'a-z');
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 16),
            Text(
              'Filter By',
              style: GoogleFonts.fredoka(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            RadioListTile(
              title: Text('All', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              value: 'all',
              groupValue: _filterBy,
              onChanged: (value) {
                setState(() => _filterBy = value ?? 'all');
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text('Cooked', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              value: 'cooked',
              groupValue: _filterBy,
              onChanged: (value) {
                setState(() => _filterBy = value ?? 'cooked');
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text('Uncooked', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
              value: 'uncooked',
              groupValue: _filterBy,
              onChanged: (value) {
                setState(() => _filterBy = value ?? 'uncooked');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // compute lists for pages that need them
    List<Recipe> pinnedRecipes = recipes.where((r) => r.isPinned).toList();
    List<Recipe> unpinnedRecipes = recipes.where((r) => !r.isPinned).toList();

    Widget content = Container();
    switch (_selectedIndex) {
      case 0:
        content = SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Image.asset(
                    'images/culinara_logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: const CulinaraSearchBar(),
                    ),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: _showSortFilterDialog,
                      icon: Icon(Icons.tune, color: Color(0xFF8B5E3C), size: 28),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              _buildRecipeCount(recipes.length),
              
              // Pinned recipes section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pinnedRecipes.isNotEmpty) ...[
                      Text(
                        'Pinned',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75,
                        children: pinnedRecipes.map((recipe) {
                          return RecipeCard(
                            recipe: recipe,
                            isPinned: true,
                            onPin: _onRecipePin,
                            onTap: () => _onRecipeCardTap(recipe),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),

              // Unpinned recipes section
              if (unpinnedRecipes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recipes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: _getSortedAndFilteredRecipes(unpinnedRecipes).map((recipe) {
                          return RecipeCard(
                            recipe: recipe,
                            isPinned: false,
                            onPin: _onRecipePin,
                            onTap: () => _onRecipeCardTap(recipe),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
        break;
      case 3:
        content = RandomizerPage(recipes: recipes);
        break;
      default:
        content = Center(child: Text('Not implemented', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)));
    }

    // unified scaffold for all pages
    return Scaffold(
      body: Stack(
        children: [
          MovingTilePattern(),
          SafeArea(child: content),
        ],
      ),
      bottomNavigationBar: CulinaraBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (idx) => setState(() => _selectedIndex = idx),
      ),
    );
  }

  Widget _buildRecipeCount(int count) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFD2B48C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF8B4513), width: 2),
      ),
      child: Text("Recipe Count: $count", 
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        )),
    );
  }
}