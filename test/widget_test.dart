import 'package:flutter_test/flutter_test.dart';
import 'package:milk_collector/main.dart';

void main() {
  testWidgets('Agil Coleta app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AgilColetaApp());
    expect(find.byType(AgilColetaApp), findsOneWidget);
  });
}
