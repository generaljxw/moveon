// test/utils/responsive_helper_test.dart — ResponsiveHelper 工具类测试
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moveon/utils/responsive_helper.dart';

void main() {
  group('ResponsiveHelper', () {
    // ---- 横屏检测 ----
    testWidgets('isLandscape returns true when width > height', (tester) async {
      // 设置横屏尺寸（1280x720）
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = ResponsiveHelper.isLandscape(context);
              return Text(result ? 'landscape' : 'portrait');
            },
          ),
        ),
      );

      expect(find.text('landscape'), findsOneWidget);
    });

    testWidgets('isLandscape returns false when height > width', (tester) async {
      // 竖屏（360x640 — 手机默认）
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final result = ResponsiveHelper.isLandscape(context);
              return Text(result ? 'landscape' : 'portrait');
            },
          ),
        ),
      );

      expect(find.text('portrait'), findsOneWidget);
    });

    // ---- 网格列数 ----
    testWidgets('gridColumns returns 2 in portrait', (tester) async {
      tester.view.physicalSize = const Size(720, 1280);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text('${ResponsiveHelper.gridColumns(context)}');
            },
          ),
        ),
      );

      // 竖屏 = 2 列
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('gridColumns returns 4 in landscape', (tester) async {
      tester.view.physicalSize = const Size(2560, 1440);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text('${ResponsiveHelper.gridColumns(context)}');
            },
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
    });

    // ---- 移动端判定 ----
    testWidgets('isMobile returns true for phone-sized screens', (tester) async {
      tester.view.physicalSize = const Size(720, 1280); // 360dp wide
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text(ResponsiveHelper.isMobile(context) ? 'mobile' : 'desktop');
            },
          ),
        ),
      );

      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('isMobile returns false for wide screens', (tester) async {
      tester.view.physicalSize = const Size(3840, 2160); // ~960dp wide
      tester.view.devicePixelRatio = 4.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text(ResponsiveHelper.isMobile(context) ? 'mobile' : 'desktop');
            },
          ),
        ),
      );

      expect(find.text('desktop'), findsOneWidget);
    });
  });
}
