import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glass_keep/glass_effect.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:glass_keep/constants.dart';

class VisionGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;

  const VisionGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 24,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Backdrop blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: const SizedBox.expand(),
            ),

            // Glass tint layer - subtle white for light theme
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),

            // Glass distortion effect layer wrapped in RepaintBoundary
            // to isolate animations from the rest of the widget tree
            RepaintBoundary(
              child: GlassDistortionEffect(
                borderRadius: borderRadius,
                distortionStrength: 2.0,
                distortionScale: 0.015,
                child: const SizedBox.expand(),
              ),
            ),

            // Inset shine effect - subtle for light theme
            _ShineLayer(borderRadius: borderRadius),

            // Content
            Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Inset shine effect for glass morphism - adjusted for light theme
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
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 1,
              spreadRadius: 0,
              offset: const Offset(1, 1),
              inset: true,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 0.5,
              spreadRadius: 0.5,
              offset: const Offset(-0.5, -0.5),
              inset: true,
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
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.primaryText, fontSize: 17),
        cursorColor: AppColors.accentBlue,
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          hintStyle: TextStyle(color: AppColors.secondaryText.withValues(alpha: 0.6)),
          border: InputBorder.none,
          icon: const Icon(CupertinoIcons.search, color: AppColors.secondaryText, size: 20),
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
        color: AppColors.accentBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2), width: 0.5),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF5F5F7),
            Color(0xFFE8E8ED),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle gradient orbs for depth
          Positioned(
            top: 100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentBlue.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
              child: Container(
                decoration: widget.isPrimary
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius - 4),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.accentBlue.withValues(alpha: 0.8),
                            AppColors.accentBlue.withValues(alpha: 0.9),
                          ],
                        ),
                      )
                    : null,
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: widget.isPrimary ? Colors.white : AppColors.primaryText,
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
        reverseCurve: Curves.spring,
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
