// lib/models/workout_category.dart — 运动类型分类
import 'package:flutter/material.dart';

/// 运动类型分类 — V1.0 预置 8 种，不可动态增删
///
/// 仅体操类预置了第八套广播体操视频；其余分类暂无视频内容。
class WorkoutCategory {
  /// 分类中文名称
  final String name;

  /// 分类图标在 assets 中的相对路径
  final String iconPath;

  /// Material Icon 图标数据（用于页面展示）
  final IconData iconData;

  /// 该分类下是否含有可播放的预置视频
  final bool hasVideos;

  /// 预置视频数量
  final int videoCount;

  /// 分类专属浅色背景色（16 进制字符串，用于卡片和标签）
  final String backgroundColorHex;

  const WorkoutCategory({
    required this.name,
    required this.iconPath,
    required this.iconData,
    required this.hasVideos,
    required this.videoCount,
    required this.backgroundColorHex,
  });

  /// V1.0 预置的 8 种运动分类
  ///
  /// 体操置首（唯一有预置视频的类型），其余按运动场景排列。
  static List<WorkoutCategory> get defaults => [
    // 体操置首：唯一预置视频（第八套广播体操 480p）
    const WorkoutCategory(name: '体操', iconPath: 'assets/images/category_icons/calisthenics.png', iconData: Icons.accessibility_new, hasVideos: true, videoCount: 1, backgroundColorHex: 'FFE8F5E9'),
    const WorkoutCategory(name: '瑜伽', iconPath: 'assets/images/category_icons/yoga.png', iconData: Icons.self_improvement, hasVideos: false, videoCount: 0, backgroundColorHex: 'FFE0F2F1'),
    const WorkoutCategory(name: '有氧操', iconPath: 'assets/images/category_icons/aerobics.png', iconData: Icons.directions_run, hasVideos: false, videoCount: 0, backgroundColorHex: 'FFFFF3E0'),
    const WorkoutCategory(name: '跳绳', iconPath: 'assets/images/category_icons/jump_rope.png', iconData: Icons.swap_vert, hasVideos: false, videoCount: 0, backgroundColorHex: 'FFFCE4EC'),
    const WorkoutCategory(name: '塑形', iconPath: 'assets/images/category_icons/sculpt.png', iconData: Icons.fitness_center, hasVideos: false, videoCount: 0, backgroundColorHex: 'FFF3E5F5'),
    const WorkoutCategory(name: '普拉提', iconPath: 'assets/images/category_icons/pilates.png', iconData: Icons.airline_seat_flat, hasVideos: false, videoCount: 0, backgroundColorHex: 'FFE8EAF6'),
    const WorkoutCategory(name: '拉伸', iconPath: 'assets/images/category_icons/stretching.png', iconData: Icons.unfold_more, hasVideos: false, videoCount: 0, backgroundColorHex: 'FFFFF8E1'),
    const WorkoutCategory(name: '冥想', iconPath: 'assets/images/category_icons/meditation.png', iconData: Icons.spa, hasVideos: false, videoCount: 0, backgroundColorHex: 'FFE1F5FE'),
  ];

  /// 将 backgroundColorHex 解析为 Color
  Color get backgroundColor => Color(int.parse(backgroundColorHex, radix: 16));
}
