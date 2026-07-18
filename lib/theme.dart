// lib/theme.dart — MoveOn Design Token 体系
///
/// 森林系 × 清爽自然风，所有 Token 定义为 static const，
/// 各页面通过 MoveOnTheme.xxx 引用，不硬编码色值。
import 'package:flutter/material.dart';

/// MoveOn Design Tokens — 集中管理颜色、间距、字体、圆角
///
/// 使用方式：MoveOnTheme.colorPrimary / MoveOnTheme.spacingPagePadding
abstract final class MoveOnTheme {
  MoveOnTheme._(); // 不可实例化

  // ============================================================
  // 配色系统（Spec §1.1）
  // ============================================================

  static const colorPrimary = Color(0xFF4CAF50);      // 森林绿
  static const colorPrimaryLight = Color(0xFF81C784);  // 浅薄荷绿
  static const colorPrimaryDark = Color(0xFF388E3C);   // 深绿
  static const colorSurface = Color(0xFFF1F8E9);       // 页面背景
  static const colorCard = Colors.white;               // 卡片底色
  static const colorAccent = Color(0xFFFF7043);        // 警示/高亮（珊瑚橙）
  static const colorTextPrimary = Color(0xFF263238);   // 主文字（蓝灰黑）
  static const colorTextSecondary = Color(0xFF546E7A); // 副文字（灰蓝）
  static const colorDivider = Color(0xFFE0E8E0);       // 分割线（浅绿灰）

  // ============================================================
  // 分类专属浅色背景（Spec §1.2）
  // ============================================================

  static const categoryColors = <String, Color>{
    '体操': Color(0xFFE8F5E9),   // 浅森林绿
    '瑜伽': Color(0xFFE0F2F1),   // 浅湖水绿
    '有氧操': Color(0xFFFFF3E0),  // 浅活力橙
    '跳绳': Color(0xFFFCE4EC),    // 浅玫瑰粉
    '塑形': Color(0xFFF3E5F5),    // 浅优雅紫
    '普拉提': Color(0xFFE8EAF6),  // 浅静谧蓝
    '拉伸': Color(0xFFFFF8E1),    // 浅温暖黄
    '冥想': Color(0xFFE1F5FE),    // 浅天空蓝
  };

  /// 根据分类名称获取专属浅色背景，未匹配返回默认浅绿
  static Color categoryColor(String name) =>
      categoryColors[name] ?? colorSurface;

  // ============================================================
  // 间距与圆角（Spec §1.4）
  // ============================================================

  static const double spacingPagePadding = 24.0;
  static const double spacingCardPadding = 20.0;
  static const double spacingCardRadius = 16.0;
  static const double spacingButtonRadius = 24.0;
  static const double spacingCardGap = 16.0;
  static const double spacingItemGap = 12.0;

  // ============================================================
  // ThemeData 构建
  // ============================================================

  /// 构建完整的 Material ThemeData
  static ThemeData buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colorPrimary,
      primary: colorPrimary,
      surface: colorSurface,
      error: colorAccent,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: colorSurface,

      // AppBar 规范（Spec §2.5）
      appBarTheme: const AppBarTheme(
        backgroundColor: colorSurface,
        foregroundColor: colorTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorTextPrimary,
        ),
      ),

      // 卡片规范（Spec §2.3）
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacingCardRadius),
        ),
      ),

      // 主按钮规范（Spec §2.1）
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacingButtonRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      // 次按钮规范
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorPrimary,
          side: const BorderSide(color: colorPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacingButtonRadius),
          ),
        ),
      ),

      // 底部导航规范（Spec §2.2）
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: colorPrimary,
        unselectedItemColor: colorTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),

      // 进度条规范（Spec §2.4）
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: colorPrimary,
        linearTrackColor: colorDivider,
        linearMinHeight: 6,
      ),

      // 全局水波纹颜色
      splashColor: colorPrimary.withAlpha(50),
    );
  }
}
