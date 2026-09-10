import 'package:flutter_test/flutter_test.dart';
import 'package:campusx/main.dart';

void main() {
  testWidgets('CampusX app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusX());

    expect(find.text('CampusX'), findsOneWidget);
  });
}
