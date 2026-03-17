import 'package:flutter/material.dart';
import 'package:culinara/models/recipe.dart';
import 'package:google_fonts/google_fonts.dart';

class TrashBinPage extends StatelessWidget {
  final List<Recipe> trashedRecipes;
  final void Function(Recipe) onRestore;
  final void Function(Recipe) onDeletePermanently;

  const TrashBinPage({
    Key? key,
    required this.trashedRecipes,
    required this.onRestore,
    required this.onDeletePermanently,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: trashedRecipes.isEmpty
          ? Center(child: Text('Trash is empty', style: GoogleFonts.fredoka(fontSize: 16, color: Color(0xFF7A6450))))
          : ListView.builder(
              itemCount: trashedRecipes.length,
              itemBuilder: (context, index) {
                final recipe = trashedRecipes[index];
                final daysLeft = 30 - DateTime.now().difference(recipe.deletedAt!).inDays;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(recipe.title, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
                    subtitle: Text('Deleted ${DateTime.now().difference(recipe.deletedAt!).inDays} days ago • ${daysLeft} days left'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.restore, color: Colors.green),
                          onPressed: () => onRestore(recipe),
                          tooltip: 'Restore',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          onPressed: () => onDeletePermanently(recipe),
                          tooltip: 'Delete Permanently',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
