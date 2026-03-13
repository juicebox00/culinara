import 'dart:convert';

import 'package:culinara/models/recipe.dart';
import 'package:culinara/services/recipe_image_store_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeStoreService {
  static const String _recipesKey = 'recipes.list.v1';
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the current user's ID
  static String? _getCurrentUserId() {
    return _firebaseAuth.currentUser?.uid;
  }

  /// Get the Firestore collection path for current user's recipes
  static String _getUserRecipesPath() {
    final userId = _getCurrentUserId();
    if (userId == null) {
      throw Exception('User must be logged in to access recipes');
    }
    return 'users/$userId/recipes';
  }

  /// Load recipes from Firebase for the current user
  static Future<List<Recipe>> loadRecipes() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        // No user logged in, return cached recipes if available
        return _loadCachedRecipes();
      }

      // Fetch from Firebase
      final recipesPath = _getUserRecipesPath();
      final snapshot = await _firestore.collection(recipesPath).get();

      final List<Recipe> recipes = [];
      for (final doc in snapshot.docs) {
        final source = Map<String, dynamic>.from(doc.data());
        final migrated = await RecipeImageStoreService.migrateLegacyImageFields(source);
        recipes.add(Recipe.fromMap(migrated));
      }

      // Cache locally for offline access
      await _cacheRecipesLocally(recipes);

      return recipes;
    } catch (e) {
      // If Firebase fails, return cached recipes
      print('Error loading from Firebase: $e');
      return _loadCachedRecipes();
    }
  }

  /// Save recipes to Firebase for the current user
  static Future<void> saveRecipes(List<Recipe> recipes) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        // No user logged in, save only to local cache
        await _cacheRecipesLocally(recipes);
        return;
      }

      final recipesPath = _getUserRecipesPath();

      // Delete old recipes first
      final oldRecipes = await _firestore.collection(recipesPath).get();
      for (final doc in oldRecipes.docs) {
        await doc.reference.delete();
      }

      // Save new recipes
      for (final recipe in recipes) {
        await _firestore
            .collection(recipesPath)
            .doc(recipe.id)
            .set(recipe.toMap());
      }

      // Cache locally
      await _cacheRecipesLocally(recipes);
    } catch (e) {
      print('Error saving to Firebase: $e');
      // Still cache locally as fallback
      await _cacheRecipesLocally(recipes);
    }
  }

  /// Cache recipes locally in SharedPreferences
  static Future<void> _cacheRecipesLocally(List<Recipe> recipes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(
        recipes.map((recipe) => recipe.toMap()).toList(),
      );
      await prefs.setString(_recipesKey, encoded);
    } catch (e) {
      print('Error caching recipes locally: $e');
    }
  }

  /// Load cached recipes from SharedPreferences
  static Future<List<Recipe>> _loadCachedRecipes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recipesKey);
      if (raw == null || raw.isEmpty) return const <Recipe>[];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <Recipe>[];

      final List<Recipe> recipes = [];
      for (final item in decoded) {
        final source = Map<String, dynamic>.from(item as Map);
        final migrated = await RecipeImageStoreService.migrateLegacyImageFields(source);
        recipes.add(Recipe.fromMap(migrated));
      }

      return recipes;
    } catch (e) {
      print('Error loading cached recipes: $e');
      return const <Recipe>[];
    }
  }

  /// Clear all local recipe cache (used on logout)
  static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recipesKey);
    } catch (e) {
      print('Error clearing local cache: $e');
    }
  }
}

