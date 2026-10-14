import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/welcome_landing_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ElectroNormApp());
}

/// Primary application widget for ElectroNorm Pro, initialized with
/// high-contrast dark field theme and reactive localization.
class ElectroNormApp extends StatelessWidget {
  const ElectroNormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: StorageService.instance,
      builder: (context, _) {
        final localeCode = StorageService.instance.localeCode;
        return MaterialApp(
          title: 'ElectroNorm Pro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          locale: Locale(localeCode),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es'),
            Locale('en'),
            Locale('pt'),
          ],
          home: const WelcomeLandingScreen(),
        );
      },
    );
  }
}
