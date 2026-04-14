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
  // Using a more efficient cache management
  static final Map<int, double> _noiseCache = {};
  static int _lastCacheClearFrame = 0;

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

    // Optimized cache clearing: clear fully only when it gets too large, but not every frame
    if (_noiseCache.length > 1000) {
      _noiseCache.clear();
    }

    final int timeHash = (time * 10).toInt();

    // Draw horizontal waves
    for (int y = 0; y <= _gridResolution; y++) {
      final path = Path();
      bool isFirstPoint = true;

      for (int x = 0; x <= _gridResolution; x++) {
        // More stable cache key
        final cacheKey = (timeHash << 16) | (y << 8) | x;
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
        final cacheKey = (timeHash << 16) | (x << 8) | y | 0x8000;
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
          // Distortion layer - wrapped in RepaintBoundary to isolate distortion drawing
          ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GlassDistortionPainter(
                  time: animationProvider.animationController.value * 8,
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
