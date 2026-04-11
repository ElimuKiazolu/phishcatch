import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/badge_provider.dart';
import '../providers/history_provider.dart';
import '../providers/streak_provider.dart';
import 'home_scaffold.dart';

class SplashScreen extends StatefulWidget {
  final bool showOnboarding;

  const SplashScreen({super.key, required this.showOnboarding});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Fade in animation for the whole splash content.
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Repeating shimmer sweep over the shield image.
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    );

    _initializeApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final minimumDisplay = Future.delayed(const Duration(milliseconds: 2500));

    final auth = context.read<AuthProvider>();
    final history = context.read<HistoryProvider>();
    final badges = context.read<BadgeProvider>();
    final streak = context.read<StreakProvider>();

    final dataLoad = auth.initUserData(history, streak, badges);

    await Future.wait([minimumDisplay, dataLoad]);

    if (!mounted) {
      return;
    }

    if (widget.showOnboarding) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScaffold(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.45;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: AnimatedBuilder(
                    animation: _shimmerAnimation,
                    builder: (context, child) {
                      return ShaderMask(
                        blendMode: BlendMode.srcATop,
                        shaderCallback: (bounds) {
                          final shimmerPosition = _shimmerAnimation.value;
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: const [
                              Colors.transparent,
                              Colors.transparent,
                              Color(0x55FFFFFF),
                              Color(0xAAFFFFFF),
                              Color(0x55FFFFFF),
                              Colors.transparent,
                              Colors.transparent,
                            ],
                            stops: [
                              0.0,
                              (shimmerPosition - 0.3).clamp(0.0, 1.0),
                              (shimmerPosition - 0.15).clamp(0.0, 1.0),
                              shimmerPosition.clamp(0.0, 1.0),
                              (shimmerPosition + 0.15).clamp(0.0, 1.0),
                              (shimmerPosition + 0.3).clamp(0.0, 1.0),
                              1.0,
                            ],
                          ).createShader(bounds);
                        },
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/images/loading_screen_img.png',
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'PhishCatch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Stay one step ahead of scammers',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'v1.0.0',
                style: TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
