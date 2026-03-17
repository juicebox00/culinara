import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:culinara/models/recipe.dart';


class RecentlyViewedService {
  static const String _recentlyViewedKey = 'recently_viewed_recipes';
  static const int _maxRecentlyViewed = 20;

  // Each entry: {"id": recipeId, "viewedAt": ISO8601 string}
  static Future<List<Map<String, dynamic>>> getRecentlyViewedEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyViewedJson = prefs.getString(_recentlyViewedKey);
      if (recentlyViewedJson == null) return [];
      
      final List<dynamic> decoded = jsonDecode(recentlyViewedJson);
      
      // Handle migration from old format (strings) to new format (objects)
      if (decoded.isEmpty) return [];
      
      // Check if this is old format (list of strings)
      if (decoded.first is String) {
        debugPrint('Migrating old recently viewed format to new format');
        final oldIds = decoded.cast<String>();
        final newFormat = oldIds.map((id) => {
          'id': id,
          'viewedAt': DateTime.now().toIso8601String(), // Use current time for migration
        }).toList();
        
        // Save the new format
        await prefs.setString(_recentlyViewedKey, jsonEncode(newFormat));
        return newFormat;
      }
      
      // Already in new format
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error loading recently viewed recipes: $e');
      return [];
    }
  }

  static Future<void> addToRecentlyViewed(String recipeId) async {
    try {
      debugPrint('Adding recipe ID to recently viewed: $recipeId');
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> recentlyViewed = List<Map<String, dynamic>>.from(await getRecentlyViewedEntries());

      // Remove if already exists (to move to top)
      recentlyViewed.removeWhere((entry) => entry['id'] == recipeId);

      // Add to beginning with current date
      recentlyViewed.insert(0, {
        'id': recipeId,
        'viewedAt': DateTime.now().toIso8601String(),
      });

      // Keep only the most recent
      if (recentlyViewed.length > _maxRecentlyViewed) {
        recentlyViewed.removeRange(_maxRecentlyViewed, recentlyViewed.length);
      }

      await prefs.setString(_recentlyViewedKey, jsonEncode(recentlyViewed));
      debugPrint('Updated recently viewed entries: $recentlyViewed');
    } catch (e) {
      debugPrint('Error adding to recently viewed: $e');
    }
  }

  static Future<void> removeFromRecentlyViewed(String recipeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> recentlyViewed = List<Map<String, dynamic>>.from(await getRecentlyViewedEntries());
      recentlyViewed.removeWhere((entry) => entry['id'] == recipeId);
      await prefs.setString(_recentlyViewedKey, jsonEncode(recentlyViewed));
    } catch (e) {
      debugPrint('Error removing from recently viewed: $e');
    }
  }

  static Future<void> clearRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentlyViewedKey);
    } catch (e) {
      debugPrint('Error clearing recently viewed: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentlyViewedRecipesWithDates(List<Recipe> allRecipes) async {
    try {
      debugPrint('Loading recently viewed recipes from [1m${allRecipes.length}[0m total recipes');
      final recentlyViewedEntries = await getRecentlyViewedEntries();
      debugPrint('Found recently viewed entries: $recentlyViewedEntries');

      if (recentlyViewedEntries.isEmpty) return [];

      final idToRecipeMap = <String, Recipe>{};
      for (final recipe in allRecipes) {
        idToRecipeMap[recipe.id] = recipe;
      }

      final result = <Map<String, dynamic>>[];
      for (final entry in recentlyViewedEntries) {
        final recipe = idToRecipeMap[entry['id']];
        if (recipe != null && !recipe.deleted) {
          result.add({
            'recipe': recipe,
            'viewedAt': entry['viewedAt'],
          });
        }
      }
      debugPrint('Returning ${result.length} recently viewed recipes with dates');
      return result;
    } catch (e) {
      debugPrint('Error getting recently viewed recipes: $e');
      return [];
    }
  }
}
