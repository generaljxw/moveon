// lib/screens/follow/follow_home_screen.dart — 跟练首页（运动类型网格）
import 'package:flutter/material.dart';
import '../../models/workout_category.dart';
import '../../services/category_service.dart';
import '../../theme.dart';
import 'video_list_screen.dart';

/// 跟练首页 — 8 种运动类型的彩色卡片网格
///
/// 一排 4 个，两排展示完毕，每个卡片使用分类专属浅色背景。
/// 顶部有引导性副标题。
class FollowHomeScreen extends StatelessWidget {
  const FollowHomeScreen({super.key});

  @override Widget build(BuildContext context) {
    final categories = CategoryService().getCategories();
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频跟练'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(24),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('选择运动，开始跟练',
              style: TextStyle(fontSize: 14, color: MoveOnTheme.colorTextSecondary)),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
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

/// 运动类型卡片 — 分类专属浅色背景 + 深色图标 + 名称 + 角标
class _CategoryCard extends StatelessWidget {
  final WorkoutCategory category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override Widget build(BuildContext context) {
    // 使用分类专属浅色背景，替代白色 Card
    final bgColor = category.backgroundColor;
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(MoveOnTheme.spacingCardRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: MoveOnTheme.colorPrimary.withAlpha(40),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 深色图标 + 浅色圆形衬托
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(180),
                  shape: BoxShape.circle,
                ),
                child: Icon(category.iconData, size: 26,
                  color: MoveOnTheme.colorPrimaryDark),
              ),
              const SizedBox(height: 8),
              Text(category.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: MoveOnTheme.colorTextPrimary),
                textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              // 视频角标：有视频=绿色圆点+文字，无视频=灰色点
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: category.hasVideos ? MoveOnTheme.colorPrimary : MoveOnTheme.colorTextSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.hasVideos ? '${category.videoCount}个视频' : '敬请期待',
                    style: TextStyle(fontSize: 10,
                      color: category.hasVideos ? MoveOnTheme.colorPrimary : MoveOnTheme.colorTextSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
