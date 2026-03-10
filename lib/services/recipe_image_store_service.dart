import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class RecipeImageStoreService {
  static const double maxDimension = 1600;
  static const int imageQuality = 75;

  static Future<String> savePickedImage({
    required XFile image,
    required String recipeId,
    required String slot,
  }) async {
    final target = await _targetFilePath(recipeId: recipeId, slot: slot);
    final sourcePath = image.path;

    if (sourcePath.isNotEmpty) {
      final source = File(sourcePath);
      if (await source.exists()) {
        await source.copy(target);
        return target;
      }
    }

    final bytes = await image.readAsBytes();
    final file = File(target);
    await file.writeAsBytes(bytes, flush: true);
    return target;
  }

  static Future<String> saveLegacyBase64Image({
    required String encoded,
    required String recipeId,
    required String slot,
  }) async {
    final bytes = base64Decode(encoded);
    return saveBytesImage(bytes: bytes, recipeId: recipeId, slot: slot);
  }

  static Future<String> saveBytesImage({
    required Uint8List bytes,
    required String recipeId,
    required String slot,
  }) async {
    final target = await _targetFilePath(recipeId: recipeId, slot: slot);
    final file = File(target);
    await file.writeAsBytes(bytes, flush: true);
    return target;
  }

  static Future<Map<String, dynamic>> migrateLegacyImageFields(
    Map<String, dynamic> source,
  ) async {
    final migrated = Map<String, dynamic>.from(source);
    final recipeId = (migrated['id'] ?? 'recipe').toString();

    final existingCoverPath = (migrated['coverImageFilePath'] ?? '')
        .toString()
        .trim();
    final hasCoverPath = existingCoverPath.isNotEmpty;

    if (!hasCoverPath && migrated['coverImageBytes'] != null) {
      final encoded = migrated['coverImageBytes'].toString();
      if (encoded.isNotEmpty) {
        migrated['coverImageFilePath'] = await saveLegacyBase64Image(
          encoded: encoded,
          recipeId: recipeId,
          slot: 'cover',
        );
      }
    }

    final rawPaths = migrated['cookedImageGalleryPaths'];
    final existingPaths = rawPaths is List
        ? rawPaths
              .map((e) => e?.toString() ?? '')
              .where((path) => path.isNotEmpty)
              .take(10)
              .toList(growable: false)
        : const <String>[];

    if (existingPaths.isNotEmpty) {
      migrated['cookedImageGalleryPaths'] = existingPaths;
    } else {
      final rawLegacy = migrated['cookedImageGalleryBytes'];
      if (rawLegacy is List) {
        final List<String> migratedPaths = [];
        var index = 0;
        for (final item in rawLegacy) {
          final encoded = item?.toString() ?? '';
          if (encoded.isEmpty) continue;
          final path = await saveLegacyBase64Image(
            encoded: encoded,
            recipeId: recipeId,
            slot: 'cooked_$index',
          );
          migratedPaths.add(path);
          index += 1;
          if (migratedPaths.length >= 10) break;
        }
        migrated['cookedImageGalleryPaths'] = migratedPaths;
      }
    }

    // Keep migrated payload compact in shared prefs.
    migrated.remove('coverImageBytes');
    migrated.remove('cookedImageGalleryBytes');

    return migrated;
  }

  static Future<String> _targetFilePath({
    required String recipeId,
    required String slot,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final safeId = _sanitize(recipeId);
    final safeSlot = _sanitize(slot);
    final imagesDir = Directory(
      '${root.path}${Platform.pathSeparator}recipe_images${Platform.pathSeparator}$safeId',
    );
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '${imagesDir.path}${Platform.pathSeparator}${safeSlot}_$stamp.jpg';
  }

  static String _sanitize(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return cleaned.isEmpty ? 'item' : cleaned;
  }
}
