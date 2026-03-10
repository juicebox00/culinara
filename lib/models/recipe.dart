import 'dart:typed_data';
import 'dart:convert';

class Recipe {
  final String id;
  final String title;
  final String imagePath;
  final String? coverImageFilePath;
  final List<String> cookedImageGalleryPaths;
  final Uint8List? coverImageBytes;
  final String ingredients;
  final String directions;
  final String servingSize;
  final String cookingTime;
  final List<String> tags;
  final List<Uint8List> cookedImageGalleryBytes;
  bool isPinned;
  bool cooked;

  Recipe({
    required this.id,
    required this.title,
    required this.imagePath,
    this.coverImageFilePath,
    this.cookedImageGalleryPaths = const [],
    this.coverImageBytes,
    this.ingredients = '',
    this.directions = '',
    this.servingSize = '',
    this.cookingTime = '',
    this.tags = const [],
    this.cookedImageGalleryBytes = const [],
    this.isPinned = false,
    this.cooked = false,
  });

  Recipe copyWith({
    String? id,
    String? title,
    String? imagePath,
    String? coverImageFilePath,
    List<String>? cookedImageGalleryPaths,
    Uint8List? coverImageBytes,
    String? ingredients,
    String? directions,
    String? servingSize,
    String? cookingTime,
    List<String>? tags,
    List<Uint8List>? cookedImageGalleryBytes,
    bool? isPinned,
    bool? cooked,
    bool clearCoverImageFilePath = false,
    bool clearCoverImageBytes = false,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      coverImageFilePath: clearCoverImageFilePath
          ? null
          : (coverImageFilePath ?? this.coverImageFilePath),
      cookedImageGalleryPaths:
          cookedImageGalleryPaths ?? this.cookedImageGalleryPaths,
      coverImageBytes: clearCoverImageBytes
          ? null
          : (coverImageBytes ?? this.coverImageBytes),
      ingredients: ingredients ?? this.ingredients,
      directions: directions ?? this.directions,
      servingSize: servingSize ?? this.servingSize,
      cookingTime: cookingTime ?? this.cookingTime,
      tags: tags ?? this.tags,
      cookedImageGalleryBytes:
          cookedImageGalleryBytes ?? this.cookedImageGalleryBytes,
      isPinned: isPinned ?? this.isPinned,
      cooked: cooked ?? this.cooked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imagePath': imagePath,
      'coverImageFilePath': coverImageFilePath,
      'ingredients': ingredients,
      'directions': directions,
      'servingSize': servingSize,
      'cookingTime': cookingTime,
      'tags': tags,
      'cookedImageGalleryPaths': cookedImageGalleryPaths
          .take(10)
          .toList(growable: false),
      'isPinned': isPinned,
      'cooked': cooked,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    final dynamic rawTags = map['tags'];
    final dynamic rawCoverPath = map['coverImageFilePath'];
    final dynamic rawCookedImagePaths = map['cookedImageGalleryPaths'];

    final dynamic rawCookedImageGallery = map['cookedImageGalleryBytes'];

    final List<Uint8List> cookedGallery = rawCookedImageGallery is List
        ? rawCookedImageGallery
              .map((e) => e?.toString() ?? '')
              .where((encoded) => encoded.isNotEmpty)
              .take(10)
              .map(base64Decode)
              .toList(growable: false)
        : const <Uint8List>[];

    final List<String> cookedGalleryPaths = rawCookedImagePaths is List
        ? rawCookedImagePaths
              .map((e) => e?.toString() ?? '')
              .where((path) => path.isNotEmpty)
              .take(10)
              .toList(growable: false)
        : const <String>[];

    return Recipe(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      imagePath: (map['imagePath'] ?? 'images/placeholder_thumbnail.png')
          .toString(),
      coverImageFilePath: rawCoverPath?.toString().isNotEmpty == true
          ? rawCoverPath.toString()
          : null,
      cookedImageGalleryPaths: cookedGalleryPaths,
      coverImageBytes: map['coverImageBytes'] == null
          ? null
          : base64Decode(map['coverImageBytes'].toString()),
      ingredients: (map['ingredients'] ?? '').toString(),
      directions: (map['directions'] ?? '').toString(),
      servingSize: (map['servingSize'] ?? '').toString(),
      cookingTime: (map['cookingTime'] ?? '').toString(),
      tags: rawTags is List
          ? rawTags.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      cookedImageGalleryBytes: cookedGallery,
      isPinned: map['isPinned'] == true,
      cooked: map['cooked'] == true,
    );
  }
}
