// Smoke test: without Supabase credentials (no --dart-define in tests), the
// app renders the "not configured" screen instead of crashing.

import 'package:flutter_test/flutter_test.dart';
import 'package:pharma_reserve/main.dart';

void main() {
  testWidgets('shows the config screen when Supabase is not configured',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PharmaReserveApp());
    expect(find.textContaining('Supabase'), findsOneWidget);
  });
}
