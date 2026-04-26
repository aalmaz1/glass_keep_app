import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:glass_keep/providers.dart';
import 'package:fast_noise/fast_noise.dart';

/// Liquid glass distortion painter using Perlin noise
/// Generates wavy distortion effect similar to macOS glass morphism
/// Optimized for minimal noise calculations
class GlassDistortionPainter extends CustomPainter {
  static final _noise = PerlinNoise();
  
  // Cache for noise values to reduce redundant calculations
  static final Map<int, double> _noiseCache = {};
  // Limit cache size to prevent memory bloat
  static const int _maxCacheSize = 500;

  final double time;
  final double strength;
  final double scale;
  final bool lowQuality;
  
  // Pre-calculated time hash for efficient shouldRepaint
  final int _timeHash;

  GlassDistortionPainter({
    required this.time,
    this.strength = 1.2,
    this.scale = 0.01,
    this.lowQuality = false,
  }) : _timeHash = time.hashCode;

  @override
  void paint(Canvas canvas, Size size) {
    _drawWavyDistortion(canvas, size);
  }

  /// Draw wavy distortion using optimized grid-based approach with Perlin noise
  void _drawWavyDistortion(Canvas canvas, Size size) {
    final gridResolution = lowQuality ? 2 : 4;
    final cellWidth = size.width / gridResolution;
    final cellHeight = size.height / gridResolution;

    // Reduced shimmer intensity for less GPU work
    final shimmer = (math.sin(time * 0.6) + 1) / 2 * 0.015;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025 + shimmer)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.25;

    // Optimized cache clearing with size limit
    if (_noiseCache.length > _maxCacheSize) {
      _noiseCache.clear();
    }

    // Draw horizontal waves
    for (int y = 0; y <= gridResolution; y++) {
      final path = Path();
      bool isFirstPoint = true;

      for (int x = 0; x <= gridResolution; x++) {
        final cacheKey = (_timeHash << 16) | (y << 8) | x;
        final noiseVal = _getNoiseOffsetCached(
          x.toDouble(),
          y.toDouble(),
          cacheKey,
          gridResolution,
        );

        final px = x * cellWidth + noiseVal;
        final py = y * cellHeight + (math.sin(time * 0.5 + x * 0.4) * 0.6);

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
    for (int x = 0; x <= gridResolution; x++) {
      final path = Path();
      bool isFirstPoint = true;

      for (int y = 0; y <= gridResolution; y++) {
        final cacheKey = (_timeHash << 16) | (x << 8) | y | 0x8000;
        final noiseVal = _getNoiseOffsetCached(
          y.toDouble(),
          x.toDouble(),
          cacheKey,
          gridResolution,
        );

        final px = x * cellWidth + (math.cos(time * 0.5 + y * 0.4) * 0.6);
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
  double _getNoiseOffsetCached(double x, double y, int cacheKey, int gridResolution) {
    final cached = _noiseCache[cacheKey];
    if (cached != null) {
      return cached;
    }
    final value = _getNoiseOffset(x, y, gridResolution);
    _noiseCache[cacheKey] = value;
    return value;
  }

  /// Sample Perlin noise with single octave for better performance
  double _getNoiseOffset(double x, double y, int gridResolution) {
    final sampleX = (x * scale + time * 0.1) / gridResolution;
    final sampleY = (y * scale) / gridResolution;
    return _noise.getNoise2(sampleX, sampleY) * strength * 0.8; // Reduced strength multiplier
  }

  @override
  bool shouldRepaint(GlassDistortionPainter oldDelegate) =>
      oldDelegate._timeHash != _timeHash || oldDelegate.strength != strength;

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

    return ValueListenableBuilder<bool>(
      valueListenable: animationProvider.isLowPerformanceMode,
      builder: (context, isLowPerf, _) {
        if (isLowPerf) return child;

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
                      time: animationProvider.animationController.value * 5,
                      strength: distortionStrength,
                      scale: distortionScale,
                      lowQuality: isLowPerf,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              // Content layer
              child ?? const SizedBox.shrink(),
            ],
          ),
          child: child,
        );
      },
    );
  }
}
