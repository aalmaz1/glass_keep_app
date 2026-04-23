import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:glass_keep/providers.dart';
import 'package:fast_noise/fast_noise.dart';

/// Liquid glass distortion painter using Perlin noise
/// Generates wavy distortion effect similar to macOS glass morphism
/// Optimized for minimal noise calculations
class GlassDistortionPainter extends CustomPainter {
  static final _noise = PerlinNoise();
  // Slightly increased grid resolution for smoother high-end distortion
  // Reduced significantly on Web for performance
  static final int _gridResolution = kIsWeb ? 6 : 12;

  // Cache for noise values to reduce redundant calculations
  static final Map<int, double> _noiseCache = {};

  final double time;
  final double strength;
  final double scale;

  const GlassDistortionPainter({
    required this.time,
    this.strength = 1.2,
    this.scale = 0.01,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawWavyDistortion(canvas, size);
  }

  /// Draw wavy distortion using optimized grid-based approach with Perlin noise
  void _drawWavyDistortion(Canvas canvas, Size size) {
    final cellWidth = size.width / _gridResolution;
    final cellHeight = size.height / _gridResolution;

    // Shimmering effect by varying opacity based on time
    final shimmer = (math.sin(time * 1.2) + 1) / 2 * 0.02;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03 + shimmer)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

    // Optimized cache clearing
    if (_noiseCache.length > 2000) {
      _noiseCache.clear();
    }

    final int timeHash = (time * 10).toInt();

    // Draw horizontal waves
    for (int y = 0; y <= _gridResolution; y++) {
      final path = Path();
      bool isFirstPoint = true;

      for (int x = 0; x <= _gridResolution; x++) {
        final cacheKey = (timeHash << 16) | (y << 8) | x;
        final noiseVal = _getNoiseOffsetCached(
          x.toDouble(),
          y.toDouble(),
          cacheKey,
        );

        final px = x * cellWidth + noiseVal;
        final py = y * cellHeight + (math.sin(time * 0.8 + x * 0.5) * 0.8);

        if (isFirstPoint) {
          path.moveTo(px, py);
          isFirstPoint = false;
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Draw vertical waves
    for (int x = 0; x <= _gridResolution; x++) {
      final path = Path();
      bool isFirstPoint = true;

      for (int y = 0; y <= _gridResolution; y++) {
        final cacheKey = (timeHash << 16) | (x << 8) | y | 0x8000;
        final noiseVal = _getNoiseOffsetCached(
          y.toDouble(),
          x.toDouble(),
          cacheKey,
        );

        final px = x * cellWidth + (math.cos(time * 0.8 + y * 0.5) * 0.8);
        final py = y * cellHeight + noiseVal;

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

  /// Get cached noise value or calculate new one
  double _getNoiseOffsetCached(double x, double y, int cacheKey) {
    final cached = _noiseCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final value = _getNoiseOffset(x, y);
    _noiseCache[cacheKey] = value;
    return value;
  }

  /// Sample Perlin noise with single octave for better performance
  double _getNoiseOffset(double x, double y) {
    final sampleX = (x * scale + time * 0.15) / _gridResolution;
    final sampleY = (y * scale) / _gridResolution;
    return _noise.getNoise2(sampleX, sampleY) * strength;
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
    this.distortionStrength = 1.2,
    this.distortionScale = 0.01,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);

    // Fallback to static if provider not available
    if (animationProvider == null) {
      return child;
    }

    return AnimatedBuilder(
      animation: animationProvider.animationController,
      builder: (context, child) => Stack(
        children: [
          // Distortion layer - wrapped in RepaintBoundary to isolate distortion drawing
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GlassDistortionPainter(
                  time: animationProvider.animationController.value * 10,
                  strength: distortionStrength,
                  scale: distortionScale,
                ),
                child: const SizedBox.expand(),
              ),
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
