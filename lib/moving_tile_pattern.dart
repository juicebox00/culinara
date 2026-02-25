import 'package:flutter/material.dart';

class MovingTilePattern extends StatefulWidget {
  const MovingTilePattern({super.key});

  @override
  _MovingTilePatternState createState() => _MovingTilePatternState();
}

class _MovingTilePatternState extends State<MovingTilePattern> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 2.3,
        child: Transform.rotate(
          angle: 0.785,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/culinara_tile_pattern.png'),
                repeat: ImageRepeat.repeat,
                alignment: Alignment(
                  _controller.value * 2.0, 
                  _controller.value * 2.0,
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}