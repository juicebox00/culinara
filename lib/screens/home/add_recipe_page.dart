import 'dart:typed_data';

import 'package:culinara/models/recipe.dart';
import 'package:culinara/widgets/moving_tile_pattern.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _directionsController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _tagsController = TextEditingController();

  final _imagePicker = ImagePicker();
  Uint8List? _coverImageBytes;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _directionsController.dispose();
    _servingSizeController.dispose();
    _cookingTimeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverPhoto() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _coverImageBytes = bytes;
    });
  }

  List<String> _parseTags(String rawTags) {
    return rawTags
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  void _saveRecipe() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSaving = true);

    final recipe = Recipe(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      imagePath: 'images/placeholder_thumbnail.png',
      coverImageBytes: _coverImageBytes,
      ingredients: _ingredientsController.text.trim(),
      directions: _directionsController.text.trim(),
      servingSize: _servingSizeController.text.trim(),
      cookingTime: _cookingTimeController.text.trim(),
      tags: _parseTags(_tagsController.text),
    );

    Navigator.pop(context, recipe);
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const MovingTilePattern(),
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
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF5D4A3A),
                        ),
                        Text(
                          'Add Recipe',
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: _pickCoverPhoto,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5E6D3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF8B6F47),
                            width: 2,
                          ),
                        ),
                        child: _coverImageBytes == null
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
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(
                                  _coverImageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
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
                      controller: _ingredientsController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: _inputDecoration('Ingredients'),
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter ingredients';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _directionsController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: _inputDecoration('Directions'),
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter directions';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _servingSizeController,
                      decoration: _inputDecoration(
                        'Serving Size (e.g. 4 servings)',
                      ),
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cookingTimeController,
                      decoration: _inputDecoration(
                        'Cooking Time (e.g. 30 mins)',
                      ),
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
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
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveRecipe,
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
                            side: const BorderSide(
                              color: Color.fromARGB(255, 93, 74, 58),
                              width: 2,
                            ),
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
                            : Text(
                                'Save Recipe',
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
    );
  }
}
