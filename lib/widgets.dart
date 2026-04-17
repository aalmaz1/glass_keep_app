import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/glass_effect.dart';
import 'package:glass_keep/main.dart';

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
    this.blur = 20,
    this.padding,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth == double.infinity ? 300.0 : constraints.maxWidth;
        final height = constraints.maxHeight == double.infinity ? 300.0 : constraints.maxHeight;

        Widget mainContent = Stack(
          children: [
            // Specular border highlights
            Positioned.fill(
              child: ValueListenableBuilder<Offset>(
                valueListenable: animationProvider?.tilt ?? ValueNotifier(Offset.zero),
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

        final aberrationProgram = animationProvider?.aberrationProgram;
        ui.ImageFilter blurFilter = ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur);

        if (aberrationProgram != null) {
          try {
            final shader = aberrationProgram.fragmentShader();
            shader.setFloat(0, width);
            shader.setFloat(1, height);
            shader.setFloat(2, 0.5); // Strength

            blurFilter = ui.ImageFilter.compose(
              outer: ui.ImageFilter.fromShader(shader),
              inner: blurFilter,
            );
          } catch (e) {
            debugPrint('Shader error: $e');
          }
        }

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              // Multi-layered deep premium shadows for physical depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 50,
                offset: const Offset(0, 25),
                spreadRadius: -15,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: blurFilter,
              child: Container(
                decoration: BoxDecoration(
                  color: color ?? AppColors.glassLight,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: border,
                ),
                child: mainContent,
              ),
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

    // Calculate light source offset based on device tilt for dynamic lighting
    final lightOffset = Offset(
      size.width * (0.5 + tilt.dx * 0.5),
      size.height * (0.5 + tilt.dy * 0.5),
    );

    // Primary specular border with complex gradient simulating light catch
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = ui.Gradient.linear(
        Offset.zero + Offset(tilt.dx * 20, tilt.dy * 20),
        Offset(size.width, size.height) + Offset(tilt.dx * 20, tilt.dy * 20),
        [
          Colors.white.withValues(alpha: 0.6),
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.5),
        ],
        [0.0, 0.25, 0.5, 0.75, 1.0],
      );

    // Secondary subtle highlight for added depth on the opposite edge
    final paint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..shader = ui.Gradient.linear(
        Offset(size.width, 0) - Offset(tilt.dx * 30, tilt.dy * 30),
        Offset(0, size.height) - Offset(tilt.dx * 30, tilt.dy * 30),
        [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.0),
        ],
        [0.0, 0.5, 1.0],
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
                      color: AppColors.accentBlue.withValues(alpha: 0.2),
                      size: 800,
                      alignment: Alignment.topLeft,
                      depth: 0.05,
                      baseOffset: Offset(
                        math.cos(animation.value * 2 * math.pi) * 150 - 150,
                        math.sin(animation.value * 2 * math.pi) * 150 - 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: AppColors.accentPurple.withValues(alpha: 0.15),
                      size: 900,
                      alignment: Alignment.bottomRight,
                      depth: 0.08,
                      baseOffset: Offset(
                        math.sin(animation.value * 2 * math.pi) * 200 + 150,
                        math.cos(animation.value * 2 * math.pi) * 200 + 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      size: 600,
                      alignment: Alignment.centerLeft,
                      depth: 0.03,
                      baseOffset: Offset(
                        math.cos(animation.value * 2 * math.pi + math.pi / 2) * 250,
                        math.sin(animation.value * 2 * math.pi + math.pi / 2) * 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: AppColors.accentPurple.withValues(alpha: 0.08),
                      size: 700,
                      alignment: Alignment.topRight,
                      depth: 0.1,
                      baseOffset: Offset(
                        math.sin(animation.value * 2 * math.pi + math.pi / 4) * 200,
                        math.cos(animation.value * 2 * math.pi + math.pi / 4) * 200,
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
                    color: Color(0x1A6C5CE7),
                    size: 500,
                    baseOffset: Offset.zero,
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: -100,
                  child: _AuroraBlob(
                    color: Color(0x1A0984E3),
                    size: 400,
                    baseOffset: Offset.zero,
                  ),
                ),
              ],
            ),

          // Noise texture overlay for tactile feel, wrapped in RepaintBoundary for performance
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _ShaderNoisePainter(
                    program: animationProvider?.grainProgram,
                    time: animation?.value ?? 0,
                  ),
                ),
              ),
            ),
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
    super.key,
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
        first: animationProvider?.pointerPosition ?? ValueNotifier(Offset.zero),
        second: animationProvider?.tilt ?? ValueNotifier(Offset.zero),
        builder: (context, pointerPos, tilt, _) {
          // Calculate interaction offset (repulsion)
          Offset interactionOffset = Offset.zero;
          if (pointerPos != Offset.zero) {
            // This is a bit tricky because pointerPos is in global coordinates
            // For simplicity, we'll assume the center of the screen is the reference
            final screenSize = MediaQuery.of(context).size;
            final center = Offset(screenSize.width / 2, screenSize.height / 2);
            final relPos = pointerPos - center;

            // Simple repulsion based on distance to pointer
            // In a real app, we'd calculate distance to blob center
            interactionOffset = relPos * -0.05;
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
                    color.withValues(alpha: color.alpha * 0.5),
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

/// Helper for listening to two ValueNotifiers
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext, A, B, Widget?) builder;
  final Widget? child;

  const ValueListenableBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, _) {
            return builder(context, a, b, child);
          },
        );
      },
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
      for (int i = 0; i < 1000; i++) {
        final x = random.nextDouble() * size.width;
        final y = random.nextDouble() * size.height;
        final paint = Paint()..color = Colors.white.withValues(alpha: 0.01);
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
      color: Colors.white.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: (value) {
          HapticFeedback.selectionClick();
          onChanged(value);
        },
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          icon: Icon(
            CupertinoIcons.search,
            color: Colors.white.withValues(alpha: 0.6),
            size: 20,
          ),
          hintText: 'Search notes...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
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
        color: AppColors.accentBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.2),
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
        color: color ?? Colors.white.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(12),
        child: Center(child: child),
      ),
    );
  }
}
