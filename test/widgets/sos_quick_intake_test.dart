import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:emergency_os/core/l10n/app_localizations.dart';
import 'package:emergency_os/core/providers/locale_provider.dart';
import 'package:emergency_os/features/sos/presentation/sos_quick_intake_page.dart';

void main() {
  testWidgets('SosQuickIntakePage drill shell shows practice banner', (tester) async {
    final router = GoRouter(
      initialLocation: '/intake',
      routes: [
        GoRoute(
          path: '/intake',
          builder: (_, __) => const SosQuickIntakePage(isDrillShell: true),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('dashboard')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.textContaining('Practice guided intake'),
      findsOneWidget,
    );
    expect(find.textContaining('Cardiac arrest'), findsOneWidget);
  });
}
