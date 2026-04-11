import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glass_keep/glass_effect.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/main.dart';

/// Optimized Vision Glass Card with perfect glassmorphism effect
/// Layer structure:
///   1. Multi-layer soft shadows for luxury depth
///   2. BackdropFilter with blur + saturation
///   3. Gradient tint layer with internal glow
///   4. Gradient border for premium edge glow
///   5. Optional distortion effect
class VisionGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final bool useDistortion;

  const VisionGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blur = 16,
    this.useDistortion = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          // Layer 1: Multi-layer shadows for luxury depth
          boxShadow: [
            // Deep ambient shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 50,
              offset: const Offset(0, 25),
              spreadRadius: -10,
            ),
            // Mid-tone shadow for volume
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
            // Sharp contact shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
              spreadRadius: -2,
            ),
            // Subtle glow highlight
            BoxShadow(
              color: Colors.white.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Layer 2: Backdrop blur effect with saturation (Optimized)
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur)
                    .compose(ui.ImageFilter.matrix(
                  _createSaturationMatrix(1.3),
                )),
                child: const SizedBox.expand(),
              ),

              // Layer 3: Premium gradient tint with internal glow
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.obsidianLight.withOpacity(0.5),
                      AppColors.obsidianDark.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),

              // Layer 4: Gradient border for premium edge glow
              Positioned.fill(
                child: CustomPaint(
                  painter: _GradientBorderPainter(
                    borderRadius: borderRadius,
                    borderWidth: 1.2,
                  ),
                ),
              ),

              // Optional distortion effect layer (isolated)
              if (useDistortion)
                RepaintBoundary(
                  child: GlassDistortionEffect(
                    borderRadius: borderRadius,
                    distortionStrength: 1.2,
                    distortionScale: 0.01,
                    child: const SizedBox.expand(),
                  ),
                ),

              // Layer 5: Enhanced inset shine effect (Internal Glow)
              _EnhancedShineLayer(borderRadius: borderRadius),

              // Content
              Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Create saturation matrix for backdrop filter
  ui.ColorFilter _createSaturationMatrix(double saturation) {
    final s = saturation;
    return ui.ColorFilter.matrix([
      (0.213 + 0.787 * s), (0.715 - 0.715 * s), (0.072 - 0.072 * s), 0, 0,
      (0.213 - 0.213 * s), (0.715 + 0.285 * s), (0.072 - 0.072 * s), 0, 0,
      (0.213 - 0.213 * s), (0.715 - 0.715 * s), (0.072 + 0.928 * s), 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }
}

/// Inset shine effect for glass morphism - adjusted for Obsidian theme
class _ShineLayer extends StatelessWidget {
  final double borderRadius;

  const _ShineLayer({required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(255, 255, 255, 0.05),
              blurRadius: 1,
              spreadRadius: 0,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced inset shine effect with gradient for premium look
class _EnhancedShineLayer extends StatelessWidget {
  final double borderRadius;

  const _EnhancedShineLayer({required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.02),
              Colors.transparent,
              Colors.transparent,
            ],
            stops: const [0.0, 0.2, 0.4, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Gradient border painter for premium edge glow effect
class _GradientBorderPainter extends CustomPainter {
  final double borderRadius;
  final double borderWidth;

  _GradientBorderPainter({
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    
    // Create gradient stroke path
    final path = Path()..addRRect(rrect);
    
    // Draw gradient border using multiple strokes for premium effect
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    // Top-left highlight (brightest)
    final gradient = SweepGradient(
      startAngle: -0.75 * 3.14159,
      endAngle: 0.25 * 3.14159,
      colors: [
        Colors.white.withOpacity(0.4),
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.3, 0.6, 1.0],
      transform: const GradientRotation(-0.75 * 3.14159),
    );

    final shaderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..shader = gradient.createShader(rect);

    canvas.drawRRect(rrect, shaderPaint);

    // Additional subtle inner glow
    final innerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawRRect(rrect.deflate(borderWidth / 2), innerGlowPaint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.borderWidth != borderWidth;
}

class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  const GlassSearchBar({super.key, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return VisionGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      borderRadius: 14,
      blur: 8,
      useDistortion: false,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
        ),
        cursorColor: AppColors.accentBlue,
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
          ),
          border: InputBorder.none,
          icon: const Icon(
            CupertinoIcons.search,
            color: Colors.white70,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class LabelChip extends StatelessWidget {
  final String label;
  const LabelChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accentBlue.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class VisionBackground extends StatelessWidget {
  const VisionBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const ObsidianBackground();
  }
}

class ObsidianBackground extends StatelessWidget {
  const ObsidianBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.obsidianDark,
        ),
        child: const Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: BreathingGlow(),
              ),
            ),
            Positioned.fill(
              child: RepaintBoundary(
                child: MicroNoise(opacity: 0.02),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BreathingGlow extends StatelessWidget {
  const BreathingGlow({super.key});

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);
    if (animationProvider == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: animationProvider.animationController,
      builder: (context, child) {
        final value = animationProvider.animationController.value;
        final breathe = (1.0 + 0.1 * math.sin(value * 2 * math.pi)) / 1.1;

        return Stack(
          children: [
            // Primary top-right blue orb
            Positioned(
              top: -100,
              right: -50,
              child: _GlowOrb(
                color: AppColors.accentBlue,
                opacity: 0.05 * breathe,
                size: 500 * breathe,
              ),
            ),
            // Secondary bottom-left purple orb
            Positioned(
              bottom: -50,
              left: -100,
              child: _GlowOrb(
                color: AppColors.accentPurple,
                opacity: 0.04 * breathe,
                size: 400 * breathe,
              ),
            ),
            // Additional accent green orb for depth
            Positioned(
              top: 200,
              left: -80,
              child: _GlowOrb(
                color: AppColors.accentGreen,
                opacity: 0.03 * breathe,
                size: 300 * breathe,
              ),
            ),
            // Subtle orange accent for warmth
            Positioned(
              bottom: 150,
              right: -60,
              child: _GlowOrb(
                color: AppColors.accentOrange,
                opacity: 0.025 * breathe,
                size: 250 * breathe,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double opacity;
  final double size;

  const _GlowOrb({
    required this.color,
    required this.opacity,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class MicroNoise extends StatelessWidget {
  final double opacity;
  const MicroNoise({super.key, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        painter: _NoisePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42); // Seeded for consistency
    // Increased point count for smoother noise distribution
    final pointCount = (size.width * size.height / 50).clamp(2000, 8000).toInt();
    for (int i = 0; i < pointCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      // Use smaller points with varying opacity for more natural look
      paint.color = Colors.white.withOpacity(random.nextDouble() * 0.3 + 0.1);
      canvas.drawRect(Rect.fromLTWH(x, y, 0.8, 0.8), paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => false;
}

/// Apple-style glass button with spring animation
class GlassButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.backgroundColor,
    this.isPrimary = false,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: VisionGlassCard(
              padding: widget.padding,
              borderRadius: widget.borderRadius,
              blur: widget.isPrimary ? 30 : 20,
              useDistortion: false,
              child: Container(
                decoration: widget.isPrimary
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius - 4),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                                AppColors.accentBlue.withOpacity(0.8),
                                AppColors.accentBlue.withOpacity(0.9),
                              ],
                        ),
                      )
                    : null,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: widget.isPrimary
                        ? Colors.white
                        : AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated glass icon button with scale effect
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;
  final double size;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.size = 44,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.bounceOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: VisionGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: widget.size / 2,
              blur: 10,
              useDistortion: false,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Icon(
                  widget.icon,
                  color: widget.iconColor ?? AppColors.primaryText,
                  size: widget.size * 0.45,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
