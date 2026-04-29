import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/glass_effect.dart';
import 'package:glass_keep/providers.dart';

/// A premium glass morphism card that uses BackdropFilter and optional distortion
/// Refactored in V1.8.1: Removed internal hover state to strictly follow premium spec.
class VisionGlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool useDistortion;
  final Color? color;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final BoxBorder? border;
  final Color? accentColor;

  const VisionGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.useDistortion = true,
    this.color,
    this.blur = 10,
    this.padding,
    this.border,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final animationProvider = GlassAnimationProvider.of(context);
    final accentColor = this.accentColor ?? animationProvider?.accentColor ?? Colors.white;

    return ValueListenableBuilder<bool>(
      valueListenable: animationProvider?.isLowPerformanceMode ?? ValueNotifier(false),
      builder: (context, isLowPerf, _) {
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
                      accentColor: accentColor,
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

        if (useDistortion && !isLowPerf) {
          mainContent = GlassDistortionEffect(
            borderRadius: borderRadius,
            distortionStrength: 0.1, // Fixed minimal distortion
            child: mainContent,
          );
        }

        final blurFilter = ui.ImageFilter.blur(
          sigmaX: blur / (isLowPerf ? 2.0 : 1.0),
          sigmaY: blur / (isLowPerf ? 2.0 : 1.0)
        );
        
        Widget cardContent = Container(
          decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
          child: mainContent,
        );

        return IntrinsicWidth(
          child: IntrinsicHeight(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
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
            ),
          ),
        );
      },
    );
  }
}

/// Painter for specular border highlights on glass cards with enhanced dual-layer gradient
/// and gyroscope-based dynamic lighting.
class _SpecularBorderPainter extends CustomPainter {
  final double borderRadius;
  final Offset tilt;
  final Color accentColor;

  const _SpecularBorderPainter({
    required this.borderRadius,
    this.tilt = Offset.zero,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double br = borderRadius;
    const double sw = 1.0;
    
    // Top path: top-left corner and top edge and top-right corner
    final Path topPath = Path()
      ..moveTo(0, br)
      ..arcToPoint(Offset(br, 0), radius: Radius.circular(br))
      ..lineTo(size.width - br, 0)
      ..arcToPoint(Offset(size.width, br), radius: Radius.circular(br));

    // Left path: top-left corner and left edge and bottom-left corner
    final Path leftPath = Path()
      ..moveTo(br, 0)
      ..arcToPoint(Offset(0, br), radius: Radius.circular(br), clockwise: false)
      ..lineTo(0, size.height - br)
      ..arcToPoint(Offset(br, size.height), radius: Radius.circular(br), clockwise: false);

    // Top highlight: horizontal gradient (90deg)
    final Paint topPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(size.width, 0),
        [
          Colors.transparent,
          accentColor.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      );

    // Left highlight: vertical gradient (180deg)
    final Paint leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [
          Colors.transparent,
          accentColor.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      );

    canvas.drawPath(topPath, topPaint);
    canvas.drawPath(leftPath, leftPaint);
  }

  @override
  bool shouldRepaint(covariant _SpecularBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || 
      oldDelegate.tilt != tilt ||
      oldDelegate.accentColor != accentColor;
}

/// Premium static background with elegant gradient and noise texture
/// V1.7.0: Removed animated blobs for clean glassmorphism aesthetic
/// V1.7.1: Fixed theme color support - now uses blobColors from provider
/// V1.8.0: Optimized noise update frequency for better performance
class VisionBackground extends StatefulWidget {
  final Color? backgroundColor;
  final List<Color>? blobColors;

  const VisionBackground({
    super.key,
    this.backgroundColor,
    this.blobColors,
  });

  @override
  State<VisionBackground> createState() => _VisionBackgroundState();
}

class _VisionBackgroundState extends State<VisionBackground> {
  double _noiseTime = 0;
  
  @override
  void initState() {
    super.initState();
    _noiseTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when theme changes by depending on InheritedWidget
    final animationProvider = GlassAnimationProvider.of(context);
    
    debugPrint('[SYSTEM-REBORN] VisionBackground.build: animationProvider found=${animationProvider != null}');
    if (animationProvider != null) {
      debugPrint('[SYSTEM-REBORN] VisionBackground.build: provider.themeColor=${animationProvider.themeColor}, provider.blobColors=${animationProvider.blobColors}');
    }
    
    // Use widget parameters if provided, otherwise fall back to provider values
    // This ensures that when parent explicitly passes colors, they take precedence
    final bg = widget.backgroundColor ?? animationProvider?.themeColor ?? AppColors.obsidianBlack;
    final blobs = widget.blobColors ?? animationProvider?.blobColors ?? [const Color(0xFF2C2C2E), const Color(0xFF3A3A3C), const Color(0xFF48484A)];
    
    debugPrint('[SYSTEM-REBORN] VisionBackground.build: final bg=$bg, blobs count=${blobs.length}');

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bg,
            bg.withValues(alpha: 0.95),
            bg.withValues(alpha: 0.98),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Dynamic accent glows based on selected theme
          Positioned(
            top: -200,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (blobs.isNotEmpty ? blobs[0] : AppColors.accentBlue).withValues(alpha: 0.15),
                    (blobs.length > 1 ? blobs[1] : AppColors.accentIndigo).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (blobs.length > 1 ? blobs[1] : AppColors.accentIndigo).withValues(alpha: 0.12),
                    (blobs.length > 2 ? blobs[2] : AppColors.accentDeepPurple).withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          
          // Noise texture overlay for tactile feel - updated less frequently
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ShaderNoisePainter(
                  program: animationProvider?.grainProgram,
                  time: _noiseTime,
                ),
              ),
            ),
          ),
        ],
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
  
