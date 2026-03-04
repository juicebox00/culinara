import 'package:culinara/widgets/moving_tile_pattern.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/widgets/recipe_card.dart';
import 'package:culinara/widgets/search_bar.dart';
import 'package:culinara/widgets/bottom_nav_bar.dart';
import 'package:culinara/models/recipe.dart';
import 'package:culinara/recipe_detail_page.dart';
import 'package:culinara/randomizer_page.dart';
import 'package:culinara/screens/home/add_recipe_page.dart';
import 'package:culinara/screens/home/tags_page.dart';
import '../settings/settings_page.dart';

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
      Recipe(
        id: '1',
        title: 'Pork Sinigang',
        imagePath: 'images/placeholder_thumbnail.png',
        isPinned: false,
        cooked: true,
        ingredients:
            '1 kg pork ribs\n8 cups water\n2 tomatoes\n1 onion\n2 tbsp fish sauce\n1 packet sinigang mix\n1 radish\n1 eggplant\n1 bunch kangkong',
        directions:
            '1. Boil pork ribs until tender.\n2. Add onion and tomatoes, simmer for 10 minutes.\n3. Stir in fish sauce and sinigang mix.\n4. Add radish and eggplant; cook until tender.\n5. Add kangkong and serve hot.',
        servingSize: '4 servings',
        cookingTime: '1 hr 10 mins',
        tags: ['filipino', 'soup', 'comfort food'],
      ),
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

  Future<void> _openAddRecipePage() async {
    final newRecipe = await Navigator.push<Recipe>(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipePage()),
    );

    if (newRecipe == null) {
      setState(() => _selectedIndex = 0);
      return;
    }

    setState(() {
      recipes = [newRecipe, ...recipes];
      _selectedIndex = 0;
    });
  }

  void _onBottomNavTap(int idx) {
    if (idx == 2) {
      _openAddRecipePage();
      return;
    }
    setState(() => _selectedIndex = idx);
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
              title: Text(
                'Most Recent',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
              value: 'recent',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() => _sortBy = value ?? 'recent');
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(
                'A - Z',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
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
              title: Text(
                'All',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
              value: 'all',
              groupValue: _filterBy,
              onChanged: (value) {
                setState(() => _filterBy = value ?? 'all');
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(
                'Cooked',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
              value: 'cooked',
              groupValue: _filterBy,
              onChanged: (value) {
                setState(() => _filterBy = value ?? 'cooked');
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: Text(
                'Uncooked',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: Row(
                  children: [
                    Expanded(child: const CulinaraSearchBar()),
                    SizedBox(width: 8),
                    IconButton(
                      onPressed: _showSortFilterDialog,
                      icon: Icon(
                        Icons.tune,
                        color: Color(0xFF8B5E3C),
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
              _buildRecipeCount(recipes.length),

              if (recipes.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                  child: _buildEmptyState(),
                ),

              // Pinned recipes section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pinned',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pinnedRecipes.isNotEmpty)
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
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Unpinned recipes section
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
                    if (unpinnedRecipes.isNotEmpty)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        children: _getSortedAndFilteredRecipes(unpinnedRecipes)
                            .map((recipe) {
                              return RecipeCard(
                                recipe: recipe,
                                isPinned: false,
                                onPin: _onRecipePin,
                                onTap: () => _onRecipeCardTap(recipe),
                              );
                            })
                            .toList(),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
        break;
      case 1:
        content = TagsPage(recipes: recipes);
        break;
      case 3:
        content = const RandomizerPage();
        break;
      case 4:
        content = const SettingsPage();
        break;
      default:
        content = Center(
          child: Text(
            'Not implemented',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        );
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
        onTap: _onBottomNavTap,
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
      child: Text(
        "Recipe Count: $count",
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B6F47), width: 2),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_rounded,
            size: 44,
            color: Color(0xFF8B6F47),
          ),
          const SizedBox(height: 8),
          Text(
            'No recipes yet',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the + button below to create your first recipe.',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _openAddRecipePage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 194, 143, 96),
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: Color.fromARGB(255, 93, 74, 58),
                width: 2,
              ),
            ),
            child: Text(
              'Create Recipe',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
