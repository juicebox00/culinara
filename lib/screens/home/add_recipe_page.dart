import 'dart:async';
import 'dart:io';

import 'package:culinara/models/recipe.dart';
import 'package:culinara/services/draft_service.dart';
import 'package:culinara/services/recipe_image_store_service.dart';
import 'package:culinara/services/ui_sound_service.dart';
import 'package:culinara/widgets/gingham_pattern_background.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({
    super.key,
    this.editingRecipe,
    this.draftKeyOverride,
    this.suggestedShelves = const [],
  });

  final Recipe? editingRecipe;
  final String? draftKeyOverride;
  final List<String> suggestedShelves;

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  static final RegExp _timerTokenRegex = RegExp(
    r'\s*\[\[t=(\d{2}):(\d{2})\]\]\s*$',
  );
  static final RegExp _legacyDirectionPrefixRegex = RegExp(
    r'^Direction\s*Step\s*\d+\s*:\s*',
    caseSensitive: false,
  );
  static final RegExp _sectionHeaderRegex = RegExp(
    r'^([A-Za-z ]{2,30})\s*:\s*(.*)$',
  );
  static final RegExp _bulletPrefixRegex = RegExp(
    r'^(?:[-*•]\s+|\d+[\).:-]\s*)',
  );
  static const Map<String, List<String>> _templateAliases = {
    'title': ['title', 'recipe', 'name'],
    'servings': ['servings', 'units', 'serving size', 'yield'],
    'ingredients': ['ingredients', 'ingredient', 'what you need'],
    'directions': [
      'directions',
      'direction',
      'steps',
      'instructions',
      'method',
    ],
    'tags': ['tags', 'tag'],
    'cooking_time': ['cooking time', 'time', 'total time'],
  };
  static const List<String> _servingSizeUnits = [
    'Servings',
    'Bowls',
    'Cups',
    'Pieces',
    'Portions',
  ];
  static const int _maxShelfCount = 10;
  static const int _maxShelvesPerRecipe = 3;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _directionsController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  final _notesController = TextEditingController();
  final _shelfNameController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final _servingSizeNumberController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _tagsController = TextEditingController();
  final List<String> _availableShelves = [];
  final Set<String> _selectedShelves = <String>{};

  final _imagePicker = ImagePicker();
  String? _coverImagePath;
  Uint8List? _legacyCoverImageBytes;
  bool _isSaving = false;
  bool _showStepValidationErrors = false;
  Timer? _autosaveDebounce;
  String? _editingRecipeId;
  String _selectedServingUnit = 'Servings';
  int _cookingHours = 0;
  int _cookingMinutes = 0;
  int _cookingSeconds = 0;
  late FixedExtentScrollController _cookingHoursController;
  late FixedExtentScrollController _cookingMinutesController;
  late FixedExtentScrollController _cookingSecondsController;
  final List<TextEditingController> _ingredientStepControllers = [];
  final List<TextEditingController> _directionStepControllers = [];
  final List<int?> _directionStepDurations = [];
  bool _isHandlingExit = false;

  bool get _isEditMode => widget.editingRecipe != null;

  String get _draftKey =>
      widget.draftKeyOverride ??
      (() {
        final editingRecipe = widget.editingRecipe;
        if (editingRecipe != null) {
          return DraftService.editDraftKey(editingRecipe.id);
        }
        return DraftService.addDraftKey();
      })();

  String get _draftMode => _isEditMode ? 'edit' : 'add';

  Recipe? get _baseRecipe => widget.editingRecipe;

  @override
  void initState() {
    super.initState();

    _availableShelves.addAll(
      widget.suggestedShelves
          .map(_normalizeShelfName)
          .where((name) => name.isNotEmpty),
    );
    _dedupeAndSortShelves();

    _cookingHoursController = FixedExtentScrollController(
      initialItem: _cookingHours,
    );
    _cookingMinutesController = FixedExtentScrollController(
      initialItem: _cookingMinutes,
    );
    _cookingSecondsController = FixedExtentScrollController(
      initialItem: _cookingSeconds,
    );

    if (_isEditMode) {
      final base = widget.editingRecipe!;
      _editingRecipeId = base.id;
      _titleController.text = base.title;
      _ingredientsController.text = base.ingredients;
      _directionsController.text = base.directions;
      _sourceUrlController.text = base.sourceUrl;
      _notesController.text = base.notes;
      _selectedShelves
        ..clear()
        ..addAll(
          base.shelves.map(_normalizeShelfName).where((s) => s.isNotEmpty),
        );
      _availableShelves.addAll(_selectedShelves);
      _dedupeAndSortShelves();
      _parseServingSize(base.servingSize);
      _parseCookingTime(base.cookingTime);
      _tagsController.text = base.tags.join(', ');
      _coverImagePath = base.coverImageFilePath;
      _legacyCoverImageBytes = base.coverImageBytes;

      _updateCookingTimeControllers();
    }

    _setStepControllersFromText();

    for (final controller in <TextEditingController>[
      _titleController,
      _ingredientsController,
      _directionsController,
      _sourceUrlController,
      _notesController,
      _servingSizeNumberController,
      _tagsController,
    ]) {
      controller.addListener(_onDraftInputChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForExistingDraft();
    });
  }

  void _parseServingSize(String servingSize) {
    if (servingSize.isEmpty) {
      _servingSizeNumberController.text = '';
      _selectedServingUnit = 'Servings';
      return;
    }

    final parts = servingSize.trim().split(RegExp(r'\s+'));
    if (parts.isNotEmpty && int.tryParse(parts[0]) != null) {
      _servingSizeNumberController.text = parts[0];
      if (parts.length > 1) {
        final unit = parts.sublist(1).join(' ');
        if (_servingSizeUnits.contains(unit)) {
          _selectedServingUnit = unit;
        } else {
          _selectedServingUnit = 'Servings';
        }
      } else {
        // No unit provided, default to Servings
        _selectedServingUnit = 'Servings';
      }
    } else {
      _servingSizeNumberController.text = servingSize;
      _selectedServingUnit = 'Servings';
    }
  }

  void _parseCookingTime(String cookingTime) {
    if (cookingTime.isEmpty) {
      _cookingHours = 0;
      _cookingMinutes = 0;
      _cookingSeconds = 0;
      return;
    }

    final parts = cookingTime.split(':');
    if (parts.isNotEmpty) {
      _cookingHours = int.tryParse(parts[0]) ?? 0;
    }
    if (parts.length >= 2) {
      _cookingMinutes = int.tryParse(parts[1]) ?? 0;
    }
    if (parts.length >= 3) {
      _cookingSeconds = int.tryParse(parts[2]) ?? 0;
    }

    _updateCookingTimeControllers();
  }

  void _updateCookingTimeControllers() {
    if (_cookingHours >= 0 && _cookingHours < 24) {
      _cookingHoursController.jumpToItem(_cookingHours);
    }
    if (_cookingMinutes >= 0 && _cookingMinutes < 60) {
      _cookingMinutesController.jumpToItem(_cookingMinutes);
    }
    if (_cookingSeconds >= 0 && _cookingSeconds < 60) {
      _cookingSecondsController.jumpToItem(_cookingSeconds);
    }
  }

  String _buildCookingTime() {
    return '${_cookingHours.toString().padLeft(2, '0')}:${_cookingMinutes.toString().padLeft(2, '0')}:${_cookingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();

    for (final controller in <TextEditingController>[
      _titleController,
      _ingredientsController,
      _directionsController,
      _sourceUrlController,
      _notesController,
      _servingSizeNumberController,
      _cookingTimeController,
      _tagsController,
    ]) {
      controller.removeListener(_onDraftInputChanged);
    }

    _titleController.dispose();
    _ingredientsController.dispose();
    _directionsController.dispose();
    _sourceUrlController.dispose();
    _notesController.dispose();
    _shelfNameController.dispose();
    _servingSizeNumberController.dispose();
    _cookingTimeController.dispose();
    _tagsController.dispose();
    _cookingHoursController.dispose();
    _cookingMinutesController.dispose();
    _cookingSecondsController.dispose();
    _disposeStepControllers(_ingredientStepControllers);
    _disposeStepControllers(_directionStepControllers);
    super.dispose();
  }

  List<String> _splitSteps(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map(
          (line) => line.replaceFirst(RegExp(r'^\d+\s*[\.)\-]\s+'), '').trim(),
        )
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    return lines;
  }

  void _disposeStepControllers(List<TextEditingController> controllers) {
    for (final controller in controllers) {
      controller.removeListener(_onDraftInputChanged);
      controller.dispose();
    }
    controllers.clear();
  }

  void _initStepControllers(
    List<TextEditingController> target,
    List<String> steps,
  ) {
    _disposeStepControllers(target);
    final normalized = steps.where((step) => step.trim().isNotEmpty).toList();
    if (normalized.isEmpty) {
      final empty = TextEditingController();
      empty.addListener(_onDraftInputChanged);
      target.add(empty);
      return;
    }

    for (final step in normalized) {
      final controller = TextEditingController(text: step);
      controller.addListener(_onDraftInputChanged);
      target.add(controller);
    }
  }

  void _setStepControllersFromText() {
    _initStepControllers(
      _ingredientStepControllers,
      _splitSteps(_ingredientsController.text),
    );

    _disposeStepControllers(_directionStepControllers);
    _directionStepDurations.clear();
    final directionSteps = _splitSteps(_directionsController.text);
    if (directionSteps.isEmpty) {
      final empty = TextEditingController();
      empty.addListener(_onDraftInputChanged);
      _directionStepControllers.add(empty);
      _directionStepDurations.add(null);
    } else {
      for (final rawStep in directionSteps) {
        final parsed = _extractTimerToken(rawStep);
        final controller = TextEditingController(text: parsed.$1);
        controller.addListener(_onDraftInputChanged);
        _directionStepControllers.add(controller);
        _directionStepDurations.add(parsed.$2);
      }
    }

    _syncStepTextToControllers();
  }

  List<String> _cleanStepList(List<TextEditingController> controllers) {
    return controllers
        .map((controller) => controller.text.trim())
        .where((step) => step.isNotEmpty)
        .toList(growable: false);
  }

  void _syncStepTextToControllers() {
    _ingredientsController.text = _cleanStepList(
      _ingredientStepControllers,
    ).join('\n');

    final List<String> serializedDirectionSteps = [];
    for (var i = 0; i < _directionStepControllers.length; i++) {
      final text = _directionStepControllers[i].text.trim();
      if (text.isEmpty) continue;

      final durationSeconds = i < _directionStepDurations.length
          ? _directionStepDurations[i]
          : null;
      if (durationSeconds != null && durationSeconds > 0) {
        final minutes = durationSeconds ~/ 60;
        final seconds = durationSeconds % 60;
        final mmss =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        serializedDirectionSteps.add('$text [[t=$mmss]]');
      } else {
        serializedDirectionSteps.add(text);
      }
    }

    _directionsController.text = serializedDirectionSteps.join('\n');
  }

  void _addIngredientStep() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(_onDraftInputChanged);
      _ingredientStepControllers.add(controller);
    });
  }

  void _addDirectionStep() {
    setState(() {
      final controller = TextEditingController();
      controller.addListener(_onDraftInputChanged);
      _directionStepControllers.add(controller);
      _directionStepDurations.add(null);
    });
  }

  Future<void> _setDirectionStepTimer(int index) async {
    if (index < 0 || index >= _directionStepControllers.length) return;

    final existingSeconds = index < _directionStepDurations.length
        ? _directionStepDurations[index]
        : null;
    final pickedSeconds = await _showTimerPickerDialog(
      existingSeconds: existingSeconds,
    );
    if (pickedSeconds == null || !mounted) return;

    setState(() {
      _directionStepDurations[index] = pickedSeconds <= 0
          ? null
          : pickedSeconds;
      _syncStepTextToControllers();
    });
    _onDraftInputChanged();
  }

  void _clearDirectionStepTimer(int index) {
    if (index < 0 || index >= _directionStepDurations.length) return;

    setState(() {
      _directionStepDurations[index] = null;
      _syncStepTextToControllers();
    });
    _onDraftInputChanged();
  }

  Future<int?> _showTimerPickerDialog({int? existingSeconds}) async {
    int selectedHours = (existingSeconds ?? 0) ~/ 3600;
    int selectedMinutes = ((existingSeconds ?? 0) % 3600) ~/ 60;
    int selectedSeconds = (existingSeconds ?? 0) % 60;

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFFF5E6D3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
            ),
            title: Text(
              'Set Step Timer',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4A3A),
              ),
            ),
            content: SizedBox(
              width: 300,
              height: 200,
              child: Row(
                children: [
                  // Hours Picker
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Hours',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedHours,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (value) {
                              setDialogState(() => selectedHours = value);
                            },
                            children: List.generate(
                              100,
                              (i) => Center(
                                child: Text(
                                  i.toString().padLeft(2, '0'),
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5D4A3A),
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Minutes Picker
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Minutes',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedMinutes,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (value) {
                              setDialogState(() => selectedMinutes = value);
                            },
                            children: List.generate(
                              60,
                              (i) => Center(
                                child: Text(
                                  i.toString().padLeft(2, '0'),
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5D4A3A),
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Seconds Picker
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Seconds',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedSeconds,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (value) {
                              setDialogState(() => selectedSeconds = value);
                            },
                            children: List.generate(
                              60,
                              (i) => Center(
                                child: Text(
                                  i.toString().padLeft(2, '0'),
                                  style: GoogleFonts.fredoka(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF5D4A3A),
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  UiSoundService.instance.playButtonBeep();
                  Navigator.pop(context);
                },
                child: const StrokedButtonLabel(
                  'Cancel',
                  fillColor: Color(0xFF5D4A3A),
                  strokeColor: Color(0xFFF5E6D3),
                ),
              ),
              TextButton(
                onPressed: () {
                  UiSoundService.instance.playButtonBeep();
                  Navigator.pop(context, 0);
                },
                child: const StrokedButtonLabel(
                  'Clear',
                  fillColor: Color(0xFF8B6F47),
                  strokeColor: Color(0xFFF5E6D3),
                ),
              ),
              TextButton(
                onPressed: () {
                  UiSoundService.instance.playButtonBeep();
                  final totalSeconds =
                      selectedHours * 3600 +
                      selectedMinutes * 60 +
                      selectedSeconds;
                  Navigator.pop(context, totalSeconds);
                },
                child: const StrokedButtonLabel(
                  'Save',
                  fillColor: Color(0xFF5D4A3A),
                  strokeColor: Color(0xFFF5E6D3),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return null;
    if (result <= 0) return 0;
    return result;
  }

  String _formatDurationLabel(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  (String, int?) _extractTimerToken(String rawStep) {
    final match = _timerTokenRegex.firstMatch(rawStep);
    if (match == null) {
      return (rawStep.trim(), null);
    }

    final mm = int.tryParse(match.group(1) ?? '');
    final ss = int.tryParse(match.group(2) ?? '');
    final seconds = mm != null && ss != null ? (mm * 60 + ss) : null;
    final cleaned = rawStep.replaceFirst(_timerTokenRegex, '').trim();
    return (cleaned, (seconds == null || seconds <= 0) ? null : seconds);
  }

  void _removeStep(
    List<TextEditingController> controllers,
    int index,
    VoidCallback ensureOne,
  ) {
    final removed = controllers.removeAt(index);
    removed.removeListener(_onDraftInputChanged);
    removed.dispose();
    if (controllers.isEmpty) {
      ensureOne();
    }
    _syncStepTextToControllers();
    _onDraftInputChanged();
  }

  Future<void> _checkForExistingDraft() async {
    final existing = await DraftService.getDraftByKey(_draftKey);
    if (!mounted || existing == null) return;

    final bool? shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6D3),
        title: Text(
          'Restore Draft?',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'We found unsaved changes. Do you want to open last saved changes?',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const PressBounce(
              child: StrokedButtonLabel(
                'No',
                fillColor: Color(0xFF5D4A3A),
                strokeColor: Color(0xFFF5E6D3),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const PressBounce(
              child: StrokedButtonLabel(
                'Yes',
                fillColor: Color(0xFF5D4A3A),
                strokeColor: Color(0xFFF5E6D3),
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldRestore == true) {
      _loadRecipeIntoForm(existing.recipe);
      return;
    }

    await DraftService.removeDraftByKey(_draftKey);
  }

  void _loadRecipeIntoForm(Recipe draftRecipe) {
    setState(() {
      _editingRecipeId = draftRecipe.id.isEmpty
          ? _editingRecipeId
          : draftRecipe.id;
      _titleController.text = draftRecipe.title;
      _ingredientsController.text = draftRecipe.ingredients;
      _directionsController.text = draftRecipe.directions;
      _sourceUrlController.text = draftRecipe.sourceUrl;
      _notesController.text = draftRecipe.notes;
      _selectedShelves
        ..clear()
        ..addAll(
          draftRecipe.shelves
              .map(_normalizeShelfName)
              .where((s) => s.isNotEmpty),
        );
      _availableShelves.addAll(_selectedShelves);
      _dedupeAndSortShelves();
      _servingSizeController.text = draftRecipe.servingSize;
      _cookingTimeController.text = draftRecipe.cookingTime;
      _tagsController.text = draftRecipe.tags.join(', ');
      _coverImagePath = draftRecipe.coverImageFilePath;
      _legacyCoverImageBytes = draftRecipe.coverImageBytes;

      _parseServingSize(draftRecipe.servingSize);

      _parseCookingTime(draftRecipe.cookingTime);

      _setStepControllersFromText();
    });
  }

  void _onDraftInputChanged() {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 600), () {
      _autosaveDraft();
    });
  }

  bool _hasMeaningfulContent() {
    return _titleController.text.trim().isNotEmpty ||
        _ingredientsController.text.trim().isNotEmpty ||
        _directionsController.text.trim().isNotEmpty ||
        _sourceUrlController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _selectedShelves.isNotEmpty ||
        _servingSizeController.text.trim().isNotEmpty ||
        _cookingTimeController.text.trim().isNotEmpty ||
        _tagsController.text.trim().isNotEmpty ||
        _coverImagePath != null ||
        _legacyCoverImageBytes != null;
  }

  String _currentRecipeId() {
    return _editingRecipeId ??
        _baseRecipe?.id ??
        (_editingRecipeId = DateTime.now().millisecondsSinceEpoch.toString());
  }

  String _buildServingSize() {
    final number = _servingSizeNumberController.text.trim();
    if (number.isEmpty) return '';
    return '$number $_selectedServingUnit';
  }

  Recipe _buildDraftRecipe() {
    _syncStepTextToControllers();
    final base = _baseRecipe;
    return Recipe(
      id: _editingRecipeId ?? base?.id ?? 'draft',
      title: _titleController.text.trim(),
      imagePath: base?.imagePath ?? 'images/default_recipe.jpg',
      coverImageFilePath: _coverImagePath,
      coverImageBytes: _legacyCoverImageBytes,
      ingredients: _ingredientsController.text.trim(),
      directions: _directionsController.text.trim(),
      sourceUrl: _sourceUrlController.text.trim(),
      notes: _notesController.text.trim(),
      shelves: _selectedShelves.toList(growable: false),
      servingSize: _buildServingSize(),
      cookingTime: _buildCookingTime(),
      tags: _parseTags(_tagsController.text),
      cookedImageGalleryPaths: base?.cookedImageGalleryPaths ?? const [],
      cookedImageGalleryBytes: base?.cookedImageGalleryBytes ?? const [],
      isPinned: base?.isPinned ?? false,
      cooked: base?.cooked ?? false,
    );
  }

  Future<void> _autosaveDraft() async {
    if (!_hasMeaningfulContent()) {
      await DraftService.removeDraftByKey(_draftKey);
      return;
    }

    await DraftService.saveDraft(
      key: _draftKey,
      mode: _draftMode,
      recipe: _buildDraftRecipe(),
      baseRecipeId: _baseRecipe?.id,
    );
  }

  Future<void> _pickCoverPhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: RecipeImageStoreService.maxDimension,
      maxHeight: RecipeImageStoreService.maxDimension,
      imageQuality: RecipeImageStoreService.imageQuality,
    );
    if (picked == null) return;

    final savedPath = await RecipeImageStoreService.savePickedImage(
      image: picked,
      recipeId: _currentRecipeId(),
      slot: 'cover',
    );

    if (!mounted) return;
    setState(() {
      _coverImagePath = savedPath;
      _legacyCoverImageBytes = null;
    });
    _onDraftInputChanged();
  }

  String _generateClipboardTemplate() {
    return '''Title:
Pasta Carbonara

Servings:
4 Servings

Ingredients:
- 400g pasta
- 200g guanciale
- 4 eggs
- 100g pecorino romano
- salt and black pepper

Directions:
1. Boil water and cook pasta [[t=09:00]]
2. Fry guanciale until crispy [[t=05:00]]
3. Mix eggs with grated cheese
4. Combine hot pasta with guanciale and egg mixture [[t=02:00]]

Tags:
italian, pasta, classic

Cooking Time:
00:15:00''';
  }

  Future<void> _copyTemplateToClipboard() async {
    final template = _generateClipboardTemplate();
    await Clipboard.setData(ClipboardData(text: template));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Template copied! Fill each section in Notes, then paste it back here.',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color.fromARGB(255, 194, 143, 96),
      ),
    );
  }

  ({Recipe? recipe, String? error}) _parseClipboardTemplate(String text) {
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    String? currentSection;
    String? title;
    String? servings;
    String? cookingTime;
    final ingredients = <String>[];
    final directions = <String>[];
    final directionDurations = <int?>[];
    final tagsBuffer = <String>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final legacyDirection = _parseLegacyDirectionLine(line);
      if (legacyDirection != null) {
        directions.add(legacyDirection.$1);
        directionDurations.add(legacyDirection.$2);
        currentSection = 'directions';
        continue;
      }

      final headerMatch = _sectionHeaderRegex.firstMatch(line);
      if (headerMatch != null) {
        final rawHeader = headerMatch.group(1)!.trim().toLowerCase();
        final value = headerMatch.group(2)!.trim();
        final section = _resolveTemplateSection(rawHeader);
        if (section != null) {
          currentSection = section;
          if (value.isNotEmpty) {
            _appendTemplateLine(
              section: section,
              value: value,
              titleSetter: (v) => title = v,
              servingsSetter: (v) => servings = v,
              cookingTimeSetter: (v) => cookingTime = v,
              ingredients: ingredients,
              directions: directions,
              directionDurations: directionDurations,
              tagsBuffer: tagsBuffer,
            );
          }
          continue;
        }
      }

      if (currentSection != null) {
        _appendTemplateLine(
          section: currentSection,
          value: line,
          titleSetter: (v) => title = v,
          servingsSetter: (v) => servings = v,
          cookingTimeSetter: (v) => cookingTime = v,
          ingredients: ingredients,
          directions: directions,
          directionDurations: directionDurations,
          tagsBuffer: tagsBuffer,
        );
      }
    }

    final normalizedTitle = title?.trim() ?? '';
    if (normalizedTitle.isEmpty) {
      return (
        recipe: null,
        error: 'Missing Title section. Add "Title:" then the recipe name.',
      );
    }
    if (ingredients.isEmpty) {
      return (
        recipe: null,
        error:
            'Missing Ingredients section. Add "Ingredients:" with one item per line.',
      );
    }
    if (directions.isEmpty) {
      return (
        recipe: null,
        error:
            'Missing Directions section. Add "Directions:" with one step per line.',
      );
    }

    int cookingHours = 0;
    int cookingMinutes = 0;
    int cookingSeconds = 0;
    final normalizedCookingTime = (cookingTime ?? '').trim();
    if (normalizedCookingTime.isNotEmpty) {
      final timeParts = normalizedCookingTime
          .split(':')
          .map((p) => p.trim())
          .toList();
      if (timeParts.length == 2) {
        cookingMinutes = int.tryParse(timeParts[0]) ?? 0;
        cookingSeconds = int.tryParse(timeParts[1]) ?? 0;
      } else if (timeParts.length == 3) {
        cookingHours = int.tryParse(timeParts[0]) ?? 0;
        cookingMinutes = int.tryParse(timeParts[1]) ?? 0;
        cookingSeconds = int.tryParse(timeParts[2]) ?? 0;
      }
    }

    var directionsText = '';
    for (int i = 0; i < directions.length; i++) {
      if (directionsText.isNotEmpty) directionsText += '\n';
      directionsText += directions[i];
      final duration = directionDurations[i];
      if (duration != null && duration > 0) {
        final mm = duration ~/ 60;
        final ss = duration % 60;
        directionsText +=
            ' [[t=${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}]]';
      }
    }

    final recipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: normalizedTitle,
      imagePath: 'images/default_recipe.jpg',
      ingredients: ingredients.join('\n'),
      directions: directionsText,
      sourceUrl: '',
      notes: '',
      shelves: const [],
      tags: _parseTags(tagsBuffer.join(', ')),
      servingSize: servings?.isNotEmpty == true ? servings! : '1 Servings',
      cookingTime:
          '${cookingHours.toString().padLeft(2, '0')}:${cookingMinutes.toString().padLeft(2, '0')}:${cookingSeconds.toString().padLeft(2, '0')}',
    );

    return (recipe: recipe, error: null);
  }

  String? _resolveTemplateSection(String header) {
    for (final entry in _templateAliases.entries) {
      if (entry.value.contains(header)) return entry.key;
    }
    return null;
  }

  (String, int?)? _parseLegacyDirectionLine(String line) {
    if (!_legacyDirectionPrefixRegex.hasMatch(line)) return null;
    final rawDirection = line
        .replaceFirst(_legacyDirectionPrefixRegex, '')
        .trim();
    final parsed = _extractDirectionWithTimer(rawDirection);
    return (parsed.$1, parsed.$2);
  }

  void _appendTemplateLine({
    required String section,
    required String value,
    required void Function(String) titleSetter,
    required void Function(String) servingsSetter,
    required void Function(String) cookingTimeSetter,
    required List<String> ingredients,
    required List<String> directions,
    required List<int?> directionDurations,
    required List<String> tagsBuffer,
  }) {
    final cleaned = value.replaceFirst(_bulletPrefixRegex, '').trim();
    if (cleaned.isEmpty) return;

    switch (section) {
      case 'title':
        titleSetter(cleaned);
        break;
      case 'servings':
        servingsSetter(cleaned);
        break;
      case 'ingredients':
        ingredients.add(cleaned);
        break;
      case 'directions':
        final parsed = _extractDirectionWithTimer(cleaned);
        directions.add(parsed.$1);
        directionDurations.add(parsed.$2);
        break;
      case 'tags':
        tagsBuffer.add(cleaned);
        break;
      case 'cooking_time':
        cookingTimeSetter(cleaned);
        break;
    }
  }

  (String, int?) _extractDirectionWithTimer(String text) {
    final timerMatch = _timerTokenRegex.firstMatch(text);
    if (timerMatch == null) return (text, null);

    final mm = int.tryParse(timerMatch.group(1) ?? '') ?? 0;
    final ss = int.tryParse(timerMatch.group(2) ?? '') ?? 0;
    final duration = (mm * 60) + ss;
    final cleaned = text.replaceFirst(_timerTokenRegex, '').trim();
    return (cleaned, duration > 0 ? duration : null);
  }

  Future<void> _importFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data == null || data.text == null || data.text!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Clipboard is empty. Copy a template first!',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = _parseClipboardTemplate(data.text!);
      if (result.recipe == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.error ??
                  'Invalid template format. Please check and try again.',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      _loadRecipeIntoForm(result.recipe!);
      _onDraftInputChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported from clipboard. Please review before saving.',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 194, 143, 96),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error importing from clipboard: $e',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showTemplateDialog() async {
    final template = _generateClipboardTemplate();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF8EFE3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Recipe Template Format',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Template Example:',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5E6D3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  template,
                  style: GoogleFonts.fredoka(fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sections:',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Required: Title, Ingredients, Directions\n'
                'Optional: Servings, Tags, Cooking Time\n'
                'Accepted headers include aliases like:\n'
                'Recipe/Title, Units/Servings, Steps/Instructions',
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  color: const Color(0xFF8B6F47),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Timer Format:',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use [[t=MM:SS]] at end of direction steps\n'
                'MM = minutes, SS = seconds\n'
                'Example: Simmer sauce [[t=05:30]]',
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  color: const Color(0xFF8B6F47),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'How to Use:',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Tap "Copy Template"\n'
                '2. Paste in Notes app\n'
                '3. Fill each section (one ingredient/step per line)\n'
                '4. Copy your filled template\n'
                '5. Tap "Paste Template"',
                style: GoogleFonts.fredoka(
                  fontSize: 11,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4A3A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _parseTags(String rawTags) {
    final normalized = rawTags.trim();
    if (normalized.isEmpty) return const <String>[];

    final tags = <String>{};

    for (final token in normalized.split(RegExp(r'[,\n]+'))) {
      final cleaned = token.trim().replaceFirst(RegExp(r'^#+'), '');
      if (cleaned.isNotEmpty) tags.add(cleaned);
    }

    final hashMatches = RegExp(r'#([A-Za-z0-9_-]+)').allMatches(normalized);
    for (final match in hashMatches) {
      final tag = (match.group(1) ?? '').trim();
      if (tag.isNotEmpty) tags.add(tag);
    }

    return tags.toList(growable: false);
  }

  String _normalizeShelfName(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _dedupeAndSortShelves() {
    final seen = <String>{};
    _availableShelves
      ..removeWhere((s) {
        final normalized = s.trim().toLowerCase();
        if (normalized.isEmpty || seen.contains(normalized)) return true;
        seen.add(normalized);
        return false;
      })
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  Future<void> _showCreateShelfDialog() async {
    _shelfNameController.clear();
    final created = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6D3),
        title: Text(
          'Create Shelf',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _shelfNameController,
          maxLength: 24,
          autofocus: true,
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          decoration: _inputDecoration('Shelf name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const StrokedButtonLabel('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, _shelfNameController.text);
            },
            child: const StrokedButtonLabel('Add'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    final normalized = _normalizeShelfName(created ?? '');
    if (normalized.isEmpty) return;

    final exists = _availableShelves.any(
      (s) => s.toLowerCase() == normalized.toLowerCase(),
    );
    if (!exists && _availableShelves.length >= _maxShelfCount) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can create up to $_maxShelfCount shelves.',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    if (_selectedShelves.length >= _maxShelvesPerRecipe &&
        !_selectedShelves.any(
          (s) => s.toLowerCase() == normalized.toLowerCase(),
        )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You can assign up to $_maxShelvesPerRecipe shelves per recipe.',
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    setState(() {
      if (!exists) {
        _availableShelves.add(normalized);
        _dedupeAndSortShelves();
      }

      final canonical = _availableShelves.firstWhere(
        (s) => s.toLowerCase() == normalized.toLowerCase(),
        orElse: () => normalized,
      );
      _selectedShelves.add(canonical);
    });
    _onDraftInputChanged();
  }

  void _toggleShelfSelection(String shelf) {
    setState(() {
      if (_selectedShelves.contains(shelf)) {
        _selectedShelves.remove(shelf);
      } else {
        if (_selectedShelves.length >= _maxShelvesPerRecipe) {
          return;
        }
        _selectedShelves.add(shelf);
      }
    });
    _onDraftInputChanged();
  }

  Widget _buildShelvesEditor() {
    final canAddMoreShelves = _availableShelves.length < _maxShelfCount;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B6F47), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Shelves (up to $_maxShelvesPerRecipe)',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4A3A),
                  ),
                ),
              ),
              PressBounce(
                child: OutlinedButton.icon(
                  onPressed: canAddMoreShelves ? _showCreateShelfDialog : null,
                  icon: const Icon(Icons.add),
                  label: const StrokedButtonLabel('Add Shelf'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide.none,
                    foregroundColor: const Color(0xFF5D4A3A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_availableShelves.isEmpty)
            Text(
              'Create shelves like Weeknight, Desserts, or To Try.',
              style: GoogleFonts.fredoka(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B6F47),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableShelves.map((shelf) {
                final selected = _selectedShelves.contains(shelf);
                return FilterChip(
                  label: Text(
                    shelf,
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                  ),
                  selected: selected,
                  selectedColor: const Color(0xFFD2B48C),
                  checkmarkColor: const Color(0xFF5D4A3A),
                  onSelected: (isSelected) {
                    if (!isSelected ||
                        _selectedShelves.length < _maxShelvesPerRecipe) {
                      _toggleShelfSelection(shelf);
                    }
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _saveRecipe() async {
    setState(() => _showStepValidationErrors = true);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_cleanStepList(_ingredientStepControllers).isEmpty ||
        _cleanStepList(_directionStepControllers).isEmpty) {
      return;
    }

    _syncStepTextToControllers();

    setState(() => _isSaving = true);

    _autosaveDebounce?.cancel();

    final base = _baseRecipe;
    final recipe = Recipe(
      id:
          _editingRecipeId ??
          base?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      imagePath: base?.imagePath ?? 'images/default_recipe.jpg',
      coverImageFilePath: _coverImagePath,
      coverImageBytes: _legacyCoverImageBytes,
      ingredients: _ingredientsController.text.trim(),
      directions: _directionsController.text.trim(),
      sourceUrl: _sourceUrlController.text.trim(),
      notes: _notesController.text.trim(),
      shelves: _selectedShelves.toList(growable: false),
      servingSize: _buildServingSize(),
      cookingTime: _buildCookingTime(),
      tags: _parseTags(_tagsController.text),
      cookedImageGalleryPaths: base?.cookedImageGalleryPaths ?? const [],
      cookedImageGalleryBytes: base?.cookedImageGalleryBytes ?? const [],
      isPinned: base?.isPinned ?? false,
      cooked: base?.cooked ?? false,
    );

    await DraftService.removeDraftByKey(_draftKey);

    if (!mounted) return;
    Navigator.pop(context, recipe);
  }

  Future<bool> _confirmExitAddRecipe() async {
    if (_isHandlingExit || _isSaving) return false;
    if (!_hasMeaningfulContent()) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF5E6D3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF8B6F47), width: 2),
        ),
        title: Text(
          'Leave Recipe Editor?',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF5D4A3A),
          ),
        ),
        content: Text(
          'Your changes will be saved as a draft. Leave this page?',
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
              strokeColor: Color(0xFFF5E6D3),
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
              strokeColor: Color(0xFFF5E6D3),
            ),
          ),
        ],
      ),
    );

    if (shouldLeave != true) return false;

    _isHandlingExit = true;
    _autosaveDebounce?.cancel();
    await _autosaveDraft();
    _isHandlingExit = false;
    return true;
  }

  Future<void> _handleBackPress() async {
    final canLeave = await _confirmExitAddRecipe();
    if (!canLeave || !mounted) return;
    Navigator.pop(context);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.fredoka(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5D4A3A),
      ),
      filled: true,
      fillColor: const Color(0xFFF8EFE3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B6F47), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8B6F47), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5D4A3A), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExitAddRecipe,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const GinghamPatternBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          PressBounce(
                            child: IconButton(
                              onPressed: _handleBackPress,
                              icon: const Icon(Icons.arrow_back),
                              color: const Color(0xFF5D4A3A),
                            ),
                          ),
                          StrokedButtonLabel(
                            _isEditMode ? 'Edit Recipe' : 'Add Recipe',
                            fillColor: const Color(0xFF5D4A3A),
                            strokeColor: const Color(0xFFF5E6D3),
                            fontSize: 24,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: PressBounce(
                                child: OutlinedButton(
                                  onPressed: _copyTemplateToClipboard,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      194,
                                      143,
                                      96,
                                    ),
                                    foregroundColor: Colors.white,
                                    side: BorderSide.none,
                                  ),
                                  child: const StrokedButtonLabel(
                                    'Copy Template',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: PressBounce(
                                child: OutlinedButton(
                                  onPressed: _importFromClipboard,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      194,
                                      143,
                                      96,
                                    ),
                                    foregroundColor: Colors.white,
                                    side: BorderSide.none,
                                  ),
                                  child: const StrokedButtonLabel(
                                    'Paste Template',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PressBounce(
                              child: IconButton(
                                onPressed: _showTemplateDialog,
                                style: IconButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    194,
                                    143,
                                    96,
                                  ),
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.help_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TapBounce(
                        onTap: _pickCoverPhoto,
                        child: AspectRatio(
                          aspectRatio: 3 / 2,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5E6D3),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF8B6F47),
                                width: 2,
                              ),
                            ),
                            child:
                                _coverImagePath == null &&
                                    _legacyCoverImageBytes == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_a_photo,
                                        size: 40,
                                        color: Color(0xFF8B6F47),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to choose cover photo',
                                        style: GoogleFonts.fredoka(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF5D4A3A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Recommended: 1200 x 800 px (3:2)',
                                        style: GoogleFonts.fredoka(
                                          color: const Color(0xFF8B6F47),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: _coverImagePath != null
                                        ? Image.file(
                                            File(_coverImagePath!),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            alignment: Alignment.center,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  if (_legacyCoverImageBytes ==
                                                      null) {
                                                    return const SizedBox.shrink();
                                                  }
                                                  return Image.memory(
                                                    _legacyCoverImageBytes!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    alignment: Alignment.center,
                                                  );
                                                },
                                          )
                                        : Image.memory(
                                            _legacyCoverImageBytes!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            alignment: Alignment.center,
                                          ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('Recipe Title'),
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a recipe title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sourceUrlController,
                        decoration: _inputDecoration('Source Link (optional)'),
                        keyboardType: TextInputType.url,
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: _inputDecoration('Notes (optional)'),
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        minLines: 3,
                        maxLines: 5,
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildShelvesEditor(),
                      const SizedBox(height: 12),
                      _buildStepEditor(
                        title: 'Ingredients (one item per entry)',
                        controllers: _ingredientStepControllers,
                        itemLabel: 'Item',
                        addButtonLabel: 'Add item',
                        onAddStep: _addIngredientStep,
                        onRemoveStep: (index) {
                          setState(() {
                            _removeStep(_ingredientStepControllers, index, () {
                              final controller = TextEditingController();
                              controller.addListener(_onDraftInputChanged);
                              _ingredientStepControllers.add(controller);
                            });
                          });
                        },
                        validator: () {
                          if (_cleanStepList(
                            _ingredientStepControllers,
                          ).isEmpty) {
                            return 'Please enter at least one ingredient';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildStepEditor(
                        title: 'Directions (one instruction per step)',
                        controllers: _directionStepControllers,
                        itemLabel: 'Step',
                        addButtonLabel: 'Add step',
                        stepDurations: _directionStepDurations,
                        onSetStepTimer: _setDirectionStepTimer,
                        onClearStepTimer: _clearDirectionStepTimer,
                        onAddStep: _addDirectionStep,
                        onRemoveStep: (index) {
                          setState(() {
                            if (index >= 0 &&
                                index < _directionStepDurations.length) {
                              _directionStepDurations.removeAt(index);
                            }
                            _removeStep(_directionStepControllers, index, () {
                              final controller = TextEditingController();
                              controller.addListener(_onDraftInputChanged);
                              _directionStepControllers.add(controller);
                              _directionStepDurations.add(null);
                            });
                          });
                        },
                        validator: () {
                          if (_cleanStepList(
                            _directionStepControllers,
                          ).isEmpty) {
                            return 'Please enter at least one direction step';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _servingSizeNumberController,
                              decoration: _inputDecoration('Number'),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedServingUnit,
                              decoration: _inputDecoration('Unit'),
                              items: _servingSizeUnits.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(
                                    unit,
                                    style: GoogleFonts.fredoka(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedServingUnit = value;
                                  });
                                  _onDraftInputChanged();
                                }
                              },
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5D4A3A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cooking Time',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5D4A3A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF8B6F47),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              height: 150,
                              child: CupertinoPicker(
                                magnification: 1.2,
                                squeeze: 1.2,
                                scrollController: _cookingHoursController,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    _cookingHours = value;
                                    _onDraftInputChanged();
                                  });
                                },
                                itemExtent: 50.0,
                                children: List<Widget>.generate(24, (
                                  int index,
                                ) {
                                  return Center(
                                    child: Text(
                                      '${index.toString().padLeft(2, '0')}h',
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: const Color(0xFF5D4A3A),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF8B6F47),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              height: 150,
                              child: CupertinoPicker(
                                magnification: 1.2,
                                squeeze: 1.2,
                                scrollController: _cookingMinutesController,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    _cookingMinutes = value;
                                    _onDraftInputChanged();
                                  });
                                },
                                itemExtent: 50.0,
                                children: List<Widget>.generate(60, (
                                  int index,
                                ) {
                                  return Center(
                                    child: Text(
                                      '${index.toString().padLeft(2, '0')}m',
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: const Color(0xFF5D4A3A),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF8B6F47),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              height: 150,
                              child: CupertinoPicker(
                                magnification: 1.2,
                                squeeze: 1.2,
                                scrollController: _cookingSecondsController,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    _cookingSeconds = value;
                                    _onDraftInputChanged();
                                  });
                                },
                                itemExtent: 50.0,
                                children: List<Widget>.generate(60, (
                                  int index,
                                ) {
                                  return Center(
                                    child: Text(
                                      '${index.toString().padLeft(2, '0')}s',
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: const Color(0xFF5D4A3A),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _tagsController,
                        decoration: _inputDecoration('Tags (comma separated)'),
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: PressBounce(
                          enabled: !_isSaving,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : () => _saveRecipe(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                194,
                                143,
                                96,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : StrokedButtonLabel(
                                    _isEditMode
                                        ? 'Update Recipe'
                                        : 'Save Recipe',
                                    fontSize: 18,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepEditor({
    required String title,
    required List<TextEditingController> controllers,
    required String itemLabel,
    required String addButtonLabel,
    required VoidCallback onAddStep,
    required ValueChanged<int> onRemoveStep,
    required String? Function() validator,
    List<int?>? stepDurations,
    ValueChanged<int>? onSetStepTimer,
    ValueChanged<int>? onClearStepTimer,
  }) {
    final validationError = _showStepValidationErrors ? validator() : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B6F47), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(controllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    '${index + 1}.',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5D4A3A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: controllers[index],
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                      decoration: _inputDecoration(
                        '$itemLabel ${index + 1}',
                      ).copyWith(filled: true, fillColor: Colors.white),
                      onChanged: (_) => _syncStepTextToControllers(),
                    ),
                  ),
                  if (stepDurations != null && onSetStepTimer != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PressBounce(
                          child: IconButton(
                            onPressed: () => onSetStepTimer(index),
                            icon: Icon(
                              stepDurations[index] != null
                                  ? Icons.timer
                                  : Icons.timer_outlined,
                            ),
                            color: const Color(0xFF5D4A3A),
                            tooltip: 'Set step timer',
                          ),
                        ),
                        if (stepDurations[index] != null &&
                            onClearStepTimer != null)
                          PressBounce(
                            child: IconButton(
                              onPressed: () => onClearStepTimer(index),
                              icon: const Icon(Icons.close),
                              color: const Color(0xFF8B6F47),
                              tooltip: 'Clear timer',
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(width: 8),
                  PressBounce(
                    enabled: controllers.length != 1,
                    child: IconButton(
                      onPressed: controllers.length == 1
                          ? null
                          : () => onRemoveStep(index),
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFF9C2D2D),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (stepDurations != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(stepDurations.length, (index) {
                  final value = stepDurations[index];
                  if (value == null) return const SizedBox.shrink();
                  return Chip(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF8B6F47), width: 1),
                    avatar: const Icon(
                      Icons.timer,
                      size: 16,
                      color: Color(0xFF5D4A3A),
                    ),
                    label: Text(
                      'Step ${index + 1}: ${_formatDurationLabel(value)}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5D4A3A),
                      ),
                    ),
                  );
                }),
              ),
            ),
          Row(
            children: [
              PressBounce(
                child: OutlinedButton.icon(
                  onPressed: onAddStep,
                  icon: const Icon(Icons.add),
                  label: StrokedButtonLabel(
                    addButtonLabel,
                    fillColor: const Color(0xFF5D4A3A),
                    strokeColor: const Color(0xFFF5E6D3),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide.none,
                    foregroundColor: const Color(0xFF5D4A3A),
                  ),
                ),
              ),
            ],
          ),
          if (validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                validationError,
                style: GoogleFonts.fredoka(
                  color: const Color(0xFF9C2D2D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