  // Cache time to reduce repaint frequency on Web
  static double? _lastCachedTime;
  static const double _timeThreshold = 0.1; // Only repaint if time changes by more than 100ms

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
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.012);

      // Use a simple deterministic pattern instead of random
      for (int y = 0; y < size.height; y += 3) {
        for (int x = 0; x < size.width; x += 3) {
          if ((x + y) % 7 == 0) {
            c.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1.2, 1.2), paint);
          }
        }
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
  bool shouldRepaint(covariant _ShaderNoisePainter oldDelegate) {
    // On Web, reduce repaint frequency for better performance
    if (kIsWeb) {
      final lastTime = _lastCachedTime;
      if (lastTime != null && (time - lastTime).abs() < _timeThreshold) {
        return false;
      }
      _lastCachedTime = time;
    }
    return (program != null && oldDelegate.time != time) || oldDelegate.program != program;
  }
}

/// Glass search bar component
class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSortPressed;

  const GlassSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onSortPressed,
  });

  @override
  Widget build(BuildContext context) {
    return VisionGlassCard(
      borderRadius: 12,
      useDistortion: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
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
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (onSortPressed != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onSortPressed!();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.arrow_up_arrow_down,
                  color: Colors.white,
                  size: 20,
                  shadows: AppColors.iconShadows,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Styled chip for note labels
class LabelChip extends StatelessWidget {
  final String label;
  final Color accentColor;

  const LabelChip({super.key, required this.label, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
        color: color ?? Colors.white.withValues(alpha: 0.11),
        padding: const EdgeInsets.all(12),
        child: Center(child: child),
      ),
    );
  }
}

/// A premium glassy checkbox with accent color glows
class GlassCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color accentColor;

  const GlassCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? accentColor : Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          color: value ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
          boxShadow: value ? [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: value
            ? Icon(
                CupertinoIcons.checkmark,
                size: 14,
                color: accentColor,
              )
            : null,
      ),
    );
  }
}

class GlassChecklistItemWidget extends StatefulWidget {
  final String text;
  final bool isChecked;
  final ValueChanged<bool?> onChecked;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemoved;
  final VoidCallback? onSubmitted;
  final Color accentColor;

  const GlassChecklistItemWidget({
    super.key,
    required this.text,
    required this.isChecked,
    required this.onChecked,
    required this.onChanged,
    required this.onRemoved,
    this.onSubmitted,
    required this.accentColor,
  });

  @override
  State<GlassChecklistItemWidget> createState() => _GlassChecklistItemWidgetState();
}

class _GlassChecklistItemWidgetState extends State<GlassChecklistItemWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(GlassChecklistItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) {
      _controller.text = widget.text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: VisionGlassCard(
        borderRadius: 12,
        useDistortion: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Icon(CupertinoIcons.bars, color: Colors.white24, size: 20),
            const SizedBox(width: 8),
            GlassCheckbox(
              value: widget.isChecked,
              onChanged: widget.onChecked,
              accentColor: widget.accentColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: widget.onChanged,
                onSubmitted: (_) => widget.onSubmitted?.call(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: widget.isChecked ? 0.5 : 1.0),
                  decoration: widget.isChecked ? TextDecoration.lineThrough : null,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.multiply, color: Colors.white54, size: 20),
              onPressed: widget.onRemoved,
            ),
          ],
        ),
      ),
    );
  }
}
