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
///   1. Outer soft shadow
///   2. BackdropFilter with blur
///   3. Gradient tint layer
///   4. Thin border for edge glow
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
          // Layer 1: Outer soft shadow for Luxury Look
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            children: [
              // Layer 2: Backdrop blur effect (Optimized)
              BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: const SizedBox.expand(),
              ),

              // Layer 3 & 4: Obsidian Gradient tint + thin border for edge glow
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.obsidianLight.withOpacity(0.6),
                      AppColors.obsidianDark.withOpacity(0.3),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 0.8,
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

              // Layer 5: Inset shine effect (Internal Glow)
              _ShineLayer(borderRadius: borderRadius),

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
            Positioned(
              top: -100,
              right: -50,
              child: _GlowOrb(
                color: AppColors.accentBlue,
                opacity: 0.05 * breathe,
                size: 500 * breathe,
              ),
            ),
            Positioned(
              bottom: -50,
              left: -100,
              child: _GlowOrb(
                color: AppColors.accentPurple,
                opacity: 0.04 * breathe,
                size: 400 * breathe,
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
    for (int i = 0; i < 1000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1, 1), paint);
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
