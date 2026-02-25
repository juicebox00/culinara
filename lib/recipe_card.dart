import 'package:flutter/material.dart';

class RecipeCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool isPinned;

  const RecipeCard({super.key, 
    required this.title,
    required this.imagePath,
    this.isPinned = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isPinned ? Colors.orangeAccent : Color(0xFF8B5E3C);
    final Color labelBgColor = isPinned ? Color(0xFFFFD54F) : Color(0xFFF5E6D3);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [


          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),


          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            width: double.infinity,
            color: labelBgColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.more_vert, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}