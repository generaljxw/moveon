// lib/screens/follow/video_player_screen.dart — 视频播放器
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/category_service.dart';

/// 全屏视频播放器 — 播放打包在应用中的跟练视频
///
/// Windows 上 VideoPlayerController.asset() 存在兼容性问题，
/// 改用 VideoPlayerController.file() 直接从 Flutter 数据目录加载。
class VideoPlayerScreen extends StatefulWidget {
  final VideoInfo video;
  const VideoPlayerScreen({super.key, required this.video});

  @override State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // Windows 桌面：将 Flutter asset 路径转换为文件系统路径
      // 资源文件在构建时被复制到 data/flutter_assets/ 目录（相对于可执行文件）
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final filePath = '$exeDir/data/flutter_assets/${widget.video.assetPath}';

      _controller = VideoPlayerController.file(File(filePath));
      await _controller.initialize();
      await _controller.play(); // 自动开始播放
      setState(() => _initialized = true);
    } catch (_) {
      setState(() => _hasError = true);
    }
  }

  @override void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.video.title)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('视频文件未找到', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                '请将第八套广播体操视频文件（480p MP4）\n'
                '放置到以下目录后重新启动应用：\n\n'
                'assets/videos/radio_calisthenics_8.mp4',
                style: TextStyle(color: Colors.grey, height: 1.6),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: VideoPlayer(_controller)),
        // 进度条和播放时间
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          colors: const VideoProgressColors(playedColor: Colors.teal),
        ),
        // 控制栏：播放/暂停 + 重新播放
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying ? _controller.pause() : _controller.play();
                  });
                },
              ),
              const Spacer(),
              if (_controller.value.position >= _controller.value.duration)
                TextButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('重新播放'),
                  onPressed: () {
                    _controller.seekTo(Duration.zero);
                    _controller.play();
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
