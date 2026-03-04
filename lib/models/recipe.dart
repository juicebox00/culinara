import 'dart:typed_data';

class Recipe {
  final String id;
  final String title;
  final String imagePath;
  final Uint8List? coverImageBytes;
  final String ingredients;
  final String directions;
  final String servingSize;
  final String cookingTime;
  final List<String> tags;
  bool isPinned;
  bool cooked;

  Recipe({
    required this.id,
    required this.title,
    required this.imagePath,
    this.coverImageBytes,
    this.ingredients = '',
    this.directions = '',
    this.servingSize = '',
    this.cookingTime = '',
    this.tags = const [],
    this.isPinned = false,
    this.cooked = false,
  });
}
