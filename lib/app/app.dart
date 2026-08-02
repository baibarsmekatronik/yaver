import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../features/auth/presentation/login_screen.dart';
import 'theme/theme.dart';

/// Uygulamanın kök widget'ı.
///
/// Dil sırası: Türkçe birinci, İngilizce ikinci. Cihaz dili ikisinden
/// biri değilse Türkçe'ye düşer (kullanıcı kitlesi ağırlıkla Türkiye'de).
class FleetCareApp extends StatelessWidget {
  const FleetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: buildBaibarsTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supported) {
        for (final locale in supported) {
          if (locale.languageCode == deviceLocale?.languageCode) {
            return locale;
          }
        }
        return const Locale('tr');
      },
      home: const LoginScreen(),
    );
  }
}
