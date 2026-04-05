import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:glass_keep/l10n/app_localizations.dart';

class VisionGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;

  const VisionGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blur = 5,
  });

  @override
  State<VisionGlassCard> createState() => _VisionGlassCardState();
}

class _VisionGlassCardState extends State<VisionGlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  
  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    _hoverController.forward();
  }

  void _onHoverEnd() {
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverStart(),
      onExit: (_) => _onHoverEnd(),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2 + 0.1 * _hoverController.value),
                  blurRadius: 6 + 10 * _hoverController.value,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1 + 0.05 * _hoverController.value),
                  blurRadius: 20 + 10 * _hoverController.value,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: widget.blur + 2 * _hoverController.value, 
                  sigmaY: widget.blur + 2 * _hoverController.value
                ),
                child: Stack(
                  children: [
                    // Background tint layer (liquid glass effect)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    // Shine/highlight effect
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 0,
                            spreadRadius: 0,
                            offset: const Offset(2, 2),
                            inset: true,
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 1,
                            spreadRadius: 1,
                            offset: const Offset(-1, -1),
                            inset: true,
                          ),
                        ],
                      ),
                    ),
                    // Border with enhanced visibility
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(widget.borderRadius),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: widget.padding ?? const EdgeInsets.all(16),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: null,
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
        style: const TextStyle(color: Colors.white, fontSize: 17),
        cursorColor: CupertinoColors.activeBlue,
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          border: InputBorder.none,
          icon: const Icon(CupertinoIcons.search, color: Colors.white70, size: 20),
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
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 200, left: -50,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withValues(alpha: 0.15)),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
            ),
          ),
        ],
      ),
    );
  }
}
