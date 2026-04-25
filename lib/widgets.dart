import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/glass_effect.dart';
import 'package:glass_keep/providers.dart';

/// A premium glass morphism card that uses BackdropFilter and optional distortion
/// Enhanced in V1.6.0 with internal hover state management and smooth distortion scaling.
class VisionGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final bool useDistortion;
  final Color? color;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;

  const VisionGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.useDistortion = true,
    this.color,
    this.blur = 30,
    this.padding,
    this.border,
  });

  @override
  State<VisionGlassCard> createState() => _VisionGlassCardState();
}

class _VisionGlassCardState extends State<VisionGlassCard> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (_isHovered == isHovered) return;
    setState(() {
      _isHovered = isHovered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);
    if (animationProvider == null) {
      debugPrint('[SYSTEM-REBORN] VisionGlassCard failed to find GlassAnimationProvider');
    }

    // Simple hover value without animation controller
    final hoverValue = _isHovered ? 1.0 : 0.0;
    
    Widget mainContent = Stack(
      children: [
        // Specular border highlights
        Positioned.fill(
          child: ValueListenableBuilder<Offset>(
            valueListenable: animationProvider?.tilt ?? GlassAnimationProvider.defaultOffset,
            builder: (context, currentTilt, _) {
              return CustomPaint(
                painter: _SpecularBorderPainter(
                  borderRadius: widget.borderRadius,
                  tilt: currentTilt,
                  hoverIntensity: hoverValue,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: widget.child,
        ),
      ],
    );

    if (widget.useDistortion) {
      mainContent = GlassDistortionEffect(
        borderRadius: widget.borderRadius,
        distortionStrength: hoverValue * 0.5,
        child: mainContent,
      );
    }

    final blurFilter = ui.ImageFilter.blur(
      sigmaX: widget.blur + (hoverValue * 4),
      sigmaY: widget.blur + (hoverValue * 4)
    );
    
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: widget.color ?? AppColors.obsidianBlack.withValues(alpha: 0.5 + (hoverValue * 0.1)),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: widget.border,
      ),
      child: mainContent,
    );

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4 + (hoverValue * 0.1)),
              blurRadius: 40 + (hoverValue * 20),
              offset: Offset(0, 20 + (hoverValue * 10)),
              spreadRadius: -10,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: blurFilter,
            child: cardContent,
          ),
        ),
      ),
    );
  }
}

/// Painter for specular border highlights on glass cards with enhanced dual-layer gradient
/// and gyroscope-based dynamic lighting, now with hover intensity.
class _SpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final Offset tilt;
  final double hoverIntensity;

  const _SpecularBorderPainter({
    required this.borderRadius,
    this.tilt = Offset.zero,
    this.hoverIntensity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Single simplified border highlight for better performance - no hover animation
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = ui.Gradient.linear(
        Offset(tilt.dx * 15, tilt.dy * 15),
        Offset(size.width, size.height) + Offset(tilt.dx * 15, tilt.dy * 15),
        [
          Colors.white.withValues(alpha: 0.7),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.5),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.6),
        ],
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      );

    canvas.drawRRect(rrect, paint1);
  }

  @override
  bool shouldRepaint(covariant _SpecularBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || 
      oldDelegate.tilt != tilt; // Removed hoverIntensity from repaint check for better performance
}

/// Premium static background with elegant gradient and noise texture
/// V1.7.0: Removed animated blobs for clean glassmorphism aesthetic
class VisionBackground extends StatelessWidget {
  final Color? backgroundColor;
  final List<Color>? blobColors;

  const VisionBackground({
    super.key,
    this.backgroundColor,
    this.blobColors,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);
    if (animationProvider == null) {
      debugPrint('[SYSTEM-REBORN] VisionBackground failed to find GlassAnimationProvider');
    }
    
    // Use theme color if available, otherwise default to obsidian black
    final bg = backgroundColor ?? animationProvider?.themeColor ?? AppColors.obsidianBlack;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bg,
            bg.withValues(alpha: 0.95),
            AppColors.accentDeepPurple.withValues(alpha: 0.08),
            bg.withValues(alpha: 0.98),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Subtle static accent glows for depth
          Positioned(
            top: -200,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentIndigo.withValues(alpha: 0.12),
                    AppColors.accentIndigo.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentTeal.withValues(alpha: 0.08),
                    AppColors.accentTeal.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // Noise texture overlay for tactile feel
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ShaderNoisePainter(
                  program: animationProvider?.grainProgram,
                  time: DateTime.now().millisecondsSinceEpoch / 1000.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter that uses a fragment shader for animated film grain noise texture
class _ShaderNoisePainter extends CustomPainter {
  final ui.FragmentProgram? program;
  final double time;

  // Cache for fallback noise to avoid generating it every frame
  static ui.Picture? _cachedFallback;
  static Size? _cachedSize;
  static bool _shaderFailed = false;

  const _ShaderNoisePainter({this.program, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final prog = program;
    if (prog == null || _shaderFailed || kIsWeb) {
      _drawFallbackNoise(canvas, size);
      return;
    }

    try {
      final shader = prog.fragmentShader();
      shader.setFloat(0, size.width);
      shader.setFloat(1, size.height);
      shader.setFloat(2, time);

      final paint = Paint()..shader = shader;
      canvas.drawRect(Offset.zero & size, paint);
    } catch (e) {
      _shaderFailed = true;
      debugPrint('[SYSTEM-REBORN] Noise shader paint failed. Fallback active: $e');
      _drawFallbackNoise(canvas, size);
    }
  }

  void _drawFallbackNoise(Canvas canvas, Size size) {
    if (_cachedFallback == null || _cachedSize != size) {
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder);
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.012);

      // Use a simple deterministic pattern instead of random
      for (int y = 0; y < size.height; y += 3) {
        for (int x = 0; x < size.width; x += 3) {
          if ((x + y) % 7 == 0) {
            c.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.2, 1.2), paint);
          }
        }
      }
      _cachedFallback = recorder.endRecording();
      _cachedSize = size;
    }
    final fallback = _cachedFallback;
    if (fallback != null) {
      canvas.drawPicture(fallback);
    }
  }

  @override
  bool shouldRepaint(covariant _ShaderNoisePainter oldDelegate) =>
      (program != null && oldDelegate.time != time) || oldDelegate.program != program;
}

/// Glass search bar component
class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return VisionGlassCard(
      borderRadius: 12,
      useDistortion: false,
      blur: 10,
      color: Colors.white.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          onChanged(value);
        },
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: const InputDecoration(
          icon: Icon(
            CupertinoIcons.search,
            color: Colors.white,
            size: 24,
            shadows: AppColors.iconShadows,
          ),
          hintText: 'Search notes...',
          hintStyle: TextStyle(color: Colors.white38),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

/// Styled chip for note labels
class LabelChip extends StatelessWidget {
  final String label;

  const LabelChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentDeepPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accentDeepPurple.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentDeepPurple,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Reusable glass button
class GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color? color;
  final double borderRadius;

  const GlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.color,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: VisionGlassCard(
        borderRadius: borderRadius,
        useDistortion: false,
        blur: 10,
        color: color ?? Colors.white.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(12),
        child: Center(child: child),
      ),
    );
  }
}
