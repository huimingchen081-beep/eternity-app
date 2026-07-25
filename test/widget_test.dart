import 'package:flutter_test/flutter_test.dart';
import 'package:eternity/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EternityApp());
    await tester.pump();
    expect(find.byType(EternityApp), findsOneWidget);
  });
}
