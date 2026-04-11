import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';

import 'package:phishcatch/models/phish_flag.dart';
import 'package:phishcatch/models/scan_result.dart';
import 'package:phishcatch/providers/badge_provider.dart';
import 'package:phishcatch/providers/history_provider.dart';
import 'package:phishcatch/providers/scan_provider.dart';
import 'package:phishcatch/providers/streak_provider.dart';
import 'package:phishcatch/providers/theme_provider.dart';
import 'package:phishcatch/screens/home_scaffold.dart';
import 'package:phishcatch/screens/onboarding/onboarding_screen.dart';
import 'package:phishcatch/screens/splash_screen.dart';
import 'package:phishcatch/services/notification_service.dart';
import 'package:phishcatch/theme/app_theme.dart';
import 'package:phishcatch/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await Hive.initFlutter();
  Hive.registerAdapter(PhishFlagAdapter());
  Hive.registerAdapter(ScanResultAdapter());
  await Hive.openBox<ScanResult>(AppStrings.hiveBoxScans);

  try {
    await NotificationService().init();
  } catch (_) {
    // Notifications are optional and should never block app startup.
  }

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool(AppStrings.prefOnboardingDone) ?? false;

  runApp(PhishCatchApp(showOnboarding: !onboardingDone));
}

class PhishCatchApp extends StatelessWidget {
  final bool showOnboarding;
  const PhishCatchApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ScanProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => StreakProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            home: SplashScreen(showOnboarding: showOnboarding),
            routes: {
              Routes.home: (_) => const HomeScaffold(),
              Routes.onboarding: (_) => const OnboardingScreen(),
            },
          );
        },
      ),
    );
  }
}
