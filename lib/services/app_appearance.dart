import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TileColorOption {
  final String name;
  final Color color;

  const TileColorOption({required this.name, required this.color});
}

class PatternOption {
  final String id;
  final String name;
  final String assetPath;

  const PatternOption({
    required this.id,
    required this.name,
    required this.assetPath,
  });
}

class AppAppearance {
  static const String _tileTintColorKey = 'appearance.tileTintColor';
  static const String _patternKey = 'appearance.patternId';

  static const List<TileColorOption> tileColorOptions = [
    TileColorOption(
      name: 'Light Gold',
      color: Color.fromARGB(255, 238, 224, 202),
    ),
    TileColorOption(
      name: 'Light Red',
      color: Color.fromARGB(255, 240, 204, 204),
    ),
    TileColorOption(
      name: 'Light Indigo',
      color: Color.fromARGB(255, 206, 219, 236),
    ),
    TileColorOption(name: 'Green', color: Color.fromARGB(255, 211, 230, 201)),
    TileColorOption(
      name: 'Light Pink',
      color: Color.fromARGB(255, 238, 211, 225),
    ),
  ];

  static final ValueNotifier<Color> tileTintColor = ValueNotifier<Color>(
    tileColorOptions.first.color,
  );

  static const List<PatternOption> patternOptions = [
    PatternOption(
      id: 'gingham',
      name: 'Gingham',
      assetPath: 'images/gingham_pattern.png',
    ),
    PatternOption(
      id: 'fruits',
      name: 'Fruits',
      assetPath: 'images/fruits_pattern.png',
    ),
    PatternOption(
      id: 'leaf',
      name: 'Leaf',
      assetPath: 'images/leaf_pattern.png',
    ),
    PatternOption(
      id: 'oblongs',
      name: 'Oblongs',
      assetPath: 'images/oblongs_pattern.png',
    ),
    PatternOption(
      id: 'diamonds',
      name: 'Diamonds',
      assetPath: 'images/diamonds_pattern.png',
    ),
    PatternOption(
      id: 'stripes',
      name: 'Stripes',
      assetPath: 'images/stripes_pattern.png',
    ),
  ];

  static final ValueNotifier<String> selectedPatternId = ValueNotifier<String>(
    patternOptions.first.id,
  );

  static PatternOption get selectedPattern {
    return patternOptions.firstWhere(
      (option) => option.id == selectedPatternId.value,
      orElse: () => patternOptions.first,
    );
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final storedColor = prefs.getInt(_tileTintColorKey);
    if (storedColor != null) {
      tileTintColor.value = Color(storedColor);
    }

    final storedPatternId = prefs.getString(_patternKey);
    if (storedPatternId != null &&
        patternOptions.any((pattern) => pattern.id == storedPatternId)) {
      selectedPatternId.value = storedPatternId;
    }
  }

  static Future<void> setTileTintColor(Color color) async {
    tileTintColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tileTintColorKey, color.toARGB32());
  }

  static Future<void> setPattern(String patternId) async {
    if (!patternOptions.any((pattern) => pattern.id == patternId)) return;

    selectedPatternId.value = patternId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_patternKey, patternId);
  }
}
