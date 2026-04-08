import 'package:flutter/material.dart';
import 'package:glass_keep/main.dart';
import 'package:noise/noise.dart';

/// Liquid glass distortion painter using Perlin noise
/// Generates wavy distortion effect similar to macOS glass morphism
class GlassDistortionPainter extends CustomPainter {
  static final Perlin _noise = Perlin();
  static const int _gridResolution = 15;

  final double time;
  final double strength;
  final double scale;

  GlassDistortionPainter({
    required this.time,
    this.strength = 3.0,
    this.scale = 0.02,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWavyDistortion(canvas, size);
  }

  /// Draw wavy distortion using grid-based approach with Perlin noise
  void _drawWavyDistortion(Canvas canvas, Size size) {
    final cellWidth = size.width / _gridResolution;
    final cellHeight = size.height / _gridResolution;
    
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw horizontal waves
    for (int y = 0; y <= _gridResolution; y++) {
      final path = Path();
      bool isFirstPoint = true;

      for (int x = 0; x <= _gridResolution; x++) {
        final noiseVal = _getNoiseOffset(
          x.toDouble(),
          y.toDouble(),
        );

        final px = x * cellWidth + noiseVal;
        final py = y * cellHeight + _getNoiseOffset(
          x.toDouble() + 100,
          y.toDouble() + 100,
        );

        if (isFirstPoint) {
          path.moveTo(px, py);
          isFirstPoint = false;
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Sample Perlin noise with layered octaves for natural-looking distortion
  double _getNoiseOffset(double x, double y) {
    double result = 0;
    double amplitude = 1;
    double frequency = 1;
    double maxVal = 0;

    // Two octaves of noise for complexity without performance hit
    for (int i = 0; i < 2; i++) {
      final sampleX = (x * scale * frequency + time * 0.25) / _gridResolution;
      final sampleY = (y * scale * frequency) / _gridResolution;

      result += _noise.noise2D(sampleX, sampleY) * amplitude;
      maxVal += amplitude;

      amplitude *= 0.5;
      frequency *= 2;
    }

    return (result / maxVal) * strength;
  }

  @override
  bool shouldRepaint(GlassDistortionPainter oldDelegate) =>
      oldDelegate.time != time;

  @override
  bool shouldRebuildSemantics(GlassDistortionPainter oldDelegate) => false;
}

/// Glass distortion effect widget using shared AnimationController
/// from GlassAnimationProvider for optimal performance
class GlassDistortionEffect extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double distortionStrength;
  final double distortionScale;

  const GlassDistortionEffect({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.distortionStrength = 3.0,
    this.distortionScale = 0.02,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);
    
    // Fallback to static if provider not available
    if (animationProvider == null) {
      return child;
    }

    return AnimatedBuilder(
      animation: animationProvider.animation,
      builder: (context, child) => Stack(
        children: [
          // Distortion layer
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: CustomPaint(
              painter: GlassDistortionPainter(
                time: animationProvider.animation.value * 8,
                strength: distortionStrength,
                scale: distortionScale,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // Content layer
          child!,
        ],
      ),
      child: child,
    );
  }
}
