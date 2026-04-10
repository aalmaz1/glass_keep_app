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
    
    // Load environment variables from .env file
    await dotenv.load(fileName: '.env');
    
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

class GlassKeepApp extends StatelessWidget {
  const GlassKeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glass Keep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
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
        stream: FirebaseAuth.instance.authStateChanges(),
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
              future: StorageService.init(),
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
    );
  }
}
