// test/widget_test.dart — 基础 Widget 测试：验证应用根组件可渲染
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/app.dart';

void main() {
  testWidgets('App renders bottom navigation with 3 tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MoveOnApp());
    // 三个底部导航 Tab 存在
    expect(find.text('跟练'), findsOneWidget);
    expect(find.text('DIY'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
