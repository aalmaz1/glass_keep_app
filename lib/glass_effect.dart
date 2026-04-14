import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:glass_keep/main.dart';
import 'package:fast_noise/fast_noise.dart';

/// Liquid glass distortion painter using Perlin noise
/// Generates wavy distortion effect similar to macOS glass morphism
/// Optimized for minimal noise calculations
class GlassDistortionPainter extends CustomPainter {
  static final _noise = PerlinNoise();
  // Reduced grid resolution for better performance on all devices
  static const int _gridResolution = 8;
  // Cache for noise values to reduce redundant calculations
  static final Map<int, double> _noiseCache = {};
  // Cache generation to invalidate old entries
  static int _cacheGeneration = 0;

  final double time;
  final double strength;
  final double scale;

  GlassDistortionPainter({
    required this.time,
    this.strength = 1.5,
    this.scale = 0.012,
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
    final shimmer = (math.sin(time * 1.5) + 1) / 2 * 0.03;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 + shimmer)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    // Cache key prefix based on time to invalidate old values
    final timeHash = (time * 100).toInt();

    // Increment cache generation periodically to allow old entries to be cleared
    if (timeHash % 10 == 0) {
      _cacheGeneration++;
    }

    // Draw horizontal waves
    for (int y = 0; y <= _gridResolution; y++) {
      final path = Path();
      bool isFirstPoint = true;

      for (int x = 0; x <= _gridResolution; x++) {
        // Use cached noise or calculate new
        final cacheKey = (_cacheGeneration * 10000 + y * 100 + x);
        final noiseVal = _getNoiseOffsetCached(
          x.toDouble(),
          y.toDouble(),
          cacheKey,
        );

        final px = x * cellWidth + noiseVal;
        final py = y * cellHeight + (math.sin(time + x) * 0.5);

        if (isFirstPoint) {
          path.moveTo(px, py);
          isFirstPoint = false;
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Draw vertical waves (added for 'Obsidian Vision' premium feel)
    for (int x = 0; x <= _gridResolution; x++) {
      final path = Path();
      bool isFirstPoint = true;

      for (int y = 0; y <= _gridResolution; y++) {
        final cacheKey = (_cacheGeneration * 20000 + x * 100 + y);
        final noiseVal = _getNoiseOffsetCached(
          y.toDouble(),
          x.toDouble(),
          cacheKey,
        );

        final px = x * cellWidth + (math.cos(time + y) * 0.5);
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

    // Clear old cache entries when generation changes significantly to prevent memory bloat
    if (_noiseCache.length > 500) {
      // Remove half of the cache entries to maintain some continuity
      final keys = _noiseCache.keys.toList();
      for (int i = 0; i < keys.length / 2; i++) {
        _noiseCache.remove(keys[i]);
      }
    }
  }

  /// Get cached noise value or calculate new one
  double _getNoiseOffsetCached(double x, double y, int cacheKey) {
    if (_noiseCache.containsKey(cacheKey)) {
      return _noiseCache[cacheKey]!;
    }
    final value = _getNoiseOffset(x, y);
    _noiseCache[cacheKey] = value;
    return value;
  }

  /// Sample Perlin noise with single octave for better performance
  double _getNoiseOffset(double x, double y) {
    // Single octave of noise for performance
    final sampleX = (x * scale + time * 0.25) / _gridResolution;
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
    this.distortionStrength = 1.5,
    this.distortionScale = 0.012,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);
    
    // Fallback to static if provider not available or on low-end devices
    if (animationProvider == null) {
      return child;
    }

    return AnimatedBuilder(
      animation: animationProvider.animationController,
      builder: (context, child) => Stack(
        children: [
          // Distortion layer
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: CustomPaint(
              painter: GlassDistortionPainter(
                time: animationProvider.animationController.value * 8,
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
