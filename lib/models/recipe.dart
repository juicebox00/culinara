import 'dart:typed_data';
import 'dart:convert';

class Recipe {
  final String id;
  final String title;
  final String imagePath;
  final String? coverImageFilePath;
  final String? coverImageStorageUrl;
  final List<String> cookedImageGalleryPaths;
  final List<String> cookedImageGalleryUrls;
  final Uint8List? coverImageBytes;
  final String ingredients;
  final String directions;
  final String sourceUrl;
  final String notes;
  final String servingSize;
  final String cookingTime;
  final List<String> shelves;
  final List<String> tags;
  final List<Uint8List> cookedImageGalleryBytes;
  bool isPinned;
  bool cooked;

  Recipe({
    required this.id,
    required this.title,
    required this.imagePath,
    this.coverImageFilePath,
    this.coverImageStorageUrl,
    this.cookedImageGalleryPaths = const [],
    this.cookedImageGalleryUrls = const [],
    this.coverImageBytes,
    this.ingredients = '',
    this.directions = '',
    this.sourceUrl = '',
    this.notes = '',
    this.servingSize = '',
    this.cookingTime = '',
    this.shelves = const [],
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
    String? coverImageStorageUrl,
    List<String>? cookedImageGalleryPaths,
    List<String>? cookedImageGalleryUrls,
    Uint8List? coverImageBytes,
    String? ingredients,
    String? directions,
    String? sourceUrl,
    String? notes,
    String? servingSize,
    String? cookingTime,
    List<String>? shelves,
    List<String>? tags,
    List<Uint8List>? cookedImageGalleryBytes,
    bool? isPinned,
    bool? cooked,
    bool clearCoverImageFilePath = false,
    bool clearCoverImageBytes = false,
    bool clearCoverImageStorageUrl = false,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      coverImageFilePath: clearCoverImageFilePath
          ? null
          : (coverImageFilePath ?? this.coverImageFilePath),
      coverImageStorageUrl: clearCoverImageStorageUrl
          ? null
          : (coverImageStorageUrl ?? this.coverImageStorageUrl),
      cookedImageGalleryPaths:
          cookedImageGalleryPaths ?? this.cookedImageGalleryPaths,
      cookedImageGalleryUrls:
          cookedImageGalleryUrls ?? this.cookedImageGalleryUrls,
      coverImageBytes: clearCoverImageBytes
          ? null
          : (coverImageBytes ?? this.coverImageBytes),
      ingredients: ingredients ?? this.ingredients,
      directions: directions ?? this.directions,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      notes: notes ?? this.notes,
      servingSize: servingSize ?? this.servingSize,
      cookingTime: cookingTime ?? this.cookingTime,
      shelves: shelves ?? this.shelves,
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
      'coverImageStorageUrl': coverImageStorageUrl,
      'cookedImageGalleryUrls': cookedImageGalleryUrls
          .take(10)
          .toList(growable: false),
      'ingredients': ingredients,
      'directions': directions,
      'sourceUrl': sourceUrl,
      'notes': notes,
      'servingSize': servingSize,
      'cookingTime': cookingTime,
      'shelves': shelves,
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
    final dynamic rawShelves = map['shelves'];
    final dynamic rawCoverPath = map['coverImageFilePath'];
    final dynamic rawCookedImagePaths = map['cookedImageGalleryPaths'];
    final dynamic rawCookedImageUrls = map['cookedImageGalleryUrls'];

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

    final List<String> cookedGalleryUrls = rawCookedImageUrls is List
        ? rawCookedImageUrls
              .map((e) => e?.toString() ?? '')
              .where((url) => url.isNotEmpty)
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
      coverImageStorageUrl:
          (map['coverImageStorageUrl'] ?? '').toString().isNotEmpty
          ? map['coverImageStorageUrl'].toString()
          : null,
      cookedImageGalleryPaths: cookedGalleryPaths,
      cookedImageGalleryUrls: cookedGalleryUrls,
      coverImageBytes: map['coverImageBytes'] == null
          ? null
          : base64Decode(map['coverImageBytes'].toString()),
      ingredients: (map['ingredients'] ?? '').toString(),
      directions: (map['directions'] ?? '').toString(),
      sourceUrl: (map['sourceUrl'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      servingSize: (map['servingSize'] ?? '').toString(),
      cookingTime: (map['cookingTime'] ?? '').toString(),
      shelves: rawShelves is List
          ? rawShelves
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      tags: rawTags is List
          ? rawTags.map((e) => e.toString()).toList(growable: false)
          : const <String>[],
      cookedImageGalleryBytes: cookedGallery,
      isPinned: map['isPinned'] == true,
      cooked: map['cooked'] == true,
    );
  }
}
