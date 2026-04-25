// Last Deployment: 2026-04-23 16:28:40
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoActivityIndicator, CupertinoThemeData, CupertinoIcons;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/screens.dart';
import 'package:glass_keep/auth_screen.dart';
import 'package:glass_keep/constants.dart';
import 'package:glass_keep/widgets.dart';
import 'package:glass_keep/providers.dart';
import 'package:glass_keep/firebase_options.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:glass_keep/notifications_service.dart';
import 'package:glass_keep/biometric_service.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await NotificationService().init();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

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
  Color? _themeColor;
  List<Color>? _blobColors;

  final ValueNotifier<Offset> _pointerPosition =
      ValueNotifier<Offset>(const Offset(-1000, -1000));
  final ValueNotifier<Offset> _tilt = ValueNotifier<Offset>(Offset.zero);
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;

  ui.FragmentProgram? _grainProgram;

  void _changeLocale(Locale newLocale) {
    setState(() => _locale = newLocale);
  }

  void _changeTheme(Color? color, List<Color>? blobs) {
    setState(() {
      _themeColor = color;
      _blobColors = blobs;
    });
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
    // Defer heavy shader loading to improve initial performance
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) _loadShaders();
    });
  }

  Future<void> _loadShaders() async {
    try {
      final grainProgram = await ui.FragmentProgram.fromAsset(
        'shaders/film_grain.frag',
      );
      if (context.mounted) {
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
      // Use longer sampling rate on Web to reduce overhead
      const sensorInterval = kIsWeb 
          ? Duration(milliseconds: 100) 
          : Duration(milliseconds: 20);

      _accelerometerSubscription =
          accelerometerEventStream(samplingPeriod: sensorInterval).listen((AccelerometerEvent event) {
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
      _gyroscopeSubscription = gyroscopeEventStream(samplingPeriod: sensorInterval).listen((GyroscopeEvent event) {
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
      themeColor: _themeColor,
      blobColors: _blobColors,
      onThemeChanged: _changeTheme,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.obsidianBlack)),
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
                scaffoldBackgroundColor: AppColors.obsidianBlack,
                colorSchemeSeed: AppColors.accentBlue,
                fontFamily: kIsWeb ? 'Roboto' : 'Noto Sans',
                fontFamilyFallback: const ['Roboto', 'Arial'],
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
                          Positioned.fill(child: VisionBackground()),
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
                        final storage = storeSnapshot.data;
                        if (storage != null) {
                          return BiometricAuthWrapper(
                            child: NotesScreen(storage: storage),
                          );
                        }
                        return const Scaffold(
                          body: Stack(
                            children: [
                              Positioned.fill(child: VisionBackground()),
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
                  'SYSTEM-REBORN-V1.6.0',
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
              AppColors.accentBlue.withValues(alpha: 0.8),
              AppColors.accentDeepPurple.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }
}

class BiometricAuthWrapper extends StatefulWidget {
  final Widget child;
  const BiometricAuthWrapper({super.key, required this.child});

  @override
  State<BiometricAuthWrapper> createState() => _BiometricAuthWrapperState();
}

class _BiometricAuthWrapperState extends State<BiometricAuthWrapper> {
  bool _isAuthenticated = false;
  bool _isChecking = true;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    if (kIsWeb) {
      if (context.mounted) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
      return;
    }

    final isEnabled = await _biometricService.isEnabled();
    if (!isEnabled) {
      if (context.mounted) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
      return;
    }

    final isAvailable = await _biometricService.isBiometricsAvailable();
    if (!isAvailable) {
      if (context.mounted) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
      return;
    }
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (context.mounted) {
      setState(() => _isChecking = true);
    }
    final authenticated = await _biometricService.authenticate();
    if (context.mounted) {
      setState(() {
        _isAuthenticated = authenticated;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context);
    final appLockedStr = l10n?.appLocked ?? 'App Locked';
    final authenticateStr = l10n?.authenticateToUnlock ?? 
                           'Please authenticate to access your notes';
    final unlockStr = l10n?.unlock ?? 'Unlock';

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: VisionBackground()),
          Center(
            child: _isChecking
                ? const CupertinoActivityIndicator(color: AppColors.accentBlue)
                : VisionGlassCard(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.lock_shield_fill,
                          size: 64,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          appLockedStr,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          authenticateStr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 32),
                        GlassButton(
                          onTap: _authenticate,
                          color: AppColors.accentBlue.withValues(alpha: 0.2),
                          borderRadius: 16,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(CupertinoIcons.lock_open_fill, color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  unlockStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
