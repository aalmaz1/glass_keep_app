import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:glass_keep/data.dart';
import 'package:glass_keep/screens.dart';
import 'package:glass_keep/auth_screen.dart';
import 'firebase_options.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS)) {
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
    
    // Single AnimationController for all glass distortion effects
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
          scaffoldBackgroundColor: const Color(0xFF0A0A14),
          colorSchemeSeed: CupertinoColors.activeBlue,
          cupertinoOverrideTheme: const CupertinoThemeData(
            brightness: Brightness.dark,
            primaryColor: CupertinoColors.activeBlue,
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
              return Scaffold(body: Center(child: Text('Auth Error: ${snapshot.error}')));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CupertinoActivityIndicator(color: CupertinoColors.activeBlue, radius: 15)),
              );
            }
            
            if (snapshot.hasData) {
              return FutureBuilder<StorageService>(
                future: _storageFuture,
                builder: (context, storeSnapshot) {
                  if (storeSnapshot.hasError) {
                    return Scaffold(body: Center(child: Text('Storage Error: ${storeSnapshot.error}')));
                  }
                  if (storeSnapshot.hasData) {
                    return NotesScreen(storage: storeSnapshot.data!);
                  }
                  return const Scaffold(
                    body: Center(child: CupertinoActivityIndicator(color: CupertinoColors.activeBlue)),
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
