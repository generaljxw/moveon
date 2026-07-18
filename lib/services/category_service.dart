// lib/services/category_service.dart — 运动分类与视频资源服务
import '../models/workout_category.dart';

/// 预置视频信息
class VideoInfo {
  final String title;
  final int durationSeconds;
  final String assetPath;
  const VideoInfo({required this.title, required this.durationSeconds, required this.assetPath});
}

/// 运动分类服务 — 提供分类列表和视频查询
///
/// V1.0 数据全部硬编码；后续版本可从服务端动态加载。
class CategoryService {
  /// 获取 V1.0 全部 8 种运动分类
  List<WorkoutCategory> getCategories() => WorkoutCategory.defaults;

  /// 查询某分类下的预置视频列表
  ///
  /// V1.0 仅体操类型有预置视频（第八套广播体操 480p），
  /// 其余分类返回空列表。
  List<VideoInfo> getVideosForCategory(String categoryName) {
    if (categoryName == '体操') {
      return const [
        VideoInfo(title: '第八套广播体操', durationSeconds: 300, assetPath: 'videos/radio_calisthenics_8.mp4'),
      ];
    }
    return [];
  }
}
