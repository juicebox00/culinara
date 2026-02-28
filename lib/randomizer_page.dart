import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:culinara/models/recipe.dart';

class RandomizerPage extends StatefulWidget {
  final List<Recipe> recipes;
  const RandomizerPage({super.key, required this.recipes});

  @override
  State<RandomizerPage> createState() => _RandomizerPageState();
}

class _RandomizerPageState extends State<RandomizerPage> with SingleTickerProviderStateMixin {
  ScrollController _scrollController = ScrollController();
  bool _spinning = false;
  Recipe? _selected;
  List<String> _tags = [];
  String _cookFilter = 'all';

  List<Recipe> get _filteredRecipes {
    var list = widget.recipes.where((r) {
      if (_cookFilter == 'cooked' && !r.cooked) return false;
      if (_cookFilter == 'uncooked' && r.cooked) return false;
      if (_tags.isNotEmpty) {
        return true;
      }
      return true;
    }).toList();
    return list;
  }

  void _toggleCookFilter(String v) {
    setState(() {
      _cookFilter = v;
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _startSpin() {
    if (_spinning) return;
    var list = _filteredRecipes;
    if (list.isEmpty) return;
    _spinning = true;
    _selected = null;
    var rng = Random();
    int rounds = 5 + rng.nextInt(5);
    double itemExtent = 60; // bar height
    double maxScroll = (list.length * itemExtent) * rounds;
    _scrollController.jumpTo(0);

    _scrollController.animateTo(
      maxScroll,
      duration: Duration(milliseconds: rounds * 200),
      curve: Curves.decelerate,
    ).then((_) {
      double viewport = _scrollController.position.viewportDimension;
      double offset = _scrollController.offset + viewport / 2;
      int idx = (offset / itemExtent).floor() % list.length;
      setState(() {
        _selected = list[idx];
      });
      _spinning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var items = _filteredRecipes;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              ListView.builder(
                controller: _scrollController,
                physics: NeverScrollableScrollPhysics(), // disable manual scrolling
                itemCount: items.length * 20,
                itemBuilder: (context, idx) {
                  var recipe = items[idx % items.length];
                  // pick from app palette rather than random hash
                  final palette = [
                    Color(0xFFC9975C), // brown
                    Color.fromARGB(255, 236, 201, 154), // tan
                    Color.fromARGB(255, 190, 124, 107), // dark brown
                    Color.fromARGB(255, 255, 240, 220), // light beige
                    Color.fromARGB(255, 247, 212, 98), // yellow accent
                  ];
                  Color color = palette[idx % palette.length];
                  return Container(
                    height: 60,
                    color: color,
                    alignment: Alignment.center,
                    child: Text(recipe.title, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
                  );
                },
              ),
              // arrow indicator
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  String.fromCharCode(Icons.arrow_right.codePoint),
                  style: TextStyle(
                    fontFamily: Icons.arrow_right.fontFamily,
                    fontSize: 48,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black, offset: Offset(0, 0), blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selected != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Selected: ${_selected!.title}', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 4,
            children: _tags.map((t) => Chip(label: Text(t), onDeleted: () => _removeTag(t))).toList(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Cooked filter:', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            DropdownButton<String>(
              value: _cookFilter,
              items: ['all', 'cooked', 'uncooked'].map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.fredoka()))).toList(),
              onChanged: (v) => _toggleCookFilter(v!),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: _startSpin,
          child: Text('SPIN', style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B5E3C)),

        ),
      ],
    );
  }
}
