import 'package:flutter/material.dart';

/// A reusable bottom navigation bar used throughout the app.
///
/// This widget holds all five main destinations.  It exposes a
/// [currentIndex] and an [onTap] callback so that the parent can manage
/// navigation state.  Individual buttons are simple icons + labels and do
/// not need their own files; extracting them would only make sense if they
/// carried substantial custom logic.
class CulinaraBottomNavBar extends StatelessWidget {
  const CulinaraBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// The currently selected tab (0‑4).
  final int currentIndex;

  /// Called when the user taps a destination.
  final ValueChanged<int> onTap;

  static const _items = <BottomNavigationBarItem>[
    BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'Recipes',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.tag),
      label: 'Tags',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.add_circle, size: 36),
      label: '',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.casino),
      label: 'Randomizer',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: _items,
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Color(0xFFC9975C),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
    );
  }
}
