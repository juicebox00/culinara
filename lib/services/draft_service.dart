import 'dart:convert';

import 'package:culinara/models/recipe.dart';
import 'package:culinara/services/recipe_image_store_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeDraft {
  final String key;
  final String mode;
  final DateTime updatedAt;
  final Recipe recipe;
  final String? baseRecipeId;

  const RecipeDraft({
    required this.key,
    required this.mode,
    required this.updatedAt,
    required this.recipe,
    this.baseRecipeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'mode': mode,
      'updatedAt': updatedAt.toIso8601String(),
      'baseRecipeId': baseRecipeId,
      'recipe': recipe.toMap(),
    };
  }

  factory RecipeDraft.fromMap(Map<String, dynamic> map) {
    return RecipeDraft(
      key: (map['key'] ?? '').toString(),
      mode: (map['mode'] ?? 'add').toString(),
      updatedAt:
          DateTime.tryParse((map['updatedAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      baseRecipeId: map['baseRecipeId']?.toString(),
      recipe: Recipe.fromMap(Map<String, dynamic>.from(map['recipe'] as Map)),
    );
  }
}

class DraftService {
  static const String _draftsKey = 'recipes.drafts.v1';

  static String addDraftKey() => 'add';

  static String editDraftKey(String recipeId) => 'edit:$recipeId';

  static Future<List<RecipeDraft>> getAllDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftsKey);
    if (raw == null || raw.isEmpty) return const <RecipeDraft>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <RecipeDraft>[];

    final List<RecipeDraft> drafts = [];
    var migratedAny = false;

    for (final item in decoded) {
      final draftMap = Map<String, dynamic>.from(item as Map);
      final rawRecipe = Map<String, dynamic>.from(draftMap['recipe'] as Map);
      final migratedRecipe =
          await RecipeImageStoreService.migrateLegacyImageFields(rawRecipe);

      if (jsonEncode(rawRecipe) != jsonEncode(migratedRecipe)) {
        migratedAny = true;
      }

      draftMap['recipe'] = migratedRecipe;
      drafts.add(RecipeDraft.fromMap(draftMap));
    }

    drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (migratedAny) {
      await _writeDrafts(drafts);
    }

    return drafts;
  }

  static Future<RecipeDraft?> getDraftByKey(String key) async {
    final drafts = await getAllDrafts();
    for (final draft in drafts) {
      if (draft.key == key) return draft;
    }
    return null;
  }

  static Future<void> saveDraft({
    required String key,
    required String mode,
    required Recipe recipe,
    String? baseRecipeId,
  }) async {
    final drafts = (await getAllDrafts()).toList(growable: true);
    drafts.removeWhere((d) => d.key == key);

    drafts.add(
      RecipeDraft(
        key: key,
        mode: mode,
        updatedAt: DateTime.now(),
        recipe: recipe,
        baseRecipeId: baseRecipeId,
      ),
    );

    await _writeDrafts(drafts);
  }

  static Future<void> removeDraftByKey(String key) async {
    final drafts = (await getAllDrafts()).toList(growable: true);
    drafts.removeWhere((d) => d.key == key);
    await _writeDrafts(drafts);
  }

  static Future<void> replaceAllDrafts(List<RecipeDraft> drafts) async {
    await _writeDrafts(drafts);
  }

  static Future<void> _writeDrafts(List<RecipeDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(drafts.map((d) => d.toMap()).toList());
    await prefs.setString(_draftsKey, encoded);
  }
}
