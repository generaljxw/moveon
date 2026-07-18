// lib/screens/follow/follow_home_screen.dart — 跟练首页（运动类型网格）
import 'package:flutter/material.dart';
import '../../models/workout_category.dart';
import '../../services/category_service.dart';
import 'video_list_screen.dart';

/// 跟练首页 — 8 种运动类型的卡片网格
///
/// 每行 2 列，显示分类图标、名称和视频数量角标。
/// 点击卡片进入对应类型的视频列表。
class FollowHomeScreen extends StatelessWidget {
  const FollowHomeScreen({super.key});

  @override Widget build(BuildContext context) {
    final categories = CategoryService().getCategories();
    return Scaffold(
      appBar: AppBar(title: const Text('视频跟练')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,           // 每行 2 列
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,      // 正方形卡片
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

/// 运动类型卡片 — 图标 + 名称 + 视频角标
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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 40, color: Colors.teal),
              const SizedBox(height: 8),
              Text(category.name, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              // 视频角标：有视频显示数量，无视频显示"敬请期待"
              Text(
                category.hasVideos ? '${category.videoCount} 个视频' : '敬请期待',
                style: TextStyle(fontSize: 12, color: category.hasVideos ? Colors.teal : Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
