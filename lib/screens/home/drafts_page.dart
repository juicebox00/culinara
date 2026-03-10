import 'package:culinara/models/recipe.dart';
import 'package:culinara/screens/home/add_recipe_page.dart';
import 'package:culinara/services/draft_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/widgets/tap_bounce.dart';

class DraftsPage extends StatefulWidget {
  const DraftsPage({
    super.key,
    required this.recipes,
    required this.onRecipeSaved,
  });

  final List<Recipe> recipes;
  final ValueChanged<Recipe> onRecipeSaved;

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  late Future<List<RecipeDraft>> _draftsFuture;

  @override
  void initState() {
    super.initState();
    _draftsFuture = DraftService.getAllDrafts();
  }

  Future<void> _refreshDrafts() async {
    setState(() {
      _draftsFuture = DraftService.getAllDrafts();
    });
  }

  Recipe? _findRecipe(String? id) {
    if (id == null) return null;
    for (final recipe in widget.recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }

  Future<void> _openDraft(RecipeDraft draft) async {
    final loadedBaseRecipe = draft.mode == 'edit'
        ? _findRecipe(draft.baseRecipeId)
        : null;
    final baseRecipe =
        loadedBaseRecipe ?? (draft.mode == 'edit' ? draft.recipe : null);

    final saved = await Navigator.push<Recipe>(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecipePage(
          editingRecipe: baseRecipe,
          draftKeyOverride: draft.key,
        ),
      ),
    );

    if (saved != null) {
      widget.onRecipeSaved(saved);
      await _refreshDrafts();
    }
  }

  Future<void> _deleteDraft(RecipeDraft draft) async {
    await DraftService.removeDraftByKey(draft.key);
    await _refreshDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecipeDraft>>(
      future: _draftsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final drafts = snapshot.data ?? const <RecipeDraft>[];
        if (drafts.isEmpty) {
          return Center(
            child: Text(
              'No drafts yet.',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4A3A),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshDrafts,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drafts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final title = draft.recipe.title.trim().isEmpty
                  ? 'Untitled draft'
                  : draft.recipe.title.trim();

              return TapBounce(
                onTap: () => _openDraft(draft),
                child: ListTile(
                  tileColor: const Color(0xFFF5E6D3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFF8B6F47),
                      width: 1.5,
                    ),
                  ),
                  title: Text(
                    title,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${draft.mode == 'edit' ? 'Edit draft' : 'New recipe draft'} • ${draft.updatedAt.toLocal().toString().split('.').first}',
                    style: GoogleFonts.fredoka(),
                  ),
                  trailing: PressBounce(
                    child: IconButton(
                      onPressed: () => _deleteDraft(draft),
                      icon: const Icon(Icons.delete, color: Color(0xFF9C2D2D)),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
