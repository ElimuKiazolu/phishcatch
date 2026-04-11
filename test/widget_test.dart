import 'package:flutter_test/flutter_test.dart';

import 'package:phishcatch/main.dart';

void main() {
  testWidgets('app boots with onboarding route', (tester) async {
    await tester.pumpWidget(const PhishCatchApp(showOnboarding: true));

    expect(find.text('Skip'), findsOneWidget);
  });
}
