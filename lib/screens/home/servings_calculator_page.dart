import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/models/recipe.dart';
import 'package:culinara/widgets/stroked_button_label.dart';

class ServingsCalculatorPage extends StatefulWidget {
  const ServingsCalculatorPage({
    super.key,
    required this.recipes,
  });

  final List<Recipe> recipes;

  @override
  State<ServingsCalculatorPage> createState() => _ServingsCalculatorPageState();
}

class _ServingsCalculatorPageState extends State<ServingsCalculatorPage> {
  Recipe? selectedRecipe;
  double originalServings = 1.0;
  double newServings = 1.0;
  final TextEditingController _newServingsController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _newServingsController.dispose();
    super.dispose();
  }

  void _updateScaling() {
    if (originalServings > 0 && newServings > 0) {
      setState(() {});
    }
  }

  void _onRecipeSelected(Recipe? recipe) {
    setState(() {
      selectedRecipe = recipe;
      if (recipe?.servingSize.isNotEmpty == true) {
        // Try to extract number from serving size
        final match = RegExp(r'(\d+)').firstMatch(recipe!.servingSize);
        if (match != null) {
          originalServings = double.tryParse(match.group(1)!) ?? 1.0;
          newServings = originalServings;
          _newServingsController.text = newServings.round().toString();
        } else {
          // Default to 1 if no number found
          originalServings = 1.0;
          newServings = 1.0;
          _newServingsController.text = '1';
        }
      } else {
        // Default to 1 if no serving size
        originalServings = 1.0;
        newServings = 1.0;
        _newServingsController.text = '1';
      }
    });
  }

  List<String> _scaleIngredients(String ingredients, double scaleFactor) {
    final lines = ingredients.split('\n');
    final scaledIngredients = <String>[];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        scaledIngredients.add(line);
        continue;
      }
      
      // Try to extract quantity from the beginning of the line
      final match = RegExp(r'^([\d\s/\.]+(?:\s*[\d/\.]+)*)\s*(.*)').firstMatch(trimmedLine);
      
      if (match != null) {
        final quantityStr = match.group(1)!.trim();
        final restOfIngredient = match.group(2)!.trim();
        
        try {
          final quantity = _parseQuantity(quantityStr);
          final scaledQuantity = quantity * scaleFactor;
          final scaledQuantityStr = _formatQuantity(scaledQuantity);
          scaledIngredients.add('$scaledQuantityStr $restOfIngredient');
        } catch (e) {
          // If parsing fails, keep original line
          scaledIngredients.add(line);
        }
      } else {
        scaledIngredients.add(line);
      }
    }
    
    return scaledIngredients;
  }

  double _parseQuantity(String quantityStr) {
    // Handle fractions like "1/2", "1 1/2", mixed numbers, and decimals
    final parts = quantityStr.split(RegExp(r'\s+'));
    double total = 0.0;
    
    for (final part in parts) {
      if (part.contains('/')) {
        // Handle fraction
        final fractionParts = part.split('/');
        if (fractionParts.length == 2) {
          final numerator = double.tryParse(fractionParts[0]) ?? 0;
          final denominator = double.tryParse(fractionParts[1]) ?? 1;
          total += numerator / denominator;
        }
      } else {
        // Handle whole number or decimal
        total += double.tryParse(part) ?? 0;
      }
    }
    
    return total;
  }

  String _formatQuantity(double quantity) {
    // Convert back to fractions for common measurements
    if (quantity.isApproximately(0.25)) return '1/4';
    if (quantity.isApproximately(0.33)) return '1/3';
    if (quantity.isApproximately(0.5)) return '1/2';
    if (quantity.isApproximately(0.67)) return '2/3';
    if (quantity.isApproximately(0.75)) return '3/4';
    
    // For whole numbers with fractions
    final whole = quantity.floor();
    final fraction = quantity - whole;
    
    if (fraction.isApproximately(0.25)) return '${whole} 1/4';
    if (fraction.isApproximately(0.33)) return '${whole} 1/3';
    if (fraction.isApproximately(0.5)) return '${whole} 1/2';
    if (fraction.isApproximately(0.67)) return '${whole} 2/3';
    if (fraction.isApproximately(0.75)) return '${whole} 3/4';
    
    // For other cases, use decimal with reasonable precision
    if (quantity == quantity.round()) {
      return quantity.round().toString();
    } else {
      return quantity.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = originalServings > 0 ? newServings / originalServings : 1.0;
    final scaledIngredients = selectedRecipe != null 
        ? _scaleIngredients(selectedRecipe!.ingredients, scaleFactor)
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const StrokedButtonLabel(
          'Servings Calculator',
          fillColor: Colors.white,
          strokeColor: Color(0xFF5D4A3A),
        ),
        backgroundColor: const Color.fromARGB(255, 194, 143, 96),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Selection
            Text(
              'Select Recipe',
              style: GoogleFonts.fredoka(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4A3A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8B6F47)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Recipe>(
                  hint: Text(
                    'Choose a recipe...',
                    style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                  ),
                  value: selectedRecipe,
                  isExpanded: true,
                  items: widget.recipes.map((recipe) {
                    return DropdownMenuItem<Recipe>(
                      value: recipe,
                      child: Text(
                        recipe.title,
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (recipe) {
                    _onRecipeSelected(recipe);
                  },
                ),
              ),
            ),
            
            if (selectedRecipe != null) ...[
              const SizedBox(height: 24),
              
              // Servings Input
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Original Servings',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF8B6F47)),
                          ),
                          child: Text(
                            originalServings.round().toString(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Servings',
                          style: GoogleFonts.fredoka(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4A3A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _newServingsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF5E6D3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF8B6F47)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF8B6F47)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF8B6F47), width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            newServings = double.tryParse(value) ?? 1.0;
                            _updateScaling();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Scaled Ingredients
              Text(
                'Scaled Ingredients',
                style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B6F47)),
                ),
                child: scaledIngredients.isEmpty
                    ? Text(
                        'No ingredients to scale',
                        style: GoogleFonts.fredoka(
                          color: const Color(0xFF7A6450),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: scaledIngredients.map((ingredient) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              ingredient,
                              style: GoogleFonts.fredoka(
                                color: const Color(0xFF5D4A3A),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension on double {
  bool isApproximately(double other, [double tolerance = 0.01]) {
    return (this - other).abs() < tolerance;
  }
}
