import 'package:flutter/material.dart';
import 'dart:ui' as ui show ImageFilter;

// Vision Background Widget - gradient background for app
class VisionBackground extends StatelessWidget {
  const VisionBackground({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E27),
            const Color(0xFF1A1F3A),
          ],
        ),
      ),
    );
  }
}

// Glass Card Widget - glassmorphism component
class VisionGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool useDistortion;

  const VisionGlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.useDistortion = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF).withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFFFFF).withAlpha(50),
          width: 1.5,
        ),
      ),
      child: useDistortion
          ? BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: child,
            )
          : child,
    );
  }
}

// Glass Search Bar Widget
class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;

  const GlassSearchBar({
    Key? key,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search notes...',
        hintStyle: TextStyle(color: Colors.white.withAlpha(128)),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(50)),
        ),
        filled: true,
        fillColor: const Color(0xFFFFFFFF).withAlpha(25),
      ),
    );
  }
}

// Label Chip Widget
class LabelChip extends StatelessWidget {
  final String label;

  const LabelChip({Key? key, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withAlpha(100),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}