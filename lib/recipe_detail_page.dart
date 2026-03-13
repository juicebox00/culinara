import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/models/recipe.dart';
import 'package:culinara/screens/home/add_recipe_page.dart';
import 'package:culinara/services/recipe_image_store_service.dart';
import 'package:culinara/services/recipe_pdf_service.dart';
import 'package:culinara/services/ui_sound_service.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';
import 'package:image_picker/image_picker.dart';

class RecipeDetailPage extends StatefulWidget {
  final Recipe recipe;
  final Function(Recipe) onPin;
  final Function(Recipe) onDelete;
  final Function(Recipe) onUpdate;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
    required this.onPin,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  static const int _maxCookedPhotos = 10;
  static final RegExp _timerTokenRegex = RegExp(r'\s*\[\[t=(\d+)\]\]\s*$');
  static final RegExp _inlineTimeRegex = RegExp(
    r'(\d+)\s*(hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)\b',
    caseSensitive: false,
  );

  late Recipe recipe;
  final ImagePicker _imagePicker = ImagePicker();

  List<String> _splitSteps(String raw) {
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(
          (line) => line.replaceFirst(RegExp(r'^\d+\s*[\.)\-]\s+'), '').trim(),
        )
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

  List<_CookModeStepData> _parseCookSteps(String rawDirections) {
    final rawSteps = _splitSteps(rawDirections);
    return rawSteps
        .map((step) {
          final tokenMatch = _timerTokenRegex.firstMatch(step);
          final tokenSeconds = tokenMatch == null
              ? null
              : int.tryParse(tokenMatch.group(1) ?? '');
          final cleanedStep = step.replaceFirst(_timerTokenRegex, '').trim();
          final fallbackSeconds = _extractInlineDurationSeconds(cleanedStep);
          final seconds = tokenSeconds != null && tokenSeconds > 0
              ? tokenSeconds
              : fallbackSeconds;

          return _CookModeStepData(
            text: cleanedStep,
            durationSeconds: seconds != null && seconds > 0 ? seconds : null,
          );
        })
        .toList(growable: false);
  }

  int? _extractInlineDurationSeconds(String text) {
    var total = 0;
    for (final match in _inlineTimeRegex.allMatches(text)) {
      final value = int.tryParse(match.group(1) ?? '') ?? 0;
      final unit = (match.group(2) ?? '').toLowerCase();

      if (value <= 0) continue;
      if (unit.startsWith('h')) {
        total += value * 3600;
      } else if (unit.startsWith('m')) {
        total += value * 60;
      } else if (unit.startsWith('s')) {
        total += value;
      }
    }
    return total <= 0 ? null : total;
  }

  String _directionsForDisplay() {
    final parsed = _parseCookSteps(recipe.directions);
    if (parsed.isEmpty) return recipe.directions;

    final lines = parsed
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final step = entry.value;
          if (step.durationSeconds == null) {
            return '${index + 1}. ${step.text}';
          }
          return '${index + 1}. ${step.text} (${_formatDuration(step.durationSeconds!)})';
        })
        .toList(growable: false);

