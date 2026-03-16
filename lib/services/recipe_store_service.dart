import 'dart:convert';
import 'dart:io';

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
        final recipe = Recipe.fromMap(migrated);
        recipes.add(await _ensureLocalImages(recipe));
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
        final synced = await _syncRecipeImages(recipe, userId);
        await _firestore
            .collection(recipesPath)
            .doc(synced.id)
            .set(synced.toMap());
      }

      // Cache locally
      await _cacheRecipesLocally(recipes);
    } catch (e) {
      print('Error saving to Firebase: $e');
      // Still cache locally as fallback
      await _cacheRecipesLocally(recipes);
    }
  }

  /// Uploads any local images that don't yet have a Firebase Storage URL.
  /// Returns an updated Recipe with storage URLs filled in.
  static Future<Recipe> _syncRecipeImages(
    Recipe recipe,
    String userId,
  ) async {
    String? coverUrl = recipe.coverImageStorageUrl;
    final List<String> galleryUrls = List.from(recipe.cookedImageGalleryUrls);

    // Upload cover image if it has a local file but no storage URL yet
    final localCover = recipe.coverImageFilePath;
    if ((coverUrl == null || coverUrl.isEmpty) &&
        localCover != null &&
        localCover.isNotEmpty) {
      coverUrl = await RecipeImageStoreService.uploadCoverImage(
        localFilePath: localCover,
        userId: userId,
        recipeId: recipe.id,
      );
    }

    // Upload gallery images that don't have a storage URL yet
    final localGallery = recipe.cookedImageGalleryPaths;
    for (int i = galleryUrls.length; i < localGallery.length; i++) {
      final url = await RecipeImageStoreService.uploadGalleryImage(
        localFilePath: localGallery[i],
        userId: userId,
        recipeId: recipe.id,
        index: i,
      );
      if (url != null) galleryUrls.add(url);
    }

    return recipe.copyWith(
      coverImageStorageUrl: coverUrl,
      cookedImageGalleryUrls: galleryUrls,
    );
  }

  /// Downloads images from Firebase Storage when local files are missing.
  /// Returns an updated Recipe with local file paths filled in.
  static Future<Recipe> _ensureLocalImages(Recipe recipe) async {
    String? localCover = recipe.coverImageFilePath;
    final List<String> localGallery =
        List.from(recipe.cookedImageGalleryPaths);

    // Download cover if missing locally but available in Storage
    final storageUrl = recipe.coverImageStorageUrl;
    if (storageUrl != null && storageUrl.isNotEmpty) {
      final missing = localCover == null ||
          localCover.isEmpty ||
          !File(localCover).existsSync();
      if (missing) {
        localCover = await RecipeImageStoreService.downloadFromStorage(
          url: storageUrl,
          recipeId: recipe.id,
          slot: 'cover',
        );
      }
    }

    // Download gallery images that are missing locally
    final galleryUrls = recipe.cookedImageGalleryUrls;
    for (int i = 0; i < galleryUrls.length; i++) {
      final localExists =
          i < localGallery.length && File(localGallery[i]).existsSync();
      if (!localExists) {
        final path = await RecipeImageStoreService.downloadFromStorage(
          url: galleryUrls[i],
          recipeId: recipe.id,
          slot: 'cooked_$i',
        );
        if (path != null) {
          if (i < localGallery.length) {
            localGallery[i] = path;
          } else {
            localGallery.add(path);
          }
        }
      }
    }

    return recipe.copyWith(
      coverImageFilePath: localCover,
      cookedImageGalleryPaths: localGallery,
    );
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

