import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/screens.dart';
import 'package:glass_keep/auth_screen.dart';
import 'package:glass_keep/constants.dart';
import 'firebase_options.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
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
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exception}');
    };

    runApp(const GlassKeepApp());
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
  });
}

/// Global provider for sharing a single AnimationController across all glass effects
class GlassAnimationProvider extends InheritedWidget {
  final AnimationController animationController;
  final Animation<double> animation;

  const GlassAnimationProvider({
    super.key,
    required this.animationController,
    required this.animation,
    required super.child,
  });

  static GlassAnimationProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlassAnimationProvider>();
  }

  @override
  bool updateShouldNotify(GlassAnimationProvider oldWidget) => false;
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
  }

  @override
  void dispose() {
    _glassAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassAnimationProvider(
      animationController: _glassAnimationController,
      animation: _glassAnimationController,
      child: MaterialApp(
        title: 'Glass Keep',
        debugShowCheckedModeBanner: false,
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
        supportedLocales: const [
          Locale('en'),
          Locale('ru'),
        ],
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
              return Scaffold(
                backgroundColor: AppColors.obsidianDark,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
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
                          CupertinoIcons.doc_text,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const CupertinoActivityIndicator(
                        color: AppColors.accentBlue,
                        radius: 14,
                      ),
                    ],
                  ),
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
                    backgroundColor: AppColors.obsidianDark,
                    body: Center(
                      child: CupertinoActivityIndicator(
                        color: AppColors.accentBlue,
                      ),
                    ),
                  );
                },
              );
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
