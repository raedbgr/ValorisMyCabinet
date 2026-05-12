import 'package:flutter_test/flutter_test.dart';
import 'package:valoris_my_cabinet/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyCabinetApp());
    expect(find.byType(MyCabinetApp), findsOneWidget);
  });
}
