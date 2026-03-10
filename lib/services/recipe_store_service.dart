import 'dart:convert';

import 'package:culinara/models/recipe.dart';
import 'package:culinara/services/recipe_image_store_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeStoreService {
  static const String _recipesKey = 'recipes.list.v1';

  static Future<List<Recipe>> loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recipesKey);
    if (raw == null || raw.isEmpty) return const <Recipe>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const <Recipe>[];

    final List<Recipe> recipes = [];
    var migratedAny = false;

    for (final item in decoded) {
      final source = Map<String, dynamic>.from(item as Map);
      final migrated = await RecipeImageStoreService.migrateLegacyImageFields(
        source,
      );
      if (jsonEncode(source) != jsonEncode(migrated)) {
        migratedAny = true;
      }
      recipes.add(Recipe.fromMap(migrated));
    }

    if (migratedAny) {
      await saveRecipes(recipes);
    }

    return recipes;
  }

  static Future<void> saveRecipes(List<Recipe> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      recipes.map((recipe) => recipe.toMap()).toList(),
    );
    await prefs.setString(_recipesKey, encoded);
  }
}
