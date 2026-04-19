import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/screens.dart';
import 'package:glass_keep/auth_screen.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/widgets.dart';
import 'firebase_options.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kIsWeb) {
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
        );
      } catch (e) {
        debugPrint('Firestore persistence error: $e');
      }
    }

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await windowManager.ensureInitialized();
      const WindowOptions windowOptions = WindowOptions(
        size: Size(1200, 800),
        minimumSize: Size(400, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('FlutterError: ${details.exception}');
    };

    runApp(const GlassKeepApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
  });
}

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

  @override
  bool updateShouldNotify(GlassAnimationProvider oldWidget) =>
      oldWidget.locale != locale ||
      oldWidget.grainProgram != grainProgram;
}

class GlassKeepApp extends StatefulWidget {
  const GlassKeepApp({super.key});

  @override
  State<GlassKeepApp> createState() => _GlassKeepAppState();
}

class _GlassKeepAppState extends State<GlassKeepApp>
    with TickerProviderStateMixin {
  late Stream<User?> _authStream;
  late Future<StorageService> _storageFuture;
  late AnimationController _glassAnimationController;
  Locale _locale = const Locale('en');

  final ValueNotifier<Offset> _pointerPosition =
      ValueNotifier<Offset>(const Offset(-1000, -1000));
  final ValueNotifier<Offset> _tilt = ValueNotifier<Offset>(Offset.zero);
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;

  ui.FragmentProgram? _grainProgram;

  void _changeLocale(Locale newLocale) {
    setState(() => _locale = newLocale);
  }

  @override
  void initState() {
    super.initState();
    // Initialize streams and futures once to avoid rebuilding
    _authStream = FirebaseAuth.instance.authStateChanges();
    _storageFuture = StorageService.init();

    // Single AnimationController for all glass distortion effects (8s duration for optimal visual)
    _glassAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _initSensors();
    _loadShaders();
  }

  Future<void> _loadShaders() async {
    try {
      final grainProgram = await ui.FragmentProgram.fromAsset(
        'shaders/film_grain.frag',
      );
      if (mounted) {
        setState(() {
          _grainProgram = grainProgram;
        });
      }
    } catch (e) {
      debugPrint('Error loading shaders: $e');
    }
  }

  void _initSensors() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        kIsWeb) {
      _accelerometerSubscription =
          accelerometerEventStream().listen((AccelerometerEvent event) {
        // Low-pass filter for smooth movement
        final newTilt = Offset(
          -event.x / 10.0, // Invert X for more natural tilt
          event.y / 10.0,
        );
        _tilt.value = Offset(
          _tilt.value.dx * 0.9 + newTilt.dx * 0.1,
          _tilt.value.dy * 0.9 + newTilt.dy * 0.1,
        );
      });

      // Properly initialize gyroscope stream for Web and Mobile
      _gyroscopeSubscription = gyroscopeEventStream().listen((GyroscopeEvent event) {
        // Integrate gyroscope for immediate responsiveness
        final kick = Offset(event.y * 0.015, event.x * 0.015);
        _tilt.value = Offset(
          (_tilt.value.dx + kick.dx).clamp(-1.5, 1.5),
          (_tilt.value.dy + kick.dy).clamp(-1.5, 1.5),
        );
      });
    }
  }

  @override
  void dispose() {
    _glassAnimationController.dispose();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _pointerPosition.dispose();
    _tilt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassAnimationProvider(
      animationController: _glassAnimationController,
      locale: _locale,
      onLocaleChanged: _changeLocale,
      pointerPosition: _pointerPosition,
      tilt: _tilt,
      grainProgram: _grainProgram,
      child: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: (event) {
              _pointerPosition.value = event.position;
            },
            onPointerMove: (event) {
              _pointerPosition.value = event.position;
            },
            child: MaterialApp(
              title: 'Glass Keep',
              debugShowCheckedModeBanner: false,
              locale: _locale,
              theme: ThemeData(
                brightness: Brightness.dark,
                useMaterial3: true,
                scaffoldBackgroundColor: AppColors.obsidianDark,
                colorSchemeSeed: AppColors.accentBlue,
                fontFamily: '.SF Pro Display',
                cupertinoOverrideTheme: const CupertinoThemeData(
                  brightness: Brightness.dark,
                  primaryColor: AppColors.accentBlue,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
                inputDecorationTheme: InputDecorationTheme(
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: StreamBuilder<User?>(
                stream: _authStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Text('Auth Error: ${snapshot.error}'),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Stack(
                        children: [
                          VisionBackground(),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _LoadingLogo(),
                                SizedBox(height: 24),
                                CupertinoActivityIndicator(
                                  color: AppColors.accentBlue,
                                  radius: 14,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
    
                  if (snapshot.hasData) {
                    return FutureBuilder<StorageService>(
                      future: _storageFuture,
                      builder: (context, storeSnapshot) {
                        if (storeSnapshot.hasError) {
                          return Scaffold(
                            body: Center(
                              child: Text('Storage Error: ${storeSnapshot.error}'),
                            ),
                          );
                        }
                        if (storeSnapshot.hasData) {
                          return NotesScreen(storage: storeSnapshot.data!);
                        }
                        return const Scaffold(
                          body: Stack(
                            children: [
                              VisionBackground(),
                              Center(
                                child: CupertinoActivityIndicator(
                                  color: AppColors.accentBlue,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                  return const AuthScreen();
                },
              ),
            ),
          ),
          // Deployment verification text - always at the bottom of the stack
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Text(
                  'Obsidian Vision Premium v2 [STABLE-READY]',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w300,
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

class _LoadingLogo extends StatelessWidget {
  const _LoadingLogo();

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'app_logo',
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentBlue.withOpacity(0.8),
              AppColors.accentPurple.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.blur_on,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}
