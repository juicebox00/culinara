import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:culinara/models/recipe.dart';
import 'package:culinara/services/background_music_service.dart';
import 'package:culinara/services/draft_service.dart';
import 'package:culinara/services/recipe_store_service.dart';
import 'package:culinara/services/ui_sound_service.dart';
import 'package:file_picker/file_picker.dart';

class DataManagementService {
  static Future<String?> exportData() async {
    final recipes = await RecipeStoreService.loadRecipes();
    final drafts = await DraftService.getAllDrafts();
    await BackgroundMusicService.instance.init();
    await UiSoundService.instance.init();

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'recipes': recipes
          .map((recipe) => recipe.toMap())
          .toList(growable: false),
      'drafts': drafts.map((draft) => draft.toMap()).toList(growable: false),
      'settings': {
        'musicEnabled': BackgroundMusicService.instance.isEnabled,
        'musicVolume': BackgroundMusicService.instance.volume,
        'sfxEnabled': UiSoundService.instance.isEnabled,
      },
    };

    final bytes = Uint8List.fromList(
      const Utf8Encoder().convert(
        const JsonEncoder.withIndent('  ').convert(payload),
      ),
    );

    final suggestedName =
        'culinara_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Culinara Data',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: const ['json'],
      bytes: bytes,
    );

    if (savePath == null || savePath.isEmpty) {
      return null;
    }

    final file = File(savePath);
    if (!await file.exists()) {
      await file.writeAsBytes(bytes, flush: true);
    }

    return savePath;
  }

  static Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw 'No backup file selected.';
    }

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null || bytes.isEmpty) {
      throw 'Selected file is empty.';
    }

    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw 'Invalid backup format.';
    }

    final root = Map<String, dynamic>.from(decoded);
    final rawRecipes = root['recipes'];
    final rawDrafts = root['drafts'];
    final rawSettings = root['settings'];

    if (rawRecipes is! List || rawDrafts is! List) {
      throw 'Backup file is missing required data.';
    }

    final recipes = rawRecipes
        .map((item) => Recipe.fromMap(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);

    final drafts = rawDrafts
        .map(
          (item) => RecipeDraft.fromMap(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);

    await RecipeStoreService.saveRecipes(recipes);
    await DraftService.replaceAllDrafts(drafts);

    if (rawSettings is Map) {
      final settings = Map<String, dynamic>.from(rawSettings);
      final musicEnabled = settings['musicEnabled'];
      final musicVolume = settings['musicVolume'];
      final sfxEnabled = settings['sfxEnabled'];

      await BackgroundMusicService.instance.init();
      if (musicEnabled is bool) {
        await BackgroundMusicService.instance.setEnabled(musicEnabled);
      }
      if (musicVolume is num) {
        await BackgroundMusicService.instance.setVolume(
          musicVolume.toDouble().clamp(0.0, 1.0),
        );
      }

      await UiSoundService.instance.init();
      if (sfxEnabled is bool) {
        await UiSoundService.instance.setEnabled(sfxEnabled);
      }
    }
  }
}
