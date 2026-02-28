class Recipe {
  final String id;
  final String title;
  final String imagePath;
  bool isPinned;
  bool cooked;

  Recipe({
    required this.id,
    required this.title,
    required this.imagePath,
    this.isPinned = false,
    this.cooked = false,
  });
}
