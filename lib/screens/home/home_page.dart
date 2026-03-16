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
  static const String _allShelvesFilter = 'All';
  static const int _maxVisibleShelves = 5;

  int _selectedIndex = 0;
  String _searchQuery = '';
  String _selectedShelfFilter = _allShelvesFilter;
  String _sortOrder = 'A to Z'; // Default
  bool _isSelectionMode = false;
  final Set<String> _selectedRecipeIds = <String>{};
  DateTime? _lastBackPressTime;

  List<Recipe> recipes = [];
  bool _isLoadingRecipes = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final storedRecipes = await RecipeStoreService.loadRecipes();

    if (!mounted) return;
    setState(() {
      recipes = storedRecipes;
      _syncSelectedShelfFilter(storedRecipes);
      _isLoadingRecipes = false;
    });
  }

  List<String> _allShelvesFromRecipes(List<Recipe> source) {
    final shelves = <String>{};
    for (final recipe in source) {
      for (final shelf in recipe.shelves) {
        final normalized = shelf.trim();
        if (normalized.isNotEmpty) {
          shelves.add(normalized);
        }
      }
    }

    final sorted = shelves.toList(growable: false)
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted;
  }

  String _normalizeLabel(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> _dedupeCaseInsensitive(List<String> values) {
    final seen = <String>{};
    final deduped = <String>[];
    for (final raw in values) {
      final normalized = _normalizeLabel(raw);
      if (normalized.isEmpty) continue;
      final key = normalized.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      deduped.add(normalized);
    }
    return deduped;
  }

  int _shelfUsageCount(String shelf) {
    final needle = shelf.trim().toLowerCase();
    if (needle.isEmpty) return 0;
    return recipes
        .where(
          (recipe) =>
              recipe.shelves.any((item) => item.trim().toLowerCase() == needle),
        )
        .length;
  }

  Future<String?> _showRenameShelfDialog(String currentShelf) async {
    final controller = TextEditingController(text: currentShelf);
    final renamed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF8EFE3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Rename Shelf',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: TextField(
          controller: controller,
          maxLength: 24,
          autofocus: true,
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: 'Shelf name',
            hintStyle: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            filled: true,
            fillColor: const Color(0xFFF5E6D3),
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
              borderSide: const BorderSide(
                color: Color(0xFF8B6F47),
                width: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const StrokedButtonLabel('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const StrokedButtonLabel('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    final normalized = _normalizeLabel(renamed ?? '');
    if (normalized.isEmpty) return null;
    return normalized;
  }

  Future<bool> _confirmDeleteShelf(String shelf, int usageCount) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF8EFE3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Delete Shelf',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          usageCount == 0
              ? 'Delete "$shelf"?'
              : 'Remove "$shelf" from $usageCount recipe(s)?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const StrokedButtonLabel('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const StrokedButtonLabel(
              'Delete',
              fillColor: Color(0xFF9C2D2D),
              strokeColor: Color(0xFFF5E6D3),
            ),
          ),
        ],
      ),
    );

    return shouldDelete == true;
  }

  void _renameShelfAcrossRecipes(String currentShelf, String nextShelf) {
    final oldLabel = _normalizeLabel(currentShelf);
    final newLabel = _normalizeLabel(nextShelf);
    if (oldLabel.isEmpty || newLabel.isEmpty) return;
    if (oldLabel.toLowerCase() == newLabel.toLowerCase()) return;

    final oldKey = oldLabel.toLowerCase();
    var changed = false;
    final updatedRecipes = recipes
        .map((recipe) {
          final hasOld = recipe.shelves.any(
            (shelf) => shelf.trim().toLowerCase() == oldKey,
          );
          if (!hasOld) return recipe;

          changed = true;
          final replacedShelves = recipe.shelves
              .map((shelf) {
                if (shelf.trim().toLowerCase() == oldKey) {
                  return newLabel;
                }
                return shelf;
              })
              .toList(growable: false);

          return recipe.copyWith(
            shelves: _dedupeCaseInsensitive(replacedShelves),
          );
        })
        .toList(growable: false);

    if (!changed) return;

    setState(() {
      recipes = updatedRecipes;
      if (_selectedShelfFilter.toLowerCase() == oldKey) {
        _selectedShelfFilter = newLabel;
      }
      _syncSelectedShelfFilter(recipes);
    });
    _persistRecipes();
  }

  void _deleteShelfAcrossRecipes(String shelf) {
    final normalized = _normalizeLabel(shelf);
    if (normalized.isEmpty) return;

    final needle = normalized.toLowerCase();
    var changed = false;
    final updatedRecipes = recipes
        .map((recipe) {
          final filteredShelves = recipe.shelves
              .where((item) => item.trim().toLowerCase() != needle)
              .toList(growable: false);
          if (filteredShelves.length == recipe.shelves.length) return recipe;

          changed = true;
          return recipe.copyWith(shelves: filteredShelves);
        })
        .toList(growable: false);

    if (!changed) return;

    setState(() {
      recipes = updatedRecipes;
      if (_selectedShelfFilter.toLowerCase() == needle) {
        _selectedShelfFilter = _allShelvesFilter;
      }
      _syncSelectedShelfFilter(recipes);
    });
    _persistRecipes();
  }

  Future<void> _showManageShelvesSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF8EFE3),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            final shelves = _allShelvesFromRecipes(recipes);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Shelves',
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4A3A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (shelves.isEmpty)
                      Text(
                        'No shelves yet.',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B6F47),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: shelves.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final shelf = shelves[index];
                            final usageCount = _shelfUsageCount(shelf);

                            return ListTile(
                              tileColor: const Color(0xFFF5E6D3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: Color(0xFF8B6F47),
                                  width: 1.5,
                                ),
                              ),
                              title: Text(
                                shelf,
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D4A3A),
                                ),
                              ),
                              subtitle: Text(
                                '$usageCount recipe(s)',
                                style: GoogleFonts.fredoka(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8B6F47),
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                color: const Color(0xFFF8EFE3),
                                onSelected: (value) async {
                                  if (value == 'rename') {
                                    final renamed =
                                        await _showRenameShelfDialog(shelf);
                                    if (renamed == null) return;
                                    _renameShelfAcrossRecipes(shelf, renamed);
                                    modalSetState(() {});
                                    return;
                                  }

                                  final confirmed = await _confirmDeleteShelf(
                                    shelf,
                                    usageCount,
                                  );
                                  if (!confirmed) return;

                                  _deleteShelfAcrossRecipes(shelf);
                                  modalSetState(() {});
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem<String>(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
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
      },
    );
  }

  void _renameTagAcrossRecipes(String currentTag, String nextTag) {
    final oldLabel = _normalizeLabel(currentTag);
    final newLabel = _normalizeLabel(nextTag);
    if (oldLabel.isEmpty || newLabel.isEmpty) return;
    if (oldLabel.toLowerCase() == newLabel.toLowerCase()) return;

    final oldKey = oldLabel.toLowerCase();
    var changed = false;
    final updatedRecipes = recipes
        .map((recipe) {
          final hasOld = recipe.tags.any(
            (tag) => tag.trim().toLowerCase() == oldKey,
          );
          if (!hasOld) return recipe;

          changed = true;
          final replacedTags = recipe.tags
              .map((tag) {
                if (tag.trim().toLowerCase() == oldKey) {
                  return newLabel;
                }
                return tag;
              })
              .toList(growable: false);

          return recipe.copyWith(tags: _dedupeCaseInsensitive(replacedTags));
        })
        .toList(growable: false);

    if (!changed) return;

    setState(() {
      recipes = updatedRecipes;
    });
    _persistRecipes();
  }

  void _deleteTagAcrossRecipes(String tag) {
    final normalized = _normalizeLabel(tag);
    if (normalized.isEmpty) return;

    final needle = normalized.toLowerCase();
    var changed = false;
    final updatedRecipes = recipes
        .map((recipe) {
          final filteredTags = recipe.tags
              .where((item) => item.trim().toLowerCase() != needle)
              .toList(growable: false);
          if (filteredTags.length == recipe.tags.length) return recipe;

          changed = true;
          return recipe.copyWith(tags: filteredTags);
        })
        .toList(growable: false);

    if (!changed) return;

    setState(() {
      recipes = updatedRecipes;
    });
    _persistRecipes();
  }

  void _syncSelectedShelfFilter(List<Recipe> source) {
    if (_selectedShelfFilter == _allShelvesFilter) return;
    final exists = _allShelvesFromRecipes(
      source,
    ).any((shelf) => shelf.toLowerCase() == _selectedShelfFilter.toLowerCase());
    if (!exists) {
      _selectedShelfFilter = _allShelvesFilter;
    }
  }

  List<Recipe> _filterRecipesByShelf(List<Recipe> source) {
    if (_selectedShelfFilter == _allShelvesFilter) return source;
    final needle = _selectedShelfFilter.toLowerCase();
    return source
        .where((recipe) {
          return recipe.shelves.any((shelf) => shelf.toLowerCase() == needle);
        })
        .toList(growable: false);
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
          pinnedRecipes.last.isPinned = false;
        }
        recipe.isPinned = true;

        recipes.removeWhere((r) => r.id == recipe.id);
        recipes = [recipe, ...recipes];
      }
    });
    _persistRecipes();
  }

  String _buildDuplicateTitle(String baseTitle) {
    final trimmed = baseTitle.trim();
    final source = trimmed.isEmpty ? 'Untitled Recipe' : trimmed;

    final existingTitles = recipes
        .map((r) => r.title.trim().toLowerCase())
        .toSet();

    var candidate = '$source (Copy)';
    var counter = 2;
    while (existingTitles.contains(candidate.toLowerCase())) {
      candidate = '$source (Copy $counter)';
      counter += 1;
    }
    return candidate;
  }

  void _onRecipeDuplicate(Recipe recipe) {
    final duplicated = recipe.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _buildDuplicateTitle(recipe.title),
      isPinned: false,
    );

    setState(() {
      recipes = [duplicated, ...recipes];
      _syncSelectedShelfFilter(recipes);
      _selectedIndex = _recipesTab;
    });
    _persistRecipes();
  }

  void _enterSelectionMode(Recipe recipe) {
    setState(() {
      _isSelectionMode = true;
      _selectedRecipeIds
        ..clear()
        ..add(recipe.id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRecipeIds.clear();
    });
  }

  void _toggleRecipeSelection(Recipe recipe) {
    setState(() {
      if (_selectedRecipeIds.contains(recipe.id)) {
        _selectedRecipeIds.remove(recipe.id);
      } else {
        _selectedRecipeIds.add(recipe.id);
      }

      if (_selectedRecipeIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _handleRecipeCardTap(Recipe recipe) {
    if (_isSelectionMode) {
      _toggleRecipeSelection(recipe);
      return;
    }
    _onRecipeCardTap(recipe);
  }

  void _handleRecipeCardLongPress(Recipe recipe) {
    if (_isSelectionMode) {
      _toggleRecipeSelection(recipe);
      return;
    }
    _enterSelectionMode(recipe);
  }

  void _toggleSelectAllVisible(List<Recipe> visibleRecipes) {
    final visibleIds = visibleRecipes.map((r) => r.id).toSet();
    if (visibleIds.isEmpty) return;

    setState(() {
      final hasUnselectedVisible = visibleIds.any(
        (id) => !_selectedRecipeIds.contains(id),
      );

      if (hasUnselectedVisible) {
        _selectedRecipeIds.addAll(visibleIds);
      } else {
        _selectedRecipeIds.removeAll(visibleIds);
      }

      if (_selectedRecipeIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _deleteSelectedRecipes() async {
    if (_selectedRecipeIds.isEmpty) return;

    final count = _selectedRecipeIds.length;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF8EFE3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Delete $count recipes?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          'This will remove the selected recipes from your collection.',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const StrokedButtonLabel('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const StrokedButtonLabel(
              'Delete',
              fillColor: Color(0xFF9C2D2D),
              strokeColor: Color(0xFFF5E6D3),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      recipes.removeWhere((recipe) => _selectedRecipeIds.contains(recipe.id));
      _selectedRecipeIds.clear();
      _isSelectionMode = false;
      _syncSelectedShelfFilter(recipes);
    });
    _persistRecipes();
  }

  void _onRecipeDelete(Recipe recipe) {
    setState(() {
      recipes.removeWhere((r) => r.id == recipe.id);
      _syncSelectedShelfFilter(recipes);
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
      _syncSelectedShelfFilter(recipes);
    });
    _persistRecipes();
  }

  void _onRecipeCardTap(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(
          recipe: recipe,
          availableShelves: _allShelvesFromRecipes(recipes),
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
      MaterialPageRoute(
        builder: (_) =>
            AddRecipePage(suggestedShelves: _allShelvesFromRecipes(recipes)),
      ),
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
      _syncSelectedShelfFilter(recipes);
    });
    _persistRecipes();
  }

  void _onMenuTap(int idx) {
    Navigator.of(context).pop();
    setState(() {
      _selectedIndex = idx;
      _isSelectionMode = false;
      _selectedRecipeIds.clear();
    });
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

  Future<void> _openToolsFromDrawer() async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await _openGeneralToolsPage();
  }

  String _headerTitle() {
    switch (_selectedIndex) {
      case _recipesTab:
        return 'My Recipes';
      case _draftsTab:
        return 'My Drafts';
      case _tagsTab:
        return 'My Tags';
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

  List<Recipe> _sortRecipes(List<Recipe> source) {
    final sorted = List<Recipe>.from(source);
    switch (_sortOrder) {
      case 'A to Z':
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Newest to Oldest':
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Oldest to Newest':
        sorted.sort((a, b) => a.id.compareTo(b.id));
        break;
    }
    return sorted;
  }

  void _showSortMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF8EFE3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Sort By',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('A to Z'),
            _buildSortOption('Newest to Oldest'),
            _buildSortOption('Oldest to Newest'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String option) {
    return ListTile(
      title: Text(
        option,
        style: GoogleFonts.fredoka(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF5D4A3A),
        ),
      ),
      trailing: _sortOrder == option
          ? const Icon(Icons.check, color: Color(0xFF5D4A3A))
          : null,
      onTap: () {
        setState(() {
          _sortOrder = option;
        });
        Navigator.pop(context);
      },
    );
  }

  void _selectShelfFilter(String shelf) {
    setState(() {
      _selectedShelfFilter = shelf;
    });
  }

  Future<void> _showShelvesSheet(List<String> shelves) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF8EFE3),
      builder: (context) {
        final allOptions = <String>[_allShelvesFilter, ...shelves];
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            itemCount: allOptions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final shelf = allOptions[index];
              final selected = shelf == _selectedShelfFilter;
              return ListTile(
                tileColor: selected
                    ? const Color(0xFFEED9C3)
                    : const Color(0xFFF5E6D3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF8B6F47), width: 1.5),
                ),
                title: Text(
                  shelf,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4A3A),
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check, color: Color(0xFF5D4A3A))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _selectShelfFilter(shelf);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShelfFilters(List<String> shelves) {
    final visible = shelves.take(_maxVisibleShelves).toList(growable: false);
    final hasMore = shelves.length > _maxVisibleShelves;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            TapBounce(
              onTap: _showManageShelvesSheet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8EFE3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF8B6F47),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  size: 18,
                  color: Color(0xFF5D4A3A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text(
                _allShelvesFilter,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              selected: _selectedShelfFilter == _allShelvesFilter,
              backgroundColor: const Color(0xFFF5E6D3),
              selectedColor: const Color(0xFFD2B48C),
              checkmarkColor: const Color(0xFF5D4A3A),
              side: const BorderSide(color: Color(0xFF8B6F47), width: 1.2),
              onSelected: (_) => _selectShelfFilter(_allShelvesFilter),
            ),
            for (final shelf in visible) ...[
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(
                  shelf,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4A3A),
                  ),
                ),
                selected: _selectedShelfFilter == shelf,
                backgroundColor: const Color(0xFFF5E6D3),
                selectedColor: const Color(0xFFD2B48C),
                checkmarkColor: const Color(0xFF5D4A3A),
                side: const BorderSide(color: Color(0xFF8B6F47), width: 1.2),
                onSelected: (_) => _selectShelfFilter(shelf),
              ),
            ],
            if (hasMore) ...[
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: Color(0xFF5D4A3A),
                ),
                backgroundColor: const Color(0xFFF5E6D3),
                side: const BorderSide(color: Color(0xFF8B6F47), width: 1.2),
                label: Text(
                  'More',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4A3A),
                  ),
                ),
                onPressed: () => _showShelvesSheet(shelves),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isSelectionMode) {
      _exitSelectionMode();
      return false;
    }

    final now = DateTime.now();

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      // First tap or more than 2 seconds since last tap
      _lastBackPressTime = now;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Press back again to exit',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 194, 143, 96),
        ),
      );
      return false; // Don't pop
    }

    // Second tap within 2 seconds - exit app
    return true; // Allow popping
  }

  @override
  Widget build(BuildContext context) {
    final allShelves = _allShelvesFromRecipes(recipes);
    final shelfFilteredRecipes = _filterRecipesByShelf(recipes);
    final visibleRecipes = _filteredRecipesByQuery(shelfFilteredRecipes);
    final visibleRecipeIds = visibleRecipes.map((r) => r.id).toSet();
    final hasUnselectedVisible = visibleRecipeIds.any(
      (id) => !_selectedRecipeIds.contains(id),
    );
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
                      const SizedBox(width: 8),
                      TapBounce(
                        onTap: _showSortMenu,
                        child: const Icon(
                          Icons.sort,
                          size: 28,
                          color: Color(0xFF5D4A3A),
                        ),
                      ),
                    ],
                  ),
                ),
                if (allShelves.isNotEmpty) ...[
                  _buildShelfFilters(allShelves),
                  const SizedBox(height: 8),
                ],
                _buildRecipeCount(recipes.length),

                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E6D3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8B6F47),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_selectedRecipeIds.length} selected',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5D4A3A),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: visibleRecipes.isEmpty
                                ? null
                                : () => _toggleSelectAllVisible(visibleRecipes),
                            child: Text(
                              hasUnselectedVisible ? 'Select all' : 'Clear all',
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5D4A3A),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _selectedRecipeIds.isEmpty
                                ? null
                                : _deleteSelectedRecipes,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFF9C2D2D),
                            ),
                          ),
                          IconButton(
                            onPressed: _exitSelectionMode,
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF5D4A3A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                              onDuplicate: _onRecipeDuplicate,
                              onTap: () => _handleRecipeCardTap(recipe),
                              onLongPress: () =>
                                  _handleRecipeCardLongPress(recipe),
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedRecipeIds.contains(
                                recipe.id,
                              ),
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
                        'My Recipes',
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
                          children: _sortRecipes(unpinnedRecipes).map((recipe) {
                            return RecipeCard(
                              recipe: recipe,
                              isPinned: false,
                              onPin: _onRecipePin,
                              onDuplicate: _onRecipeDuplicate,
                              onTap: () => _handleRecipeCardTap(recipe),
                              onLongPress: () =>
                                  _handleRecipeCardLongPress(recipe),
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedRecipeIds.contains(
                                recipe.id,
                              ),
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
          content = TagsPage(
            recipes: recipes,
            onRecipeTap: _onRecipeCardTap,
            onRenameTag: _renameTagAcrossRecipes,
            onDeleteTag: _deleteTagAcrossRecipes,
          );
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                    label: 'My Recipes',
                    icon: Icons.menu_book_rounded,
                    tab: _recipesTab,
                  ),
                  _buildDrawerItem(
                    label: 'My Drafts',
                    icon: Icons.edit_note_rounded,
                    tab: _draftsTab,
                  ),
                  _buildDrawerItem(
                    label: 'My Tags',
                    icon: Icons.sell_rounded,
                    tab: _tagsTab,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.build_rounded,
                      color: Color(0xFF5D4A3A),
                    ),
                    title: Text(
                      'My Tools',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4A3A),
                      ),
                    ),
                    onTap: _openToolsFromDrawer,
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
        floatingActionButton: _selectedIndex == _recipesTab && !_isSelectionMode
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
      ),
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
        '$count saved recipes',
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
            'Add your first recipe to start building your cookbook.',
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
