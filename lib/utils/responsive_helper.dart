// lib/utils/responsive_helper.dart — 屏幕适配工具
//
// 提供横/竖屏检测、网格列数计算、移动端/桌面端弹窗适配。
// 所有需要响应屏幕大小或方向的 Widget 通过本工具获取参数，
// 避免在业务代码中硬编码尺寸判断。
import 'package:flutter/material.dart';

/// 屏幕适配工具 — 集中管理响应式断点和平台差异
abstract final class ResponsiveHelper {
  ResponsiveHelper._();

  /// 移动端宽度断点（逻辑像素）
  ///
  /// 宽度 ≤ 600dp → 手机布局；> 600dp → 桌面/平板布局
  static const double _mobileBreakpoint = 600.0;

  /// 当前是否为横屏
  ///
  /// 通过 MediaQuery 获取屏幕尺寸，宽度 > 高度 → 横屏。
  static bool isLandscape(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  /// 当前是否为移动端（小屏设备）
  ///
  /// 判定标准：逻辑像素宽度 ≤ 600dp（符合 Material Design 断点规范）。
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= _mobileBreakpoint;
  }

  /// 运动类型网格列数
  ///
  /// 竖屏 → 2 列（手机屏幕 ~360dp 宽度，卡片 + 间距约 170dp/列）；
  /// 横屏 → 4 列（同桌面版布局）。
  static int gridColumns(BuildContext context) {
    return isLandscape(context) ? 4 : 2;
  }

  /// 移动端/桌面端自适应确认弹窗
  ///
  /// 移动端（宽度 ≤ 600dp）：底部 BottomSheet 样式
  /// 桌面端：居中 Dialog 样式
  /// 返回 true = 确认，false = 取消，null = 关闭。
  static Future<bool?> showMobileConfirm(
    BuildContext context, {
    required String title,
    required String content,
    String confirmLabel = '确定',
    String cancelLabel = '取消',
    Color? confirmColor,
  }) {
    if (isMobile(context)) {
      return showModalBottomSheet<bool>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(content, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(cancelLabel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: confirmColor != null
                            ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                            : null,
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 桌面端：标准 Dialog
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel, style: confirmColor != null ? TextStyle(color: confirmColor) : null),
          ),
        ],
      ),
    );
  }

  /// 移动端/桌面端自适应内容容器
  ///
  /// 移动端（宽度 ≤ 600dp）：铺满屏幕宽度（BottomSheet 风格）
  /// 桌面端：居中 Dialog 风格
  /// 返回弹出层的结果。
  static Future<T?> showMobileSheet<T>(
    BuildContext context,
    Widget content,
  ) {
    if (isMobile(context)) {
      return showModalBottomSheet<T>(
        context: context,
        builder: (ctx) => SafeArea(child: content),
      );
    }

    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(content: content),
    );
  }
}
