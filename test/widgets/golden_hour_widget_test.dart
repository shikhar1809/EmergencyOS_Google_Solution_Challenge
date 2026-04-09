import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emergency_os/features/sos/presentation/widgets/golden_hour_widget.dart';

void main() {
  testWidgets('GoldenHourWidget shows EXPIRED after 60+ minutes', (tester) async {
    final start = DateTime.now().subtract(const Duration(hours: 1, minutes: 5));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoldenHourWidget(startTime: start),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('EXPIRED'), findsOneWidget);
    expect(find.text('GOLDEN HOUR'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('GoldenHourWidget fires 5-minute milestone', (tester) async {
    GoldenHourMilestone? seen;
    final start = DateTime.now().subtract(const Duration(minutes: 5, seconds: 2));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoldenHourWidget(
            startTime: start,
            onMilestone: (m) => seen = m,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(seen, isNotNull);
    expect(seen!.minuteMark, 5);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
