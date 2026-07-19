// lib/screens/follow/follow_home_screen.dart — 跟练首页（运动类型网格 + 在线视频计数）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/workout_category.dart';
import '../../services/category_service.dart';
import '../../services/database_service.dart';
import '../../state/auth_provider.dart';
import '../../theme.dart';
import '../../utils/responsive_helper.dart';
import 'video_list_screen.dart';

/// 跟练首页 — 8 种运动类型的彩色卡片网格
///
/// 一排 4 个，每个卡片使用分类专属浅色背景。
/// 视频计数 = 内置视频数 + 用户在该分类下的在线视频数。
class FollowHomeScreen extends StatefulWidget {
  const FollowHomeScreen({super.key});
  @override State<FollowHomeScreen> createState() => _FollowHomeScreenState();
}

class _FollowHomeScreenState extends State<FollowHomeScreen> {
  /// 各分类的在线视频数量映射（categoryName → count）
  Map<String, int> _onlineCounts = {};

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOnlineCounts();
  }

  /// 查询当前用户在各分类下的在线视频数量
  Future<void> _loadOnlineCounts() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.currentUser?.id == null) {
      if (mounted) setState(() => _onlineCounts = {});
      return;
    }

    final db = await DatabaseService.instance.database;
    // 按 category 分组统计在线视频数量
    final rows = await db.rawQuery(
      'SELECT category, COUNT(*) as cnt FROM online_videos '
      'WHERE user_id = ? GROUP BY category',
      [auth.currentUser!.id!],
    );
    if (mounted) {
      setState(() {
        _onlineCounts = {
          for (final r in rows) r['category'] as String: r['cnt'] as int,
        };
      });
    }
  }

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
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.gridColumns(context),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          // 总视频数 = 内置视频数 + 用户在线视频数
          final onlineCount = _onlineCounts[cat.name] ?? 0;
          final totalCount = cat.videoCount + onlineCount;
          return _CategoryCard(
            category: cat,
            onlineCount: onlineCount,
            totalCount: totalCount,
            // await push → 返回后刷新计数（与 DIY 列表模式一致）
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VideoListScreen(category: cat)));
              _loadOnlineCounts();
            },
          );
        },
      ),
    );
  }
}

/// 运动类型卡片 — 分类专属浅色背景 + 深色图标 + 名称 + 视频计数角标
class _CategoryCard extends StatelessWidget {
  final WorkoutCategory category;
  final int onlineCount;
  final int totalCount;
  final VoidCallback onTap;
  const _CategoryCard({
    required this.category,
    required this.onlineCount,
    required this.totalCount,
    required this.onTap,
  });

  @override Widget build(BuildContext context) {
    final bgColor = category.backgroundColor;
    // 有视频（内置+在线）时用绿色，否则灰色
    final hasVideos = totalCount > 0;
    final dotColor = hasVideos ? MoveOnTheme.colorPrimary : MoveOnTheme.colorTextSecondary;
    final textColor = hasVideos ? MoveOnTheme.colorPrimary : MoveOnTheme.colorTextSecondary;

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
              // 深色图标 + 白色半透明圆形衬托
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
              // 视频角标：绿色圆点（有视频）+ 数量，灰色（无视频）
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 6, height: 6,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text(
                    hasVideos ? '$totalCount 个视频' : '敬请期待',
                    style: TextStyle(fontSize: 10, color: textColor),
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
