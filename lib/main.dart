import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/demo/demo_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const BFarmApp(),
    ),
  );
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
          home: const _AppEntry(),
        );
      },
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () {
          if (mounted) setState(() => _splashDone = true);
        },
      );
    }
    return const DemoHome();
  }
}
