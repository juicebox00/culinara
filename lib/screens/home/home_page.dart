import 'package:culinara/widgets/gingham_pattern_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/widgets/recipe_card.dart';
import 'package:culinara/widgets/search_bar.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';
import 'package:culinara/models/recipe.dart';
import 'package:culinara/recipe_detail_page.dart';
import 'package:culinara/screens/home/general_tools_page.dart';
import 'package:culinara/screens/home/add_recipe_page.dart';
import 'package:culinara/screens/home/drafts_page.dart';
import 'package:culinara/screens/home/tags_page.dart';
import 'package:culinara/services/recipe_store_service.dart';
import 'package:culinara/services/ui_sound_service.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _recipesTab = 0;
  static const int _draftsTab = 1;
  static const int _tagsTab = 2;
  static const int _settingsTab = 3;

  int _selectedIndex = 0;
  String _searchQuery = '';

  List<Recipe> recipes = [];
  bool _isLoadingRecipes = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  List<Recipe> _defaultRecipes() {
    return [
      Recipe(
        id: '1',
        title: 'Pork Sinigang',
        imagePath: 'images/placeholder_thumbnail.png',
        isPinned: false,
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

  Future<void> _loadRecipes() async {
    final storedRecipes = await RecipeStoreService.loadRecipes();
    final hasStored = storedRecipes.isNotEmpty;
    final loaded = hasStored ? storedRecipes : _defaultRecipes();

    if (!hasStored) {
      await RecipeStoreService.saveRecipes(loaded);
    }

    if (!mounted) return;
    setState(() {
      recipes = loaded;
      _isLoadingRecipes = false;
    });
  }

  void _persistRecipes() {
    RecipeStoreService.saveRecipes(recipes);
  }

  void _onRecipePin(Recipe recipe) {
    setState(() {
      final pinnedRecipes = recipes
          .where((r) => r.isPinned)
          .toList(growable: false);

      if (recipe.isPinned) {
        recipe.isPinned = false;
      } else {
        if (pinnedRecipes.length >= 3) {
          // Keep a max of three pinned recipes by unpinning the least-recent
          // pinned item in list order, then move the new pin to the front.
          pinnedRecipes.last.isPinned = false;
        }
        recipe.isPinned = true;

        recipes.removeWhere((r) => r.id == recipe.id);
        recipes = [recipe, ...recipes];
      }
    });
    _persistRecipes();
  }

  void _onRecipeDelete(Recipe recipe) {
    setState(() {
      recipes.removeWhere((r) => r.id == recipe.id);
    });
    _persistRecipes();
  }

  void _upsertRecipe(Recipe recipe) {
    final index = recipes.indexWhere((r) => r.id == recipe.id);
    setState(() {
      if (index == -1) {
        recipes = [recipe, ...recipes];
      } else {
        recipes[index] = recipe;
      }
    });
    _persistRecipes();
  }

  void _onRecipeCardTap(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(
          recipe: recipe,
          onPin: _onRecipePin,
          onDelete: _onRecipeDelete,
          onUpdate: _upsertRecipe,
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
      setState(() => _selectedIndex = _recipesTab);
      return;
    }

    setState(() {
      final index = recipes.indexWhere((r) => r.id == newRecipe.id);
      if (index == -1) {
        recipes = [newRecipe, ...recipes];
      } else {
        recipes[index] = newRecipe;
      }
      _selectedIndex = _recipesTab;
    });
    _persistRecipes();
  }

  void _onMenuTap(int idx) {
    Navigator.of(context).pop();
    setState(() => _selectedIndex = idx);
  }

  Future<void> _openGeneralToolsPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GeneralToolsPage(recipes: recipes, onRecipeTap: _onRecipeCardTap),
      ),
    );
  }

  String _headerTitle() {
    switch (_selectedIndex) {
      case _recipesTab:
        return 'Recipes';
      case _draftsTab:
        return 'Drafts';
      case _tagsTab:
        return 'Tags';
      case _settingsTab:
        return 'Settings';
      default:
        return 'Culinara';
    }
  }

  List<Recipe> _filteredRecipesByQuery(List<Recipe> source) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return source;

    final isTagQuery = query.startsWith('#');
    final tagNeedle = isTagQuery ? query.substring(1).trim() : query;
    if (isTagQuery && tagNeedle.isEmpty) return source;

    return source
        .where((recipe) {
          final title = recipe.title.toLowerCase();
          final ingredients = recipe.ingredients.toLowerCase();
          final tags = recipe.tags
              .map((tag) => tag.trim().toLowerCase())
              .where((tag) => tag.isNotEmpty)
              .toList(growable: false);

          if (isTagQuery) {
            return tags.any((tag) => tag.contains(tagNeedle));
          }

          return title.contains(query) ||
              ingredients.contains(query) ||
              tags.any((tag) => tag.contains(query));
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final visibleRecipes = _filteredRecipesByQuery(recipes);
    final pinnedRecipes = visibleRecipes
        .where((r) => r.isPinned)
        .toList(growable: false);
    final unpinnedRecipes = visibleRecipes
        .where((r) => !r.isPinned)
        .toList(growable: false);

    Widget content = const SizedBox.shrink();
    if (_isLoadingRecipes) {
      content = const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 194, 143, 96),
        ),
      );
    }

    if (!_isLoadingRecipes) {
      switch (_selectedIndex) {
        case _recipesTab:
          content = SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CulinaraSearchBar(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRecipeCount(visibleRecipes.length),

                if (recipes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                    child: _buildEmptyState(),
                  )
                else if (visibleRecipes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
                    child: _buildNoSearchResults(),
                  ),

                // Pinned recipes section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pinned',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (unpinnedRecipes.isNotEmpty)
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          children: unpinnedRecipes.map((recipe) {
                            return RecipeCard(
                              recipe: recipe,
                              isPinned: false,
                              onPin: _onRecipePin,
                              onTap: () => _onRecipeCardTap(recipe),
                            );
                          }).toList(),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
                const SizedBox(height: 110),
              ],
            ),
          );
          break;
        case _draftsTab:
          content = DraftsPage(recipes: recipes, onRecipeSaved: _upsertRecipe);
          break;
        case _tagsTab:
          content = TagsPage(recipes: recipes, onRecipeTap: _onRecipeCardTap);
          break;
        case _settingsTab:
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
    }

    return Scaffold(
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          UiSoundService.instance.playSideMenuOpen();
        }
      },
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 194, 143, 96),
        elevation: 0,
        centerTitle: true,
        title: StrokedButtonLabel(
          _headerTitle(),
          fillColor: Colors.white,
          strokeColor: const Color(0xFF5D4A3A),
          fontSize: 20,
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF8EFE3),
        child: Container(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Image.asset(
                    'images/culinara_logo.png',
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  label: 'Recipes',
                  icon: Icons.menu_book_rounded,
                  tab: _recipesTab,
                ),
                _buildDrawerItem(
                  label: 'Drafts',
                  icon: Icons.edit_note_rounded,
                  tab: _draftsTab,
                ),
                _buildDrawerItem(
                  label: 'Tags',
                  icon: Icons.sell_rounded,
                  tab: _tagsTab,
                ),
                _buildDrawerItem(
                  label: 'Settings',
                  icon: Icons.settings_rounded,
                  tab: _settingsTab,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const GinghamPatternBackground(),
          Padding(padding: const EdgeInsets.only(top: 12), child: content),
        ],
      ),
      floatingActionButton: _selectedIndex == _recipesTab
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PressBounce(
                  child: FloatingActionButton.extended(
                    heroTag: 'tools_fab',
                    onPressed: _openGeneralToolsPage,
                    backgroundColor: const Color.fromARGB(255, 194, 143, 96),
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.build_rounded),
                    label: const StrokedButtonLabel('Tools'),
                  ),
                ),
                const SizedBox(width: 10),
                PressBounce(
                  child: FloatingActionButton(
                    heroTag: 'add_fab',
                    onPressed: _openAddRecipePage,
                    backgroundColor: const Color.fromARGB(255, 194, 143, 96),
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildDrawerItem({
    required String label,
    required IconData icon,
    required int tab,
  }) {
    final isSelected = _selectedIndex == tab;
    return ListTile(
      selected: isSelected,
      selectedTileColor: const Color(0xFFEED9C3),
      leading: Icon(icon, color: const Color(0xFF5D4A3A)),
      title: Text(
        label,
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF5D4A3A),
        ),
      ),
      onTap: () => _onMenuTap(tab),
    );
  }

  Widget _buildRecipeCount(int count) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFD2B48C),
        borderRadius: BorderRadius.circular(10),
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
          PressBounce(
            child: ElevatedButton(
              onPressed: _openAddRecipePage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 194, 143, 96),
                foregroundColor: Colors.white,
              ),
              child: const StrokedButtonLabel('Create Recipe'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
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
            Icons.search_off_rounded,
            size: 44,
            color: Color(0xFF8B6F47),
          ),
          const SizedBox(height: 8),
          Text(
            'No matching recipes',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different title, ingredient, or #tag keyword.',
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
        ],
      ),
    );
  }
}
