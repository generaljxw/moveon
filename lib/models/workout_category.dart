// lib/models/workout_category.dart — 运动类型分类
/// 运动类型分类 — V1.0 预置 8 种，不可动态增删
///
/// 仅体操类预置了第八套广播体操视频；其余分类暂无视频内容。
class WorkoutCategory {
  /// 分类中文名称
  final String name;

  /// 分类图标在 assets 中的相对路径
  final String iconPath;

  /// 该分类下是否含有可播放的预置视频
  final bool hasVideos;

  /// 预置视频数量
  final int videoCount;

  const WorkoutCategory({
    required this.name,
    required this.iconPath,
    required this.hasVideos,
    required this.videoCount,
  });

  /// V1.0 预置的 8 种运动分类
  ///
  /// 运动类型覆盖"燃脂→塑形→放松"全场景：
  /// - 瑜伽/有氧操/跳绳 → 燃脂心肺
  /// - 塑形/普拉提/体操 → 力量塑形
  /// - 拉伸/冥想 → 恢复放松
  static List<WorkoutCategory> get defaults => [
    const WorkoutCategory(name: '瑜伽', iconPath: 'assets/images/category_icons/yoga.png', hasVideos: false, videoCount: 0),
    const WorkoutCategory(name: '有氧操', iconPath: 'assets/images/category_icons/aerobics.png', hasVideos: false, videoCount: 0),
    const WorkoutCategory(name: '跳绳', iconPath: 'assets/images/category_icons/jump_rope.png', hasVideos: false, videoCount: 0),
    const WorkoutCategory(name: '塑形', iconPath: 'assets/images/category_icons/sculpt.png', hasVideos: false, videoCount: 0),
    // 体操类：V1.0 唯一预置视频（第八套广播体操 480p）
    const WorkoutCategory(name: '体操', iconPath: 'assets/images/category_icons/calisthenics.png', hasVideos: true, videoCount: 1),
    const WorkoutCategory(name: '普拉提', iconPath: 'assets/images/category_icons/pilates.png', hasVideos: false, videoCount: 0),
    const WorkoutCategory(name: '拉伸', iconPath: 'assets/images/category_icons/stretching.png', hasVideos: false, videoCount: 0),
    const WorkoutCategory(name: '冥想', iconPath: 'assets/images/category_icons/meditation.png', hasVideos: false, videoCount: 0),
  ];
}
