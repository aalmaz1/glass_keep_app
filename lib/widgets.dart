import 'dart:ui' as ui;
import 'dart:math' as math;
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

class _VisionGlassCardState extends State<VisionGlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _hoverAnimation = CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _handleHover(bool isHovered) {
    if (_isHovered == isHovered) return;
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);
    if (animationProvider == null) {
      debugPrint('[SYSTEM-REBORN] VisionGlassCard failed to find GlassAnimationProvider');
    }

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          final hoverValue = _hoverAnimation.value;
          
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
              distortionStrength: hoverValue * 1.5, // Animate distortion strength from 0.0 to 1.5 on hover
              child: mainContent,
            );
          }

          final blurFilter = ui.ImageFilter.blur(
            sigmaX: widget.blur + (hoverValue * 8), 
            sigmaY: widget.blur + (hoverValue * 8)
          );
          
          Widget cardContent = Container(
            decoration: BoxDecoration(
              color: widget.color ?? AppColors.obsidianBlack.withValues(alpha: 0.5 + (hoverValue * 0.1)),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: widget.border,
            ),
            child: mainContent,
          );

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                // Multi-layered deep premium shadows for physical depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5 + (hoverValue * 0.15)),
                  blurRadius: 50 + (hoverValue * 30),
                  offset: Offset(0, 25 + (hoverValue * 15)),
                  spreadRadius: -15,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3 + (hoverValue * 0.05)),
                  blurRadius: 25 + (hoverValue * 15),
                  offset: Offset(0, 12 + (hoverValue * 8)),
                  spreadRadius: -5,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
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
          );
        },
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

    // Primary specular border with complex gradient simulating light catch
    // Intensifies and widens slightly on hover
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + (hoverIntensity * 0.5)
      ..shader = ui.Gradient.linear(
        Offset.zero + Offset(tilt.dx * 20, tilt.dy * 20),
        Offset(size.width, size.height) + Offset(tilt.dx * 20, tilt.dy * 20),
        [
          Colors.white.withValues(alpha: 0.9 + (hoverIntensity * 0.1)),
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.7 + (hoverIntensity * 0.2)),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.8 + (hoverIntensity * 0.15)),
        ],
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      );

    // Secondary subtle highlight for added depth on the opposite edge
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 + (hoverIntensity * 0.4)
      ..shader = ui.Gradient.linear(
        Offset(size.width, 0) - Offset(tilt.dx * 30, tilt.dy * 30),
        Offset(0, size.height) - Offset(tilt.dx * 30, tilt.dy * 30),
        [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.4 + (hoverIntensity * 0.3)),
          Colors.white.withValues(alpha: 0.0),
        ],
        const [0.0, 0.5, 1.0],
      );

    canvas.drawRRect(rrect, paint1);
    canvas.drawRRect(rrect, paint2);
  }

  @override
  bool shouldRepaint(covariant _SpecularBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || 
      oldDelegate.tilt != tilt || 
      oldDelegate.hoverIntensity != hoverIntensity;
}

