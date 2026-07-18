import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/main.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MoveOnApp());

    // Verify the app title is displayed
    expect(find.text('MoveOn (动起来)'), findsOneWidget);
  });
}
