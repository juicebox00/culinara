import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:culinara/widgets/stroked_button_label.dart';
import 'package:culinara/widgets/tap_bounce.dart';

class UnitsConverterPage extends StatefulWidget {
  const UnitsConverterPage({super.key});

  @override
  State<UnitsConverterPage> createState() => _UnitsConverterPageState();
}

class _UnitsConverterPageState extends State<UnitsConverterPage> {
  static const String _volume = 'Volume';
  static const String _weight = 'Weight';
  static const String _temperature = 'Temperature';

  final TextEditingController _inputController = TextEditingController(
    text: '1',
  );

  String _category = _volume;
  String _fromUnit = 'Cup';
  String _toUnit = 'Milliliter';
  String _result = '236.588';
  String _secondaryResult = '';

  static const List<String> _categories = [_volume, _weight, _temperature];

  static const Map<String, double> _volumeToMl = {
    'Teaspoon': 4.92892,
    'Tablespoon': 14.7868,
    'Cup': 236.588,
    'Milliliter': 1,
    'Liter': 1000,
    'Gallon': 3785.41,
    'Quart': 946.353,
    'Pint': 473.176,
  };

  static const Map<String, double> _weightToGram = {
    'Milligram': 0.001,
    'Gram': 1,
    'Kilogram': 1000,
    'Ounce': 28.3495,
    'Pound': 453.592,
  };

  List<String> _unitsForCategory(String category) {
    switch (category) {
      case _volume:
        return _volumeToMl.keys.toList(growable: false);
      case _weight:
        return _weightToGram.keys.toList(growable: false);
      case _temperature:
        return const ['Celsius', 'Fahrenheit'];
      default:
        return const [];
    }
  }

  void _onCategoryChanged(String category) {
    final units = _unitsForCategory(category);
    if (units.isEmpty) return;

    setState(() {
      _category = category;
      _fromUnit = units.first;
      _toUnit = units.length > 1 ? units[1] : units.first;
      _result = '0';
    });
    _recalculate();
  }

  double? _parsedInput() {
    final input = _inputController.text.trim();
    if (input.isEmpty) return null;

    // Try to parse as decimal first
    final decimal = double.tryParse(input);
    if (decimal != null) return decimal;

    // Try to parse as fraction (e.g., "1/2")
    final fractionRegex = RegExp(r'^(\d+\.?\d*)\s*\/\s*(\d+\.?\d*)$');
    final fractionMatch = fractionRegex.firstMatch(input);
    if (fractionMatch != null) {
      final numerator = double.parse(fractionMatch.group(1)!);
      final denominator = double.parse(fractionMatch.group(2)!);
      if (denominator != 0) return numerator / denominator;
    }

    // Try to parse as mixed fraction (e.g., "2 1/3")
    final mixedRegex = RegExp(r'^(\d+\.?\d?)\s+(\d+\.?\d*)\s*\/\s*(\d+\.?\d*)$');
    final mixedMatch = mixedRegex.firstMatch(input);
    if (mixedMatch != null) {
      final whole = double.parse(mixedMatch.group(1)!);
      final numerator = double.parse(mixedMatch.group(2)!);
      final denominator = double.parse(mixedMatch.group(3)!);
      if (denominator != 0) return whole + (numerator / denominator);
    }

    return null;
  }

  String _decimalToFraction(double value) {
    // Convert decimal to fraction string for display
    if (value == value.toInt()) {
      return value.toInt().toString();
    }

    // Common fractions mapping
    final fractionMap = {
      0.125: '1/8',
      0.25: '1/4',
      0.333: '1/3',
      0.375: '3/8',
      0.5: '1/2',
      0.625: '5/8',
      0.666: '2/3',
      0.75: '3/4',
      0.875: '7/8',
    };

    // Check for common fractions
    for (final entry in fractionMap.entries) {
      if ((value - entry.key).abs() < 0.001) {
        return entry.value;
      }
    }

    // If not a common fraction, return decimal format
    return value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  void _recalculate() {
    final input = _parsedInput();
    if (input == null) {
      setState(() {
        _result = 'Invalid number';
        _secondaryResult = '';
      });
      return;
    }

    double converted;
    if (_category == _volume) {
      final ml = input * (_volumeToMl[_fromUnit] ?? 1);
      converted = ml / (_volumeToMl[_toUnit] ?? 1);
    } else if (_category == _weight) {
      final grams = input * (_weightToGram[_fromUnit] ?? 1);
      converted = grams / (_weightToGram[_toUnit] ?? 1);
    } else {
      if (_fromUnit == _toUnit) {
        converted = input;
      } else if (_fromUnit == 'Celsius' && _toUnit == 'Fahrenheit') {
        converted = (input * 9 / 5) + 32;
      } else {
        converted = (input - 32) * 5 / 9;
      }
    }

    setState(() {
      final resultStr = converted.toStringAsFixed(3).replaceFirst(RegExp(r'\.0+$'), '');
      _result = resultStr;
      _secondaryResult = _decimalToFraction(input);
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
    });
    _recalculate();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final units = _unitsForCategory(_category);
    
    // Ensure selected units are valid for current category
    String fromUnit = _fromUnit;
    String toUnit = _toUnit;
    
    if (!units.contains(fromUnit)) {
      fromUnit = units.isNotEmpty ? units.first : 'N/A';
    }
    if (!units.contains(toUnit)) {
      toUnit = units.length > 1 ? units[1] : (units.isNotEmpty ? units.first : 'N/A');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8EFE3),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 194, 143, 96),
        centerTitle: true,
        title: const StrokedButtonLabel(
          'Units Converter',
          fillColor: Colors.white,
          strokeColor: Color(0xFF5D4A3A),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Category',
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF5D4A3A),
            ),
          ),
          const SizedBox(height: 8),
          _buildDropdown(
            value: _category,
            items: _categories,
            onChanged: (value) {
              if (value != null) _onCategoryChanged(value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9/. ]')),
            ],
            onChanged: (_) => _recalculate(),
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            decoration: _inputDecoration(label: 'Value'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: fromUnit,
                  items: units,
                  label: 'From',
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _fromUnit = value;
                    });
                    _recalculate();
                  },
                ),
              ),
              const SizedBox(width: 8),
              PressBounce(
                child: IconButton(
                  onPressed: _swapUnits,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  color: const Color(0xFF5D4A3A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDropdown(
                  value: toUnit,
                  items: units,
                  label: 'To',
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _toUnit = value;
                    });
                    _recalculate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5E6D3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8B6F47), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Result',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4A3A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _secondaryResult.isEmpty
                      ? _result
                      : '$_result or $_secondaryResult',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5D4A3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$fromUnit -> $toUnit',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B6F47),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.fredoka(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF5D4A3A),
      ),
      filled: true,
      fillColor: const Color(0xFFF5E6D3),
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

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B6F47), width: 1.5),
      ),
      child: DropdownButton<String>(
        isExpanded: true,
        underline: const SizedBox.shrink(),
        value: value,
        hint: label == null
            ? null
            : Text(
                label,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5D4A3A),
                ),
              ),
        items: items
            .map(
              (unit) => DropdownMenuItem(
                value: unit,
                child: Text(
                  unit,
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}
