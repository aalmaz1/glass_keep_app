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
class VisionGlassCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget mainContent = Stack(
          children: [
            // Specular border highlights
            Positioned.fill(
              child: ValueListenableBuilder<Offset>(
                valueListenable: animationProvider?.tilt ?? GlassAnimationProvider.defaultOffset,
                builder: (context, currentTilt, _) {
                  return CustomPaint(
                    painter: _SpecularBorderPainter(
                      borderRadius: borderRadius,
                      tilt: currentTilt,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ],
        );

        if (useDistortion) {
          mainContent = GlassDistortionEffect(
            borderRadius: borderRadius,
            child: mainContent,
          );
        }

        final blurFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur);
        
        Widget cardContent = Container(
          decoration: BoxDecoration(
            color: color ?? AppColors.glassLight,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border,
          ),
          child: mainContent,
        );

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              // Multi-layered deep premium shadows for physical depth
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 50,
                offset: const Offset(0, 25),
                spreadRadius: -15,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: blurFilter,
              child: cardContent,
            ),
          ),
        );
      },
    );
  }
}

/// Painter for specular border highlights on glass cards with enhanced dual-layer gradient
/// and gyroscope-based dynamic lighting
class _SpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final Offset tilt;

  const _SpecularBorderPainter({
    required this.borderRadius,
    this.tilt = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Primary specular border with complex gradient simulating light catch
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = ui.Gradient.linear(
        Offset.zero + Offset(tilt.dx * 20, tilt.dy * 20),
        Offset(size.width, size.height) + Offset(tilt.dx * 20, tilt.dy * 20),
        [
          Colors.white.withOpacity(0.9),
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.7),
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.8),
        ],
        const [0.0, 0.25, 0.5, 0.75, 1.0],
      );

    // Secondary subtle highlight for added depth on the opposite edge
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = ui.Gradient.linear(
        Offset(size.width, 0) - Offset(tilt.dx * 30, tilt.dy * 30),
        Offset(0, size.height) - Offset(tilt.dx * 30, tilt.dy * 30),
        [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.0),
        ],
        const [0.0, 0.5, 1.0],
      );

    canvas.drawRRect(rrect, paint1);
    canvas.drawRRect(rrect, paint2);
  }

  @override
  bool shouldRepaint(covariant _SpecularBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.tilt != tilt;
}

/// Premium animated background with moving aurora blobs and noise texture
class VisionBackground extends StatelessWidget {
  const VisionBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);
    final animation = animationProvider?.animationController;

    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          if (animation != null)
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Drifting aurora blobs optimized with RadialGradient
                    _AuroraBlob(
                      color: AppColors.accentBlue.withOpacity(0.25),
                      size: 800,
                      alignment: Alignment.topLeft,
                      depth: 0.05,
                      baseOffset: Offset(
                        math.cos(animation.value * 2 * math.pi) * 150 - 150,
                        math.sin(animation.value * 2 * math.pi) * 150 - 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: AppColors.accentPurple.withOpacity(0.2),
                      size: 900,
                      alignment: Alignment.bottomRight,
                      depth: 0.08,
                      baseOffset: Offset(
                        math.sin(animation.value * 2 * math.pi) * 200 + 150,
                        math.cos(animation.value * 2 * math.pi) * 200 + 150,
                      ),
                    ),
                    if (!kIsWeb) ...[
                      _AuroraBlob(
                        color: AppColors.accentBlue.withOpacity(0.15),
                        size: 600,
                        alignment: Alignment.centerLeft,
                        depth: 0.03,
                        baseOffset: Offset(
                          math.cos(animation.value * 2 * math.pi + math.pi / 2) * 250,
                          math.sin(animation.value * 2 * math.pi + math.pi / 2) * 150,
                        ),
                      ),
                      _AuroraBlob(
                        color: AppColors.accentPurple.withOpacity(0.12),
                        size: 700,
                        alignment: Alignment.topRight,
                        depth: 0.1,
                        baseOffset: Offset(
                          math.sin(animation.value * 2 * math.pi + math.pi / 4) * 200,
                          math.cos(animation.value * 2 * math.pi + math.pi / 4) * 200,
                        ),
                      ),
                    ],
                    
                    // Noise texture overlay for tactile feel, moved inside AnimatedBuilder for animation
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
            const Stack(
              children: [
                Positioned(
                  top: -150,
                  right: -150,
                  child: _AuroraBlob(
                    color: Color(0x336C5CE7),
                    size: 500,
                    baseOffset: Offset.zero,
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: -100,
                  child: _AuroraBlob(
                    color: Color(0x330984E3),
                    size: 400,
                    baseOffset: Offset.zero,
                  ),
                ),
              ],
            ),
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
            final screenSize = MediaQuery.of(context).size;
            final center = Offset(screenSize.width / 2, screenSize.height / 2);
            final relPos = pointerPos - center;
            final dist = relPos.distance;
            final maxDim = math.max(screenSize.width, screenSize.height);
            
            // Non-linear scaling: using square root for a more organic, liquid transition.
            // This ensures the movement isn't strictly linear to the pointer position.
            final normalizedDist = (dist / maxDim).clamp(0.0, 1.0);
            final liquidFactor = math.sqrt(normalizedDist);

            // Incorporate depth into interaction to create layered 3D repulsion effect.
            // Blobs at different depths will react with different intensities.
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
                    color.withOpacity(color.opacity * 0.5),
                    color.withOpacity(0.0),
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

  const _ShaderNoisePainter({this.program, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    if (program == null) {
      // Fallback to simpler grain if shader not loaded
      final random = math.Random(42);
      for (int i = 0; i < 400; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final paint = Paint()..color = Colors.white.withOpacity(0.01);
        canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
      }
      return;
    }

    final shader = program!.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ShaderNoisePainter oldDelegate) =>
      oldDelegate.time != time || oldDelegate.program != program;
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
      color: Colors.white.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          onChanged(value);
        },
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          icon: const Icon(
            CupertinoIcons.search,
            color: Colors.white, // simplified for const
            size: 24,
            shadows: AppColors.iconShadows,
          ),
          hintText: 'Search notes...',
          hintStyle: const TextStyle(color: Colors.white38),
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
        color: AppColors.accentBlue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accentBlue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentBlue,
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
        color: color ?? Colors.white.withOpacity(0.1),
        padding: const EdgeInsets.all(12),
        child: Center(child: child),
      ),
    );
  }
}
