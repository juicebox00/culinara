import 'package:flutter/material.dart';
import '../services/app_appearance.dart';

class GinghamPatternBackground extends StatelessWidget {
  const GinghamPatternBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppAppearance.tileTintColor,
      builder: (context, tileTintColor, child) {
        return ValueListenableBuilder<String>(
          valueListenable: AppAppearance.selectedPatternId,
          builder: (context, patternId, child) {
            final lightToneColor = _lightToneFrom(tileTintColor);
            final selectedPattern = AppAppearance.selectedPattern;

            return Stack(
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
                        image: AssetImage(selectedPattern.assetPath),
                        repeat: ImageRepeat.repeat,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _lightToneFrom(Color baseColor) {
    return Color.lerp(baseColor, Colors.white, 0.3) ?? Colors.white;
  }

  ColorFilter _buildGrayToColorFilter(Color targetColor, Color lightToneColor) {
    const double grayPivot = 205.0;

    int toChannel(double value) {
      return (value * 255.0).round().clamp(0, 255);
    }

    double slopeFor(int lightChannel, int targetChannel) {
      return (lightChannel - targetChannel) / (255.0 - grayPivot);
    }

    double biasFor(double slope, int lightChannel) {
      return lightChannel - (255.0 * slope);
    }

    final int lightR = toChannel(lightToneColor.r);
    final int lightG = toChannel(lightToneColor.g);
    final int lightB = toChannel(lightToneColor.b);
    final int targetR = toChannel(targetColor.r);
    final int targetG = toChannel(targetColor.g);
    final int targetB = toChannel(targetColor.b);

    final double rSlope = slopeFor(lightR, targetR);
    final double gSlope = slopeFor(lightG, targetG);
    final double bSlope = slopeFor(lightB, targetB);

    final double rBias = biasFor(rSlope, lightR);
    final double gBias = biasFor(gSlope, lightG);
    final double bBias = biasFor(bSlope, lightB);

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
}
