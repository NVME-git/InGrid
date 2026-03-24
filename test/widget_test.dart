import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingrid/app.dart';

void main() {
  testWidgets('InGrid app launches and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: InGridApp()));
    // App should show the InGrid title
    expect(find.text('InGrid'), findsOneWidget);
  });
}
