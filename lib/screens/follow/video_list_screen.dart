// lib/screens/follow/video_list_screen.dart — 分类下的视频列表
import 'package:flutter/material.dart';
import '../../models/workout_category.dart';
import '../../services/category_service.dart';
import 'video_player_screen.dart';

/// 视频列表页 — 展示某运动类型下的所有跟练视频
///
/// 无视频时显示空状态插图和提示文字。
class VideoListScreen extends StatelessWidget {
  final WorkoutCategory category;
  const VideoListScreen({super.key, required this.category});

  @override Widget build(BuildContext context) {
    final videos = CategoryService().getVideosForCategory(category.name);

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: videos.isEmpty
          ? _buildEmpty()                       // 空状态
          : ListView.builder(                   // 视频列表
              padding: const EdgeInsets.all(16),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return ListTile(
                  leading: const Icon(Icons.play_circle_fill, color: Colors.teal, size: 36),
                  title: Text(video.title),
                  subtitle: Text('${video.durationSeconds ~/ 60} 分钟'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video))),
                );
              },
            ),
    );
  }

  /// 空状态：该分类暂无视频
  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无视频，敬请期待', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
