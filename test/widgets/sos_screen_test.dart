import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_os/core/l10n/app_localizations.dart';
import 'package:emergency_os/features/sos/presentation/sos_screen.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('SosScreen shows hold banner and SOS semantics', (tester) async {
    await pumpLocalizedApp(tester, child: const SosScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final ctx = tester.element(find.byType(SosScreen));
    final l = AppLocalizations.of(ctx);
    expect(find.text(l.sosHoldBanner), findsOneWidget);
    expect(find.text(l.sosHoldButton), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
  });
}
