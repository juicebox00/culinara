import 'package:culinara/moving_tile_pattern.dart';
import 'package:flutter/material.dart';
import 'moving_tile_pattern.dart';
import 'recipe_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MovingTilePattern(),
          SafeArea(
            child: Column(
              children: [
                _buildRecipeCount(11), 
                
                // The Grid that holds your Mock Cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2, // 2 columns like your design
                    padding: EdgeInsets.all(16),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      // Test Pinned (Yellow)
                      RecipeCard(
                        title: "Pork Sinigang",
                        imagePath: 'assets/placeholder_thumbnail.png',
                        isPinned: true, 
                      ),
                      RecipeCard(
                        title: "Pork Adobo",
                        imagePath: 'assets/placeholder_thumbnail.png',
                        isPinned: true,
                      ),
                      // Test Regular (Brown)
                      RecipeCard(
                        title: "Menudo",
                        imagePath: 'assets/placeholder_thumbnail.png',
                        isPinned: false,
                      ),
                      RecipeCard(
                        title: "Chicken Tinola",
                        imagePath: 'assets/placeholder_thumbnail.png',
                        isPinned: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCount(int count) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFD2B48C), // Match your brown header color
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF8B4513), width: 2),
      ),
      child: Text("Recipe Count: $count", 
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}