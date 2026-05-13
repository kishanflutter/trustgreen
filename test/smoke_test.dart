import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustgreen/app.dart';

/// Phase-1 smoke test — verifies the full widget graph imports
/// cleanly and renders a first frame without crashing. Real golden
/// / behaviour tests land in Phase 5.
void main() {
  testWidgets('app boots and renders boot screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TrustGreenApp()),
    );

    // First frame should show the boot spinner (CircularProgressIndicator
    // inside BootScreen).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
