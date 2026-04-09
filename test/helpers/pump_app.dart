import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emergency_os/core/l10n/app_localizations.dart';
import 'package:emergency_os/core/providers/locale_provider.dart';

/// Pumps [child] wrapped with [ProviderScope] and app localization delegates.
Future<void> pumpLocalizedApp(
  WidgetTester tester, {
  required Widget child,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: child,
      ),
    ),
  );
}
