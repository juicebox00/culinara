import 'package:flutter/material.dart';
import '../services/app_appearance.dart';

class MovingTilePattern extends StatefulWidget {
  const MovingTilePattern({super.key});

  @override
  State<MovingTilePattern> createState() => _MovingTilePatternState();
}

class _MovingTilePatternState extends State<MovingTilePattern>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  Color _lightToneFrom(Color baseColor) {
    return Color.lerp(baseColor, Colors.white, 0.64) ?? Colors.white;
  }

  ColorFilter _buildGrayToColorFilter(Color targetColor, Color lightToneColor) {
    const double grayPivot = 205.0;

    double slopeFor(int lightChannel, int targetChannel) {
      return (lightChannel - targetChannel) / (255.0 - grayPivot);
    }

    double biasFor(double slope, int lightChannel) {
      return lightChannel - (255.0 * slope);
    }

    final double rSlope = slopeFor(lightToneColor.red, targetColor.red);
    final double gSlope = slopeFor(lightToneColor.green, targetColor.green);
    final double bSlope = slopeFor(lightToneColor.blue, targetColor.blue);

    final double rBias = biasFor(rSlope, lightToneColor.red);
    final double gBias = biasFor(gSlope, lightToneColor.green);
    final double bBias = biasFor(bSlope, lightToneColor.blue);

    return ColorFilter.matrix(<double>[
      rSlope,
      0,
      0,
      0,
      rBias,
      0,
      gSlope,
      0,
      0,
      gBias,
      0,
      0,
      bSlope,
      0,
      bBias,
      0,
      0,
      0,
      1,
      0,
    ]);
  }

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
    return ValueListenableBuilder<Color>(
      valueListenable: AppAppearance.tileTintColor,
      builder: (context, tileTintColor, child) {
        final lightToneColor = _lightToneFrom(tileTintColor);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: 2.3,
              child: Transform.rotate(
                angle: 0.785,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: lightToneColor),
                    ColorFiltered(
                      colorFilter: _buildGrayToColorFilter(
                        tileTintColor,
                        lightToneColor,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage(
                              'images/culinara_tile_pattern.png',
                            ),
                            repeat: ImageRepeat.repeat,
                            alignment: Alignment(
                              _controller.value * 2.0,
                              _controller.value * 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
