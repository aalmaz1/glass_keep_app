import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Global provider for sharing a single AnimationController across all glass effects
/// and managing app locale state, sensor data, and pointer positions
class GlassAnimationProvider extends InheritedWidget {
  final AnimationController animationController;
  final Locale locale;
  final Function(Locale) onLocaleChanged;
  final ValueNotifier<Offset> pointerPosition;
  final ValueNotifier<Offset> tilt;
  final ui.FragmentProgram? grainProgram;

  const GlassAnimationProvider({
    super.key,
    required this.animationController,
    required this.locale,
    required this.onLocaleChanged,
    required this.pointerPosition,
    required this.tilt,
    this.grainProgram,
    required super.child,
  });

  static GlassAnimationProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassAnimationProvider>();
  }

  static final ValueNotifier<Offset> defaultOffset = ValueNotifier(Offset.zero);

  @override
  bool updateShouldNotify(GlassAnimationProvider oldWidget) =>
      oldWidget.locale != locale ||
      oldWidget.grainProgram != grainProgram;
}

/// Helper for listening to two ValueNotifiers
class ValueListenableBuilder2<A, B> extends StatelessWidget {
  final ValueListenable<A> first;
  final ValueListenable<B> second;
  final Widget Function(BuildContext context, A a, B b, Widget? child) builder;
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
      builder: (context, a, child) {
        return ValueListenableBuilder<B>(
          valueListenable: second,
          builder: (context, b, child) {
            return builder(context, a, b, child);
          },
          child: child,
        );
      },
      child: child,
    );
  }
}
