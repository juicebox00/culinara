import 'package:flutter/material.dart';

class TileColorOption {
  final String name;
  final Color color;

  const TileColorOption({required this.name, required this.color});
}

class AppAppearance {
  static const List<TileColorOption> tileColorOptions = [
    TileColorOption(name: 'Light Gold', color: Color.fromARGB(255, 238, 224, 202)),
    TileColorOption(name: 'Light Red', color: Color.fromARGB(255, 240, 204, 204)),
    TileColorOption(name: 'Light Indigo', color: Color.fromARGB(255, 206, 219, 236)),
    TileColorOption(name: 'Green', color: Color.fromARGB(255, 211, 230, 201)),
    TileColorOption(name: 'Light Pink', color: Color.fromARGB(255, 238, 211, 225)),
  ];

  static final ValueNotifier<Color> tileTintColor = ValueNotifier<Color>(
    tileColorOptions.first.color,
  );

  static void setTileTintColor(Color color) {
    tileTintColor.value = color;
  }
}
