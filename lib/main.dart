import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await MobileAds.instance.initialize();
  runApp(const ProviderScope(child: CalendarApp()));
}

class CalendarApp extends ConsumerWidget {
  const CalendarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Calendar 2026',
      debugShowCheckedModeBanner: false,
      theme: settings.highContrastMode
          ? AppTheme.highContrastLightTheme(settings.fontSize)
          : AppTheme.lightTheme(settings.fontSize),
      darkTheme: settings.highContrastMode
          ? AppTheme.highContrastDarkTheme(
              settings.fontSize,
              settings.trueBlackMode,
            )
          : AppTheme.darkTheme(settings.fontSize, settings.trueBlackMode),
      themeMode: settings.themeMode,
      home: const SplashScreen(),
    );
  }
}
