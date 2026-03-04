import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/models/recipe.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;
  final Function(Recipe) onPin;
  final Function(Recipe) onDelete;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
    required this.onPin,
    required this.onDelete,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late Recipe recipe;

  ImageProvider<Object> get _coverImage {
    if (recipe.coverImageBytes != null) {
      return MemoryImage(recipe.coverImageBytes!);
    }
    return AssetImage(recipe.imagePath);
  }

  @override
  void initState() {
    super.initState();
    recipe = widget.recipe;
  }

  void _deleteRecipe() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Recipe',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this recipe?',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete(recipe);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          recipe.title,
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFC9975C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(image: _coverImage, fit: BoxFit.cover),
              ),
            ),

            // Recipe Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: GoogleFonts.fredoka(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pin Button
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onPin(recipe);
                      setState(() {});
                    },
                    icon: Icon(
                      recipe.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                    label: Text(
                      recipe.isPinned ? 'Unpin' : 'Pin',
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: recipe.isPinned
                          ? Color(0xFFFFD54F)
                          : Color(0xFF8B5E3C),
                      foregroundColor: recipe.isPinned
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Mark as Cooked Button
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        recipe.cooked = !recipe.cooked;
                      });
                    },
                    icon: Icon(
                      recipe.cooked
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                    ),
                    label: Text(
                      recipe.cooked ? 'Mark as Uncooked' : 'Mark as Cooked',
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: recipe.cooked
                          ? Colors.green
                          : Color(0xFF8B5E3C),
                      foregroundColor: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recipe Content
                  Text(
                    'Recipe Details',
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailSection('Ingredients', recipe.ingredients),
                  const SizedBox(height: 10),
                  _buildDetailSection('Directions', recipe.directions),
                  const SizedBox(height: 10),
                  _buildDetailSection(
                    'Serving Size',
                    recipe.servingSize.isEmpty
                        ? 'Not specified'
                        : recipe.servingSize,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailSection(
                    'Cooking Time',
                    recipe.cookingTime.isEmpty
                        ? 'Not specified'
                        : recipe.cookingTime,
                  ),
                  const SizedBox(height: 10),
                  _buildDetailSection(
                    'Tags',
                    recipe.tags.isEmpty
                        ? 'No tags added'
                        : recipe.tags.map((tag) => '#$tag').join(', '),
                  ),

                  const SizedBox(height: 32),

                  // Edit and Delete Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Edit functionality would go here
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Edit feature coming soon',
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.edit),
                          label: Text(
                            'Edit',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8B5E3C),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _deleteRecipe,
                          icon: Icon(Icons.delete),
                          label: Text(
                            'Delete',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
