// lib/screens/follow/video_player_screen.dart — 视频播放器
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../services/category_service.dart';

/// 全屏视频播放器 — 播放应用内置的跟练视频
///
/// Windows 上由 video_player_win 插件提供 VideoPlayerController 实现，
/// 通过 file:// 路径加载 Flutter 数据目录中的视频文件。
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
      // 构建时 Flutter 将 assets/ 内容复制到 data/flutter_assets/ 目录
      // video_player_win 需要 file:// 路径来加载视频
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final filePath = '$exeDir/data/flutter_assets/${widget.video.assetPath}';

      _controller = VideoPlayerController.file(File(filePath));
      await _controller.initialize();
      await _controller.play();
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('视频无法播放', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('请确认视频文件已正确内置到应用中',
              style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(child: VideoPlayer(_controller)),
        VideoProgressIndicator(_controller, allowScrubbing: true,
          colors: const VideoProgressColors(playedColor: Colors.teal)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  setState(() { _controller.value.isPlaying ? _controller.pause() : _controller.play(); });
                },
              ),
              const Spacer(),
              if (_controller.value.position >= _controller.value.duration)
                TextButton.icon(
                  icon: const Icon(Icons.replay), label: const Text('重新播放'),
                  onPressed: () { _controller.seekTo(Duration.zero); _controller.play(); setState(() {}); },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
