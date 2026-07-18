// test/screens/follow/add_video_dialog_test.dart — 视频添加弹窗 Widget 测试
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/models/online_video.dart';
import 'package:moveon/screens/follow/add_video_dialog.dart';

void main() {
  group('AddVideoDialog', () {
    // ---- 添加模式：标题正确 ----
    testWidgets('shows "添加在线视频" title in add mode', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context, category: '瑜伽'),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('添加在线视频'), findsOneWidget);
    });

    // ---- 添加模式：有名称和 URL 输入框 ----
    testWidgets('renders name and URL text fields', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context, category: '体操'),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 弹窗中有两个 TextField（名称 + URL）+ 两个 ChoiceChip
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('视频名称'), findsOneWidget); // labelText
      expect(find.text('视频链接'), findsOneWidget); // labelText
    });

    // ---- 添加模式：空名称保存 → 显示校验错误 ----
    testWidgets('shows validation error for empty title', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context, category: '体操'),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 不输入任何内容，直接点保存
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 校验错误应显示
      expect(find.text('请输入视频名称'), findsOneWidget);
      // 弹窗应仍然显示（未关闭）
      expect(find.text('添加在线视频'), findsOneWidget);
    });

    // ---- 添加模式：空 URL 保存 → 显示校验错误 ----
    testWidgets('shows validation error for empty URL', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context, category: '体操'),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 输入名称但不输入 URL
      await tester.enterText(find.byType(TextField).first, '我的视频');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      expect(find.text('请输入视频链接'), findsOneWidget);
    });

    // ---- 添加模式：取消 → Pop 返回 null ----
    testWidgets('cancel returns null', (tester) async {
      OnlineVideo? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showAddVideoDialog(context, category: '瑜伽');
              },
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    // ---- 编辑模式：预填已有数据 ----
    testWidgets('pre-fills fields in edit mode', (tester) async {
      final existing = OnlineVideo(
        id: 1, userId: 42, category: '瑜伽',
        title: '晨间瑜伽', url: 'https://example.com/yoga.mp4',
        videoType: 'direct', createdAt: DateTime(2026, 7, 18, 8, 0),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context,
                  category: '瑜伽', existingVideo: existing),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 弹窗标题变为"编辑在线视频"
      expect(find.text('编辑在线视频'), findsOneWidget);
      // TextField 预填了名称
      expect(find.text('晨间瑜伽'), findsOneWidget);
      // 找到第二个 ChoiceChip（直链视频），应处于选中态
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips[1].selected, true); // '直链视频' = 第二个 Chip
    });

    // ---- 类型切换：ChoiceChip 交互 ----
    testWidgets('toggle video type switches to link', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () => showAddVideoDialog(context, category: '瑜伽'),
              child: const Text('open'),
            );
          }),
        ),
      ));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // '在线链接' 默认选中（因为空 URL → detectVideoType 返回 'link'）
      var chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips[0].selected, true);  // '在线链接' = 第一个 Chip
      expect(chips[1].selected, false); // '直链视频' = 第二个 Chip

      // 点击 '直链视频' 切换
      await tester.tap(find.text('直链视频'));
      await tester.pumpAndSettle();

      chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips[0].selected, false);
      expect(chips[1].selected, true);  // 现在 '直链视频' 选中
    });
  });
}
