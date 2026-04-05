import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import 'package:glass_keep/constants.dart' show AppColors;
import 'package:glass_keep/firebase_options.dart';
import 'package:glass_keep/l10n/app_localizations.dart';
import 'package:glass_keep/screens.dart';
import 'package:glass_keep/auth_screen.dart';
import 'package:glass_keep/data.dart';

Future<void> main() async {
  runZonedGuarded(
    _initializeApp,
    _handleUncaughtError,
  );
}

/// Initialize the application
Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize desktop window if applicable
  if (!kIsWeb && _isDesktopPlatform()) {
    await _initializeDesktopWindow();
  }

  // Setup error handlers
  FlutterError.onError = _handleFlutterError;

  runApp(const GlassKeepApp());
}

/// Check if platform is desktop (Windows, macOS, Linux)
bool _isDesktopPlatform() {
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Initialize desktop window
Future<void> _initializeDesktopWindow() async {
  try {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
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
  } catch (e) {
    debugPrint('Error initializing desktop window: $e');
  }
}

/// Handle Flutter errors
void _handleFlutterError(FlutterErrorDetails details) {
  FlutterError.presentError(details);
  debugPrint('Flutter Error: ${details.exception}');
  debugPrint('Stack: ${details.stack}');
}

/// Handle uncaught errors
void _handleUncaughtError(Object error, StackTrace stackTrace) {
  debugPrint('Uncaught Error: $error');
  debugPrint('Stack Trace: $stackTrace');
}

/// Main application widget
class GlassKeepApp extends StatelessWidget {
  const GlassKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glass Keep',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
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
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Handle authentication state changes
          if (snapshot.hasError) {
            return _ErrorScreen(error: snapshot.error.toString());
          }

          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen();
          }

          // User is authenticated
          if (snapshot.hasData) {
            return FutureBuilder<StorageService>(
              future: StorageService.init(),
              builder: (context, storageSnapshot) {
                if (storageSnapshot.hasError) {
                  return _ErrorScreen(error: storageSnapshot.error.toString());
                }

                if (storageSnapshot.hasData) {
                  return NotesScreen(storage: storageSnapshot.data!);
                }

                return const _LoadingScreen();
              },
            );
          }

          // User is not authenticated
          return const AuthScreen();
        },
      ),
    );
  }

  /// Build application theme
  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorSchemeSeed: CupertinoColors.activeBlue,
      cupertinoOverrideTheme: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.activeBlue,
      ),
    );
  }
}

/// Loading screen widget
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CupertinoActivityIndicator(
          color: CupertinoColors.activeBlue,
          radius: 20,
        ),
      ),
    );
  }
}

/// Error screen widget
class _ErrorScreen extends StatelessWidget {
  final String error;

  const _ErrorScreen({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_circle,
                color: CupertinoColors.systemRed,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'An Error Occurred',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                ),
                icon: const Icon(CupertinoIcons.home),
                label: const Text('Return Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