    return lines.join('\n');
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  ImageProvider<Object> get _coverImage {
    if (recipe.coverImageFilePath != null &&
        recipe.coverImageFilePath!.trim().isNotEmpty) {
      return FileImage(File(recipe.coverImageFilePath!));
    }
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
            child: PressBounce(
              child: const StrokedButtonLabel(
                'Cancel',
                fillColor: Color(0xFF5D4A3A),
                strokeColor: Color(0xFFFFFFFF),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete(recipe);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: PressBounce(
              child: const StrokedButtonLabel(
                'Delete',
                fillColor: Colors.red,
                strokeColor: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editRecipe() async {
    final updated = await Navigator.push<Recipe>(
      context,
      MaterialPageRoute(builder: (_) => AddRecipePage(editingRecipe: recipe)),
    );

    if (updated == null || !mounted) return;

    setState(() {
      recipe = updated;
    });
    widget.onUpdate(updated);
  }

  Future<void> _exportToPdf() async {
    await RecipePdfService.exportRecipeToPdf(recipe);
  }

  void _updateRecipe(Recipe updated) {
    setState(() {
      recipe = updated;
    });
    widget.onUpdate(updated);
  }

  void _saveCookedGallery(List<String> galleryPaths) {
    final capped = galleryPaths.take(_maxCookedPhotos).toList(growable: false);
    _updateRecipe(recipe.copyWith(cookedImageGalleryPaths: capped));
  }

  Future<void> _addCookedPhotos() async {
    final remaining = _maxCookedPhotos - recipe.cookedImageGalleryPaths.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This recipe already has the maximum of 10 photos.',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final picked = await _imagePicker.pickMultiImage(
      maxWidth: RecipeImageStoreService.maxDimension,
      maxHeight: RecipeImageStoreService.maxDimension,
      imageQuality: RecipeImageStoreService.imageQuality,
    );
    if (picked.isEmpty) return;

    final allowed = picked.take(remaining).toList(growable: false);
    final List<String> addedPaths = [];
    var index = 0;
    for (final image in allowed) {
      final path = await RecipeImageStoreService.savePickedImage(
        image: image,
        recipeId: recipe.id,
        slot: 'cooked_${DateTime.now().millisecondsSinceEpoch}_$index',
      );
      addedPaths.add(path);
      index += 1;
    }

    if (!mounted || addedPaths.isEmpty) return;

    _saveCookedGallery([...recipe.cookedImageGalleryPaths, ...addedPaths]);

    if (picked.length > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Only $remaining photo(s) were added to keep the 10-photo limit.',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Future<void> _replaceCookedPhoto(int index) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: RecipeImageStoreService.maxDimension,
      maxHeight: RecipeImageStoreService.maxDimension,
      imageQuality: RecipeImageStoreService.imageQuality,
    );
    if (picked == null) return;

    final savedPath = await RecipeImageStoreService.savePickedImage(
      image: picked,
      recipeId: recipe.id,
      slot: 'cooked_replace_$index',
    );
    if (!mounted) return;

    final updated = recipe.cookedImageGalleryPaths.toList(growable: true);
    if (index < 0 || index >= updated.length) return;
    updated[index] = savedPath;
    _saveCookedGallery(updated);
  }

  void _deleteCookedPhoto(int index) {
    final updated = recipe.cookedImageGalleryPaths.toList(growable: true);
    if (index < 0 || index >= updated.length) return;
    updated.removeAt(index);
    _saveCookedGallery(updated);
  }

  Future<void> _uploadSingleCookedPhoto() async {
    final remaining = _maxCookedPhotos - recipe.cookedImageGalleryPaths.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This recipe already has the maximum of 10 photos.',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: RecipeImageStoreService.maxDimension,
      maxHeight: RecipeImageStoreService.maxDimension,
      imageQuality: RecipeImageStoreService.imageQuality,
    );
    if (picked == null) return;

    final savedPath = await RecipeImageStoreService.savePickedImage(
      image: picked,
      recipeId: recipe.id,
      slot: 'cooked_single',
    );
    if (!mounted) return;

    _saveCookedGallery([...recipe.cookedImageGalleryPaths, savedPath]);
  }

  Future<void> _promptUploadAfterCookMode() async {
    final shouldUpload = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6D3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Show Off Your Dish?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          'Cook mode is done. Do you want to upload a photo of your creation now?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: PressBounce(
              child: const StrokedButtonLabel(
                'Later',
                fillColor: Color(0xFF5D4A3A),
                strokeColor: Color(0xFFFFFFFF),
              ),
            ),
          ),
          PressBounce(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5E3C),
                foregroundColor: Colors.white,
              ),
              child: const StrokedButtonLabel('Upload Photo'),
            ),
          ),
        ],
      ),
    );

    if (shouldUpload == true && mounted) {
      await _uploadSingleCookedPhoto();
    }
  }

  Future<void> _viewCookedPhoto(int initialIndex) async {
    final photos = recipe.cookedImageGalleryPaths;
    if (photos.isEmpty || initialIndex < 0 || initialIndex >= photos.length) {
      return;
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _CookedGalleryViewerPage(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _showCookedPhotoOptions(int index) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5E6D3),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text(
                'View',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _viewCookedPhoto(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(
                'Replace',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _replaceCookedPhoto(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFF9C2D2D)),
              title: Text(
                'Delete',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9C2D2D),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteCookedPhoto(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookedPhotoGallerySection() {
    final photos = recipe.cookedImageGalleryPaths;
    final canAddMore = photos.length < _maxCookedPhotos;
    final itemCount = canAddMore ? photos.length + 1 : photos.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Cooked Photos (${photos.length}/$_maxCookedPhotos)',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
            ),
            PressBounce(
              enabled: canAddMore,
              child: OutlinedButton.icon(
                onPressed: canAddMore ? _addCookedPhotos : null,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const StrokedButtonLabel(
                  'Add Photos',
                  fillColor: Color(0xFF5D4A3A),
                  strokeColor: Color(0xFFFFFFFF),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide.none,
                  foregroundColor: const Color(0xFF5D4A3A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index >= photos.length) {
              return TapBounce(
                onTap: _addCookedPhotos,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF8B6F47),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate,
                    color: Color(0xFF8B6F47),
                    size: 34,
                  ),
                ),
              );
            }

            final photoPath = photos[index];
            return TapBounce(
              onTap: () => _showCookedPhotoOptions(index),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF5E6D3),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF8B6F47),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.more_horiz,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _openCookMode() async {
    final ingredients = _splitSteps(recipe.ingredients);
    final steps = _parseCookSteps(recipe.directions);

    if (steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add direction steps first before starting Cook Mode.',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF5E6D3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
          ),
          title: Text(
            'Ready to Cook?',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do you have all the ingredients?',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (ingredients.isEmpty)
                    Text(
                      'No ingredient list was provided for this recipe.',
                      style: GoogleFonts.fredoka(
                        color: const Color(0xFF5D4A3A),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    ...ingredients.map(
                      (ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $ingredient',
                          style: GoogleFonts.fredoka(
                            color: const Color(0xFF5D4A3A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: PressBounce(
                child: const StrokedButtonLabel(
                  'Not Yet',
                  fillColor: Color(0xFF5D4A3A),
                  strokeColor: Color(0xFFFFFFFF),
                ),
              ),
            ),
            PressBounce(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E3C),
                  foregroundColor: Colors.white,
                ),
                child: const StrokedButtonLabel('I Have Everything'),
              ),
            ),
          ],
        );
      },
    );

    if (proceed != true || !mounted) return;

    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _CookModePage(recipeTitle: recipe.title, directionSteps: steps),
      ),
    );

    if (completed == true && mounted) {
      _updateRecipe(recipe.copyWith(cooked: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cook Mode completed. Great job!',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        ),
      );
      await _promptUploadAfterCookMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StrokedButtonLabel(
          recipe.title,
          fillColor: Colors.white,
          strokeColor: const Color(0xFF5D4A3A),
          fontSize: 20,
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
                  PressBounce(
                    child: ElevatedButton.icon(
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
                  ),

                  const SizedBox(height: 12),

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
                  _buildDetailSection('Directions', _directionsForDisplay()),
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

                  const SizedBox(height: 16),
                  _buildCookedPhotoGallerySection(),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: PressBounce(
                      child: ElevatedButton.icon(
                        onPressed: _openCookMode,
                        icon: const Icon(Icons.soup_kitchen),
                        label: const StrokedButtonLabel('Start Cook Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB96E3A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Edit and Delete Buttons
                  Row(
                    children: [
                      Expanded(
                        child: PressBounce(
                          child: ElevatedButton.icon(
                            onPressed: _editRecipe,
                            icon: Icon(Icons.edit),
                            label: const StrokedButtonLabel('Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF8B5E3C),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PressBounce(
                          child: ElevatedButton(
                            onPressed: _exportToPdf,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7E5630),
                              foregroundColor: Colors.white,
                            ),
                            child: const StrokedButtonLabel('Export PDF'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PressBounce(
                          child: ElevatedButton.icon(
                            onPressed: _deleteRecipe,
                            icon: Icon(Icons.delete),
                            label: const StrokedButtonLabel('Delete'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
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

class _CookModePage extends StatefulWidget {
  const _CookModePage({
    required this.recipeTitle,
    required this.directionSteps,
  });

  final String recipeTitle;
  final List<_CookModeStepData> directionSteps;

  @override
  State<_CookModePage> createState() => _CookModePageState();
}

class _CookModePageState extends State<_CookModePage> {
  Timer? _timer;
  final AudioPlayer _runningSfxPlayer = AudioPlayer();
  final AudioPlayer _alarmSfxPlayer = AudioPlayer();
  int _stepIndex = 0;
  int _selectedSeconds = 0;
  int _remainingSeconds = 0;
  bool _isTimerRunning = false;
  bool _allowExitWithoutPrompt = false;

  @override
  void initState() {
    super.initState();
    _syncTimerForCurrentStep(notify: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _runningSfxPlayer.dispose();
    _alarmSfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRunningSfx() async {
    try {
      await _runningSfxPlayer.setReleaseMode(ReleaseMode.loop);
      await _runningSfxPlayer.setVolume(0.5); // Set volume to 50%
      await _runningSfxPlayer.stop();
      debugPrint('Attempting to play timer sound');
      
      // AssetSource automatically looks in assets/ folder
      await _runningSfxPlayer.play(AssetSource('sounds/timer.wav'));
      debugPrint('Timer sound started successfully');
    } catch (e) {
      debugPrint('Error playing timer sound: $e');
      // SFX should not interrupt cook mode.
    }
  }

  Future<void> _stopRunningSfx() async {
    try {
      await _runningSfxPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping timer sound: $e');
      // Best effort cleanup.
    }
  }

  Future<void> _playTimerDoneSfx() async {
    try {
      await _alarmSfxPlayer.setReleaseMode(ReleaseMode.stop);
      await _alarmSfxPlayer.setVolume(0.8); // Set alarm volume to 80%
      await _alarmSfxPlayer.stop();
      
      // Add extra delay to ensure stop completes
      await Future.delayed(const Duration(milliseconds: 100));
      
      debugPrint('Attempting to play alarm sound');
      
      // AssetSource automatically looks in assets/ folder
      await _alarmSfxPlayer.play(AssetSource('sounds/alarm.wav'));
      debugPrint('Alarm sound played successfully');
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
      // SFX should not interrupt cook mode.
    }
  }

  bool get _isLastStep => _stepIndex >= widget.directionSteps.length - 1;

  bool get _currentStepHasTimer =>
      (widget.directionSteps[_stepIndex].durationSeconds ?? 0) > 0;

  bool get _hasTimerInProgress {
    if (!_currentStepHasTimer) return false;
    if (_isTimerRunning) return true;

    final hasStarted =
        _selectedSeconds > 0 && _remainingSeconds < _selectedSeconds;
    final stillRemaining = _remainingSeconds > 0;
    return hasStarted && stillRemaining;
  }

  void _syncTimerForCurrentStep({bool notify = true}) {
    _timer?.cancel();
    _stopRunningSfx();
    final seconds = widget.directionSteps[_stepIndex].durationSeconds ?? 0;
    final update = () {
      _isTimerRunning = false;
      _selectedSeconds = seconds;
      _remainingSeconds = seconds;
    };

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startTimer() {
    if (_isTimerRunning || _remainingSeconds <= 0) return;

    setState(() {
      _isTimerRunning = true;
    });
    _startRunningSfx();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        _stopRunningSfx();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        _stopRunningSfx();
        setState(() {
          _remainingSeconds = 0;
          _isTimerRunning = false;
        });
        
        // Play alarm sound immediately, don't wait for context
        _playTimerDoneSfx();
        
        // Show snackbar after a brief delay to ensure state is updated
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Step ${_stepIndex + 1} timer finished.',
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
        });
        return;
      }

      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _stopRunningSfx();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _stopRunningSfx();
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = _selectedSeconds;
    });
  }



  void _goNext() {
    _handleNext();
  }

  void _goPrevious() {
    _handlePrevious();
  }

  Future<void> _handleNext() async {
    if (_isLastStep) {
      final canFinish = await _confirmFinishCookModeIfNeeded();
      if (!canFinish || !mounted) return;

      _timer?.cancel();
      _stopRunningSfx();
      _allowExitWithoutPrompt = true;
      Navigator.pop(context, true);
      return;
    }

    final canAdvance = await _confirmStepChangeIfNeeded('next');
    if (!canAdvance || !mounted) return;

    _timer?.cancel();
    _stopRunningSfx();
    setState(() {
      _stepIndex += 1;
      _isTimerRunning = false;
    });
    _syncTimerForCurrentStep();
  }

  Future<void> _handlePrevious() async {
    if (_stepIndex == 0) return;

    final canGoBack = await _confirmStepChangeIfNeeded('previous');
    if (!canGoBack || !mounted) return;

    _timer?.cancel();
    _stopRunningSfx();
    setState(() {
      _stepIndex -= 1;
      _isTimerRunning = false;
    });
    _syncTimerForCurrentStep();
  }

  Future<bool> _confirmFinishCookModeIfNeeded() async {
    if (!_currentStepHasTimer) return true;

    final timerRunning = _isTimerRunning;
    final timerHasRemaining = _remainingSeconds > 0;
    if (!timerRunning && !timerHasRemaining) return true;

    final message = timerRunning
        ? 'The step timer is still running. Finish Cook Mode anyway?'
        : 'This timed step still has time remaining. Finish Cook Mode anyway?';

    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6D3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Finish Cook Mode?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              UiSoundService.instance.playButtonBeep();
              Navigator.pop(context, false);
            },
            child: const StrokedButtonLabel(
              'Keep Cooking',
              fillColor: Color(0xFF5D4A3A),
              strokeColor: Color(0xFFFFFFFF),
            ),
          ),
          TextButton(
            onPressed: () {
              UiSoundService.instance.playButtonBeep();
              Navigator.pop(context, true);
            },
            child: const StrokedButtonLabel(
              'Finish',
              fillColor: Color(0xFF9C2D2D),
              strokeColor: Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );

    return shouldFinish == true;
  }

  Future<bool> _confirmStepChangeIfNeeded(String direction) async {
    if (!_hasTimerInProgress) return true;

    final shouldMove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6D3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Move to ${direction == 'next' ? 'Next' : 'Previous'} Step?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          _isTimerRunning
              ? 'The timer is currently running for this step. Continue anyway?'
              : 'This step timer is not finished yet. Continue anyway?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              UiSoundService.instance.playButtonBeep();
              Navigator.pop(context, false);
            },
            child: const StrokedButtonLabel(
              'Stay',
              fillColor: Color(0xFF5D4A3A),
              strokeColor: Color(0xFFFFFFFF),
            ),
          ),
          TextButton(
            onPressed: () {
              UiSoundService.instance.playButtonBeep();
              Navigator.pop(context, true);
            },
            child: const StrokedButtonLabel(
              'Continue',
              fillColor: Color(0xFF9C2D2D),
              strokeColor: Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );

    return shouldMove == true;
  }

  Future<bool> _confirmExitCookMode() async {
    if (_allowExitWithoutPrompt) return true;

    final hasActiveTimer = _isTimerRunning;
    final hasRemainingTimer = _currentStepHasTimer && _remainingSeconds > 0;

    final message = hasActiveTimer
        ? 'A step timer is still running. Are you sure you want to leave Cook Mode?'
        : (hasRemainingTimer
              ? 'This step still has time remaining. Are you sure you want to leave Cook Mode?'
              : 'Are you sure you want to leave Cook Mode?');

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6D3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Leave Cook Mode?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              UiSoundService.instance.playButtonBeep();
              Navigator.pop(context, false);
            },
            child: const StrokedButtonLabel(
              'Stay',
              fillColor: Color(0xFF5D4A3A),
              strokeColor: Color(0xFFFFFFFF),
            ),
          ),
          TextButton(
            onPressed: () {
              UiSoundService.instance.playButtonBeep();
              Navigator.pop(context, true);
            },
            child: const StrokedButtonLabel(
              'Leave',
              fillColor: Color(0xFF9C2D2D),
              strokeColor: Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave == true) {
      _timer?.cancel();
      _stopRunningSfx();
      _isTimerRunning = false;
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.directionSteps[_stepIndex];

    return WillPopScope(
      onWillPop: _confirmExitCookMode,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              UiSoundService.instance.playButtonBeep();
              final shouldLeave = await _confirmExitCookMode();
              if (!shouldLeave || !mounted) return;
              Navigator.pop(context, false);
            },
          ),
          backgroundColor: const Color(0xFFC9975C),
          title: const StrokedButtonLabel(
            'Cook Mode',
            fillColor: Colors.white,
            strokeColor: Color(0xFF5D4A3A),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.recipeTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${_stepIndex + 1} of ${widget.directionSteps.length}',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8B6F47),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF8B6F47),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      currentStep.text,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4A3A),
                      ),
                    ),
                  ),
                ),
              ),
              if (_currentStepHasTimer) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6D3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B6F47),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatTime(_remainingSeconds),
                        style: GoogleFonts.fredoka(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4A3A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isTimerRunning ? 'Running...' : 'Ready',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B6F47),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: PressBounce(
                              child: ElevatedButton.icon(
                                onPressed: _isTimerRunning
                                    ? _pauseTimer
                                    : _startTimer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF8B5E3C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: Icon(
                                  _isTimerRunning
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                label: StrokedButtonLabel(
                                  _isTimerRunning ? 'Pause' : 'Start',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PressBounce(
                              child: OutlinedButton.icon(
                                onPressed: _resetTimer,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide.none,
                                  foregroundColor: const Color(0xFF5D4A3A),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.restart_alt),
                                label: const StrokedButtonLabel(
                                  'Reset',
                                  fillColor: Color(0xFF5D4A3A),
                                  strokeColor: Color(0xFFF8EFE3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PressBounce(
                      enabled: _stepIndex != 0,
                      child: OutlinedButton(
                        onPressed: _stepIndex == 0 ? null : _goPrevious,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide.none,
                          foregroundColor: const Color(0xFF5D4A3A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const StrokedButtonLabel(
                          'Previous',
                          fillColor: Color(0xFF5D4A3A),
                          strokeColor: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressBounce(
                      child: ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5E3C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: StrokedButtonLabel(
                          _isLastStep ? 'Finish' : 'Next Step',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CookModeStepData {
  const _CookModeStepData({required this.text, this.durationSeconds});

  final String text;
  final int? durationSeconds;
}

class _CookedGalleryViewerPage extends StatefulWidget {
  const _CookedGalleryViewerPage({
    required this.photos,
    required this.initialIndex,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<_CookedGalleryViewerPage> createState() =>
      _CookedGalleryViewerPageState();
}

class _CookedGalleryViewerPageState extends State<_CookedGalleryViewerPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: StrokedButtonLabel(
          'Photo ${_currentIndex + 1} of ${widget.photos.length}',
          fillColor: Colors.white,
          strokeColor: const Color(0xFF5D4A3A),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final photoPath = widget.photos[index];
          return InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image.file(
                File(photoPath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
