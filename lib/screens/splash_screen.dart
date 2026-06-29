import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  int _brandingIndex = 0;
  Timer? _brandingTimer;
  bool _precacheDone = false;

  final List<String> _precacheTargets = [
    'assets/images/farm_products_banner.png',
    'assets/images/farm_machines_banner.png',
    'assets/images/farm_chemicals_banner.png',
  ];

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _mainController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _startFlow();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precacheDone) {
      _precacheDone = true;
      _runPrecache();
    }
  }

  Future<void> _runPrecache() async {
    for (var path in _precacheTargets) {
      try {
        await precacheImage(AssetImage(path), context);
      } catch (e) {
        debugPrint('Precache failed for $path: $e');
      }
    }
  }

  void _startFlow() {
    _mainController.forward();

    // Branding Carousel Timer
    _brandingTimer =
        Timer.periodic(const Duration(milliseconds: 2800), (timer) {
      if (mounted) {
        setState(() => _brandingIndex = (_brandingIndex + 1) % 2);
      }
      if (timer.tick >= 2) timer.cancel();
    });

    // Forced Navigation Timer (Safety net)
    Timer(const Duration(milliseconds: 6000), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _brandingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF0D3B26),
              Color(0xFF030D08),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 4),

                // Animated Logo Section
                AnimatedBuilder(
                  animation: _mainController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.green.withOpacity(0.4),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/Bfarm_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'FARMERS MARKET',
                        style: TextStyle(
                          color: AppTheme.greenLight.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                // Subtle Premium Loader
                SizedBox(
                  width: 50,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.greenLight),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Branding Carousel
                SizedBox(
                  height: 80,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1000),
                    child: _brandingIndex == 0
                        ? _buildBrandingItem('A product of',
                            'assets/images/BIVmark_icon.png', 48)
                        : _buildBrandingItem('Powered by',
                            'assets/images/carousel/buyaff.png', 55),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingItem(String label, String asset, double height) {
    return Column(
      key: ValueKey(asset),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 3),
        ),
        const SizedBox(height: 12),
        Image.asset(asset, height: height, fit: BoxFit.contain),
      ],
    );
  }
}
