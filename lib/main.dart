import 'dart:ui' show PlatformDispatcher, PointerDeviceKind;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show FlutterError, debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/theme_provider.dart';
import 'widgets/common_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = FlutterError.presentError;
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled async error: $error\n$stack');
    return true;
  };
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFF5F9F5),
        child: AppErrorState(
          title: 'This section could not be displayed',
          message: kDebugMode
              ? details.exceptionAsString()
              : 'Return to the previous page and try again.',
        ),
      );

  try {
    await Firebase.initializeApp(
      options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
    );

    // FCM background handlers and local notifications are unavailable on web.
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider(create: (_) => AuthService()),
        ],
        child: const BFarmApp(),
      ),
    );
  } catch (error, stack) {
    debugPrint('Application startup failed: $error\n$stack');
    runApp(_StartupFailureApp(error: error));
  }
}

class BFarmApp extends StatelessWidget {
  const BFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'BFarm',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          scrollBehavior: const _AppScrollBehavior(),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _splashDone = false;
  int _retryVersion = 0;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () {
          if (mounted) setState(() => _splashDone = true);
        },
      );
    }

    return StreamBuilder<User?>(
      key: ValueKey(_retryVersion),
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: AppErrorState(
              title: 'Unable to check your session',
              onRetry: () => setState(() => _retryVersion++),
            ),
          );
        }
        if (snapshot.hasData) return const HomeShell();
        if (kIsWeb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthService>().signInAnonymously().catchError((e) {
              debugPrint('Failed to sign in anonymously: $e');
            });
          });
          return const HomeShell();
        }
        return const LoginScreen();
      },
    );
  }
}

class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _StartupFailureApp extends StatelessWidget {
  final Object error;

  const _StartupFailureApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: AppErrorState(
          title: 'BFarm could not start',
          message: kDebugMode
              ? error.toString()
              : 'Check your internet connection, then refresh the page.',
        ),
      ),
    );
  }
}
