import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    Widget mainContent = Stack(
      children: [
        // Specular border highlights
        Positioned.fill(
          child: CustomPaint(
            painter: _SpecularBorderPainter(borderRadius: borderRadius),
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
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
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
  }
}

/// Painter for specular border highlights on glass cards with enhanced dual-layer gradient
class _SpecularBorderPainter extends CustomPainter {
  final double borderRadius;

  const _SpecularBorderPainter({required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Primary specular border with complex gradient simulating light catch
    final paint1 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
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
        Offset(size.width, 0),
        Offset(0, size.height),
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
      oldDelegate.borderRadius != borderRadius;
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
                      offset: Offset(
                        math.cos(animation.value * 2 * math.pi) * 150 - 150,
                        math.sin(animation.value * 2 * math.pi) * 150 - 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: AppColors.accentPurple.withValues(alpha: 0.15),
                      size: 900,
                      alignment: Alignment.bottomRight,
                      offset: Offset(
                        math.sin(animation.value * 2 * math.pi) * 200 + 150,
                        math.cos(animation.value * 2 * math.pi) * 200 + 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      size: 600,
                      alignment: Alignment.centerLeft,
                      offset: Offset(
                        math.cos(animation.value * 2 * math.pi + math.pi / 2) * 250,
                        math.sin(animation.value * 2 * math.pi + math.pi / 2) * 150,
                      ),
                    ),
                    _AuroraBlob(
                      color: AppColors.accentPurple.withValues(alpha: 0.08),
                      size: 700,
                      alignment: Alignment.topRight,
                      offset: Offset(
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
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: -100,
                  child: _AuroraBlob(
                    color: Color(0x1A0984E3),
                    size: 400,
                  ),
                ),
              ],
            ),

          // Noise texture overlay for tactile feel, wrapped in RepaintBoundary for performance
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _NoisePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A blurred drifting color blob for the aurora effect using optimized RadialGradient
class _AuroraBlob extends StatelessWidget {
  final Color color;
  final double size;
  final Offset offset;
  final Alignment alignment;

  const _AuroraBlob({
    super.key,
    required this.color,
    required this.size,
    this.offset = Offset.zero,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
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
      ),
    );
  }
}

/// Painter that adds a subtle film grain noise texture
class _NoisePainter extends CustomPainter {
  const _NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Use slightly more dots and varied opacities for a more premium grain look
    for (int i = 0; i < 2500; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = random.nextDouble() * 0.015 + 0.005;
      final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        onChanged: onChanged,
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
      onTap: onTap,
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
