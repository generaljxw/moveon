// lib/screens/follow/follow_home_screen.dart — 跟练首页（运动类型网格）
import 'package:flutter/material.dart';
import '../../models/workout_category.dart';
import '../../services/category_service.dart';
import 'video_list_screen.dart';

/// 跟练首页 — 8 种运动类型的卡片网格
///
/// 一排 4 个，两排展示完毕，无需滚动。
/// 每个卡片显示分类专属图标、名称和视频数量角标。
class FollowHomeScreen extends StatelessWidget {
  const FollowHomeScreen({super.key});

  @override Widget build(BuildContext context) {
    final categories = CategoryService().getCategories();
    return Scaffold(
      appBar: AppBar(title: const Text('视频跟练')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,              // 一排 4 个，8 类刚好两排
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,         // 略高的卡片比例
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return _CategoryCard(
            category: cat,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VideoListScreen(category: cat))),
          );
        },
      ),
    );
  }
}

/// 运动类型卡片 — 专属图标 + 名称 + 视频角标
class _CategoryCard extends StatelessWidget {
  final WorkoutCategory category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // 紧凑内边距适配 4 列布局
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(category.iconData, size: 28, color: Colors.teal),
              const SizedBox(height: 4),
              Text(category.name, style: const TextStyle(fontSize: 13),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                category.hasVideos ? '${category.videoCount}个视频' : '敬请期待',
                style: TextStyle(fontSize: 10, color: category.hasVideos ? Colors.teal : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