/// Premium animated background with moving aurora blobs and noise texture
/// Enhanced in V1.6.0 with more layers and support for theme-specific colors.
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
    final animation = animationProvider?.animationController;
    
    // Default colors if none provided - preferring provider state if available
    final bg = backgroundColor ?? animationProvider?.themeColor ?? AppColors.obsidianBlack;
    final colors = blobColors ?? animationProvider?.blobColors ?? [
      AppColors.accentIndigo,
      AppColors.accentTeal,
      AppColors.accentDeepPurple,
      AppColors.accentIndigo,
      AppColors.accentTeal,
      AppColors.accentDeepPurple,
    ];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bg,
      child: Stack(
        children: [
          if (animation != null)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // 5 complex aurora layers with higher opacity and movement
                    _AuroraBlob(
                      color: colors[0 % colors.length].withValues(alpha: 0.45),
                      size: kIsWeb ? 500 : 900,
                      alignment: Alignment.topLeft,
                      depth: 0.07,
                      baseOffset: Offset(
                        math.cos(animation.value * 2 * math.pi) * 300 - 150,
                        math.sin(animation.value * 2 * math.pi) * 300 - 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: colors[1 % colors.length].withValues(alpha: 0.4),
                      size: kIsWeb ? 600 : 1000,
                      alignment: Alignment.bottomRight,
                      depth: 0.12,
                      baseOffset: Offset(
                        math.sin(animation.value * 2 * math.pi) * 400 + 150,
                        math.cos(animation.value * 2 * math.pi) * 400 + 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: colors[2 % colors.length].withValues(alpha: 0.35),
                      size: kIsWeb ? 450 : 850,
                      alignment: Alignment.topRight,
                      depth: 0.09,
                      baseOffset: Offset(
                        math.cos(animation.value * 2 * math.pi + math.pi/3) * 350,
                        math.sin(animation.value * 2 * math.pi + math.pi/3) * 350,
                      ),
                    ),
                    _AuroraBlob(
                      color: colors[3 % colors.length].withValues(alpha: 0.3),
                      size: kIsWeb ? 550 : 750,
                      alignment: Alignment.bottomLeft,
                      depth: 0.06,
                      baseOffset: Offset(
                        math.sin(animation.value * 2 * math.pi + math.pi/2) * 250 - 100,
                        math.cos(animation.value * 2 * math.pi + math.pi/2) * 250 + 100,
                      ),
                    ),
                    _AuroraBlob(
                      color: colors[4 % colors.length].withValues(alpha: 0.25),
                      size: kIsWeb ? 500 : 800,
                      alignment: Alignment.center,
                      depth: 0.15,
                      baseOffset: Offset(
                        math.cos(animation.value * 4 * math.pi) * 200,
                        math.sin(animation.value * 4 * math.pi) * 200,
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
                );
              },
            )
          else
            const ColoredBox(color: AppColors.obsidianBlack),
        ],
      ),
    );
  }
}

/// A blurred drifting color blob for the aurora effect using optimized RadialGradient
/// with parallax and pointer interaction
class _AuroraBlob extends StatelessWidget {
  final Color color;
  final double size;
  final Offset baseOffset;
  final Alignment alignment;
  final double depth;

  const _AuroraBlob({
    required this.color,
    required this.size,
    required this.baseOffset,
    this.alignment = Alignment.center,
    this.depth = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);

    return Align(
      alignment: alignment,
      child: ValueListenableBuilder2<Offset, Offset>(
        first: animationProvider?.pointerPosition ?? GlassAnimationProvider.defaultOffset,
        second: animationProvider?.tilt ?? GlassAnimationProvider.defaultOffset,
        builder: (context, pointerPos, tilt, _) {
          // Calculate interaction offset (repulsion)
          Offset interactionOffset = Offset.zero;
          if (pointerPos != Offset.zero && pointerPos.dx > -500) {
            final screenSize = MediaQuery.sizeOf(context);
            final center = Offset(screenSize.width / 2, screenSize.height / 2);
            final relPos = pointerPos - center;
            final dist = relPos.distance;
            final maxDim = math.max(screenSize.width, screenSize.height);
            
            final normalizedDist = (dist / maxDim).clamp(0.0, 1.0);
            final liquidFactor = math.sqrt(normalizedDist);

            interactionOffset = relPos * (-0.1 - depth * 2.0) * liquidFactor;
          }

          // Calculate parallax offset based on tilt and depth
          final parallaxOffset = tilt * (depth * 500);

          return Transform.translate(
            offset: baseOffset + parallaxOffset + interactionOffset,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color,
                    color.withValues(alpha: color.a * 0.5),
                    color.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          );
        },
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
      final random = math.Random(42);
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.012);

      for (int i = 0; i < 800; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        c.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
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
