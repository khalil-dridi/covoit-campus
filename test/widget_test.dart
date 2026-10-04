import 'package:flutter_test/flutter_test.dart';
import 'package:covoit_campus/main.dart';

void main() {
  testWidgets(
    'Covoit Campus démarre correctement',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const CovoitCampusApp(),
      );

      expect(
        find.byType(CovoitCampusApp),
        findsOneWidget,
      );
    },
  );
}